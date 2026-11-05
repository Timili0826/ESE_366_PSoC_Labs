
#include "layer.h"

#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>


static float uniform01(void)
{
    return ((float)rand() + 0.5f) / ((float)RAND_MAX + 1.0f);
}


// Box-Muller Gaussian sampling.
static float normal_sample(void)
{
    float u = uniform01();
    float v = uniform01();

    return sqrtf(-2.0f * logf(u)) * cosf(6.283185307179586f * v);
}


void layer_free(Layer *l)
{
    if (!l)
        return;

    free(l->weights);
    free(l->biases);
    free(l->inputs);
    free(l->z);
    free(l->outputs);

    free(l->grad_weights);
    free(l->grad_biases);

    memset(l, 0, sizeof(*l));
}


int layer_init(Layer *l, int n_in, int n_out, ActivationType act)
{
    if (!l || n_in <= 0 || n_out <= 0)
        return -1;

    memset(l, 0, sizeof(*l));

    l->input_size  = n_in;
    l->output_size = n_out;
    l->activation  = act;

    size_t nw = (size_t)n_in * (size_t)n_out;

    if (nw > SIZE_MAX / sizeof(float))
        return -1;

    // Allocate weights, biases, and intermediate buffers.
    l->weights      = malloc(nw * sizeof(float));
    l->biases       = calloc((size_t)n_out, sizeof(float));
    l->inputs       = malloc((size_t)n_in * sizeof(float));
    l->z            = malloc((size_t)n_out * sizeof(float));
    l->outputs      = malloc((size_t)n_out * sizeof(float));

    l->grad_weights = calloc(nw, sizeof(float));
    l->grad_biases  = calloc((size_t)n_out, sizeof(float));

    if (!l->weights ||
        !l->biases ||
        !l->inputs ||
        !l->z ||
        !l->outputs ||
        !l->grad_weights ||
        !l->grad_biases) {

        layer_free(l);
        return -1;
    }

    // He initialization for ReLU/GELU, Xavier-style otherwise.
    float scale = sqrtf(
        (act == RELU || act == GELU ? 2.0f : 1.0f) /
        (float)n_in
    );

    for (size_t i = 0; i < nw; i++) {
        l->weights[i] = normal_sample() * scale;
    }

    return 0;
}


const float *layer_forward(Layer *l, const float *x)
{
    if (!l || !x)
        return NULL;

    memcpy(l->inputs, x, (size_t)l->input_size * sizeof(float));

    // Compute weighted sums and apply the activation function.
    for (int j = 0; j < l->output_size; j++) {

        float z = l->biases[j];

        const float *w = l->weights + (size_t)j * l->input_size;

        for (int i = 0; i < l->input_size; i++) {
            z += w[i] * x[i];
        }

        l->z[j]       = z;
        l->outputs[j] = activation_apply(z, l->activation);
    }

    return l->outputs;
}


void layer_backward(Layer *l, const float *grad_output, float *grad_input)
{
    if (!l || !grad_output || !grad_input)
        return;

    for (int i = 0; i < l->input_size; i++) {
        grad_input[i] = 0.0f;
    }

    // Backpropagate gradients through the activation and weights.
    for (int j = 0; j < l->output_size; j++) {

        float dz = grad_output[j] *
                   activation_derivative(l->z[j], l->activation);

        l->grad_biases[j] += dz;

        for (int i = 0; i < l->input_size; i++) {

            size_t idx = (size_t)j * l->input_size + i;

            grad_input[i]        += l->weights[idx] * dz;
            l->grad_weights[idx] += dz * l->inputs[i];
        }
    }
}


void layer_zero_grad(Layer *l)
{
    if (!l)
        return;

    memset(l->grad_weights, 0,
           (size_t)l->input_size * l->output_size * sizeof(float));

    memset(l->grad_biases, 0,
           (size_t)l->output_size * sizeof(float));
}


void layer_step(Layer *l, float lr, float inv_batch)
{
    if (!l)
        return;

    size_t nw = (size_t)l->input_size * l->output_size;

    // Update weights and biases using accumulated gradients.
    for (size_t i = 0; i < nw; i++) {
        l->weights[i] -= lr * inv_batch * l->grad_weights[i];
    }

    for (int j = 0; j < l->output_size; j++) {
        l->biases[j] -= lr * inv_batch * l->grad_biases[j];
    }
}