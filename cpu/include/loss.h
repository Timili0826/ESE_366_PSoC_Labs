#ifndef LOSS_H
#define LOSS_H
/* Categorical cross entropy from raw logits (numerically stable). */
float cross_entropy_logits(const float *logits,int n_classes,int label,float *grad_logits);
int argmax(const float *values,int n);
#endif
