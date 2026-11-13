# CPU wall-time experiment

One 20-epoch run on Jetson Orin Nano: MNIST 48,000/12,000/10,000,
784-128-64-10 FP32, SGD lr=0.01, batch=32, seed=39.
Each epoch includes shuffle, training and post-epoch training/validation evaluation;
setup, final test and export are outside the timing interval.

The first 95% validation accuracy is at epoch 11, 319.108336923s;96% is at epoch 17,
493.208834642s. The 20 epochs total 580.215648411s. The separate process clock
field is not used in the wall-time comparison. Older CPU records are not
additional timing repeats.

metrics.csv contains the measurements; train.log/run_info.txt describe the run.
runner.log and incremental_checks/PASS.txt retain the numerical checks;
status.txt is COMPLETED and environment.txt identifies the test system.
Reproduce analysis from the repository root using
`python3 scripts/analyze_time_accuracy.py --out outputs/new_analysis`.
