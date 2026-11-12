# ESE366 Project 2: MNIST FNN on CPU and CUDA

MNIST; **784–128–64–10**, FP32, ReLU/ReLU/linear, cross-entropy, ordinary SGD;
**lr=0.01, batch=32, seed=39**, 48,000 training / 12,000 validation / 10,000 test.
CUDA uses 128 one-dimensional threads/block; selective tile16, Opt2 fusion on,
and Opt3 dW1 rows/thread=2. All commands below start at the **repository root**.

## Origin and attribution

The CPU foundation was provided by a classmate through
[marcusvel28/ESE_366_PSoC_Labs](https://github.com/marcusvel28/ESE_366_PSoC_Labs),
the upstream repository from which this repository is forked. Credit remains
with the original author. The CUDA baseline and optimization experiments were
developed on top of that CPU implementation. The preserved
[CPU reference snapshot](https://github.com/Timili0826/ESE_366_PSoC_Labs/tree/62e4aee6af94989494c78b25bf62a49c138df2fc/FNN)
uses the historical `FNN/` path; current CPU files live in `cpu/`.
No license is introduced or changed by this organization.

## Source and results

| Directory | Purpose |
|---|---|
| `cpu/` | CPU reference, monotonic epoch timing, independent output directory |
| `cuda_00_baseline/` | Plain CUDA baseline |
| `cuda_01_tiling_attempt/` | Preserved failed broad tiling experiment; excluded from final Opt1 curves |
| `cuda_01_selective_tiling/` | Final Opt1: selective eligible dA1 tiling |
| `cuda_02_forward_fusion/` | Opt2: forward fusion |
| `cuda_03_register_reuse/` | Final Opt3: dW1 register reuse |
| `incremental/` | Checkpoint/new-data entry directly including final Opt3 computation |
| `results/cpu/baseline/` | Original CPU experiment, unchanged |
| `results/cpu/wall_time_20261112/` | One formal 20-epoch CPU wall-time run |
| `results/incremental/20261112/` | Initial/new metrics, sample IDs, logs, checks and provenance |
| `results/time_accuracy/20261112/` | Five PNG/vector-PDF pairs, derived CSVs, relative source manifest |
| Other `results/` folders | Original CUDA experiments, controls and profiler text, unchanged |
| `scripts/`, `docs/` | Reproduction scripts and methodology/audits |
| `data/`, `outputs/` | Dataset instructions and fresh-run outputs |

See [methodology and runbook](docs/time_accuracy_incremental.md),
[figures and analysis](results/time_accuracy/20261112/README.md),
[CPU run](results/cpu/wall_time_20261112/README.md),
[incremental run](results/incremental/20261112/README.md) and the
[failed broad tiling explanation](cuda_01_tiling_attempt/README.md).

## Build and correctness checks

Linux/Jetson requires GCC, GNU Make and nvcc. The measured Orin Nano is CC8.7;
`sm_87` is appropriate for that board.

```bash
make -C cpu
make -C incremental host-check
python3 tests/test_cpu_output.py cpu/fnn
export PATH=/usr/local/cuda/bin:$PATH
for v in cuda_00_baseline cuda_01_selective_tiling cuda_02_forward_fusion cuda_03_register_reuse; do
    make -C "$v" ARCH=sm_87 && make -C "$v" ARCH=sm_87 check || exit 1
done
make -C incremental ARCH=sm_87
mkdir -p outputs
CHECK=$(mktemp -d outputs/check_XXXXXX)
./incremental/fnn_incremental --check "$CHECK/incremental"
```

Retained Jetson logs show CPU compilation/output tests, four CUDA numerical
checks and incremental GPU checks passed, followed by COMPLETED CPU and
incremental experiments. These are **Jetson executions**, not GPU checks on the
local integration machine. No training or remote operation was performed during
the local result integration.

## Data and independent training outputs

MNIST is not committed. Prepare the original IDX files using
`bash scripts/download_mnist.sh`, or use an existing dataset directory.

```bash
mkdir -p outputs
./cpu/fnn data/mnist 20 0.01 32 "outputs/cpu_$(date +%Y%m%d_%H%M%S)"
make -C cpu run OUT="outputs/cpu_$(date +%Y%m%d_%H%M%S)"
./cuda_03_register_reuse/fnn_cuda_opt3 data/mnist 20 0.01 32 \
    "outputs/opt3_$(date +%Y%m%d_%H%M%S)" 128 16 targeted on 2
```

CPU CLI: `./cpu/fnn [dataset] [epochs] [lr] [batch] [output_directory]`.
Original CSV fields/process-clock logs remain; `cpu_process_s` and
`epoch_wall_s` are additional fields. Existing output files are refused.
The individual CUDA READMEs retain their version-specific training examples.

## Checkpoint and incremental training

```bash
mkdir -p outputs
RUN=$(mktemp -d outputs/incremental_XXXXXX)
./incremental/fnn_incremental initial data/mnist "$RUN/b_initial" 10
# Deliberate separate process; only the previously unused 8,000 training IDs:
./incremental/fnn_incremental new data/mnist "$RUN/b_new" 5 "$RUN/b_initial/epoch_10.ckpt"
# Same-stage resume: EPOCHS is the number of additional epochs.
# ./incremental/fnn_incremental resume data/mnist outputs/new_resume 3 PATH_TO_EPOCH_7.ckpt
```

The fixed training partition is split into 40,000 initial and 8,000 new images;
validation/test stay fixed. Checkpoints contain all weights/biases, architecture,
configuration, epoch/update count, shuffle RNG, active order and split IDs.
Plain SGD has no momentum state. Loading checks shape, length, integrity,
finite values and split identity; existing checkpoints are not replaced.
Warm-up performs no parameter update. Checkpoint payloads remain local and are
excluded from Git; keep the original result archive as backup.

For serial checks followed by training, use
`ARCH=sm_87 DATA="$PWD/data/mnist" bash scripts/jetson_experiments.sh cpu-only`,
or mode `incremental` / `all-five`. The runner records PID, source/data hashes,
logs and status in a new `outputs/experiments/` directory. Background launch
alone is not completion; see the runbook for detached launch/status commands.

## Reproduce analysis without training

```bash
python3 -m pip install -r requirements-analysis.txt
python3 scripts/analyze_time_accuracy.py --out "outputs/reproduced_$(date +%Y%m%d_%H%M%S)"
python3 -m unittest discover -s tests -p 'test_analysis.py'
python3 -m unittest discover -s tests -p 'test_results.py'
```

This is the single formal analysis implementation. It reads repository-relative
original results, selects only the designated CPU wall-time run and final CUDA
settings, and exports five PNG/vector-PDF pairs. Use `--no-plots` for CSV-only
checks or `--png-only` if optional PDF dependencies are unavailable. The supplied
vector PDFs are retained unchanged. Output directories must be new.
No GPU, training or archived absolute path is needed for analysis.

## Measured results and limits

Primary time is **cumulative measured epoch wall time**: shuffle, training and
post-epoch training/validation evaluation; it excludes setup, warm-up, final test
and export. GPU completion precedes stopping the timer. This is different from
Opt3's approximately **442 ms/epoch train_GPU** steady-state event measure.

| Version | Timing runs | First ≥95% wall time (s) | First ≥96% wall time (s) | First ≥96% epoch |
|---|---:|---:|---:|---:|
| CPU | 1 | 319.108336923 | 493.208834642 | 17 |
| CUDA baseline | 1 | 9.386114114 | 15.340387537 | 18 |
| Opt1 selective | 3 | 8.567541537 | 14.013447661 | 18 |
| Opt2 fusion | 3 | 7.888520655 | 12.907159669 | 18 |
| Opt3 register reuse | 3 | 7.460290254 | 12.207741468 | 18 |

Opt1–3 are same-seed timing repeats, not independent convergence seeds.
Thresholds are found within each actual run before averaging; no smoothing,
interpolated crossing time or forced common crossing epoch is used.
Historical CUDA runs lack exact build/dataset provenance; temperature,
frequency and power were not controlled across dates.

Incremental validation accuracy changes from **94.4916667% to 94.8250%**,
a gain of **0.3333333 percentage points**. Five new-data epochs take
**0.760827039 s** for training plus evaluation; new-stage process wall time is
**1.68254 s**. Final test accuracy is **95.60%**. This demonstrates loading learned
parameters and learning from new data. It does not establish superiority over
training from scratch, solve catastrophic forgetting, or prove every course
assignment requirement has been completed.

## Upload scope and history

Include source, documentation, retained CSV/log/provenance and figures.
Exclude MNIST, binaries/build/cache, raw profiler reports/databases, downloaded
archives and checkpoints. Ignore rules do not automatically untrack files.
CSV/log/PDF/PNG and the full `results/` tree are not blanket-ignored.

[Organization notes](ORGANIZATION.md), [root migration](docs/root_migration.md)
and [original audit](docs/original_audit.md) retain their historical path/hash
records. Absolute paths in original logs/run_info remain evidence only;
current reproduction uses the relative retained source manifest.
