# Verification against the original backup

Reference (read only): `/Users/lichenyi/Downloads/ESE366_project2_backup2/`.
Upload tree: `/Users/lichenyi/Downloads/ESE366_project2_backup/FNN/`.

This comparison uses the user-designated original backup, independently of the
previous organization manifests. It contains 329 original files. The earlier
622-file inventory also included copies from the previous organization pass;
these counts describe different starting snapshots.

## Original-file comparison

- 255 files are byte-identical at their expected organized paths, verified with SHA-256. This includes all C/CUDA source, headers, Makefiles, scripts, and retained experiment logs, CSV, text summaries and images.
- Six README files were intentionally updated for the new layout and instructions.
- 68 original files were excluded from this upload copy: build artifacts/executables, downloaded MNIST, transfer packages and raw profiler binary reports/databases. This follows the user's subsequent request to retain upload files only.
- No required source or experimental evidence is missing or unexpectedly changed. No result evidence in the organized tree lacks a matching original file.
- The original directory was not modified; its full file inventory and SHA-256 hashes were rechecked after validation.

[original_comparison.csv](original_comparison.csv) provides one row for every
original file, its expected upload path, original SHA-256 and comparison status.
`excluded_from_upload` entries have an empty destination. Earlier move/removal
manifests remain historical records of the previous cleanup steps.

## Upload and build checks

- All 18 formal trials are complete: six each for opt1, opt2 and opt3, with metrics.csv, predictions.csv, run_info.txt and matching sibling logs.
- Every existing upload-copy file passes the project's .gitignore rules; no residual ignored data, archive, executable or cache file remains. No symlinks, old CUDA source directory names or Git metadata directory are present.
- CPU compilation succeeds with the Makefile's flags into a temporary directory outside the project. The binary was not run and no experiment data were generated.
- CPU and all five CUDA build targets, plus all five CUDA check targets, resolve in forced dry runs. This is not evidence of CUDA compilation.
- Both shell scripts pass bash syntax checks; plot.py passes Python syntax compilation without execution. 45 local Markdown links were checked before adding this audit report.
- nvcc is unavailable. Actual CUDA compilation and GPU execution/correctness checks remain unverified. No CUDA installation, training or profiling was performed.
- The largest upload file is the opt1 initial diagnosis targeted_trace.csv: 11,276,692 bytes (10.75 MiB). No upload file reaches 50 MiB.
- No git init, commit, push, remote update, git rm or history rewrite was performed. This directory is ready as an upload source; no actual upload was attempted.

MNIST is intentionally absent. Run `bash scripts/download_mnist.sh` before
training. Keep .gitignore when uploading so future data and build products remain
excluded.

## Subsequent README command correction

The original audit's link and build-target dry-run checks did not prove that
all README executable strings were correct. The later correction explicitly
matches them to the unchanged five Makefiles and checks working directories,
CLI order, output variables and logs. Incorrect local_archive invocations were
replaced with the actual local executable targets. New baseline foreground and
nohup runs independently create timestamped directories under outputs; no new
run writes to historical results.

See [current static-validation details and README hashes](validation.md) for
13 checked CUDA training/comparison sites, 24 bash syntax checks and 228 ignore
probes. All original source/evidence hashes remain unchanged; original README
hashes in the comparison CSV are historical hashes, not current README hashes.
No actual CUDA compilation or GPU test was performed in this correction.
