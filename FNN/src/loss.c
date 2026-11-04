#include "loss.h"
#include "activation.h"
#include <math.h>
#include <stddef.h>
int argmax(const float *v,int n){if(!v||n<=0)return -1;int k=0;for(int i=1;i<n;i++)if(v[i]>v[k])k=i;return k;}
float cross_entropy_logits(const float *logits,int n,int label,float *grad){
    if(!logits||n<=0||label<0||label>=n)return NAN;
    float max=logits[0];for(int i=1;i<n;i++)if(logits[i]>max)max=logits[i];
    float sum=0.f;for(int i=0;i<n;i++)sum+=expf(logits[i]-max);
    float loss=max+logf(sum)-logits[label];
    if(grad){for(int i=0;i<n;i++)grad[i]=expf(logits[i]-max)/sum-(i==label?1.f:0.f);}
    return loss;
}
