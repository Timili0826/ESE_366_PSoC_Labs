// transposeMatrix.cu

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

#define TILE 32
#define ROWS_PER_BLOCK 8

// Coalesced reads and writes through padded shared memory
__global__ void transposeMatrix(const float *A, float *B, int N) {
    __shared__ float tile[TILE][TILE + 1];

    int x = blockIdx.x * TILE + threadIdx.x;
    int y = blockIdx.y * TILE + threadIdx.y;

    // Each thread transfers four elements
    #pragma unroll
    for (int j = 0; j < TILE; j += ROWS_PER_BLOCK) {
        if (x < N && y + j < N)
            tile[threadIdx.y + j][threadIdx.x] = A[(y + j) * N + x];
    }
    __syncthreads();

    x = blockIdx.y * TILE + threadIdx.x;
    y = blockIdx.x * TILE + threadIdx.y;

    #pragma unroll
    for (int j = 0; j < TILE; j += ROWS_PER_BLOCK) {
        if (x < N && y + j < N)
            B[(y + j) * N + x] = tile[threadIdx.x][threadIdx.y + j];
    }
}

int main(int argc, char **argv) {

    // 1. Matrix dimensions
    int N = 512;

    if (argc > 1) {
        N = atoi(argv[1]);
    }

    if (N <= 0) return 1;

    size_t n = (size_t)N * N;
    size_t size = n * sizeof(float);

    // 2. CPU Arrays
    float *h_A = (float*)malloc(size);
    float *h_B = (float*)malloc(size);

    for (size_t i = 0; i < n; i++) {
        h_A[i] = (float)(i % 1024);
    }

    // 3. GPU Arrays
    float *d_A, *d_B;

    if (cudaMalloc(&d_A, size) != cudaSuccess ||
        cudaMalloc(&d_B, size) != cudaSuccess) {
        printf("GPU memory allocation failed\n");
        return 1;
    }

    // 4. Copy input matrix to GPU
    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);

    // 5. Configure CUDA grid and blocks
    dim3 block(TILE, ROWS_PER_BLOCK);

    dim3 grid(
        (N + TILE - 1) / TILE,
        (N + TILE - 1) / TILE
    );

    // 6. Time kernel execution
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);

    transposeMatrix<<<grid, block>>>(d_A, d_B, N);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms;
    cudaEventElapsedTime(&ms, start, stop);

    printf("Kernel time: %f ms\n", ms);

    // 7. Copy result back to CPU
    cudaMemcpy(h_B, d_B, size, cudaMemcpyDeviceToHost);

    // 8. Validate result
    int errors = 0;

    for (int row = 0; row < N; row++) {
        for (int col = 0; col < N; col++) {

            float expected = h_A[row * N + col];
            float actual = h_B[col * N + row];

            if (actual != expected) {
                errors++;
            }
        }
    }

    printf("Matrix size: %d x %d\n", N, N);
    printf("Block dimensions: %d x %d\n", block.x, block.y);
    printf("Grid dimensions: %d x %d\n", grid.x, grid.y);

    if (N > 2) {
        printf("A[1][2] = %f\n", h_A[N + 2]);
        printf("B[2][1] = %f\n", h_B[2 * N + 1]);
    }

    if (errors == 0) {
        printf("Validation: PASS\n");
    } else {
        printf("Validation: FAIL (%d errors)\n", errors);
    }

    // 9. Free GPU memory
    cudaFree(d_A);
    cudaFree(d_B);

    // 10. Free CPU memory
    free(h_A);
    free(h_B);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return 0;
}
