NVCC ?= nvcc
CC ?= gcc
ARCH ?= sm_87
CFLAGS = -O2 -Wall -Wextra -std=c11 -I../cpu/include
NVCCFLAGS = -O2 -lineinfo -std=c++14 -arch=$(ARCH) -I../cpu/include -Xcompiler=-Wall,-Wextra
CPU_NAMES = activation dataset layer loss network
CPU_OBJS = $(addprefix build/,$(addsuffix .o,$(CPU_NAMES)))

.PHONY: all clean check
all: fnn_cuda

build:
	mkdir -p build

build/%.o: ../cpu/src/%.c $(wildcard ../cpu/include/*.h) | build
	$(CC) $(CFLAGS) -c $< -o $@

fnn_cuda: fnn_cuda.cu $(CPU_OBJS) $(wildcard ../cpu/include/*.h)
	$(NVCC) $(NVCCFLAGS) fnn_cuda.cu $(CPU_OBJS) -o $@ -lm

check: fnn_cuda
	./fnn_cuda --check

clean:
	rm -rf build fnn_cuda
