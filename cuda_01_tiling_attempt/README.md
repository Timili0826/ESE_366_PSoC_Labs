# ESE 366 FNN: optimization 1

## Command working directory

Start from the repository root (the FNN project root) for the initial `cd cuda_01_tiling_attempt`
build/check block. All subsequent shell examples and CLI paths on this page
assume the current directory is `cuda_01_tiling_attempt/` relative to the repository root; if starting a new
shell, change to that directory first. The initial build/check block is a
subshell and returns to the FNN root; before a later block, run
`cd cuda_01_tiling_attempt` from that root. Build before invoking `./fnn_cuda_opt1`.
MNIST is `../data/mnist`; download it with the root README's script before
training. Each new run writes under `../outputs/opt1/tiling_attempt/`; historical
records under `../results/` are read-only references. Timestamped run directories
are created with `mktemp -d` so repeated invocations cannot reuse an existing run.
The source's documented CLI defaults remain unchanged.

Place `cuda_01_tiling_attempt/` beside `cuda_00_baseline/` at the repository root. The package uses the existing `../src/` and `../include/`
CPU reference. It does not modify the CPU implementation or CUDA baseline.

CPU reference commit:
https://github.com/Timili0826/ESE_366_PSoC_Labs/tree/62e4aee6af94989494c78b25bf62a49c138df2fc/FNN

This is a pinned historical CPU reference, whose `FNN/` path was valid at
that commit. The current FNN project root is the repository root. See the
[root attribution](../README.md#origin-and-attribution) for the classmate
CPU baseline and the CUDA work built on it.

## Scope

Shared-memory tiled GEMM with cooperative loads adapted to each operand's
physical layout. An operand requested transposed is loaded contiguously
where the tile/row boundaries permit, then transposed inside shared memory.
There is no separate global transpose buffer. A padded shared leading
dimension `TILE+1` limits bank conflicts from transposed tile stores; this
does not guarantee every access pattern is conflict-free.

- FP32, architecture 784-128-64-10, seed 39, split/shuffle, loss, SGD and
  all buffer lifetimes match the baseline.
- One output per tiled thread. No fusion, register tiling, fast math,
  mixed precision, cuBLAS, or explicitly expanded inner loop.
- The tile multiply loop uses `#pragma unroll 1` to keep this experiment
  separate from explicit unrolling.
- Every thread participates in two barriers per K tile. Boundary loads
  write zero. Only the final output store is conditional on valid M/N.
- All backward computations still use old weights before any parameter update.

## Build and check on Jetson Orin

```bash
(
    set -e -o pipefail
    cd cuda_01_tiling_attempt  # start this block from the FNN project root
    make
    mkdir -p ../outputs/opt1/tiling_attempt
    check_dir=$(mktemp -d "../outputs/opt1/tiling_attempt/check_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda_opt1 --check 2>&1 | tee "$check_dir/check_opt1.log"
    echo "$check_dir"
)
```

Build flags match the baseline: `-O2 -lineinfo -std=c++14 -arch=sm_87`.
The GPU check requires no MNIST files. It checks:

- 24 direct GEMM cases against an independent FP64 dot-product reference:
  tiles 8/16, all four transpose combinations, and M/N/K tails.
- 16 network cases against the repository's C implementation: irregular
  widths, actual batches 1/7/17/32, and forced-tiled plus targeted dispatch.
- Losses, logits gradients, every layer's preactivations/outputs/dW/db,
  updated parameters, and logits from a subsequent forward pass.

Tolerance remains `3e-5 + 5e-4 * abs(reference)`. Nonfinite values fail.
Exit codes: 0 PASS, 2 numerical mismatch, 1 runtime/configuration error.
Do not train or benchmark a version that fails its GPU check.

## CLI and dispatch policies

```text
./fnn_cuda_opt1 [data_dir] [epochs] [lr] [batch] [output_dir] [threads] [tile] [policy]
```

Defaults:
`../data/mnist 20 0.01 32 ../outputs/cuda_opt1 128 16 targeted`

`threads` controls only the original 1-D kernels and any naive GEMMs.
Tiled GEMMs use `block=(tile,tile)`, independently of that setting.

| Tile | Tiled threads/block | Warps/block | Static shared bytes/block |
| --- | ---: | ---: | ---: |
| 8 | 64 | 2 | 576 |
| 16 | 256 | 8 | 2176 |

The shared-memory count is `2 * tile * (tile+1) * sizeof(float)`.
Registers must be measured with the compiler/profiler on the target device.

- `targeted`: tiled only if M>=tile, N>=128, K>=tile. For the fixed network
  and batch 32, this selects exactly forward L1, dA1, and dW1. Other GEMMs
  stay naive. Small partial batches can select the naive fallback.
- `all`: force tiled GEMM for every shape. Useful for correctness checks and
  for measuring whether tiling the small shapes helps or hurts.
- `naive`: force the baseline GEMM for every shape, as an in-binary control.
  This is not a new optimization. The original baseline remains the primary
  reference and is not overwritten.

The targeted predicate is a hypothesis for this workload, not an autotuner
or a universally optimal rule. The three targeted GEMMs may prefer different
tiles; use per-operation profiling before adding more dispatch complexity.

For the full batch, expected tiled launch geometry is:

| GEMM | M,N,K | Tile 8 grid (x,y) | Tile 16 grid (x,y) |
| --- | --- | --- | --- |
| Forward L1 | 32,128,784 | 16,4 | 8,2 |
| dA1 | 32,128,64 | 16,4 | 8,2 |
| dW1 | 784,128,32 | 16,98 | 8,49 |

Both tile choices launch the same logical output elements, but distribute
them among different numbers of blocks/warps and use different phase counts.
Larger tiles are not assumed to be faster.

## First training experiment

After the GPU check passes, run one epoch for both tiles, with unique output
directories. A directory already containing `metrics.csv` is rejected.

```bash
(
    set -e -o pipefail
    mkdir -p ../outputs/opt1/tiling_attempt
    smoke_dir=$(mktemp -d "../outputs/opt1/tiling_attempt/smoke_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda_opt1 ../data/mnist 1 0.01 32 "$smoke_dir/tile16" 128 16 targeted 2>&1 | tee "$smoke_dir/tile16.log"
    ./fnn_cuda_opt1 ../data/mnist 1 0.01 32 "$smoke_dir/tile8" 128 8 targeted 2>&1 | tee "$smoke_dir/tile8.log"
    echo "$smoke_dir"
)
```

Then compare matched 20-epoch runs with the original baseline and both tiles.
Use at least three trials with unique output directories and alternate run
order to reduce clock/temperature/order bias. Keep batch=32, lr=0.01,
seed=39, dataset, precision and power/clock conditions the same.

Record `train_GPU`, `eval_wall`, `epoch_wall`, Bash `time -p` real time,
validation/test loss and accuracy. Do not require bitwise-identical training
results: the GPU and CPU use different floating-point evaluation paths.

Timing boundaries and output schema are the same as the baseline. In
particular, `train_GPU` includes all training kernels and intervening device
gaps, but excludes epoch evaluations and setup. No per-batch allocation,
dataset upload, or device-wide synchronization has been added.

## Profiling later

`matmul_tiled<8>` and `matmul_tiled<16>` are separate kernel specializations.
The naive fallback remains named `matmul_naive`. Filtering only that name
will therefore omit the optimized work. Account for both names in summaries.
Warm-up still performs eight GEMMs, but targeted dispatch divides them
between the two kernel families: do not reuse a filter-specific launch-skip
count of eight without checking which launches match the new filter.

Measure per-GEMM time, memory transactions, register count, shared-memory
behavior, occupancy and synchronization effects. Compare normal execution
time outside the profiler before claiming an end-to-end improvement.

## Local validation status

The authoring environment has neither nvcc nor an NVIDIA GPU. No native CUDA
compilation, device execution, or speedup is claimed here.

Local phased host emulation reused the production tile load and arithmetic
expressions, executing every lane's loads before every lane's consumption
to model the barrier boundaries. It passed all 24 direct GEMM and 16 network
cases under AddressSanitizer/UndefinedBehaviorSanitizer. Four two-epoch
synthetic IDX runs (naive, targeted 8/16, all 16) exercised partial batches,
training/evaluation/export, and produced matching learning metrics. Invalid
tile/policy/thread arguments were rejected. LeakSanitizer was disabled due
to the execution environment's tracing restrictions.

These are indexing and algorithm checks, not a CUDA race/synchronization
test. The required next validation is `make` and `--check` on the Jetson.
Model checkpoints/resume and incremental retraining are still not implemented.
