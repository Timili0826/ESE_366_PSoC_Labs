// traceMatrix.cu

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define ITEMS_PER_THREAD 4

__global__ void trace(const float *A, float *partial, int N) {
    extern __shared__ float sdata[];
    unsigned int th = threadIdx.x;
    int i = (blockIdx.x * blockDim.x + th) * ITEMS_PER_THREAD;
    float sum = 0.0f;

    // Each thread accumulates four diagonal entries
    #pragma unroll
    for (int j = 0; j < ITEMS_PER_THREAD; j++) {
        if (i + j < N) sum += A[(size_t)(i + j) * (N + 1)];
    }
    sdata[th] = sum;
    __syncthreads();

    for (unsigned int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (th < stride) sdata[th] += sdata[th + stride];
        __syncthreads();
    }
    if (th == 0) partial[blockIdx.x] = sdata[0];
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
    int blocks = (N + threads * ITEMS_PER_THREAD - 1) /
                 (threads * ITEMS_PER_THREAD);

    float *h_partial = (float*)malloc(blocks * sizeof(float));

    if (cudaMalloc(&d_A, size) != cudaSuccess ||
        cudaMalloc(&d_partial, blocks * sizeof(float)) != cudaSuccess) {
        printf("GPU memory allocation failed\n");
        return 1;
    }

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
