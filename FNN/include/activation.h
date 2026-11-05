#ifndef ACTIVATION_H
#define ACTIVATION_H

typedef enum { LINEAR, SIGMOID, TANH, RELU, GELU } ActivationType;

float activation_apply(float z, ActivationType type);

float activation_derivative(float z, ActivationType type);

void softmax(const float *logits, float *probabilities, int n);

#endif
