#include "activation.h"
#include <math.h>
float activation_apply(float z, ActivationType type) {
    switch(type) {
        case SIGMOID: return 1.f / (1.f + expf(-z));
        case TANH: return tanhf(z);
        case RELU: return z > 0.f ? z : 0.f;
        case GELU: {
            float u = 0.7978845608f * (z + 0.044715f*z*z*z);
            return 0.5f*z*(1.f+tanhf(u));
        }
        default: return z;
    }
}
float activation_derivative(float z, ActivationType type) {
    switch(type) {
        case SIGMOID: { float s = activation_apply(z,type);return s*(1.f-s); }
        case TANH: { float t = tanhf(z);return 1.f-t*t; }
        case RELU: return z > 0.f ? 1.f : 0.f;
        case GELU: {
            float u = 0.7978845608f*(z+0.044715f*z*z*z);
            float t = tanhf(u);
            float du = 0.7978845608f*(1.f+3.f*0.044715f*z*z);
            return 0.5f*(1.f+t)+0.5f*z*(1.f-t*t)*du;
        }
        default: return 1.f;
    }
}
void softmax(const float *logits, float *p, int n) {
    if (!logits || !p || n<=0) return;
    
    float max = logits[0];
    for(int i=1; i<n; i++) 
        if(logits[i] > max) max = logits[i];
    
    float sum=0.f;
    for(int i=0; i<n; i++){
        p[i] = expf(logits[i] - max);
        sum += p[i];
    }

    for(int i=0; i<n; i++)
        p[i] /= sum;
}
