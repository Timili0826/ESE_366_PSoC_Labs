# Experiment results

- [Five-version time–accuracy comparison](time_accuracy/README.md): CPU, CUDA
  baseline and three final optimizations using comparable epoch wall time.
- [Incremental training](incremental_training/README.md): 40000 initial images,
  followed by8000 new images loaded in a separate process.
- [CPU wall-time run](cpu/wall_time_20261112/README.md): the formal CPU timing input.

Original CPU records remain under cpu/baseline, cpu/smoke and cpu/outputs_snapshot.
Only the formal wall-time run is used for the current timing comparison.
CUDA baseline training and profiling text are under cuda_baseline/.

Optimization experiments retain comparisons, numerical checks, formal trials and
profiling text/CSV for studying why an optimization helps or fails:

- opt1/tiling_attempt: broad tiling, retained as a failed attempt.
- opt1/selective: final selective dA1 tiling; targeted is the final setting,
  naive is the control. The earlier broad attempt's targeted label means a
  different policy and must not be substituted for final Opt1.
- opt2/: on enables forward fusion; off is the control.
- opt3/: rows2 enables register reuse; rows1 is the Opt2 control.

Each optimized configuration has three same-seed formal timing repetitions.
Profiling and smoke data are diagnostic, not formal performance measurements.
Raw experiment CSVs, logs and run_info are retained as recorded, including their
historical path strings. Consult the usage guide in docs/ to reproduce analysis.
