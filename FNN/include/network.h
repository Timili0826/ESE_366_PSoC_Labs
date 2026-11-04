#ifndef NETWORK_H
#define NETWORK_H
#include "layer.h"
typedef struct { Layer *layers; int num_layers; } Network;
/* Size count includes input and output widths; final activation must be ACT_LINEAR. */
int network_init(Network *net,const int *sizes,const ActivationType *acts,int size_count);
const float *network_forward(Network *net,const float *input);
void network_zero_grad(Network *net);
/* Accumulates one sample's gradients; returns its cross-entropy loss. */
float network_accumulate(Network *net,const float *input,int label);
/* Call after accumulating batch_size samples. */
void network_step(Network *net,float lr,int batch_size);
int network_predict(Network *net,const float *input);
void network_free(Network *net);
#endif
