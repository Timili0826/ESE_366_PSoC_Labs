# MNIST data

From the repository root (the FNN project root), run the existing script:

```bash
bash scripts/download_mnist.sh
```

The script uses `curl` and `gzip`, downloads from
`https://storage.googleapis.com/cvdf-datasets/mnist`, retains the `.gz` files,
and extracts them into `data/mnist/`:

- `train-images-idx3-ubyte`
- `train-labels-idx1-ubyte`
- `t10k-images-idx3-ubyte`
- `t10k-labels-idx1-ubyte`

CPU runs from the repository root use `data/mnist`; CUDA runs from their source
directories use `../data/mnist`. Downloaded data were removed from the GitHub upload copy; rerun the script
before training. `/data/mnist/` remains ignored to avoid adding future downloads.
No data were downloaded during organization.
