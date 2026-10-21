// multMatrix.cu

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <cuda_runtime.h>

#define TILE 16

__global__ void multMatrix(const float *A, const float *B, float *C,
                           int M, int K, int N) {

    __shared__ float tileA[TILE][TILE];
    __shared__ float tileB[TILE][TILE];

    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;

    int tx = threadIdx.x;
    int ty = threadIdx.y;

    float sum = 0.0f;

    // Loop through tiles
    for (int t = 0; t < (K + TILE - 1) / TILE; t++) {

        int aCol = t * TILE + tx;
        int bRow = t * TILE + ty;

        // Load A into shared memory
        if (row < M && aCol < K) {
            tileA[ty][tx] = A[row * K + aCol];
        } else {
            tileA[ty][tx] = 0.0f;
        }

        // Load B into shared memory
        if (bRow < K && col < N) {
            tileB[ty][tx] = B[bRow * N + col];
        } else {
            tileB[ty][tx] = 0.0f;
        }

        __syncthreads();

        // Multiply tiles
        #pragma unroll
        for (int k = 0; k < TILE; k++) {
            sum += tileA[ty][k] * tileB[k][tx];
        }

        __syncthreads();
    }

    // Store result
    if (row < M && col < N) {
        C[row * N + col] = sum;
    }
}

int main(int argc, char **argv) {

    // 1. Matrix dimensions
    // A = M x K, B = K x N, C = M x N
    int M = 512;
    int K = 512;
    int N = 512;

    if (argc > 1) M = atoi(argv[1]);
    if (argc > 2) K = atoi(argv[2]);
    if (argc > 3) N = atoi(argv[3]);

    if (M <= 0 || K <= 0 || N <= 0) {
        printf("Invalid matrix dimensions\n");
        return 1;
    }

    size_t nA = (size_t)M * K;
    size_t nB = (size_t)K * N;
    size_t nC = (size_t)M * N;

    size_t sizeA = nA * sizeof(float);
    size_t sizeB = nB * sizeof(float);
    size_t sizeC = nC * sizeof(float);

    // 2. CPU Arrays
    float *h_A = (float*)malloc(sizeA);
    float *h_B = (float*)malloc(sizeB);
    float *h_C = (float*)malloc(sizeC);

    if (!h_A || !h_B || !h_C) {
        printf("CPU memory allocation failed\n");
        return 1;
    }

    // Initialize matrices with varying values
    for (size_t i = 0; i < nA; i++) {
        h_A[i] = ((int)(i % 17) - 8) * 0.125f;
    }

    for (size_t i = 0; i < nB; i++) {
        h_B[i] = ((int)(i % 13) - 6) * 0.125f;
    }

    // 3. GPU Arrays
    float *d_A, *d_B, *d_C;

    cudaMalloc(&d_A, sizeA);
    cudaMalloc(&d_B, sizeB);
    cudaMalloc(&d_C, sizeC);

    // 4. Copy inputs to GPU
    cudaMemcpy(d_A, h_A, sizeA, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, sizeB, cudaMemcpyHostToDevice);

    // 5. Configure CUDA grid and blocks
    dim3 block(TILE, TILE);

    dim3 grid(
        (N + TILE - 1) / TILE,
        (M + TILE - 1) / TILE
    );

    // 6. Time kernel execution
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);

    multMatrix<<<grid, block>>>(d_A, d_B, d_C, M, K, N);

    cudaEventRecord(stop);
    cudaEventSynchronize(stop);

    float ms;
    cudaEventElapsedTime(&ms, start, stop);

    printf("Kernel time: %f ms\n", ms);

    // 7. Copy result back to CPU
    cudaMemcpy(h_C, d_C, sizeC, cudaMemcpyDeviceToHost);

    // 8. Validate result using CPU multiplication
    int errors = 0;
    int samples = 10;

    for (int s = 0; s < samples; s++) {

        int row = (int)((long long)s * (M - 1) / samples);
        int col = (int)((long long)s * (N - 1) / samples);

        float expected = 0.0f;

        for (int k = 0; k < K; k++) {
            expected += h_A[row * K + k] * h_B[k * N + col];
        }

        float actual = h_C[row * N + col];

        if (fabsf(actual - expected) >
            0.001f * fmaxf(1.0f, fabsf(expected))) {
            errors++;
        }
    }

    printf("\nMatrix A: %d x %d\n", M, K);
    printf("Matrix B: %d x %d\n", K, N);
    printf("Matrix C: %d x %d\n", M, N);

    printf("Block dimensions: %d x %d\n", block.x, block.y);
    printf("Grid dimensions: %d x %d\n", grid.x, grid.y);

    printf("C[0] = %f\n", h_C[0]);
    printf("Validation samples: %d\n", samples);

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
