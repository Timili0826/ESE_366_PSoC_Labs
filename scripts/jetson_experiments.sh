#!/usr/bin/env bash
# Run on Jetson only, serially. No SSH, profiler, git commit or push commands.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"
MODE=${1:-cpu-only}
case "$MODE" in cpu-only|all-five|incremental|checks) ;; *) echo 'Modes: cpu-only | all-five | incremental | checks' >&2; exit 2;; esac

mkdir -p "$ROOT/outputs/experiments"
# Prevent two experiment runners from contending on the same Jetson.
exec 9>"$ROOT/outputs/experiments/.benchmark.lock"
flock -n 9 || { echo 'Another experiment runner holds the benchmark lock' >&2; exit 1; }
RUN=$(mktemp -d "$ROOT/outputs/experiments/${MODE}_$(date +%Y%m%d_%H%M%S)_XXXXXX")
printf '%s\n' "$RUN" > "$ROOT/outputs/experiments/latest_${MODE}.txt"
printf '%s\n' "$$" > "$RUN/pid.txt"
echo "Run directory: $RUN; PID: $$"
exec > >(tee -a "$RUN/runner.log") 2>&1
trap 'code=$?; printf "FAILED exit=%s line=%s\n" "$code" "$LINENO" > "$RUN/status.txt"; exit "$code"' ERR
trap 'printf "INTERRUPTED\n" > "$RUN/status.txt"; exit 130' INT TERM
printf 'RUNNING\n' > "$RUN/status.txt"
if [[ -z "${ARCH:-}" ]]; then
    echo 'Set ARCH from the actual board: Orin=sm_87; original Nano=sm_53' >&2
    false
fi
DATA=$(realpath "${DATA:-$ROOT/data/mnist}")
export PATH="/usr/local/cuda/bin:$PATH"
command -v nvcc >/dev/null
command -v python3 >/dev/null
for f in train-images-idx3-ubyte train-labels-idx1-ubyte t10k-images-idx3-ubyte t10k-labels-idx1-ubyte; do
    test -f "$DATA/$f" || { echo "Missing data: $DATA/$f" >&2; false; }
done
{
    date -Is; uname -a
    cat /proc/device-tree/model; echo
    nvcc --version; gcc --version | head -n 1
    git rev-parse HEAD; git status --short
    printf 'ARCH=%s\nDATA=%s\nMODE=%s\n' "$ARCH" "$DATA" "$MODE"
} > "$RUN/environment.txt"
python3 -c 'import struct,sys; from pathlib import Path; p=Path(sys.argv[1]); specs=[("train-images-idx3-ubyte",(2051,60000,28,28),47040016),("train-labels-idx1-ubyte",(2049,60000),60008),("t10k-images-idx3-ubyte",(2051,10000,28,28),7840016),("t10k-labels-idx1-ubyte",(2049,10000),10008)]; [(None if struct.unpack(">"+"I"*len(h),(p/n).read_bytes()[:4*len(h)])==h and (p/n).stat().st_size==size else (_ for _ in ()).throw(ValueError(n))) for n,h,size in specs]; print("Full MNIST IDX counts/shapes/lengths verified")' "$DATA"
make -C cpu clean
make -C cpu
python3 tests/test_cpu_output.py cpu/fnn
python3 tests/test_analysis.py
make -C incremental host-check
# Gate all requested training on successful CUDA compile + numerical checks.
for v in cuda_00_baseline cuda_01_selective_tiling cuda_02_forward_fusion cuda_03_register_reuse; do
    make -C "$v" clean
    make -C "$v" ARCH="$ARCH"
    make -C "$v" ARCH="$ARCH" check
 done
make -C incremental clean
make -C incremental ARCH="$ARCH"
./incremental/fnn_incremental --check "$RUN/incremental_checks"
record_run_info() {
    local dir=$1
    printf '\nsource_commit=%s\nenvironment_file=%s\nprofiler=none\n' "$(git rev-parse HEAD)" "$RUN/environment.txt" >> "$dir/run_info.txt"
}
if [[ "$MODE" == cpu-only || "$MODE" == all-five ]]; then
    ./cpu/fnn "$DATA" 20 0.01 32 "$RUN/a_cpu" 2>&1 | tee "$RUN/a_cpu.log"
    record_run_info "$RUN/a_cpu"
fi
if [[ "$MODE" == all-five ]]; then
    ./cuda_00_baseline/fnn_cuda "$DATA" 20 0.01 32 "$RUN/a_baseline" 128 2>&1 | tee "$RUN/a_baseline.log"
    record_run_info "$RUN/a_baseline"
    ./cuda_01_selective_tiling/fnn_cuda_opt1 "$DATA" 20 0.01 32 "$RUN/a_opt1" 128 16 targeted 2>&1 | tee "$RUN/a_opt1.log"
    record_run_info "$RUN/a_opt1"
    ./cuda_02_forward_fusion/fnn_cuda_opt2 "$DATA" 20 0.01 32 "$RUN/a_opt2" 128 16 targeted on 2>&1 | tee "$RUN/a_opt2.log"
    record_run_info "$RUN/a_opt2"
    ./cuda_03_register_reuse/fnn_cuda_opt3 "$DATA" 20 0.01 32 "$RUN/a_opt3" 128 16 targeted on 2 2>&1 | tee "$RUN/a_opt3.log"
    record_run_info "$RUN/a_opt3"
fi
if [[ "$MODE" == incremental ]]; then
    ./incremental/fnn_incremental initial "$DATA" "$RUN/initial_training" 10 2>&1 | tee "$RUN/initial_training.log"
    record_run_info "$RUN/initial_training"
    # Deliberate separate process; source checkpoint must contain 10 completed initial epochs.
    ./incremental/fnn_incremental new "$DATA" "$RUN/new_data_training" 5 "$RUN/initial_training/epoch_10.ckpt" 2>&1 | tee "$RUN/new_data_training.log"
    record_run_info "$RUN/new_data_training"
fi
printf 'COMPLETED\n' > "$RUN/status.txt"
echo "COMPLETED: $RUN"
