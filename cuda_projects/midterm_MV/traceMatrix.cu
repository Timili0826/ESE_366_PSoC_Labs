// traceMatrix.cu

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

__global__ void trace(float *g_idata, float *g_odata, int N) {

    extern __shared__ float sdata[]; // shared memory

    unsigned int th = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + th;

    // 1. Load diagonal elements into shared memory
    if (i < N) {
        sdata[th] = g_idata[i * (N + 1)];
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
    int N = 512;

    if (argc > 1) {
        N = atoi(argv[1]);
    }

    if (N <= 0) {
        printf("Invalid matrix size\n");
        return 1;
    }

    size_t size = (size_t)N * N * sizeof(float);

    // 2. CPU Arrays
    float *h_A = (float*)malloc(size);

    for (size_t i = 0; i < (size_t)N * N; i++) {
        h_A[i] = 1.0f;
    }

    // 3. GPU Arrays
    float *d_A, *d_partial;

    int threads = 256;
    int blocks = (N + threads - 1) / threads;

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

    trace<<<blocks, threads, threads * sizeof(float)>>>(
        d_A, d_partial, N
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

    // 7. Sum the partial results
    float traceResult = 0.0f;

    for (int i = 0; i < blocks; i++) {
        traceResult += h_partial[i];
    }

    printf("Matrix size: %d x %d\n", N, N);
    printf("Threads per block: %d\n", threads);
    printf("Number of blocks: %d\n", blocks);
    printf("Matrix trace: %f\n", traceResult);
    printf("Expected trace: %f\n", (float)N);
    printf("Validation: %s\n", traceResult == (float)N ? "PASS" : "FAIL");

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
