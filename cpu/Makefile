CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=c11 -Iinclude
LDFLAGS = -lm
SRCS = main.c $(wildcard src/*.c)
DATA ?= data/mnist
OUT ?= outputs
.PHONY: all clean run
all: fnn
fnn: $(SRCS) $(wildcard include/*.h)
	$(CC) $(CFLAGS) $(SRCS) -o $@ $(LDFLAGS)
run: fnn
	cd .. && ./cpu/fnn "$(DATA)" 20 0.01 32 "$(OUT)"
clean:
	rm -f fnn fnn.exe *.o src/*.o
