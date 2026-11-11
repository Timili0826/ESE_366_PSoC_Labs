
#include "visualization.h"

#include <stdio.h>
#include <math.h>


int save_digit_grid(const char *filename, const float *images,
                    int rows, int cols, const int *indices, int count)
{
    if (!filename || !images || !indices ||
        rows <= 0 || cols <= 0 || count <= 0)
        return -1;

    // Determine the grid dimensions (maximum 10 columns).
    int grid_cols = count < 10 ? count : 10;
    int grid_rows = (count + grid_cols - 1) / grid_cols;

    FILE *f = fopen(filename, "wb");

    if (!f) {
        perror(filename);
        return -1;
    }

    // Write the PGM image header.
    fprintf(f, "P5\n%d %d\n255\n",
            grid_cols * cols, grid_rows * rows);

    // Write each digit's pixels into the image grid.
    for (int gy = 0; gy < grid_rows; gy++) {
        for (int y = 0; y < rows; y++) {
            for (int gx = 0; gx < grid_cols; gx++) {
                for (int x = 0; x < cols; x++) {

                    int slot = gy * grid_cols + gx;
                    unsigned char value = 0;

                    if (slot < count) {

                        float p = images[
                            (size_t)indices[slot] * (size_t)rows * cols +
                            (size_t)y * cols + x
                        ];

                        if (!isfinite(p))
                            p = 0.0f;

                        if (p < 0.0f)
                            p = 0.0f;

                        if (p > 1.0f)
                            p = 1.0f;

                        value = (unsigned char)(p * 255.0f + 0.5f);
                    }

                    if (fwrite(&value, 1, 1, f) != 1) {
                        fclose(f);
                        return -1;
                    }
                }
            }
        }
    }

    return fclose(f) == 0 ? 0 : -1;
}
