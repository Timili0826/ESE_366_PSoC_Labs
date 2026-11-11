# ESE 366 FNN: optimization 3, dW1 register reuse

## Command working directory

Start from the `FNN/` project root for the initial `cd cuda_03_register_reuse`
build/check block. All subsequent shell examples and CLI paths on this page
assume the current directory is `FNN/cuda_03_register_reuse/`; if starting a new
shell, change to that directory first. The initial build/check block is a
subshell and returns to the FNN root; before a later block, run
`cd cuda_03_register_reuse` from that root. Build before invoking `./fnn_cuda_opt3`.
MNIST is `../data/mnist`; download it with the root README's script before
training. Each new run writes under `../outputs/opt3/`; historical
records under `../results/` are read-only references. Timestamped run directories
are created with `mktemp -d` so repeated invocations cannot reuse an existing run.
The source's documented CLI defaults remain unchanged.

Install `cuda_03_register_reuse/` inside the existing repository's `FNN/`, beside opt2.
No earlier source or experiment result is overwritten. This is the final
planned optimization experiment, with an in-binary opt2 control.

## Scope and rationale

Retain opt1's selective dA1 tile 16 and opt2's fused forward epilogues.
Change only the FIRST layer's weight-gradient computation:

```text
dW1 = transpose(X) * delta1
[784,32] * [32,128] -> [784,128] for batch 32
```

The opt2 Nsight Systems trace attributed about 25.2% of training kernel
execution time to dW1. The subsequent NCU capture showed 784 blocks,
128 threads/block, 40 registers/thread, 92.39% Achieved Occupancy and
95.77% L1 global-load hit rate. These are reasons to investigate per-thread
reuse and instruction organization, not evidence of DRAM saturation.

`dw1_register2` computes two adjacent input-feature rows at the SAME output
column. Each reduction iteration loads two X values and one delta value,
then updates two register accumulators. Separate threads computing these two
outputs would express four input loads rather than three. Cache behavior
means this source-level reduction is not an equivalent DRAM-byte prediction.
Keeping adjacent lanes on adjacent output columns preserves the existing
coalesced delta reads and output stores for the real N=128 shape.

The batch reduction order for each output is unchanged. A separate final-row
path handles odd input widths. There are no extra kernel launches, atomics,
shared-memory tiles, block barriers, or explicit K-loop unrolling.

| dW1 configuration, 128 threads/block | Mode 1 | Mode 2 |
| --- | ---: | ---: |
| Outputs per thread | 1 | 2 |
| Grid blocks for 784x128 outputs | 784 (naive control) | 392 |
| Mathematical outputs | 100352 | 100352 |
| Explicit shared bytes/block | 0 | 0 |

Registers/thread and final occupancy must be measured on the Jetson.
More registers or reduced parallelism can offset the reuse/ILP benefits.
Keep the version only if matched timings support it; a regression is also
a valid result to retain in the optimization report.

## Build and correctness check

```bash
(
    set -e -o pipefail
    cd cuda_03_register_reuse  # start this block from the FNN project root
    make
    mkdir -p ../outputs/opt3
    check_dir=$(mktemp -d "../outputs/opt3/check_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda_opt3 --check 2>&1 | tee "$check_dir/check_opt3.log"
    echo "$check_dir"
)
```

Build flags match opt2: `-O2 -lineinfo -std=c++14 -arch=sm_87`. The build uses
the existing `../src/` and `../include/` CPU implementation, which is unchanged:
https://github.com/Timili0826/ESE_366_PSoC_Labs/tree/62e4aee6af94989494c78b25bf62a49c138df2fc/FNN

The check needs no MNIST files. It includes 18 direct paired-row gradient
checks against an independent FP64 reference (odd/even feature widths,
non-warp-aligned output widths, batches 1/3/5/7/23/32, blocks 64/128/256),
plus opt2's 24 tiled GEMM and six fused-forward cases. There are 64 full
CPU-reference network cases across output/thread modes 1/2, tiles 8/16,
fusion off/on, and all/targeted policies, including partial actual batches.

The full checks compare preactivations, activations, losses, logits gradients,
all dW/db values, updated parameters, and a subsequent forward pass.
Tolerance remains `3e-5 + 5e-4 * abs(reference)`; nonfinite values fail.
Exit codes: 0 PASS, 2 mismatch, 1 configuration/runtime error.

## CLI and controlled comparison

```text
./fnn_cuda_opt3 [data_dir] [epochs] [lr] [batch] [output_dir] [threads] [tile] [policy] [fusion] [dw1_rows]
```

Defaults:
`../data/mnist 20 0.01 32 ../outputs/cuda_opt3 128 16 targeted on 2`

Keep `128 16 targeted on` fixed for the opt2-to-opt3 comparison. Change ONLY
the final `dw1_rows` argument:

- `1`: original opt2 dW1 implementation; the external opt2 binary remains
  available as an additional reference.
- `2`: replace only dW1 with `dw1_register2`.

The two-row override applies to first-layer dW regardless of the general
GEMM policy. Other GEMMs continue through opt2's dispatcher. Forward fusion
and selective dA1 tiling remain separate switches for earlier experiments.
Using `policy=naive` or `fusion=off` would change other variables and is not
the intended opt2-to-opt3 performance comparison.

## First three-epoch comparison

After the GPU check passes:

```bash
(
set -e -o pipefail
mkdir -p ../outputs/opt3
compare_dir=$(mktemp -d "../outputs/opt3/compare_$(date +%Y%m%d_%H%M%S)_XXXXXX")
for rows in 1 2
do
    { time -p ./fnn_cuda_opt3 ../data/mnist 3 0.01 32 \
        "$compare_dir/rows${rows}" 128 16 targeted on "$rows"; } \
        2>&1 | tee "$compare_dir/rows${rows}.log" || break
done
echo "$compare_dir"
)
```

Each run restarts from the same initialization, seed 39, data split, shuffle,
learning rate and precision. Compare epoch 2/3 train_GPU, evaluation/epoch wall,
whole-program real time, loss and accuracy. This change only affects training;
evaluation time is not expected to gain from the dW1 change.
For formal results use matched 20-epoch runs, three repetitions with alternate
1/2 ordering, and consistent device power/clock conditions.

Kernel counts stay 22 per training batch and 6 per evaluation batch with
forward fusion on. For the existing whole-program one-epoch workload the
expected total stays 46,163. Mode 2 replaces one kernel instead of eliminating
one; the dW1 block count changes instead.

## Profiling after correctness and timing

For the default fused/targeted mode, `dw1_register2` runs once in warm-up
and once per training batch. Filtering it and skipping one matching launch
selects the first real training dW1. Under mode 1, the previous matmul_naive
skip=7 selects dW1; that count is NOT valid for mode 2, which removes dW1
from the matmul_naive family. Validate selected shapes against the new trace.

Compare dW1 duration, registers/thread, achieved occupancy, instructions,
global load requests/sectors and local-memory loads/stores. The goal is a
faster kernel and training loop, not maximized occupancy alone. The registers
and compiler-generated instructions are measurements, not source promises.

## Saved results and remaining features

Output schema and timing boundaries match opt2. Each run saves metrics.csv,
run_info.txt (including dw1_rows_per_thread), and predictions.csv. tee logs
also retain Bash real/user/sys. Existing metrics are not overwritten.
Model checkpoints/resume/incremental retraining remain pending; this
experiment does not add those features or alter the training objective.

## Validation before delivery

The authoring environment has no nvcc or NVIDIA GPU. Local emulation executed
the production paired-row and fused-forward bodies and a phased translation
of the unchanged shared-memory kernel. All checks passed under AddressSanitizer
and UndefinedBehaviorSanitizer. Three-epoch synthetic IDX runs for original
opt2, opt3/mode1 and opt3/mode2 produced matching learning metrics and exercised
partial batches/export. Mode logging, the 392-block calculation, unchanged
kernel counts, and invalid final arguments were checked. LeakSanitizer was
disabled due to the environment's tracing restrictions.

This is not a native CUDA compile, GPU race/synchronization test or speedup
measurement. Required next validation: make and --check on Jetson, then timing.
