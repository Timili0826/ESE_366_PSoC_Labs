# Training, timing and checkpoint guide

All shell commands below start at the repository root. The measured device is a
Jetson Orin Nano, compute capability 8.7; builds use `ARCH=sm_87`. Install GCC,
GNU Make and CUDA/nvcc, and prepare the original MNIST IDX files with
`bash scripts/download_mnist.sh` or use an existing dataset directory.

## CPU and CUDA versions

```bash
make -C cpu
mkdir -p outputs
RUN=$(mktemp -d outputs/cpu_XXXXXX)
./cpu/fnn data/mnist 20 0.01 32 "$RUN"
# Equivalent Make entry, with a different fresh output directory:
# make -C cpu run OUT=outputs/new_cpu_run
```

CPU CLI: `./cpu/fnn [dataset] [epochs] [lr] [batch] [output_directory]`.
Existing output files are refused. The original metric columns/process-clock
log remain; `cpu_process_s` and `epoch_wall_s` are additional fields.

Build and check all four final CUDA versions:

```bash
set -e
export PATH=/usr/local/cuda/bin:$PATH
for v in cuda_00_baseline cuda_01_selective_tiling cuda_02_forward_fusion cuda_03_register_reuse; do
    make -C "$v" ARCH=sm_87
    make -C "$v" ARCH=sm_87 check
done
```

Training uses positional arguments `dataset epochs lr batch output threads`,
followed by `tile policy` for Opt1, `fusion` for Opt2 and `dw1_rows` for Opt3.
Use 128 threads, tile 16, `targeted`, fusion `on` and rows 2 for the final settings.
See the version-specific guides for complete examples:
[baseline](../cuda_00_baseline/README.md),
[Opt1](../cuda_01_selective_tiling/README.md),
[Opt2](../cuda_02_forward_fusion/README.md),
[Opt3](../cuda_03_register_reuse/README.md).
The [broad-tiling attempt](../cuda_01_tiling_attempt/README.md) is preserved for
comparison but is not the final Opt1 implementation.

## Incremental training and resume

The network remains 784-128-64-10, FP32, plain SGD lr=0.01, batch=32, seed=39.
The seed=39 split produces 48,000 training and 12,000 validation IDs. Within training,
the first 40,000 split IDs form the initial set, and the remaining 8,000 are new
data. Test remains the separate 10,000-image MNIST test set. `sample_ids.csv`
records dataset namespaces and IDs for all subsets.

```bash
make -C incremental ARCH=sm_87
mkdir -p outputs
RUN=$(mktemp -d outputs/incremental_XXXXXX)
./incremental/fnn_incremental initial data/mnist "$RUN/initial_training" 10
# Separate process, loading the initial-stage model:
./incremental/fnn_incremental new data/mnist "$RUN/new_data_training" 5 "$RUN/initial_training/epoch_10.ckpt"
```

Initial training performs 12,500 updates; new-data training adds 1,250. Before any
new-stage update, `loaded_before_update` records validation loss/accuracy, which
must match the initial stage's final observation. Validation/test IDs never
enter training updates. Final test evaluation occurs only at the end of the
new-data phase and does not select a stopping point.

For same-stage resume, the epoch count means **additional** epochs:

```bash
# Example: continue a saved phase1 epoch7 for three more epochs.
./incremental/fnn_incremental resume data/mnist outputs/new_resume 3 PATH_TO_EPOCH_7.ckpt
```

`new` explicitly switches to the new 8,000 IDs and starts that phase's shuffle
sequence at seed+1. `resume` restores the current phase's saved RNG and order.
Output directories must be new. Checkpoints are local artifacts, not repository
contents; recover an older model from its local backup before attempting resume.

### Checkpoint format and safety

The standalone incremental entry directly includes final Opt3 computation.
Format magic is `FNNOPT3`, version 1, little-endian IEEE FP32. It saves all GPU-layout
weights W[in,out], biases, layer widths and ReLU/ReLU/linear activation structure;
learning rate, batch, seed and CUDA strategy; phase/epoch, update count, shuffle
RNG, active index order, all split IDs, dataset fingerprint and cumulative time.
Ordinary SGD has no momentum or other optimizer buffers.

Loading checks size bounds, format version, full input consumption, checksum,
configuration, tensor shapes, finite values, dataset identity, split coverage,
disjointness and active-order membership. Update counts must agree with the phase
and epoch. Exclusive file creation prevents checkpoint replacement. FNV-1a detects
accidental corruption; it is not cryptographic authentication. Failed writes may
leave an incomplete file for diagnosis, which loading rejects.

Parameters are restored before forward evaluation. Warm-up performs
forward/loss/backward without updates and verifies unchanged weights/biases.
Every epoch saves a new checkpoint outside the measured epoch interval.
Bitwise resume equivalence is tested on one device; it is not promised across
different GPUs, drivers or CUDA versions.

## Correctness validation

```bash
make -C incremental host-check
python3 tests/test_cpu_output.py cpu/fnn
CHECK=$(mktemp -d outputs/check_XXXXXX)
./incremental/fnn_incremental --check "$CHECK/incremental"
```

Host tests cover serialization, shape/finite-value checks, malformed/truncated
files, split/order validation and refusal to overwrite. GPU tests compare against
the CPU numerical reference, verify parameter/logits/loss roundtrip and no-update
warm-up, and compare continuous three-epoch synthetic training with one epoch,
save/load, then two epochs. The 71-sample fixture includes full and partial batches.

Retained Jetson logs report these checks passed on Orin Nano CC 8.7, CUDA 12.6,
GCC 11.4, followed by completed CPU 20-epoch and incremental 10+5-epoch experiments.
See the [CPU record](../results/cpu/wall_time_20261112/README.md) and
[incremental record](../results/incremental_training/README.md) for evidence.
Those are recorded Jetson executions, not GPU checks performed by analysis tests.

## Timing and analysis

The primary comparison sums actual monotonic `epoch_wall_s`, including the first
epoch. Each interval starts before shuffle and ends after training-set and
validation evaluation. CUDA completion is established by synchronized training
events and synchronous metric reads. Loading, setup, warm-up, final test and
export are excluded. CPU uses CLOCK_MONOTONIC on Linux and QueryPerformanceCounter
on Windows; its old clock() process time is a different measure.

CUDA `train_gpu_ms` excludes evaluation. The incremental entry also omits the
benchmark's online monitoring reduction, so its training-event time is not the
same scope as the original Opt3 benchmark. Checkpoint I/O and pre-update evaluation
are outside epoch time; full process wall time includes those overheads.

```bash
python3 -m pip install -r requirements-analysis.txt
python3 scripts/analyze_time_accuracy.py --out "outputs/reproduced_$(date +%Y%m%d_%H%M%S)"
python3 -m unittest discover -s tests -p 'test_analysis.py'
python3 -m unittest discover -s tests -p 'test_results.py'
```

The single analysis entry reads retained repository-relative inputs and needs no
GPU or checkpoint. Add `--no-plots` for CSV-only output, or `--png-only` if optional
PDF dependencies are unavailable. Otherwise it exports PNG and vector PDF.
Use a new output directory.

One CPU wall-time run and one baseline run are selected; Opt1–3 each use three
same-seed timing repeats. Old CPU snapshots, profiling, smoke, controls and failed
broad tiling are excluded. Thresholds are found per run at observed epoch ends,
then summarized; no interpolated crossing or smoothing is used. CPU reaches 96%
at epoch 17, CUDA at 18. See [detailed results](../results/time_accuracy/README.md)
for figures and unrounded CSVs. Historical CUDA build/dataset provenance and
cross-date power/clock/thermal controls are incomplete.

## Serial experiment runner

`scripts/jetson_experiments.sh` supports `checks`, `cpu-only`, `all-five` and
`incremental`. It compiles/checks before training, creates a fresh run directory,
records the environment and stops on errors. Use only one benchmark at a time.

```bash
mkdir -p outputs
LAUNCH=$(mktemp outputs/launch_XXXXXX.log)
nohup env ARCH=sm_87 DATA="$PWD/data/mnist" bash scripts/jetson_experiments.sh incremental > "$LAUNCH" 2>&1 &
echo "PID=$! log=$LAUNCH"
RUN=$(cat outputs/experiments/latest_incremental.txt)
cat "$RUN/pid.txt" "$RUN/status.txt"
tail -n 60 "$RUN/runner.log"
```

Wait for the runner to create its latest-run pointer before checking status.
Background launch is not completion; require `COMPLETED`. The lock coordinates
this working directory's runners, not arbitrary external GPU workloads.
