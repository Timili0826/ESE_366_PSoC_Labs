# ESE 366 FNN: plain CUDA baseline

## Command working directory

Start from the repository root (the FNN project root) for the initial `cd cuda_00_baseline`
build/check block. All subsequent shell examples and CLI paths on this page
assume the current directory is `cuda_00_baseline/` relative to the repository root; if starting a new
shell, change to that directory first. Build before invoking `./fnn_cuda`.
MNIST is `../data/mnist`; download it with the root README's script before
training. Each new run writes under `../outputs/cuda_baseline/`; historical
records under `../results/` are read-only references. Timestamped run directories
are created with `mktemp -d` so repeated invocations cannot reuse an existing run.
The source's documented CLI defaults remain unchanged.

Place this directory at the repository root.
The existing C files and their saved CPU results are not modified. This is
the first GPU implementation, before shared-memory tiling and unrolling.

## Source and mathematical contract

CPU reference: https://github.com/Timili0826/ESE_366_PSoC_Labs/tree/62e4aee6af94989494c78b25bf62a49c138df2fc/FNN

This is a pinned historical CPU reference, whose `FNN/` path was valid at
that commit. The current FNN project root is the repository root. See the
[root attribution](../README.md#origin-and-attribution) for the classmate
CPU baseline and the CUDA work built on it.

The build links the repository's `src/{activation,dataset,layer,loss,network}.c`
and headers as C objects. They provide the dataset parser, split/shuffle,
initialization, and independent CPU reference used by `--check`.

- Architecture: 784 -> 128 -> 64 -> 10; hidden ReLU, linear logits.
- Loss: stable softmax cross-entropy; no ReLU on the final logits.
- SGD: sum gradients for the actual batch, divide once during the update.
- Seed: **39**, matching `main.c` at the source commit above (the root README and executable code both use 39).
- Split: the same shuffled 80% training / 20% validation split.
- Shuffle: seed + 1 initial state, reshuffle only training indices each epoch.
- All backward computations finish using old weights before any SGD update.
- CPU weights are laid out `[out,in]`; GPU weights are transposed once on the
  host to `[in,out]`. Activations and deltas are row-major `[batch,width]`.
- The CPU program processes samples serially within a mini-batch; the CUDA
  program processes that mini-batch as matrix operations. Floating-point
  rounding can therefore differ; identical full-training metrics are not a
  requirement for correctness.

This source implements the scalar dot-product matrix-operation approach used
as a baseline in Project 1. It does not import a particular Project 1 source
file or call cuBLAS. Future versions can replace `matmul_naive` with a tiled
implementation without changing the network equations.

## Build on Jetson Orin

Start in the repository root (the FNN project root):

```bash
cd cuda_00_baseline
make && ./fnn_cuda --check
```

The default target is `sm_87`, for the Orin used in this project. It is not
the architecture of the older, non-Orin Jetson Nano. Override `ARCH` only
when intentionally targeting different NVIDIA hardware.

Requirements: the existing C source tree, a C compiler, `make`, and CUDA/nvcc.
No Eigen, LibTorch, cuBLAS, or Python dependency is needed for this executable.

## First check, then train

`--check` needs no MNIST files. It copies the same initialized weights to the
GPU, and compares against the repository's C reference for:

- Every layer's preactivation and output.
- Per-sample loss and the loss gradient at the logits.
- Every layer's weight and bias gradients.
- Every weight and bias after one averaged SGD update.
- A second forward pass using the updated parameters.

Cases: an irregular 7-5-4-3 network, and the real 784-128-64-10 network with
actual batches 1, 7, and 32 inside capacity 32. Comparisons use, per value:

`abs(gpu - cpu) <= 3e-5 + 5e-4 * abs(cpu)`

Nonfinite values fail. Exit status is 0 for PASS, 2 for a numerical mismatch,
and 1 for a runtime/configuration error. Do not suppress a failed check by
loosening tolerances without examining the differences.

After `Overall CPU/GPU check: PASS`, run one epoch:

```bash
(
    set -e -o pipefail
    mkdir -p ../outputs/cuda_baseline
    run_dir=$(mktemp -d "../outputs/cuda_baseline/smoke_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda ../data/mnist 1 0.01 32 "$run_dir" 128 2>&1 | tee "$run_dir/train.log"
    echo "$run_dir"
)
```

After inspecting the result, run the matched 20-epoch experiment:

```bash
(
    set -e -o pipefail
    mkdir -p ../outputs/cuda_baseline
    run_dir=$(mktemp -d "../outputs/cuda_baseline/full_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda ../data/mnist 20 0.01 32 "$run_dir" 128 2>&1 | tee "$run_dir/train.log"
    echo "$run_dir"
)
```

CLI:

```text
./fnn_cuda [data_directory] [epochs] [learning_rate] [batch_size] [output_directory] [threads_per_block]
```

Defaults: `../data/mnist 20 0.01 32 ../outputs/cuda_baseline 128`.
Threads/block must be a multiple of 32 within the device limit.
An existing output `metrics.csv` is rejected; choose another output directory
for another run. Each invocation starts from newly initialized parameters.
Model checkpoints, resume, incremental retraining, hidden-width sweeps,
and the final optimization experiments are outside this first baseline.

For a session that must survive disconnecting SSH, after the check succeeds:

```bash
(
    set -e
    mkdir -p ../outputs/cuda_baseline
    run_dir=$(mktemp -d "../outputs/cuda_baseline/full_nohup_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    nohup ./fnn_cuda ../data/mnist 20 0.01 32 "$run_dir" 128 > "$run_dir/train.log" 2>&1 < /dev/null &
    echo "PID=$! output=$run_dir log=$run_dir/train.log"
)
```

Do not run the foreground and background commands together: they are two
alternative ways of starting the same training job.

## Execution and timing

Normalized training/test images, labels, weights, and working buffers stay on
the device. Images are uploaded once during setup; shuffled indices are
uploaded once per epoch. All buffers are allocated outside the training loop.
All dependent kernels use the same default stream. The naive kernels have no
shared tile and therefore need no block-wide barrier. Later tiling kernels
will need barriers for their shared-memory dependencies.

Forward/backward kernels are warmed up once without updating weights.
Only epoch-level metrics (and the final small prediction export) return to
the CPU. No per-batch `cudaDeviceSynchronize` or allocation is performed.

Output files in the selected directory:

- `metrics.csv`: post-epoch training/validation loss and accuracy, online
  training loss, training GPU event time, evaluation and epoch wall times.
- `run_info.txt`: configuration, GPU, final test metrics, and wall times.
- `predictions.csv`: the first up to 100 test predictions (visualization subset).

The complete test set is evaluated for the final test accuracy.

Timing definitions:

- `train_GPU`: CUDA events around all mini-batch training work in the epoch,
  including gathers and loss monitoring. It includes idle gaps if the host
  is late submitting work. It excludes the epoch's index upload, evaluations,
  dataset loading, allocation, initialization, and warm-up.
- `eval_wall`: post-epoch training-set and validation-set evaluations together.
- `epoch_wall`: shuffle, index upload, training, metric readback, and evaluations.
- `Train + epoch evaluations wall`: all epochs together, excluding setup and
  final testing/export.
- `total_wall_s_before_cleanup`: loading/setup/warm-up/training/evaluation/
  prediction export; excludes final object destruction and process exit.

The CPU run's 568.43 s `real` value includes the whole CPU process. Do not
divide that by a single GPU kernel time or a training-only event time and
label the ratio end-to-end speedup. For a matched whole-program measurement,
use Bash `time -p` for both executables and document the small difference in
exported outputs. The CPU's printed per-epoch `CPU` value is process CPU time
including its training/validation evaluations, not pure training wall time.

## Optimization comments

`OPTIMIZATION` comments identify candidates, not promised improvements:

1. Shared-memory tiling of forward and backward GEMMs.
2. GEMM epilogue fusion for bias/activation; preserve the ReLU backward mask.
3. Work/thread and loop unrolling, measured against register usage.
4. Softmax/reduction parallelization and approximate math with accuracy checks.
5. CPU/GPU overlap if profiling finds preparation or transfer on the critical path.

Compare configurations with the same data split, initialization, update rule,
batch size, and number of epochs before varying model/training parameters.

## Validation status before delivery

No NVIDIA GPU or nvcc is available in the authoring environment. This has
**not** been compiled with nvcc or executed on a physical CUDA device here.

Local checks executed the kernel bodies in serial host emulation against the
independent C reference. The four check cases passed under AddressSanitizer
and UndefinedBehaviorSanitizer. A small synthetic IDX training run also
exercised dataset loading, gather/indexing, partial training/validation/test
batches, and CSV export. These are algorithm/memory checks, not GPU benchmarks
or proof of CUDA device correctness. LeakSanitizer was disabled because the
local environment does not support it under its process tracing.

The next required validation is `make` and `./fnn_cuda --check` on the Jetson.
