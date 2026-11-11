# ESE 366 FNN: optimization 2, forward epilogue fusion

## Command working directory

Start from the `FNN/` project root for the initial `cd cuda_02_forward_fusion`
build/check block. All subsequent shell examples and CLI paths on this page
assume the current directory is `FNN/cuda_02_forward_fusion/`; if starting a new
shell, change to that directory first. The initial build/check block is a
subshell and returns to the FNN root; before a later block, run
`cd cuda_02_forward_fusion` from that root. Build before invoking `./fnn_cuda_opt2`.
MNIST is `../data/mnist`; download it with the root README's script before
training. Each new run writes under `../outputs/opt2/`; historical
records under `../results/` are read-only references. Timestamped run directories
are created with `mktemp -d` so repeated invocations cannot reuse an existing run.
The source's documented CLI defaults remain unchanged.

Install `cuda_02_forward_fusion/` inside the existing repository's `FNN/` directory, beside
`cuda_01_selective_tiling/`. All prior code and experiment results remain unchanged.
The build links the existing `../src/` and `../include/` C reference.

CPU reference commit:
https://github.com/Timili0826/ESE_366_PSoC_Labs/tree/62e4aee6af94989494c78b25bf62a49c138df2fc/FNN

## What changes

Opt1 selective uses a forward GEMM followed by a separate bias/activation
kernel for each layer. Opt2's `forward_fused` computes the same scalar dot
product, adds bias, applies the requested activation, and writes both the
preactivation and output within one kernel.

- Forward GEMM remains one output per thread with a serial dot product.
  It uses direct non-transposed forward indexing, not shared-memory tiling.
- Bias is added after the dot product, preserving opt1's operation ordering.
- Hidden layers use ReLU. Final logits remain linear, including negatives.
- Both biased preactivation `z` and activation output are preserved for
  backward calculations and CPU-reference checks.
- The unfused raw GEMM-result global store/reload is avoided. This is not
  a claim of an equal decrease in DRAM traffic, since those accesses may cache.
- The fused kernel is specialized for non-transposed forward operands.
  Timings can reflect the resulting compiler/register changes as well as
  the avoided launch and intermediate accesses.
- Opt1's targeted dA1 tile 16 is retained by default. Backward GEMM,
  activation derivative, loss, gradient accumulation, and SGD are unchanged.
- No register tiling, approximate math, mixed precision, new buffers,
  per-batch allocation, or extra synchronization was added.

| Kernel launches | Opt1 / fusion off | Opt2 / fusion on |
| --- | ---: | ---: |
| Three-layer forward pass | 6 | 3 |
| Full training mini-batch | 25 | 22 |
| Evaluation mini-batch | 9 | 6 |

For the existing one-epoch whole-program profile (warm-up, training,
train/validation/test evaluation and prediction export), the expected launch
count decreases from 57,242 to 46,163. The number of mathematical GEMMs is
unchanged. More work per kernel does not guarantee a speedup; benchmark it.

## Build and check on Jetson Orin

```bash
(
    set -e -o pipefail
    cd cuda_02_forward_fusion  # start this block from the FNN project root
    make
    mkdir -p ../outputs/opt2
    check_dir=$(mktemp -d "../outputs/opt2/check_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda_opt2 --check 2>&1 | tee "$check_dir/check_opt2.log"
    echo "$check_dir"
)
```

Build flags match opt1: `-O2 -lineinfo -std=c++14 -arch=sm_87`.
`--check` needs no MNIST files. It checks:

- Six fused-forward cases against FP64 references, including signed nonzero
  biases, linear/ReLU outputs, small outputs, and incomplete 1-D blocks.
- The 24 direct tiled GEMM cases and dA1 dispatch checks retained from opt1.
- 32 complete CPU-reference network cases covering fusion off/on, tiles 8/16,
  tiny/irregular networks, actual batches 1/7/17/32, and all/targeted policies.
- Preactivations, activations, losses, logits gradients, every layer's dW/db,
  updated parameters and a subsequent forward pass.

Tolerance stays `3e-5 + 5e-4 * abs(reference)`. Nonfinite values fail.
Exit codes: 0 PASS, 2 numerical mismatch, 1 runtime/configuration error.
Do not benchmark a version that fails its GPU correctness check.

## Command line and comparison control

```text
./fnn_cuda_opt2 [data_dir] [epochs] [lr] [batch] [output_dir] [threads] [tile] [policy] [fusion]
```

Defaults:
`../data/mnist 20 0.01 32 ../outputs/cuda_opt2 128 16 targeted on`

For the opt1-to-opt2 comparison, keep `policy=targeted` in BOTH modes:

- `targeted off`: opt1 selective behavior, including dA1 tiling and the
  original two-kernel forward path.
- `targeted on`: same backward behavior plus fused forward epilogues.

Do not use `policy=naive` for the opt1 control: that would also disable dA1
tiling and confound the fusion comparison.

`policy` controls GEMMs launched through the unfused GEMM dispatcher:

- `targeted`: tile only when transpose_B and M>=tile, N>=128, K>=tile;
  only dA1 qualifies in the fixed network when its batch is large enough.
- `all`: force tiling for every unfused GEMM (primarily a test mode).
- `naive`: use naive for every unfused GEMM (baseline experiment mode).

When fusion is on, forward always uses `forward_fused`, irrespective of this
policy. The fusion switch changes only the forward execution path.

`threads` controls fused forward and all original 1-D kernels/naive GEMMs.
The default is 128. Backward tiled GEMMs independently use tile*tile threads:
tile 16 = 256 threads/2176 shared bytes; tile 8 = 64 threads/576 shared bytes.
Forward fusion itself uses zero explicit shared memory. Measure register
usage on the target device rather than inferring it from the source.

## First matched training comparison

After `--check` passes, compare three epochs with a unique output directory:

```bash
(
set -e -o pipefail
mkdir -p ../outputs/opt2
compare_dir=$(mktemp -d "../outputs/opt2/compare_$(date +%Y%m%d_%H%M%S)_XXXXXX")
for fusion in off on
do
    { time -p ./fnn_cuda_opt2 ../data/mnist 3 0.01 32 \
        "$compare_dir/$fusion" 128 16 targeted "$fusion"; } \
        2>&1 | tee "$compare_dir/$fusion.log" || break
done
echo "$compare_dir"
)
```

Both runs start from identical initialization (seed 39), with batch 32,
lr 0.01, architecture 784-128-64-10, FP32 and the same split/shuffle.
Compare epoch 2/3 training event time, evaluation/epoch wall times, whole
program `real`, and learning metrics. For formal results, use matched
20-epoch runs repeated three times with alternating off/on order and the
same device power/clock conditions. No GPU speedup is promised in advance.

The original opt1 remains the external reference. The `off` mode provides
an in-binary control and should reproduce opt1 before attributing a gain
to forward fusion. Floating-point paths need not be bitwise identical.

## Saved results and timing

Each output directory contains `metrics.csv`, `run_info.txt` and
`predictions.csv`. `run_info.txt` records `forward_fusion`, policy, tile,
threads, seed, training settings and final metrics. Console logs captured
with `tee` retain the process `real/user/sys` values.

Timing definitions match opt1: `train_GPU` includes the full training loop
and device gaps but excludes epoch evaluations/setup; `eval_wall` includes
post-epoch train/validation evaluation; total wall before cleanup includes
loading/setup/warm-up/export; Bash `real` covers the full process.

Existing output metrics are not overwritten. Every invocation restarts from
initialization. Model weight checkpoints/resume/incremental training remain
pending and are not introduced as part of this fusion experiment.

## Profiling

With fusion on, `bias_activation` should disappear from the training run;
`forward_fused` accounts for all forward GEMMs and activations. Backward
still appears as `matmul_naive` and `matmul_tiled<16>` under targeted mode.
Summaries must include all three families. Re-check filter-specific warm-up
skip counts instead of copying the old GEMM-only filter's skip count.

Fusion removes kernel boundaries and intermediate accesses; this does not
establish CPU launch overhead as the dominant bottleneck. Inspect per-layer
times/register usage and verify the ordinary, unprofiled end-to-end result.

## Validation status before delivery

No nvcc or NVIDIA GPU is available in the authoring environment. Local host
emulation executed the production fused-forward body and a phased translation
of the unchanged tiled GEMM's load/arithmetic expressions. All direct and
network checks passed under AddressSanitizer and UndefinedBehaviorSanitizer.
Synthetic three-epoch IDX runs for original opt1, opt2/off and opt2/on
produced matching learning metrics and exercised partial batches and exports.
Kernel-count logging and rejection of invalid fusion arguments were checked.
LeakSanitizer was disabled due to the execution environment's tracing limits.

These checks are not native CUDA compilation, GPU race/synchronization tests
or performance measurements. Required next step: `make` and `--check` on Jetson.
