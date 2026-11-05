#!/usr/bin/env bash
set -e

# Move to the project root directory.
cd "$(dirname "$0")/.."

# Compile the plotting program.
gcc -O2 -Wall -Wextra -std=c11 \
    -Iinclude \
    plot_main.c \
    src/predictions.c \
    -o plot_predictions \
    -lm

# Run the plotting program.
echo "Generating prediction plots..."
./plot_predictions

echo "Plotting complete."
