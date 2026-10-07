#include <stdio.h>
#include <cuda_runtime.h>

__global__ void hello()
{
	printf("Hello from GPU! Thread %d\n",
			threadIdx.x);
}

int main()
{
	hello<<<1, 5>>>();
	cudaDeviceSynchronize();
	return 0;	
}
