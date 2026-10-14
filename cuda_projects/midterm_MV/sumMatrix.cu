// sumMatrix.cu

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

__global__ void sumMatrix(float *g_idata, float *g_odata, int n) {

    extern __shared__ float sdata[];

    unsigned int th = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + th;

    // 1. Load matrix elements into shared memory
    if (i < n) {
        sdata[th] = g_idata[i];
    } else {
        sdata[th] = 0.0f;
    }

    __syncthreads();

    // 2. Parallel reduction
    for (unsigned int stride = blockDim.x / 2;
         stride > 0;
         stride /= 2) {

        if (th < stride) {
            sdata[th] += sdata[th + stride];
        }

        __syncthreads();
    }

    // 3. Store the partial sum from each block
    if (th == 0) {
        g_odata[blockIdx.x] = sdata[0];
    }
}

int main(int argc, char **argv) {

    // 1. Matrix dimensions
    int N = 1024;

    if (argc > 1) {
        N = atoi(argv[1]);
    }

    if (N <= 0) {
        printf("Invalid matrix size\n");
        return 1;
    }

    size_t n = (size_t)N * N;
    size_t size = n * sizeof(float);

    // 2. CPU Arrays
    float *h_A = (float*)malloc(size);

    for (size_t i = 0; i < n; i++) {
        h_A[i] = 1.0f;
    }

    // 3. GPU Arrays
    float *d_A, *d_partial;

    int threads = 256;
    size_t blocks = (n + threads - 1) / threads;

    float *h_partial = (float*)malloc(blocks * sizeof(float));

    cudaMalloc(&d_A, size);
    cudaMalloc(&d_partial, blocks * sizeof(float));

    // 4. Copy input matrix to GPU
    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);

    // 5. Time kernel execution
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);

    sumMatrix<<<blocks, threads, threads * sizeof(float)>>>(
        d_A, d_partial, n
    );

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms;
    cudaEventElapsedTime(&ms, start, stop);

    printf("Kernel time: %f ms\n", ms);

    // 6. Copy partial sums back to CPU
    cudaMemcpy(h_partial, d_partial,
               blocks * sizeof(float),
               cudaMemcpyDeviceToHost);

    // 7. Sum partial results
    double sumResult = 0.0;

    for (size_t i = 0; i < blocks; i++) {
        sumResult += h_partial[i];
    }

    printf("Matrix size: %d x %d\n", N, N);
    printf("Threads per block: %d\n", threads);
    printf("Number of blocks: %zu\n", blocks);
    printf("Matrix sum: %.6f\n", sumResult);
    printf("Expected sum: %.6f\n", (double)n);

    // 8. Free GPU memory
    cudaFree(d_A);
    cudaFree(d_partial);

    // 9. Free CPU memory
    free(h_A);
    free(h_partial);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return 0;
}
