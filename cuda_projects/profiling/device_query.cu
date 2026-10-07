// device_query.cu

#include <stdio.h>
#include <cuda_runtime.h>

int main()
{
	cudaDeviceProp prop;
	cudaGetDeviceProperties(&prop, 0);

	printf("GPU: %s\n", prop.name);
	printf("SMs: %d\n", prop.multiProcessorCount);
	printf("Warp size: %d\n", prop.warpSize);
	printf("Max thr/block: %d\n", prop.maxThreadsPerBlock);
	printf("Shared/block: %zu KB\n", prop.sharedMemPerBlock/1024);

	size_t free_b, total_b;
	cudaMemGetInfo(&free_b, &total_b);
	printf("Mem: %zu / %zu MB\n",
			free_b>>20, total_b>>20);
	return 0;
}
