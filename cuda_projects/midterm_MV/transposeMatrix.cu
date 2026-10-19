// transposeMatrix.cu

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

__global__ void transposeMatrix(const float *A, float *B, int N) {

    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    // Each thread transposes one element
    if (row < N && col < N) {
        B[col * N + row] = A[row * N + col];
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

    for (size_t i = 0; i < n; i++) {
        h_A[i] = (float)(i % 1024);
    }

    // 3. GPU Arrays
    float *d_A, *d_B;

    cudaMalloc(&d_A, size);
    cudaMalloc(&d_B, size);

    // 4. Copy input matrix to GPU
    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);

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
