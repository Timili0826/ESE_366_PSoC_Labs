#!/usr/bin/env python3
"""Compile and benchmark the four ESE 366 CUDA programs.

Folder layout:
  baseline/{transposeMatrix,traceMatrix,sumMatrix,multMatrix}.cu
  optimized/{transposeMatrix,traceMatrix,sumMatrix,multMatrix}.cu

Example:
  python3 benchmark_cuda.py --variant baseline --sizes 256 512 1024 4096
  python3 benchmark_cuda.py --variant optimized --sizes 256 512 1024 4096
"""
import argparse
import csv
import re
import statistics
import subprocess
from pathlib import Path

PROGRAMS = {
    "transpose": "transposeMatrix.cu",
    "trace": "traceMatrix.cu",
    "sum": "sumMatrix.cu",
    "multiply": "multMatrix.cu",
}
FIELDS = ["variant", "operation", "size", "kernel_ms", "repeats"]


def run(command, timeout):
    return subprocess.run(command, capture_output=True, text=True, timeout=timeout)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--variant", choices=["baseline", "optimized"], required=True)
    p.add_argument("--sizes", nargs="+", type=int, default=[256, 512, 1024, 4096])
    p.add_argument("--repeats", type=int, default=5)
    p.add_argument("--timeout", type=int, default=240)
    p.add_argument("--output", default="benchmark_results.csv")
    args = p.parse_args()
    if args.repeats < 1 or any(n < 1 for n in args.sizes):
        p.error("Repeats and sizes must be positive")

    # Find the project directory (one level above eval)
    project_dir = Path(__file__).resolve().parent.parent
    
    folder = project_dir if args.variant == "baseline" else project_dir / "optimized"
    
    binaries = folder / "bin"
    binaries.mkdir(parents=True, exist_ok=True)
    out = Path(__file__).resolve().parent / args.output
    prior = []
    if out.exists():
        with out.open(newline="") as f:
            prior = list(csv.DictReader(f))

    rows = []
    for op, source_name in PROGRAMS.items():
        source = folder / source_name
        if not source.exists():
            print(f"SKIP {op}: missing {source}")
            continue
        binary = binaries / op
        compile_cmd = ["nvcc", "-O3", str(source), "-o", str(binary)]
        try:
            result = run(compile_cmd, 120)
        except (OSError, subprocess.TimeoutExpired) as e:
            print(f"Compile failed for {op}: {e}")
            continue
        if result.returncode:
            print(f"Compile failed for {op}:\n{result.stderr}")
            continue

        for n in args.sizes:
            cmd = [str(binary), str(n)] if op != "multiply" else [str(binary), str(n), str(n), str(n)]
            times = []
            try:
                # First run warms up the GPU; it isn't included in the median.
                for trial in range(args.repeats + 1):
                    result = run(cmd, args.timeout)
                    if result.returncode:
                        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "nonzero exit")
                    if "Validation: FAIL" in result.stdout:
                        raise RuntimeError("Validation failed")
                    match = re.search(r"Kernel time:\s*([0-9]+(?:\.[0-9]+)?)\s*ms", result.stdout)
                    if not match:
                        raise RuntimeError("No 'Kernel time: ... ms' line; inspect CUDA errors")
                    if trial > 0:
                        times.append(float(match.group(1)))
            except (OSError, subprocess.TimeoutExpired, RuntimeError) as e:
                print(f"SKIP {op} N={n}: {e}")
                continue
            median_ms = statistics.median(times)
            rows.append(dict(variant=args.variant, operation=op, size=n,
                             kernel_ms=f"{median_ms:.6f}", repeats=args.repeats))
            print(f"{args.variant:9s} {op:10s} {n:5d}x{n:<5d} {median_ms:.6f} ms")

    # Replace previous data for this variant and operation/size, if re-run.
    keys = {(r["variant"], r["operation"], str(r["size"])) for r in rows}
    merged = [r for r in prior if (r.get("variant"), r.get("operation"), r.get("size")) not in keys]
    merged.extend(rows)
    with out.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(merged)
    print(f"Saved {len(rows)} results to {out}")


if __name__ == "__main__":
    main()
