# MNIST FNN classifier — pure C baseline

CPU-only reference for ESE 366; CUDA acceleration is **not** implemented yet.
This is **classification**, not image segmentation. It trains a 784-128-64-10 FNN on MNIST with ReLU hidden activations, raw-logit categorical cross entropy, and mini-batch SGD.

## Build and run (Linux)

```bash
bash scripts/download_mnist.sh
make
make run
```

To adjust training without recompiling:

```bash
./fnn data/mnist 10 0.01 32
```

Arguments: dataset directory, epochs, learning rate, batch size. Defaults are 5, 0.01, and 32. For train/validation ratio and layer sizes, edit `main.c` and rebuild with `make`.

Training set: 80% of original MNIST train split, validation: remaining 20%, held-out MNIST test: 10,000 samples. Both have their original separate images/labels; split uses a fixed random seed. The sample indices are shuffled each epoch.

## Outputs

- `outputs/metrics.csv`: epoch, training/validation loss and accuracy.
- `outputs/predictions.csv`: first 40 test sample true/predicted classes.
- `outputs/test_digits.pgm`: first 40 test images arranged as a grid; labels are in the CSV in left-to-right, top-to-bottom order. Open PGM in an image viewer or convert with ImageMagick: `magick outputs/test_digits.pgm outputs/figures/test_digits.png`.

To view figures:

```bash
xdg-open outputs/figures/accuracy.svg
xdg-open outputs/figures/loss.svg
xdg-open outputs/test_digits.pgm
```

Training uses per-sample forward/backward passes and accumulates gradients for each mini-batch. CPU reference code prioritizes readability rather than speed.

## Implementation notes

- `activation.c`: ReLU/Tanh/Sigmoid/GELU plus numerical-stability-aware Softmax utility.
- `layer.c`: dense matrix-vector layer, gradients, SGD step.
- `loss.c`: stable softmax-cross-entropy on raw logits (no sigmoid on output).
- `network.c`: layer orchestration and backpropagation.
- `dataset.c`: direct IDX binary reader (no Python/Pillow dependency).
- `visualization.c`: PGM grid, plus predictions CSV generated in `main.c`.

## Next steps

After validating CPU accuracy, use your Project 1 CUDA matrix operations for batched dense layers and compare kernel configurations on Jetson Orin Nano. Also add model checkpointing for incremental retraining, since that requirement is **not yet implemented** here.
