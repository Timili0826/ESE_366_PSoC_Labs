# ESE 366 FNN: optimization 1, selective dA1 tiling

## Command working directory

Start from the repository root (the FNN project root) for the initial `cd cuda_01_selective_tiling`
build/check block. All subsequent shell examples and CLI paths on this page
assume the current directory is `cuda_01_selective_tiling/` relative to the repository root; if starting a new
shell, change to that directory first. The initial build/check block is a
subshell and returns to the FNN root; before a later block, run
`cd cuda_01_selective_tiling` from that root. Build before invoking `./fnn_cuda_opt1`.
MNIST is `../data/mnist`; download it with the root README's script before
training. Each new run writes under `../outputs/opt1/selective/`; historical
records under `../results/` are read-only references. Timestamped run directories
are created with `mktemp -d` so repeated invocations cannot reuse an existing run.
The source's documented CLI defaults remain unchanged.

Install this directory as `cuda_01_selective_tiling/` relative to the repository root, beside the original
`cuda_00_baseline/` and `cuda_01_tiling_attempt/`. Both earlier versions remain unchanged.
This is a refinement of optimization 1, not optimization 2.

## Why dispatch changed

The initial opt1 tiled forward L1, dA1 and dW1. The matched three-epoch
experiment showed stable training times (mean of epochs 2/3):

| Mode | Training event time |
| --- | ---: |
| naive | 580.655 ms |
| initial targeted tile 16 | 605.720 ms |
| initial targeted tile 8 | 734.270 ms |

The user's two Nsight Systems traces were matched against the complete
57,242-launch sequence, excluding warm-up from the following training means:

| Training GEMM | Naive mean | Tile 16 mean | Time change |
| --- | ---: | ---: | ---: |
| Forward L1 | 61.042 us | 121.905 us | +99.7% |
| dA1 | 64.607 us | 14.056 us | -78.2% |
| dW1 | 73.011 us | 81.852 us | +12.1% |

Source: [naive trace](../results/opt1/tiling_attempt/profiling/nsys_diagnosis_20261109_200107/naive_trace.csv) and
[targeted trace](../results/opt1/tiling_attempt/profiling/nsys_diagnosis_20261109_200107/targeted_trace.csv). Each training role has 1,500 calls. Excluding the first
100 batches preserves the direction of all three comparisons. Most unchanged
training GEMMs differ by about 1% or less in the full-epoch mean.

These are profiler measurements, not end-to-end speedup claims for this
revision. This revision must be measured separately without the profiler.

## Changes from the initial opt1

The GEMM kernel and arithmetic are unchanged. The targeted rule now is:

```text
transpose_B && M >= tile && N >= 128 && K >= tile
```

For the fixed 784-128-64-10 network and batch 32, this selects only dA1:
`[32,64] * transpose([128,64]) -> [32,128]`.
Forward L1 and dW1, and all other GEMMs, use the original naive kernel.
Evaluation therefore uses naive GEMMs throughout in targeted mode.
This is a measured-workload rule, not a general-purpose autotuner.

- `targeted`: selective dA1 tiling as above (default).
- `all`: force all GEMMs through the tiled path; primarily for correctness.
- `naive`: all GEMMs use the baseline implementation; in-binary control.

The old source, results and archives are not overwritten. The naive-mode
console output now correctly reports zero explicit shared memory per GEMM
block rather than printing the unused tiled kernel configuration.

## Build and validate on Jetson Orin

```bash
(
    set -e -o pipefail
    cd cuda_01_selective_tiling  # start this block from the FNN project root
    make
    mkdir -p ../outputs/opt1/selective
    check_dir=$(mktemp -d "../outputs/opt1/selective/check_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda_opt1 --check 2>&1 | tee "$check_dir/check_selective.log"
    echo "$check_dir"
)
```

The build uses the same flags as the baseline/initial opt1:
`-O2 -lineinfo -std=c++14 -arch=sm_87`. It links the existing `../cpu/src/` C
reference and `../cpu/include/` headers, without changing them.

CPU source reference:
https://github.com/Timili0826/ESE_366_PSoC_Labs/tree/62e4aee6af94989494c78b25bf62a49c138df2fc/FNN

This is a pinned historical CPU reference, whose `FNN/` path was valid at
that commit. The current FNN project root is the repository root. See the
[root attribution](../README.md#origin-and-attribution) for the classmate
CPU baseline and the CUDA work built on it.

`--check` needs no MNIST files. It retains 24 independent FP64-reference GEMM
cases and 16 CPU-reference network cases from opt1 (tiles 8/16, transpose
combinations, M/N/K tails, partial batches, gradients and parameter updates).
It additionally checks that targeted dispatch selects exactly dA1 for a full
batch and correctly falls back for small partial batches. The existing
tolerance `3e-5 + 5e-4 * abs(reference)` is unchanged; nonfinite values fail.

## Matched first performance comparison

After the GPU check passes, compare three epochs against the in-binary
naive control. Both invocations start from identical initialization and use
seed=39, batch=32, learning rate=0.01 and FP32.

```bash
(
set -e -o pipefail
mkdir -p ../outputs/opt1/selective
compare_dir=$(mktemp -d "../outputs/opt1/selective/compare_$(date +%Y%m%d_%H%M%S)_XXXXXX")
for policy in naive targeted
do
    { time -p ./fnn_cuda_opt1 ../data/mnist 3 0.01 32 \
        "$compare_dir/$policy" 128 16 "$policy"; } \
        2>&1 | tee "$compare_dir/$policy.log" || break
done
echo "$compare_dir"
)
```

For formal results, repeat matched 20-epoch runs, alternate run order, keep
power/clock conditions consistent, and record training/evaluation/whole-run
times and validation/test loss/accuracy. A normal run is required to verify
that the isolated dA1 gain translates into an end-to-end improvement.

CLI:

```text
./fnn_cuda_opt1 [data_dir] [epochs] [lr] [batch] [output_dir] [threads] [tile] [policy]
```

Defaults:
`../data/mnist 20 0.01 32 ../outputs/cuda_opt1_selective 128 16 targeted`.
`threads` sets the original 1-D/naive block size. Tiled GEMMs use a separate
`tile*tile` block: tile 16 = 256 threads / 2176 shared bytes; tile 8 = 64
threads / 576 shared bytes. Registers must be measured on the device.

## Validation limits

The authoring environment has no nvcc or NVIDIA GPU. Local phased host
emulation passed the dispatch, GEMM and CPU-network checks under AddressSanitizer
and UndefinedBehaviorSanitizer. The emulation executes the production tile
load/arithmetic expressions with barrier phases separated. This is not a
native CUDA compilation, synchronization/race test, or GPU benchmark.
LeakSanitizer was disabled due to the execution environment's tracing limits.

The user's earlier GPU PASS applies to the initial opt1; the selective
revision still requires `make` and `--check` on Jetson before benchmarking.
No fusion, register tiling, mixed precision, training-rule changes, per-batch
allocation or additional kernel boundaries were introduced. Timing boundaries
match the baseline. Checkpoints/resume/incremental retraining remain pending.
