#ifndef ACTIVATION_H
#define ACTIVATION_H

typedef enum { ACT_LINEAR, ACT_SIGMOID, ACT_TANH, ACT_RELU, ACT_GELU } ActivationType;
float activation_apply(float z, ActivationType type);
float activation_derivative(float z, ActivationType type);
void softmax(const float *logits, float *probabilities, int n);
#endif
