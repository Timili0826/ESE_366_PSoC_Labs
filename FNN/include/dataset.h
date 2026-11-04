#ifndef DATASET_H
#define DATASET_H
#include <stddef.h>
typedef struct {
    float *images; /* sample-major, images[n * pixels + i] */
    unsigned char *labels;
    int count, rows, cols;
} Dataset;
int dataset_load_mnist(Dataset *d,const char *images_path,const char *labels_path);
void dataset_free(Dataset *d);
/* Training indices [0,train_count), validation indices [train_count,count). */
int dataset_split_indices(int count,float train_ratio,unsigned seed,int **indices,int *train_count);
void dataset_shuffle_indices(int *indices,int count,unsigned *rng_state);
#endif
