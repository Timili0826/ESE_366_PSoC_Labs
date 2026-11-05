# Feedforward Neural Network (FNN) in C

A fully connected neural network implemented from scratch in C for MNIST handwritten digit classification. This is the CPU baseline for ESE 366, with CUDA acceleration planned.

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

## 5. Output Files

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

## 7. Future Work

- CUDA acceleration of dense layers and backpropagation.
- CPU/GPU execution-time comparison.
- Model checkpointing.
- Confusion matrices and per-class accuracy analysis.
```
