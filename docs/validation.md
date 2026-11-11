# Final upload-copy validation

- Removed local_archive, downloaded MNIST, and cache/metadata files at the user's request: 360 files, 292,832,662 bytes (about 279 MiB). 231 removed files have an identical retained file; other removals include unique local binary reports, packages, datasets and prior documentation copies.
- All retained source/header, active Makefile/script, log, experiment CSV, text summary and image contents match the hashes taken immediately before cleanup. Only README/organization documentation and the move manifest were updated.
- All 18 formal trials remain complete (six per optimization), including metrics.csv, predictions.csv, run_info.txt and matching logs. Missing records: none.
- Local Markdown links pass validation. CPU and all five CUDA Makefile build targets pass forced dry runs. Earlier shell and Python syntax checks passed; scripts are unchanged.
- CUDA compilation and GPU execution remain unverified because nvcc is unavailable. No training, profiling, dependency installation or figure regeneration was performed.
- The historical pre-organization inventory is not a claim that removed files still exist. Move-manifest entries marked removed_local_only have empty destinations; removed_files.csv records deletion hashes and identical retained paths where available.
- No Git initialization, commit, push, remote update, git rm or history rewrite was performed. Ignore rules remain for future downloads and build outputs; they do not automatically untrack existing tracked files.
- MNIST must be downloaded again using bash scripts/download_mnist.sh before training.

## Largest retained files

| Path | MiB |
|---|---:|
| `results/opt1/tiling_attempt/profiling/nsys_diagnosis_20261109_200107/targeted_trace.csv` | 10.75 |
| `results/opt2/profiling/nsys_fusion_20261110_130819/off_trace.csv` | 10.66 |
| `results/cuda_baseline/profiling/nsys_20261109_152558/kernel_execution_trace.csv` | 10.66 |
| `results/opt1/tiling_attempt/profiling/nsys_diagnosis_20261109_200107/naive_trace.csv` | 10.64 |
| `results/opt3/profiling/nsys_ncu_20261110_214823/rows1_trace.csv` | 8.87 |
| `results/opt2/profiling/nsys_fusion_20261110_130819/on_trace.csv` | 8.87 |
| `results/opt3/profiling/nsys_ncu_20261110_214823/rows2_trace.csv` | 8.85 |
| `results/cuda_baseline/profiling/ncu_20261109_152907/metrics.txt` | 0.54 |

No retained file is 50 MiB or larger.

## Independent comparison with the original folder

The subsequent read-only comparison against the user-designated original backup
passes: 255 byte-identical retained files, six updated READMEs, 68 intentional
upload exclusions; no missing source/evidence or unexpected content changes.
CPU compilation was verified again. See [original audit](original_audit.md) and
[per-file comparison](original_comparison.csv) for details.

## README command correction: static validation

The earlier Markdown-link and Makefile dry-run checks did not detect incorrect
executable strings in README examples. Their previous broad path-validity
conclusion was incomplete. This revision explicitly compares documented
executable paths with each unchanged Makefile's all/output/check targets.

| Source directory | Makefile executable / documented invocation |
|---|---|
| `cuda_00_baseline` | `./fnn_cuda` |
| `cuda_01_tiling_attempt` | `./fnn_cuda_opt1` |
| `cuda_01_selective_tiling` | `./fnn_cuda_opt1` |
| `cuda_02_forward_fusion` | `./fnn_cuda_opt2` |
| `cuda_03_register_reuse` | `./fnn_cuda_opt3` |

- All CUDA executable references in the five version READMEs match the Makefile targets. No example invokes local_archive/build_artifacts. Binary existence is not required: make -n -B confirms the target would be generated.
- Reviewed 13 CUDA training/comparison invocation sites, including root examples and baseline nohup; CLI positional order, epoch counts and numerical/optimization configurations are unchanged. Working-directory declarations, ../data/mnist resolution, explicit output variables and log paths were checked statically.
- Baseline smoke/full/nohup examples each independently define a timestamped mktemp directory under ../outputs/cuda_baseline and log into it. Other CUDA run/check examples use fresh outputs directories. No CUDA code block writes new data into results; existing historical result references stay in results.
- 24 Bash code blocks pass bash -n. They were not executed. No build/check, training, nohup job, profiling or GPU command was run from the README.
- All five Makefile build/check targets pass forced dry runs. This is static dependency/command validation, not actual compilation.
- 228 ignore probes, including source/header paths and formal log/CSV files, are not ignored. .gitignore itself is unchanged.
- Every byte-identical source/evidence entry in original_comparison.csv still matches its stored original SHA-256. Original backup hashes and historical inventory/move/removal/comparison CSV files are unchanged.
- File names, directory structure, source, Makefiles, scripts and all historical experiment files are unchanged relative to the snapshot before this README correction. Only six READMEs and these two audit Markdown reports are edited inside FNN.
- Historical host-emulation/synthetic-run statements retained in version READMEs came from the original documentation; they are not tests performed during this correction. Previous CPU compilation results are historical checks, not a new build in this revision.
- nvcc remains unavailable. Actual CUDA compilation, CUDA numerical checks and GPU execution are unverified. No installation, training, profiling, commit or push was performed.

### Current README SHA-256

These are hashes of the corrected READMEs, separate from the unchanged original
backup hashes in the historical manifests.

| README path | Current SHA-256 |
|---|---|
| `README.md` | `f97e131cd6d08d0a605321d571303182139ddbf3e76953e38c421be1a2d6d620` |
| `cuda_00_baseline/README.md` | `c3fd977bbb60299e3be29361752c28ee12b2b6fb10f79be08fa682839d160486` |
| `cuda_01_tiling_attempt/README.md` | `b65e1fd424ed5475afad7faf14b0e23947b2956a0346b5901480f623fc264c1a` |
| `cuda_01_selective_tiling/README.md` | `304cff123f861ffcb0b199b90842b384b1612e60632eb13ecb7f74e564a42bf6` |
| `cuda_02_forward_fusion/README.md` | `cd90d8d82aa3c2c21daf9900df2d21a0e6cd12fb36758311bb113fd624bbb906` |
| `cuda_03_register_reuse/README.md` | `437c16af613f1278b01a27f3ffad887e51d186009bcf4082e322c89456911f70` |
