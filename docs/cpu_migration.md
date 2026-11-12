# CPU directory migration validation

Base commit: aefd0e4bfe7495e33b0c43614adc7b5c4d34e55e.

## Changes

- Moved main.c, include/, src/ and the CPU Makefile into cpu/.
- Updated all five CUDA Makefiles, including compiler include flags, source prerequisites and header prerequisites.
- CPU make run creates ../outputs and executes from the repository root, using data/mnist and outputs/ without changing application code.
- Updated active README paths and .gitignore; scripts already resolve the repository root and are unchanged.
- All C/CUDA source, training settings, kernels, results, and historical audit records are unchanged. Historical paths describe their original snapshots.

## Local validation

Windows x64, portable w64devkit 2.11.0 GCC/GNU Make:

- make -C cpu: compiled successfully with -O2 -Wall -Wextra -std=c11; no compiler diagnostics.
- make -n -B -C cpu run: resolves root data and output paths correctly; training was not executed.
- make -n -B -C <each CUDA directory> check: all five passed dependency resolution; commands use ../cpu/src and ../cpu/include.
- Source include review: project headers use header names, with no explicit obsolete root paths to rewrite.
- sh -n scripts/download_mnist.sh and sh -n scripts/plot.sh: passed. Script execution that downloads data or generates figures was not performed.
- scripts/plot.py resolves ROOT from its own location and uses root outputs/; no path change needed.
- CPU invalid-epoch invocation exits with usage before loading data or training.
- Active README local links: all resolved. Git rename detection confirms all moved C sources and headers are 100% identical; CUDA sources and historical records have no diff.
- Build ignore checks cover cpu/fnn, cpu/fnn.exe, CPU objects, CUDA objects and CUDA executables.
- No training or profiling was performed. No nvcc/GPU is available locally: CUDA compilation and execution are NOT verified.
- SSH to cad28107@ubuntu reached authentication but failed with Permission denied (publickey,password); remote checks are pending.

## Jetson rebuild and numerical checks

Run from a clean checkout of this branch on the Jetson, at the repository root:

~~~bash
set -e
export PATH=/usr/local/cuda/bin:$PATH
cat /proc/device-tree/model; echo
nvcc --version
make -C cpu clean
make -C cpu

# Original Jetson Nano (Maxwell): sm_53. For Orin Nano use sm_87.
ARCH=sm_53
for variant in cuda_00_baseline cuda_01_tiling_attempt cuda_01_selective_tiling cuda_02_forward_fusion cuda_03_register_reuse; do
    make -C "$variant" clean
    make -C "$variant" ARCH="$ARCH"
    make -C "$variant" ARCH="$ARCH" check
done
~~~

Each check target invokes that version's executable with --check. It requires no MNIST dataset and does not run training or profiling. The CPU CLI has no --check mode; compile it only for this validation.

Architecture reference: [NVIDIA legacy GPU compute capabilities](https://developer.nvidia.com/cuda/gpus/legacy) lists the original Jetson Nano as compute capability 5.3. Confirm the actual board before selecting ARCH; existing Makefile defaults remain sm_87.

For later user-requested training only (not executed during this migration):

~~~bash
make -C cpu
./cpu/fnn data/mnist 20 0.01 32
# Equivalent default training through Make, with root data/output paths:
make -C cpu run
~~~
