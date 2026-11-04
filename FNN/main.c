#include "network.h"
#include "dataset.h"
#include "visualization.h"
#include "loss.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <time.h>

/* Change these settings for experiments. */
#define EPOCHS 5
#define LEARNING_RATE 0.01f
#define BATCH_SIZE 32
#define TRAIN_RATIO 0.8f
#define SEED 42u
#define PREDICTION_SAMPLES 40

static void usage(const char *prog){
    fprintf(stderr,"Usage: %s [data/mnist] [epochs] [learning_rate] [batch_size]\n",prog);
}
static void evaluate(Network *net,const Dataset *data,const int *idx,int count,float *loss_out,float *acc_out){
    double loss=0;int correct=0;
    size_t pixels=(size_t)data->rows*data->cols;
    for(int k=0;k<count;k++){
        int id=idx?idx[k]:k;
        const float *logits=network_forward(net,data->images+(size_t)id*pixels);
        loss+=cross_entropy_logits(logits,10,data->labels[id],NULL);
        correct+=argmax(logits,10)==data->labels[id];
    }
    *loss_out=(float)(loss/count);*acc_out=(float)correct/count;
}
int main(int argc,char **argv){
    if(argc>5){usage(argv[0]);return 1;}
    const char *dir=argc>1?argv[1]:"data/mnist";
    int epochs=argc>2?atoi(argv[2]):EPOCHS;
    float lr=argc>3?strtof(argv[3],NULL):LEARNING_RATE;
    int batch_size=argc>4?atoi(argv[4]):BATCH_SIZE;
    if(epochs<=0||!isfinite(lr)||lr<=0.f||batch_size<=0){usage(argv[0]);return 1;}
    char train_img[1024],train_lbl[1024],test_img[1024],test_lbl[1024];
    snprintf(train_img,sizeof train_img,"%s/train-images-idx3-ubyte",dir);
    snprintf(train_lbl,sizeof train_lbl,"%s/train-labels-idx1-ubyte",dir);
    snprintf(test_img,sizeof test_img,"%s/t10k-images-idx3-ubyte",dir);
    snprintf(test_lbl,sizeof test_lbl,"%s/t10k-labels-idx1-ubyte",dir);
    Dataset train={0},test={0};Network net={0};int *indices=NULL;FILE *csv=NULL;int exitcode=1;
    if(dataset_load_mnist(&train,train_img,train_lbl)||dataset_load_mnist(&test,test_img,test_lbl))goto cleanup;
    if(train.rows!=test.rows||train.cols!=test.cols){fprintf(stderr,"Incompatible MNIST image sizes\n");goto cleanup;}
    int ntrain=0;
    if(dataset_split_indices(train.count,TRAIN_RATIO,SEED,&indices,&ntrain))goto cleanup;
    int nval=train.count-ntrain;
    int sizes[]={train.rows*train.cols,128,64,10};
    ActivationType acts[]={ACT_RELU,ACT_RELU,ACT_LINEAR};
    srand(SEED);
    if(network_init(&net,sizes,acts,4)){fprintf(stderr,"Network init failed\n");goto cleanup;}
    csv=fopen("outputs/metrics.csv","w");
    if(!csv){perror("outputs/metrics.csv (create outputs directory)");goto cleanup;}
    fprintf(csv,"epoch,train_loss,train_accuracy,val_loss,val_accuracy\n");
    printf("Training %d, validation %d, test %d | %dx%d\n",ntrain,nval,test.count,train.cols,train.rows);
    unsigned state=SEED+1u;
    size_t pixels=(size_t)train.rows*train.cols;
    for(int epoch=1;epoch<=epochs;epoch++){
        dataset_shuffle_indices(indices,ntrain,&state);
        double train_loss=0;
        clock_t start=clock();
        for(int offset=0;offset<ntrain;offset+=batch_size){
            int actual=batch_size;
            if(offset+actual>ntrain)actual=ntrain-offset;
            network_zero_grad(&net);
            for(int j=0;j<actual;j++){
                int id=indices[offset+j];
                float loss=network_accumulate(&net,train.images+(size_t)id*pixels,train.labels[id]);
                if(!isfinite(loss)){fprintf(stderr,"Nonfinite loss; try lower LR\n");goto cleanup;}
                train_loss+=loss;
            }
            network_step(&net,lr,actual);
        }
        float val_loss,val_acc,train_eval_loss,train_acc;
        evaluate(&net,&train,indices,ntrain,&train_eval_loss,&train_acc);
        evaluate(&net,&train,indices+ntrain,nval,&val_loss,&val_acc);
        double elapsed=(double)(clock()-start)/CLOCKS_PER_SEC;
        printf("Epoch %d/%d train_loss %.4f train_acc %.2f%% val_loss %.4f val_acc %.2f%% CPU %.2fs\n",
               epoch,epochs,train_loss/ntrain,100.f*train_acc,val_loss,100.f*val_acc,elapsed);
        fprintf(csv,"%d,%.6f,%.6f,%.6f,%.6f\n",epoch,train_eval_loss,train_acc,val_loss,val_acc);
        fflush(csv);
    }
    {float loss,acc;evaluate(&net,&test,NULL,test.count,&loss,&acc);
     printf("Test loss %.4f | test accuracy %.2f%%\n",loss,100.f*acc);}
    {
        int count=test.count<PREDICTION_SAMPLES?test.count:PREDICTION_SAMPLES;
        int *sample_ids=malloc((size_t)count*sizeof(int));
        if(!sample_ids)goto cleanup;
        FILE *f=fopen("outputs/predictions.csv","w");
        if(!f){perror("outputs/predictions.csv");free(sample_ids);goto cleanup;}
        fprintf(f,"index,true_label,predicted_label,correct\n");
        for(int i=0;i<count;i++){
            sample_ids[i]=i;
            int pred=network_predict(&net,test.images+(size_t)i*pixels);
            fprintf(f,"%d,%d,%d,%d\n",i,test.labels[i],pred,pred==test.labels[i]);
        }
        fclose(f);
        if(save_digit_grid("outputs/test_digits.pgm",test.images,test.rows,test.cols,sample_ids,count)){
            fprintf(stderr,"Failed to save digit contact sheet\n");free(sample_ids);goto cleanup;
        }
        free(sample_ids);
    }
    puts("Saved outputs/metrics.csv, outputs/predictions.csv, outputs/test_digits.pgm");
    exitcode=0;
cleanup:
    if(csv)fclose(csv);
    free(indices);network_free(&net);dataset_free(&train);dataset_free(&test);
    return exitcode;
}
