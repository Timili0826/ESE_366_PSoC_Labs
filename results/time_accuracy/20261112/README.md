# Time–accuracy analysis — 2026-11-12

All commands start at the repository root. One formal CPU wall-time run, one
CUDA baseline and3 same-seed timing repeats each of Opt1/2/3 are selected.
Opt1 is selective tiling, not the preserved failed broad-tiling attempt.

Five PNG/vector-PDF pairs are in `figures/`: accuracy_vs_epoch,
validation_accuracy_vs_time, validation_accuracy_vs_time_cuda,
validation_accuracy_vs_time_log and incremental_validation_accuracy_vs_time.
The supplied vector figures are retained unchanged; thin curves show repeats,
thick comparison curves show per-epoch replicate means. Lines connect measured
epoch endpoints, with no smoothing or interpolated crossing time.

`source_manifest.csv` contains11 selected inputs with repository-relative paths
and actual retained byte hashes. `selection_audit.csv` records exclusions.
`input_crosscheck.csv` establishes agreement with all11 analysis-ZIP inputs;
old CUDA raw files are not copied again or rewritten. `figure_import_manifest.csv`
records unchanged figure hashes. Source LF/CRLF and analysis-maintenance differences
are explicit in `source_hash_comparison.csv`.

Derived tables: epoch_observations.csv, epoch_time_summary.csv,
time_to_accuracy.csv, time_to_accuracy_summary.csv, time_to_accuracy_speedup.csv,
incremental_observations.csv and incremental_summary.csv. Thresholds are located
separately per run and only then summarized; CPU crosses96% at epoch17, CUDA at18.
The old CPU baseline/snapshot remains but is not another timed replicate.

The time scope is shuffle+train+post-epoch train/validation evaluation, excluding
setup/warm-up/final test/export. It is not Opt3's ~442ms train_GPU event timing.
See the root README and `docs/time_accuracy_incremental.md` for exact times,
stage results and provenance limits. `checkpoint_audit_supplied.csv` is supplied
analysis evidence about15 local archived models; it is not model payload data.

Reproduce with the single current analysis implementation:

```bash
python3 -m pip install -r requirements-analysis.txt
python3 scripts/analyze_time_accuracy.py --out outputs/new_analysis
```

Use a new output directory. Add --no-plots for CSV-only, or --png-only when optional
PDF font dependencies are unavailable. The script needs no GPU, model checkpoint,
training or original download-package location. Current local checks recomputed
CSV and PNG; the supplied vector PDFs were hash/resource-checked, not locally rerendered.

Historical CUDA build commits/dataset hashes are incomplete, and cross-date
power/clock/thermal conditions were not controlled. Timing repeats are not
independent convergence experiments. Incremental improvement does not establish
superiority over from-scratch training or solve catastrophic forgetting.
