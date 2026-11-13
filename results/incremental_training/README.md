# Incremental training with Opt3

initial_training/ uses 40,000 MNIST training images for 10 epochs (12,500 updates).
A separate new_data_training/ process loads that model and uses only the new 8,000
images for 5 epochs (1,250 additional updates). Validation stays fixed at 12,000;
test uses the separate 10,000-image test files.

The two sample_ids.csv files record identical, disjoint training/validation
partitions. The first new-data metrics row is loaded_before_update: its loss,
accuracy, update count and cumulative time match the last initial-stage row.

Validation accuracy improves 94.4916667% to 94.8250%, a gain of 0.3333333 percentage
points. The new-data epochs take 0.760827039s for training plus evaluation;
process wall time is 1.68254s and final test accuracy 95.60%.
The temporary accuracy decrease at the second new-data epoch is retained.

metrics.csv and run_info.txt in each stage, the stage logs, runner.log,
status.txt, environment.txt and incremental_checks/PASS.txt record the experiment.
The Jetson Orin Nano numerical/restore checks passed and the run is COMPLETED.
Original path strings in logs are retained; checkpoints are local runtime files.

This demonstrates loading a trained model and learning from new data. It does
not establish superiority over training from scratch or solve catastrophic
forgetting. See the [usage guide](../../docs/time_accuracy_incremental.md) for
checkpoint/resume commands and timing definitions.
