#include "dataset.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <limits.h>
static uint32_t read_u32be(FILE *f,int *ok){unsigned char b[4];if(fread(b,1,4,f)!=4){*ok=0;return 0;}return ((uint32_t)b[0]<<24)|((uint32_t)b[1]<<16)|((uint32_t)b[2]<<8)|b[3];}
void dataset_free(Dataset *d){if(!d)return;free(d->images);free(d->labels);memset(d,0,sizeof(*d));}
int dataset_load_mnist(Dataset *d,const char *images_path,const char *labels_path){
    if(!d||!images_path||!labels_path)return -1;
    memset(d,0,sizeof(*d));
    FILE *fi=fopen(images_path,"rb");if(!fi){perror(images_path);return -1;}
    FILE *fl=fopen(labels_path,"rb");if(!fl){perror(labels_path);fclose(fi);return -1;}
    int ok=1;
    uint32_t magic_i=read_u32be(fi,&ok), n=read_u32be(fi,&ok), rows=read_u32be(fi,&ok),cols=read_u32be(fi,&ok);
    uint32_t magic_l=read_u32be(fl,&ok), n_labels=read_u32be(fl,&ok);
    if(!ok||magic_i!=2051||magic_l!=2049||n!=n_labels||n==0||n>INT_MAX||rows==0||cols==0||rows>10000||cols>10000){fprintf(stderr,"Invalid MNIST IDX headers\n");goto error;}
    size_t pixels=(size_t)rows*cols;
    if((size_t)n>SIZE_MAX/pixels || (size_t)n*pixels>SIZE_MAX/sizeof(float)){fprintf(stderr,"MNIST size overflow\n");goto error;}
    size_t total=(size_t)n*pixels;
    d->images=malloc(total*sizeof(float));d->labels=malloc((size_t)n);
    if(!d->images||!d->labels)goto error;
    unsigned char *buffer=malloc(pixels);
    if(!buffer)goto error;
    for(uint32_t k=0;k<n;k++){
        if(fread(buffer,1,pixels,fi)!=pixels){free(buffer);goto error;}
        for(size_t j=0;j<pixels;j++)d->images[(size_t)k*pixels+j]=buffer[j]/255.f;
    }
    free(buffer);
    if(fread(d->labels,1,n,fl)!=n)goto error;
    for(uint32_t k=0;k<n;k++)if(d->labels[k]>9){fprintf(stderr,"Invalid MNIST label\n");goto error;}
    d->count=(int)n;d->rows=(int)rows;d->cols=(int)cols;
    fclose(fi);fclose(fl);return 0;
error:
    fprintf(stderr,"Failed to load MNIST files: %s / %s\n",images_path,labels_path);
    fclose(fi);fclose(fl);dataset_free(d);return -1;
}
static unsigned next_rand(unsigned *state){*state=*state*1664525u+1013904223u;return *state;}
void dataset_shuffle_indices(int *idx,int n,unsigned *state){
    if(!idx||!state)return;
    for(int i=n-1;i>0;i--){int j=(int)(next_rand(state)%(unsigned)(i+1));int t=idx[i];idx[i]=idx[j];idx[j]=t;}
}
int dataset_split_indices(int count,float ratio,unsigned seed,int **indices,int *train_count){
    if(count<2||ratio<=0.f||ratio>=1.f||!indices||!train_count)return -1;
    *indices=malloc((size_t)count*sizeof(int));if(!*indices)return -1;
    for(int i=0;i<count;i++)(*indices)[i]=i;
    dataset_shuffle_indices(*indices,count,&seed);
    *train_count=(int)(count*ratio);
    if(*train_count<1)*train_count=1;
    if(*train_count>=count)*train_count=count-1;
    return 0;
}
