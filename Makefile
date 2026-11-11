CC = gcc
CFLAGS = -O2 -Wall -Wextra -std=c11 -Iinclude
LDFLAGS = -lm
SRCS = main.c $(wildcard src/*.c)
.PHONY: all clean run
all: fnn
fnn: $(SRCS) $(wildcard include/*.h)
	$(CC) $(CFLAGS) $(SRCS) -o $@ $(LDFLAGS)
run: fnn
	mkdir -p outputs
	./fnn
clean:
	rm -f fnn *.o src/*.o
