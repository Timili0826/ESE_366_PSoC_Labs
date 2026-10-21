// sumMatrix.cu - Baseline CUDA matrix addition

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

__global__ void sumMatrix(const float *A, const float *B, float *C,
                          int rows, int cols) {

    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    // Each thread adds one element
    if (row < rows && col < cols) {
        int i = row * cols + col;
        C[i] = A[i] + B[i];
    }
}

int main(int argc, char **argv) {

    // 1. Matrix dimensions
    int rows = 512;
    int cols = 512;

    if (argc > 1) rows = atoi(argv[1]);
    if (argc > 2) cols = atoi(argv[2]);
    else cols = rows;

    if (rows <= 0 || cols <= 0) {
        printf("Invalid matrix dimensions\n");
        return 1;
    }

    size_t n = (size_t)rows * cols;
    size_t size = n * sizeof(float);

    // 2. CPU arrays
    float *h_A = (float*)malloc(size);
    float *h_B = (float*)malloc(size);
    float *h_C = (float*)malloc(size);

    if (!h_A || !h_B || !h_C) {
        printf("CPU memory allocation failed\n");
        return 1;
    }

    for (size_t i = 0; i < n; i++) {
        h_A[i] = (float)(i % 17);
        h_B[i] = (float)(i % 13);
    }

    // 3. GPU arrays
    float *d_A, *d_B, *d_C;
    if (cudaMalloc(&d_A, size) != cudaSuccess ||
        cudaMalloc(&d_B, size) != cudaSuccess ||
        cudaMalloc(&d_C, size) != cudaSuccess) {
        printf("GPU memory allocation failed\n");
        return 1;
    }

    // 4. Copy inputs to GPU
    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

    // 5. Configure CUDA grid and blocks
    dim3 block(16, 16);
    dim3 grid(
        (cols + block.x - 1) / block.x,
        (rows + block.y - 1) / block.y
    );

    // 6. Time kernel execution
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    sumMatrix<<<grid, block>>>(d_A, d_B, d_C, rows, cols);
    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms;
    cudaEventElapsedTime(&ms, start, stop);
    printf("Kernel time: %f ms\n", ms);

    // 7. Copy result back to CPU
    cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);

    // 8. Validate result
    int errors = 0;
    for (size_t i = 0; i < n; i++) {
        float expected = h_A[i] + h_B[i];
        if (h_C[i] != expected) errors++;
    }

    printf("Matrix size: %d x %d\n", rows, cols);
    printf("Block dimensions: %d x %d\n", block.x, block.y);
    printf("Grid dimensions: %d x %d\n", grid.x, grid.y);
    printf("C[0] = %f\n", h_C[0]);
    printf("Expected C[0] = %f\n", h_A[0] + h_B[0]);
    printf("Validation: %s", errors == 0 ? "PASS\n" : "FAIL\n");
    if (errors) printf("Errors: %d\n", errors);

    // 9. Free GPU memory
    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);

    // 10. Free CPU memory
    free(h_A);
    free(h_B);
    free(h_C);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);

    return 0;
}
