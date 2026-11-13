# Validation accuracy versus training time

The comparison uses one CPU wall-time run, one CUDA baseline, and three same-seed
timing repetitions each of Opt1 selective tiling, Opt2 forward fusion and Opt3
register reuse. Profiling, smoke, controls, old CPU snapshots and the failed
broad-tiling attempt are excluded. The run_id in epoch_observations.csv identifies each
original measurement directory; source measurements are not duplicated here.

figures/ contains PNG and vector PDF versions of accuracy_vs_epoch,
validation_accuracy_vs_time, validation_accuracy_vs_time_cuda,
validation_accuracy_vs_time_log and incremental_validation_accuracy_vs_time.
Thick comparison curves show per-epoch replicate means; faint curves show the
individual timing runs. Lines connect observed epoch endpoints without smoothing.

Time sums measured epoch wall intervals: shuffle, training and post-epoch
training/validation evaluation. Setup, warm-up, final test and export are excluded.
It differs from the train-only GPU event measure. Thresholds are found within
each run before averaging: CPU first reaches 96% at epoch 17, CUDA at 18.

The derived CSVs retain epoch observations, mean epoch times, per-run threshold
crossings, summaries, speedup ratios and incremental-stage observations/results.
Temperature, frequency and power were not controlled across measurement dates;
these repeats do not measure variation across independent random seeds.

From the repository root:

```bash
python3 -m pip install -r requirements-analysis.txt
python3 scripts/analyze_time_accuracy.py --out outputs/new_analysis
```

Use a new output directory; add --no-plots for CSV-only, or --png-only when PDF
dependencies are unavailable. No training, GPU or checkpoint is needed.
See the [usage guide](../../docs/time_accuracy_incremental.md) for methodology
and [incremental results](../incremental_training/README.md) for the new-data experiment.
