#include "network.h"
#include "loss.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
void network_free(Network *n){if(!n)return;for(int i=0;i<n->num_layers;i++)layer_free(&n->layers[i]);free(n->layers);memset(n,0,sizeof(*n));}
int network_init(Network *n,const int *sizes,const ActivationType *acts,int count){
    if(!n||!sizes||!acts||count<2||acts[count-2]!=ACT_LINEAR)return -1;
    memset(n,0,sizeof(*n));
    for(int i=0;i<count;i++)if(sizes[i]<=0)return -1;
    n->num_layers=count-1;n->layers=calloc((size_t)n->num_layers,sizeof(Layer));
    if(!n->layers){n->num_layers=0;return -1;}
    for(int i=0;i<n->num_layers;i++)if(layer_init(&n->layers[i],sizes[i],sizes[i+1],acts[i])!=0){network_free(n);return -1;}
    return 0;
}
const float *network_forward(Network *n,const float *x){
    if(!n||!n->layers||!x)return NULL;
    for(int i=0;i<n->num_layers;i++){x=layer_forward(&n->layers[i],x);if(!x)return NULL;}
    return x;
}
void network_zero_grad(Network *n){if(!n)return;for(int i=0;i<n->num_layers;i++)layer_zero_grad(&n->layers[i]);}
float network_accumulate(Network *n,const float *x,int label){
    const float *logits=network_forward(n,x);
    if(!logits)return NAN;
    int last=n->num_layers-1;
    int maxw=n->layers[0].input_size;
    for(int i=0;i<n->num_layers;i++)if(n->layers[i].output_size>maxw)maxw=n->layers[i].output_size;
    float *a=malloc((size_t)maxw*sizeof(float)),*b=malloc((size_t)maxw*sizeof(float));
    if(!a||!b){free(a);free(b);return NAN;}
    float loss=cross_entropy_logits(logits,n->layers[last].output_size,label,a);
    if(isfinite(loss)){
        for(int i=last;i>=0;i--){layer_backward(&n->layers[i],a,b);float *tmp=a;a=b;b=tmp;}
    }
    free(a);free(b);return loss;
}
void network_step(Network *n,float lr,int batch){
    if(!n||batch<=0)return;
    for(int i=0;i<n->num_layers;i++)layer_step(&n->layers[i],lr,1.f/(float)batch);
}
int network_predict(Network *n,const float *x){
    const float *logits=network_forward(n,x);
    return logits?argmax(logits,n->layers[n->num_layers-1].output_size):-1;
}
