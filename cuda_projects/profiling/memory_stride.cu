// memory_stride.cu

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>


__global__ void copyStride(float *in, float *out, int n, int stride)
{
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	int j = (long long)i * stride % n;
	if (i<n)
		out[j] = in[j];
}

/*
 stride 1: thread i touches j = 1
    neighbors read neighbors

 stride 32: j jumps by 32 floats
    every thread hits its own memory segment
*/

int main() {
	int n = 1 << 22;
	size_t size = n * sizeof(float);
	float *d_in, *d_out;
	cudaMalloc(&d_in, size);
	cudaMalloc(&d_out, size);

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	// warm-up: first launch pays
	// one-time setup -> never time it!
	copyStride<<<(n+255)/256, 256>>>
				(d_in, d_out, n, 1);

	for(int s = 1; s <= 32; s *= 32)
	{
		cudaEventRecord(start);
		copyStride<<<(n+255)/256, 256>>>
				(d_in, d_out, n, s);
		cudaEventRecord(stop);
		cudaEventSynchronize(stop);
		float ms;
		cudaEventElapsedTime(&ms, start, stop);
		printf("stride %2d: %f ms\n", s, ms);
	}

	return 0;
}
