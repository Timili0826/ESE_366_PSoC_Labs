# Feedforward Neural Network (FNN) in C

A fully connected neural network implemented from scratch in C for MNIST handwritten digit classification. This ESE 366 project includes a CPU baseline and five preserved CUDA implementation stages.

Architecture: **784 → 128 → 64 → 10**  
Training: ReLU, cross-entropy loss, mini-batch SGD.

## 1. Setup

Download the MNIST dataset:

```bash
bash scripts/download_mnist.sh
```

Install Python dependencies for visualization:

```bash
python3 -m pip install numpy matplotlib pillow
```

## 2. Compile and Train

Compile the C implementation:

```bash
make
```

Train with default parameters:

```bash
make run
```

Alternatively, specify training parameters:

```bash
./fnn data/mnist 20 0.01 32
```

Arguments:

```text
./fnn [dataset_directory] [epochs] [learning_rate] [batch_size]
```

Default parameters:

| Parameter | Value |
|-----------|-------|
| Epochs | 20 |
| Learning rate | 0.01 |
| Batch size | 32 |
| Training split | 80% |
| Validation split | 20% |
| Random seed | 42 |

To change the network architecture, dataset split, or number of saved predictions, edit `main.c` and rebuild with `make`.

## 3. Generate Figures

After training, run:

```bash
./scripts/plot.sh
```

Or directly:

```bash
python3 scripts/plot.py
```

This generates:

- Training and validation accuracy curves.
- Training and validation loss curves.
- Representative correct and incorrect classifications.
- A PNG contact sheet of the selected MNIST digits.

The contact sheet retains 10 columns regardless of sample count.

## 4. View Results

Open the MNIST digit grid:

```bash
xdg-open outputs/test_digits.png
```

Open the scientific figures:

```bash
xdg-open outputs/figures/accuracy.pdf
xdg-open outputs/figures/loss.pdf
xdg-open outputs/figures/classifications.pdf
```

Figures are exported as PNG, PDF, and SVG.

## 5. Output Files for New Runs

| File | Description |
|------|-------------|
| `outputs/metrics.csv` | Training and validation metrics |
| `outputs/predictions.csv` | True and predicted digit labels |
| `outputs/test_digits.pgm` | Original MNIST contact sheet |
| `outputs/test_digits.png` | PNG version of the contact sheet |
| `outputs/figures/accuracy.*` | Accuracy versus epoch |
| `outputs/figures/loss.*` | Cross-entropy loss versus epoch |
| `outputs/figures/classifications.*` | Correct and incorrect classification examples |

The complete MNIST test set (10,000 images) is used for final evaluation. Saved prediction examples are a selected subset for visualization.

## 6. Quick Workflow

For subsequent experiments:

```bash
make
./fnn data/mnist 20 0.01 32
./scripts/plot.sh
```

The training and visualization results are saved automatically under `outputs/`.

## 7. Repository Layout

All commands in this README start from the `FNN/` root. The CPU implementation,
architecture, training settings, and all CUDA source contents are unchanged.

```text
FNN/
├── main.c, Makefile, include/, src/    CPU implementation
├── scripts/                           download and visualization scripts
├── cuda_00_baseline/                  CUDA baseline
├── cuda_01_tiling_attempt/             original broad GEMM tiling attempt
├── cuda_01_selective_tiling/           final opt1: eligible dA1 tiling
├── cuda_02_forward_fusion/             opt2: forward fusion
├── cuda_03_register_reuse/             opt3: dW1 two-output register reuse
├── data/                              download instructions (MNIST not bundled)
├── outputs/                           future run outputs
├── results/
│   ├── cpu/{baseline,smoke,outputs_snapshot}/
│   ├── cuda_baseline/{training_20ep,smoke,logs,profiling}/
│   ├── opt1/{tiling_attempt,selective}/
│   ├── opt2/                          comparisons, formal, checks, profiling
│   └── opt3/                          comparisons, formal, checks, profiling
└── docs/                              inventories, move and removal manifests
```

[Results index](results/README.md) describes the preserved experiments and their
configuration names. [Data preparation](data/README.md) documents the original
MNIST download source. [File moves](docs/file_moves.csv) maps original paths to
current paths with original SHA-256 hashes. Entries marked `removed_local_only`
were removed during the final upload cleanup; their destination is blank.
[Removal manifest](docs/removed_files.csv) records removed files and any identical
retained copies.
[Organization notes](ORGANIZATION.md) record verification and provenance limits.

Historical CPU outputs were moved to `results/cpu/outputs_snapshot/`. This is a
snapshot, not proof that its logs and metrics came from one run. No snapshots
were deduplicated. The output paths in sections 3–6 describe new CPU runs: run
training before plotting. CUDA source default output paths remain valid;
explicit paths in the examples below keep new runs separate from saved results.

## 8. CUDA Build, Check, and Training

CUDA builds require `nvcc` and a compatible NVIDIA GPU for execution. The default
Makefile architecture is `sm_87`; set `ARCH` for your CUDA host when necessary.
The following loop builds each version and runs its original numerical checks:

```bash
for variant in cuda_00_baseline cuda_01_tiling_attempt cuda_01_selective_tiling cuda_02_forward_fusion cuda_03_register_reuse; do
    make -C "$variant" && make -C "$variant" check || break
done
```

Run each example from the `FNN/` project root, one at a time after its
GPU check passes. Each subshell changes into that version's source directory,
creates its own fresh timestamped output directory, and keeps its log there.
No example writes new data into `results/`. The examples preserve the original
20 epochs, learning rate 0.01, batch 32 and version-specific CLI configuration:

```bash
# cuda_00_baseline
(
    set -e -o pipefail
    cd cuda_00_baseline
    mkdir -p ../outputs/cuda_baseline
    run_dir=$(mktemp -d "../outputs/cuda_baseline/full_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda ../data/mnist 20 0.01 32 "$run_dir" 128 2>&1 | tee "$run_dir/train.log"
    echo "$run_dir"
)

# cuda_01_tiling_attempt
(
    set -e -o pipefail
    cd cuda_01_tiling_attempt
    mkdir -p ../outputs/opt1/tiling_attempt
    run_dir=$(mktemp -d "../outputs/opt1/tiling_attempt/full_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda_opt1 ../data/mnist 20 0.01 32 "$run_dir" 128 16 targeted 2>&1 | tee "$run_dir/train.log"
    echo "$run_dir"
)

# cuda_01_selective_tiling
(
    set -e -o pipefail
    cd cuda_01_selective_tiling
    mkdir -p ../outputs/opt1/selective
    run_dir=$(mktemp -d "../outputs/opt1/selective/full_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda_opt1 ../data/mnist 20 0.01 32 "$run_dir" 128 16 targeted 2>&1 | tee "$run_dir/train.log"
    echo "$run_dir"
)

# cuda_02_forward_fusion
(
    set -e -o pipefail
    cd cuda_02_forward_fusion
    mkdir -p ../outputs/opt2
    run_dir=$(mktemp -d "../outputs/opt2/full_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda_opt2 ../data/mnist 20 0.01 32 "$run_dir" 128 16 targeted on 2>&1 | tee "$run_dir/train.log"
    echo "$run_dir"
)

# cuda_03_register_reuse
(
    set -e -o pipefail
    cd cuda_03_register_reuse
    mkdir -p ../outputs/opt3
    run_dir=$(mktemp -d "../outputs/opt3/full_$(date +%Y%m%d_%H%M%S)_XXXXXX")
    ./fnn_cuda_opt3 ../data/mnist 20 0.01 32 "$run_dir" 128 16 targeted on 2 2>&1 | tee "$run_dir/train.log"
    echo "$run_dir"
)
```

Variant details: [baseline](cuda_00_baseline/README.md),
[initial tiling](cuda_01_tiling_attempt/README.md),
[final selective tiling](cuda_01_selective_tiling/README.md),
[forward fusion](cuda_02_forward_fusion/README.md), and
[register reuse](cuda_03_register_reuse/README.md).
The restored selective source uses `fnn_cuda_opt1.cu`, matching its original
Makefile. The redundant earlier copy with a filename suffix was removed during upload cleanup.

On the organizing Mac, `nvcc` is unavailable. CUDA compilation and GPU execution
are unverified. `make -n -B` validates dependency resolution and displays commands;
it does not compile CUDA. No training or profiling was run during organization.

## 9. GitHub Upload Scope

`.gitignore` excludes downloaded MNIST, compiled artifacts, raw profiler reports,
SQLite databases, caches, and all of `local_archive/`. Formal logs, CSV data,
text summaries and figures remain eligible for upload. Local archives, caches,
and downloaded MNIST files have been removed from this upload copy. Run the
download script before training. Ignore rules do not automatically untrack files already tracked by Git.
This backup has no Git repository; no Git initialization, commit, push, remote
change, or history rewrite was performed.

The final upload tree was independently checked against the user-designated
original backup. See [original comparison report](docs/original_audit.md) for
source/evidence hashes, exclusions and build-validation limits.
