#!/usr/bin/env python3
"""Make one graph per CUDA operation from benchmark_results.csv."""
import csv
from pathlib import Path
import matplotlib.pyplot as plt

eval_dir = Path(__file__).resolve().parent

rows = list(csv.DictReader(
    (eval_dir / "benchmark_results.csv").open(newline="")
))

for operation in ("transpose", "trace", "sum", "multiply"):
    subset = [r for r in rows if r["operation"] == operation]
    if not subset:
        continue
    fig, ax = plt.subplots(figsize=(7, 4.5))
    for variant in ("baseline", "optimized"):
        data = sorted((r for r in subset if r["variant"] == variant),
                      key=lambda r: int(r["size"]))
        if data:
            ax.plot([int(r["size"]) for r in data],
                    [float(r["kernel_ms"]) for r in data],
                    marker="o", label=variant.capitalize())
    ax.set(xlabel="Square matrix dimension N (N x N)",
           ylabel="Median GPU kernel time (ms)",
           title=f"CUDA Matrix {operation.capitalize()} Performance")
    ax.set_xticks(sorted({int(r["size"]) for r in subset}))
    ax.grid(True, alpha=0.3)
    ax.legend()
    fig.tight_layout()
    path = eval_dir / f"{operation}_timings.png"
    fig.savefig(path, dpi=200)
    plt.close(fig)
    print(f"Saved {path}")
