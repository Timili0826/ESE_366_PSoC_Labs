
#include "loss.h"
#include "activation.h"

#include <math.h>
#include <stddef.h>


int argmax(const float *v, int n)
{
    if (!v || n <= 0)
        return -1;

    int k = 0;

    for (int i = 1; i < n; i++) {
        if (v[i] > v[k])
            k = i;
    }

    return k;
}


float cross_entropy_logits(const float *logits, int n, int label, float *grad)
{
    if (!logits || n <= 0 || label < 0 || label >= n)
        return NAN;

    // Find the maximum logit for numerical stability.
    float max = logits[0];

    for (int i = 1; i < n; i++) {
        if (logits[i] > max)
            max = logits[i];
    }

    // Compute the exponential sum.
    float sum = 0.0f;

    for (int i = 0; i < n; i++) {
        sum += expf(logits[i] - max);
    }

    // Cross-entropy loss using log-sum-exp.
    float loss = max + logf(sum) - logits[label];

    // Compute the gradient when requested.
    if (grad) {
        for (int i = 0; i < n; i++) {
            grad[i] = expf(logits[i] - max) / sum - (i == label ? 1.0f : 0.0f);
        }
    }

    return loss;
}
