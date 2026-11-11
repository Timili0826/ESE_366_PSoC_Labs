# Preserved experiment results

These are historical records; their contents, trial names and timestamps are
unchanged. See the [move manifest](../docs/file_moves.csv) for old paths and
SHA-256 hashes. Local-only archives were removed during final upload cleanup;
see the [removal manifest](../docs/removed_files.csv).

## CPU and CUDA baseline

- [CPU baseline](cpu/baseline/), [CPU smoke](cpu/smoke/), and [CPU output snapshot](cpu/outputs_snapshot/).
- [CUDA 20-epoch baseline](cuda_baseline/training_20ep/), [CUDA smoke](cuda_baseline/smoke/), and [baseline logs](cuda_baseline/logs/).
- Baseline profiling: [Nsight Systems](cuda_baseline/profiling/nsys_20261109_152558/) and [Nsight Compute](cuda_baseline/profiling/ncu_20261109_152907/).

CPU directories are preserved independently. A smoke log and metrics in the same
historical directory are not assumed to describe the same run. No duplicate
records were removed.

## Optimization 1

The initial broader tiling attempt is retained separately from final selective
dA1 tiling:

- Initial attempt: [smoke](opt1/tiling_attempt/smoke_20261109_170032/), [comparison](opt1/tiling_attempt/compare_20261109_170526/), [checks](opt1/tiling_attempt/checks/), and [diagnostic profiling](opt1/tiling_attempt/profiling/nsys_diagnosis_20261109_200107/).
- Final selective version: [comparison](opt1/selective/compare_20261109_201600/), [formal](opt1/selective/formal_20261109_202856/), and [checks](opt1/selective/checks/).

In opt1 formal results, `naive` is the control and `targeted` is the final
selective tiling strategy. In the initial diagnostic profiling, `targeted`
means the earlier broader tiling policy; it is not the final selective version.

## Optimization 2

[Comparison](opt2/compare_20261110_123619/), [formal](opt2/formal_20261110_124310/),
[checks](opt2/checks/), [Nsight Systems](opt2/profiling/nsys_fusion_20261110_130819/),
and [Nsight Compute](opt2/profiling/ncu_20261110_151153/).
`off` and `on` disable and enable forward fusion respectively.

## Optimization 3

[Comparison](opt3/compare_20261110_210146/), [formal](opt3/formal_20261110_212458/),
[checks](opt3/checks/), and [profiling](opt3/profiling/nsys_ncu_20261110_214823/).
`rows1` is the optimization 2 control; `rows2` enables optimization 3's dW1
register reuse with two outputs per thread.

## Interpreting records

Each opt1, opt2 and opt3 formal experiment has six trials: three repetitions for
each of its two configurations. Each trial contains metrics, predictions and
run information, with its matching log beside the trial directory.

Profiling run metrics are instrumented measurements, not formal performance
benchmarks. Text summaries, CSV traces and capture/export/background logs
(including empty logs) remain here. Original `.nsys-rep`, `.sqlite` and `.ncu-rep` files, compiled products,
transfer packages, and previous-pass duplicate copies were removed at the user's
request. Their hashes and any identical retained files are recorded in the
[removal manifest](../docs/removed_files.csv). Profiler binary reports are not
included; preserved text summaries and CSV traces remain available here.
