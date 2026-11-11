#ifndef LAYER_H
#define LAYER_H
#include "activation.h"
typedef struct {
    int input_size, output_size;
    ActivationType activation;
    float *weights, *biases;
    float *inputs, *z, *outputs;
    float *grad_weights, *grad_biases;
} Layer;
int layer_init(Layer *layer, int n_in, int n_out, ActivationType activation);
const float *layer_forward(Layer *layer, const float *input);
/* Accumulate parameter gradients; use old weights for grad_input. */
void layer_backward(Layer *layer, const float *grad_output, float *grad_input);
/* Last layer is linear: grad_output is dL/dlogits. */
void layer_zero_grad(Layer *layer);
void layer_step(Layer *layer, float learning_rate, float inv_batch_size);
void layer_free(Layer *layer);
#endif
