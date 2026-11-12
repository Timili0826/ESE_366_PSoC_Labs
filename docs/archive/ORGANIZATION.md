# Organization and upload cleanup

This Mac backup contains the CPU implementation and all five renamed CUDA
stages, with original source contents, filenames, executable names and training
settings unchanged. Active Makefiles and scripts require no path edits.

Before the detailed organization pass, 622 files were present, including both
previously organized files and restored originals. 284 target conflicts were
compared (278 identical, six differing documentation/Makefile copies). Existing
target copies were initially kept in local_archive; nothing was overwritten.

At the user's subsequent request to retain only GitHub upload files, local_archive
was deleted, including previous-pass duplicates, binaries, transfer packages and
raw profiler reports. Downloaded MNIST and metadata/cache files were also removed.
The active selective source is fnn_cuda_opt1.cu; the redundant unusual-filename
copy was removed. Source, experiment logs, CSV, text summaries and figures in the
upload tree were retained unchanged.

[Original inventory](../inventory_before.csv) is a historical record.
[Move manifest](../file_moves.csv) maps retained original files; removed entries
have an empty new_path and category removed_local_only.
[Removal manifest](../removed_files.csv) records deleted paths, hashes, sizes,
reasons and identical retained files where available.
[Collision comparisons](../collision_comparisons.csv) records prior comparisons;
its target paths refer to that earlier step, not necessarily current files.

CPU snapshots remain separate and are not assumed to represent a single run.
Initial opt1 diagnosis targeted differs from final selective targeted. Profiling
metrics are not formal performance benchmarks. Historical record contents,
including paths inside logs, were not rewritten.

No Ubuntu/Jetson connection, Git initialization, commit, push, remote change,
git rm or history rewrite was performed. .gitignore remains to exclude future
build products, downloaded data and caches. See [validation](validation.md).
