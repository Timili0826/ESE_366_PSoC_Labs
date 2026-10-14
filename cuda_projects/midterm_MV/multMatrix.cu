// multMatrix.cu

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

__global__ void multMatrix(const float *A, const float *B, float *C, int N) {

    int col = blockIdx.x * blockDim.x + threadIdx.x; // (~tranpose operation)
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    // Each thread computes one element of C
    if (row < N && col < N) { // within matrix size

        float sum = 0.0f;

        for (int k = 0; k < N; k++) {
            sum += A[row * N + k] * B[k * N + col];
        }

        C[row * N + col] = sum;
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

    size_t n = (size_t)N * N;
    size_t size = n * sizeof(float);

    // 2. CPU Arrays
    float *h_A = (float*)malloc(size);
    float *h_B = (float*)malloc(size);
    float *h_C = (float*)malloc(size);

    for (size_t i = 0; i < n; i++) {
        h_A[i] = 1.0f;
        h_B[i] = 2.0f;
    }

    // 3. GPU Arrays
    float *d_A, *d_B, *d_C;

    cudaMalloc(&d_A, size);
    cudaMalloc(&d_B, size);
    cudaMalloc(&d_C, size);

    // 4. Copy inputs to GPU
    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

    // 5. Configure CUDA grid and blocks
    dim3 block(16, 16);

    dim3 grid(
        (N + block.x - 1) / block.x,
        (N + block.y - 1) / block.y
    );

    // 6. Time kernel execution
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);

    multMatrix<<<grid, block>>>(d_A, d_B, d_C, N);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms;
    cudaEventElapsedTime(&ms, start, stop);

    printf("Kernel time: %f ms\n", ms);

    // 7. Copy result back to CPU
    cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);

    // 8. Validate result
    float expected = 2.0f * N;
    int errors = 0;

    for (size_t i = 0; i < n; i++) {
        if (h_C[i] != expected) {
            errors++;
        }
    }

    printf("Matrix size: %d x %d\n", N, N);
    printf("Block dimensions: %d x %d\n", block.x, block.y);
    printf("Grid dimensions: %d x %d\n", grid.x, grid.y);

    printf("C[0] = %f\n", h_C[0]);
    printf("Expected value = %f\n", expected);

    if (errors == 0) {
        printf("Validation: PASS\n");
    } else {
        printf("Validation: FAIL (%d errors)\n", errors);
    }

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
