# ESE 366 CUDA matrix operations — matched versions

Each program defaults to **512 x 512** and supports command-line sizes.
Both versions initialize inputs identically for a given operation, use float,
print `Kernel time: ... ms`, and validate results.

| Program | Baseline | Optimized |
|---|---|---|
| sumMatrix.cu | 16x16 block, one addition per thread | 256-thread 1D block, four elements per thread, unrolling |
| traceMatrix.cu | 256-thread shared-memory reduction, one diagonal element per thread | 256-thread shared-memory reduction, four elements per thread, unrolling |
| transposeMatrix.cu | 16x16 block, direct transpose | 32x8 block, padded shared-memory tiles and unrolling |
| multMatrix.cu | 16x16 shared-memory tiled multiplication, unrolling **already enabled** | 16x16 threads, two output rows per thread, reused B tile |

Note: Baseline multiplication is **your provided original tiled implementation**, not a naive global-memory implementation. The optimized version does not guarantee a speedup on every GPU. The original 32x32 optimization that measured much slower was replaced with 16x16 threads computing two output values per thread.

Compile examples (from this folder):

    nvcc -O3 baseline/multMatrix.cu -o baseline/multiply
    nvcc -O3 optimized/multMatrix.cu -o optimized/multiply

Run defaults or sizes:

    ./baseline/multiply
    ./optimized/multiply 512 512 512
    ./baseline/sumMatrix 512 512   # after compiling with -o baseline/sumMatrix

Collect and plot four size points (benchmark script compiles sources itself):

    python3 benchmark_cuda.py --variant baseline --sizes 256 512 1024 4096
    python3 benchmark_cuda.py --variant optimized --sizes 256 512 1024 4096
    python3 plot_cuda.py

The benchmark runs 1 warm-up plus 5 timed process executions for each size, and saves median times. It measures only the GPU kernel event timing, not memory transfers or CPU work. Be cautious about testing large square multiplication: it takes significantly longer than addition/transpose, and the system may run out of RAM. Trace's final partial-sum accumulation happens on the CPU, outside the measured kernel.

Not tested with nvcc in this environment; compile and validate on your Jetson before relying on measurements.
