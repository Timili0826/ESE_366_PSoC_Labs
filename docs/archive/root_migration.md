# FNN root migration validation

Base commit: `57ad63fc806fb0699e65eac042d165c7d9b7d0e7` on main. Origin remains
`https://github.com/Timili0826/ESE_366_PSoC_Labs.git`.

Before any changes, the complete worktree (excluding Git internals) was copied to:
`/Users/lichenyi/Downloads/ESE_366_PSoC_Labs_worktree_backup_20261111_174054`.
All 1633 backed-up files match their before-migration SHA-256 hashes.
The old root README, Labs, cuda_projects and notes.txt remain in that external
backup. A sibling `.manifest.json` records original hashes and file modes.
No LICENSE file was present; no license or original author credit was removed.
The fork parent is marcusvel28/ESE_366_PSoC_Labs; CPU attribution is explicit in
the current root README. Git history and fork relationship are retained.

## Content preservation

All 273 former FNN files are present at the repository root after
removing the leading FNN/ path component. 266 files match byte-for-byte;
only seven active README files changed. All C/CUDA source, headers, Makefiles,
scripts, historical results and original audit records retain their SHA-256.
The original `.gitignore` was moved unchanged; there was no root ignore conflict.
[Per-file before/after hashes](../root_migration_hashes.csv) record each former
FNN file. Old inventory, comparison, removal and validation records are retained
as historical documents without rewriting their hashes or paths.

## Static checks

- All 18 formal trials are complete, with metrics, predictions, run information and matching logs.
- CPU and all five CUDA Makefile build targets, plus five CUDA check targets, pass forced dry runs. Shared include/src and data/output paths remain valid at the same relative depth.
- Executable references in the five CUDA READMEs match their Makefile targets. 25 Bash blocks pass bash -n. No active command or script uses the obsolete FNN/ nesting; old pinned-commit URLs intentionally retain their historical FNN path.
- 49 active README local links resolve. The migration report and hash-manifest links are checked again after these files are written.
- 179 source/header/log/CSV paths are not ignored. Sample data, executable, build and raw profiler paths are ignored. No data, build executable, archive package or profiler binary exists in the final project tree.
- README Random seed is 39, matching unchanged code. Existing training configurations are unchanged.
- nvcc is unavailable. No actual CUDA compilation, GPU test, training or profiling was performed. Dry runs are static command/dependency checks, not GPU validation. No CPU executable was built in this migration either.

## Modified current documentation

- `README.md`
- `cuda_00_baseline/README.md`
- `cuda_01_selective_tiling/README.md`
- `cuda_01_tiling_attempt/README.md`
- `cuda_02_forward_fusion/README.md`
- `cuda_03_register_reuse/README.md`
- `data/README.md`

Current README hashes are recorded separately in root_migration_hashes.csv; original hashes in older audit records remain untouched.
