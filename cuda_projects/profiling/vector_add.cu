// add_vector.cu

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

__global__ void vecAdd(float *a, float *b, float *c, int n) {
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	if (i < n) {
		c[i] = a[i] + b[i];
	}
}

int main() {
	int n = 1 << 20;		// 1.048,576
	size_t size = n * sizeof(float);

	// 1. CPU Arrays
	float *h_a = (float*)malloc(size);
	float *h_b = (float*)malloc(size);
	float *h_c = (float*)malloc(size);
	for (int i = 0 ; i < n; i++)
		{ h_a[i] = i; h_b[i] = 2*i; }

	// 2. GPU arrays
	float *d_a, *d_b, *d_c;
	cudaMalloc(&d_a, size);
	cudaMalloc(&d_b, size);
	cudaMalloc(&d_c, size);

	// 3. copy inputs across the bridge
	cudaMemcpy (d_a, h_a, size, cudaMemcpyHostToDevice);
	cudaMemcpy (d_b, h_b, size, cudaMemcpyHostToDevice);

	// 4. time the kernal with events (2nd profiling technique)
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	
	cudaEventRecord(start);
	vecAdd<<< (n+255) / 256, 256>>>
			(d_a, d_b, d_c, n);
	cudaEventRecord(stop);
	cudaEventSynchronize(stop);
	
	float ms;
	cudaEventElapsedTime(&ms, start, stop);
	printf("Kernal time: %f ms\n", ms);

	// 5. copy the result back

	cudaMemcpy(h_c, d_c, size, cudaMemcpyDeviceToHost);
	printf("c[100] = %f\n", h_c[100]); // 100 proves round trip happened 100 + 200 = 300

	// 6. free both worlds
	cudaFree(d_a); cudaFree(d_b); cudaFree(d_c);

	free(h_a); free(h_b); free(h_c);

	return 0;
}
