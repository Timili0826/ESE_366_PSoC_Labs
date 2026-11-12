# CPU monotonic wall-time run — 2026-11-12

One formal run: MNIST 48000/12000/10000, 784-128-64-10 FP32, SGD lr=0.01,
batch=32, seed=39, 20 epochs. Imported byte-for-byte from `timeinc_results.tar.gz`;
the old `results/cpu/baseline/` is unchanged and is not a second timing repeat.

Jetson Orin Nano CC8.7 (`ARCH=sm_87`), CUDA12.6/GCC11.4: `status.txt` is COMPLETED.
`runner.log` records CPU compilation/output tests, host checkpoint checks, four
CUDA numerical checks and incremental GPU PASS before training. These are retained
Jetson executions, not new local GPU validation.

From the repository root, inspect `metrics.csv`, `train.log`, `run_info.txt`,
`environment.txt`, `source_sha256.txt`, and `incremental_checks/PASS.txt` here.
The imported run_info's remote absolute paths are retained as original provenance;
the active analysis manifest resolves the local retained files using relative paths.

Each epoch wall time includes shuffle, training, training/validation evaluation.
Setup, warm-up, final test and export are outside this scope. First 95%: epoch11,
319.108336923s; first96%: epoch17,493.208834642s. Total20 epochs:580.215648411s.
The separate process clock field is not used as the comparison time.

Reproduce from the repository root with `python3 scripts/analyze_time_accuracy.py
--out outputs/reproduced_cpu_analysis` (use a new output directory).
Raw import hashes are in `docs/timeinc_import_manifest.csv`.
