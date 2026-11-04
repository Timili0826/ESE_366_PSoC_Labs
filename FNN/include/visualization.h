#ifndef VISUALIZATION_H
#define VISUALIZATION_H
/* Save a contact sheet of MNIST examples as portable graymap PGM.
   Accompanying CSV records true/predicted labels. */
int save_digit_grid(const char *filename,const float *images,int rows,int cols,const int *sample_indices,int count);
#endif
