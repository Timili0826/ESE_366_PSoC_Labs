# Incremental Opt3 experiment — 2026-11-12

Imported raw files are unchanged. `b_initial/` trains 40000 images for10 epochs,
12500 updates; a separate `b_new/` process loads the epoch10 checkpoint and trains
only the new8000 images for5 epochs, adding1250 updates. Both keep validation12000
and test10000 fixed; sample IDs are retained separately from the test namespace.

`b_new/metrics.csv` starts with `loaded_before_update`; its loss, accuracy,
update count and cumulative epoch time equal the last initial-stage observation.
Validation accuracy94.4916666667% →94.8250%, gain0.3333333333 percentage points.
New-stage measured epoch time0.760827039s; process wall time1.68254s;
final test accuracy95.60%. The second new-data epoch's decrease is retained.

`status.txt` is COMPLETED. Jetson Orin Nano CC8.7/sm_87 logs include four CUDA
numerical PASS records plus incremental GPU checks. `incremental_checks/PASS.txt`
reports no-update warm-up, checkpoint parameter/logits/loss roundtrip and exact
same-device continuous-versus-resumed synthetic training. These are Jetson
execution records, not newly executed local GPU checks.

Source/data provenance is in `source_sha256.txt`, `environment.txt`, `runner.log`
and both run_info files. Original remote paths remain unchanged as evidence;
analysis uses the retained repository-relative files. All checkpoint payloads
remain in the original local TAR backup and are intentionally not committed.

From the repository root, run `python3 scripts/analyze_time_accuracy.py --out
outputs/new_analysis` (new directory), or use the root README for future training.
This demonstrates new-data continuation, not superiority over training from
scratch or a solution to catastrophic forgetting.
