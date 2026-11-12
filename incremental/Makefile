NVCC ?= nvcc
CC = gcc
CXX = g++
ARCH ?= sm_87
CFLAGS = -O2 -Wall -Wextra -std=c11 -I../cpu/include
NVCCFLAGS = -O2 -lineinfo -std=c++14 -arch=$(ARCH) -I../cpu/include -Xcompiler=-Wall,-Wextra
CPU_NAMES = activation dataset layer loss network
CPU_OBJS = $(addprefix build/,$(addsuffix .o,$(CPU_NAMES)))
.PHONY: all clean host-check
all: fnn_incremental
build:
	mkdir -p build
build/%.o: ../cpu/src/%.c $(wildcard ../cpu/include/*.h) | build
	$(CC) $(CFLAGS) -c $< -o $@
fnn_incremental: fnn_incremental.cu checkpoint.hpp ../cuda_03_register_reuse/fnn_cuda_opt3.cu $(CPU_OBJS)
	$(NVCC) $(NVCCFLAGS) fnn_incremental.cu $(CPU_OBJS) -o $@ -lm
host-check: | build
	$(CXX) -O2 -Wall -Wextra -std=c++14 ../tests/checkpoint_host.cpp -o build/checkpoint_host
	./build/checkpoint_host
clean:
	rm -rf build fnn_incremental fnn_incremental.exe