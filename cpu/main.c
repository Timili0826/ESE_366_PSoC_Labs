#ifndef _WIN32
#define _POSIX_C_SOURCE 200809L
#endif

#include "network.h"
#include "dataset.h"
#include "visualization.h"
#include "loss.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <time.h>
#include <errno.h>
#include <sys/stat.h>
#include <fcntl.h>
#ifdef _WIN32
#include <windows.h>
#include <direct.h>
#include <io.h>
#endif

static FILE *exclusive_output(const char *path)
{
#ifdef _WIN32
    int fd = _open(path, _O_CREAT | _O_EXCL | _O_WRONLY | _O_BINARY, _S_IREAD | _S_IWRITE);
    if (fd < 0) return NULL;
    FILE *f = _fdopen(fd, "wb");
    if (!f) _close(fd);
    return f;
#else
    return fopen(path, "wx");
#endif
}

static double monotonic_s(void)
{
#ifdef _WIN32
    LARGE_INTEGER ticks, frequency;
    if (!QueryPerformanceFrequency(&frequency) || !QueryPerformanceCounter(&ticks)) abort();
    return (double)ticks.QuadPart / frequency.QuadPart;
#else
    struct timespec t;
    if (clock_gettime(CLOCK_MONOTONIC, &t)) { perror("clock_gettime"); exit(1); }
    return t.tv_sec + t.tv_nsec * 1e-9;
#endif
}

static int make_output_dir(const char *path)
{
    char buf[4096];
    if (!*path || strlen(path) >= sizeof buf) return -1;
    strcpy(buf, path);
#ifdef _WIN32
    for (char *q = buf; *q; ++q) if (*q == '\\') *q = '/';
#endif
    for (char *p = buf + 1; ; ++p) {
        if (*p && *p != '/') continue;
#ifdef _WIN32
        if (p == buf + 2 && buf[1] == ':') continue;
#endif
        char saved = *p; *p = 0;
#ifdef _WIN32
        int result = _mkdir(buf);
#else
        int result = mkdir(buf, 0755);
#endif
        if (result && errno != EEXIST) return -1;
        *p = saved; if (!saved) break;
    }
    return 0;
}

static int output_path(char *buf, size_t n, const char *dir, const char *name)
{
    int len = snprintf(buf, n, "%s/%s", dir, name);
    return len < 0 || (size_t)len >= n ? -1 : 0;
}


// Training parameters.
#define EPOCHS 20
#define LEARNING_RATE 0.01f
#define BATCH_SIZE 32
#define TRAIN_RATIO 0.8f
#define SEED 39u
#define PREDICTION_SAMPLES 100


static void usage(const char *prog)
{
    fprintf(stderr,
            "Usage: %s [data/mnist] [epochs] [learning_rate] [batch_size] [output_directory]\n",
            prog);
}


static void evaluate(Network *net, const Dataset *data,
                     const int *idx, int count,
                     float *loss_out, float *acc_out)
{
    double loss = 0;
    int correct = 0;

    size_t pixels = (size_t)data->rows * data->cols;

    for (int k = 0; k < count; k++) {

        int id = idx ? idx[k] : k;

        const float *logits = network_forward(
            net, data->images + (size_t)id * pixels
        );

        loss += cross_entropy_logits(
            logits, 10, data->labels[id], NULL
        );

        correct += argmax(logits, 10) == data->labels[id];
    }

    *loss_out = (float)(loss / count);
    *acc_out = (float)correct / count;
}


int main(int argc, char **argv)
{
    if (argc > 6) {
        usage(argv[0]);
        return 1;
    }

    // Read command-line arguments or use default parameters.
    const char *dir = argc > 1 ? argv[1] : "data/mnist";
    int epochs = argc > 2 ? atoi(argv[2]) : EPOCHS;
    float lr = argc > 3 ? strtof(argv[3], NULL) : LEARNING_RATE;
    int batch_size = argc > 4 ? atoi(argv[4]) : BATCH_SIZE;
    const char *out_dir = argc > 5 ? argv[5] : "outputs";
    char metrics_path[4096], predictions_path[4096], digits_path[4096], info_path[4096];
    if (output_path(metrics_path, sizeof metrics_path, out_dir, "metrics.csv") ||
        output_path(predictions_path, sizeof predictions_path, out_dir, "predictions.csv") ||
        output_path(digits_path, sizeof digits_path, out_dir, "test_digits.pgm") ||
        output_path(info_path, sizeof info_path, out_dir, "run_info.txt")) return 1;

    if (epochs <= 0 || !isfinite(lr) || lr <= 0.0f || batch_size <= 0) {
        usage(argv[0]);
        return 1;
    }

    char train_img[1024];
    char train_lbl[1024];
    char test_img[1024];
    char test_lbl[1024];

    snprintf(train_img, sizeof train_img,
             "%s/train-images-idx3-ubyte", dir);

    snprintf(train_lbl, sizeof train_lbl,
             "%s/train-labels-idx1-ubyte", dir);

    snprintf(test_img, sizeof test_img,
             "%s/t10k-images-idx3-ubyte", dir);

    snprintf(test_lbl, sizeof test_lbl,
             "%s/t10k-labels-idx1-ubyte", dir);

    Dataset train = {0};
    Dataset test = {0};
    Network net = {0};

    int *indices = NULL;
    FILE *csv = NULL;
    int exitcode = 1;

    // Load the MNIST training and test datasets.
    if (dataset_load_mnist(&train, train_img, train_lbl) ||
        dataset_load_mnist(&test, test_img, test_lbl))
        goto cleanup;

    if (train.rows != test.rows || train.cols != test.cols) {
        fprintf(stderr, "Incompatible MNIST image sizes\n");
        goto cleanup;
    }

    // Split the training dataset into training and validation sets.
    int ntrain = 0;

    if (dataset_split_indices(train.count, TRAIN_RATIO,
                              SEED, &indices, &ntrain))
        goto cleanup;

    int nval = train.count - ntrain;

    // Define the fully connected network architecture.
    int sizes[] = {
        train.rows * train.cols,
        128,
        64,
        10
    };

    ActivationType acts[] = {
        RELU,
        RELU,
        LINEAR
    };

    srand(SEED);

    if (network_init(&net, sizes, acts, 4)) {
        fprintf(stderr, "Network init failed\n");
        goto cleanup;
    }

    if (make_output_dir(out_dir)) { perror(out_dir); goto cleanup; }
    const char *paths[] = {metrics_path, predictions_path, digits_path, info_path};
    for (size_t i = 0; i < sizeof paths / sizeof paths[0]; ++i) {
        struct stat st;
        if (!stat(paths[i], &st)) { fprintf(stderr, "Refusing to overwrite %s\n", paths[i]); goto cleanup; }
    }
    FILE *info = exclusive_output(info_path);
    if (!info) { perror(info_path); goto cleanup; }
    fprintf(info, "implementation=CPU FP32\narchitecture=784,128,64,10\nseed=39\nepochs=%d\nlr=%.9g\nbatch=%d\ntrain_count=%d\nval_count=%d\ntest_count=%d\ntiming=monotonic_shuffle_train_trainval_evaluation\nprofiler=none\n", epochs, (double)lr, batch_size, ntrain, nval, test.count);
    if (fclose(info)) goto cleanup;
    csv = exclusive_output(metrics_path);

    if (!csv) {
        perror(metrics_path);
        goto cleanup;
    }

    fprintf(csv, "epoch,train_loss,train_accuracy,val_loss,val_accuracy,cpu_process_s,epoch_wall_s\n");

    printf("Training %d, validation %d, test %d | %dx%d\n",
           ntrain, nval, test.count, train.cols, train.rows);

    unsigned state = SEED + 1u;
    size_t pixels = (size_t)train.rows * train.cols;

    // Train the network using mini-batch gradient descent.
    for (int epoch = 1; epoch <= epochs; epoch++) {

        double wall_start = monotonic_s();
        dataset_shuffle_indices(indices, ntrain, &state);

        double train_loss = 0;
        clock_t start = clock();

        for (int offset = 0; offset < ntrain; offset += batch_size) {

            int actual = batch_size;

            if (offset + actual > ntrain)
                actual = ntrain - offset;

            network_zero_grad(&net);

            for (int j = 0; j < actual; j++) {

                int id = indices[offset + j];

                float loss = network_accumulate(
                    &net,
                    train.images + (size_t)id * pixels,
                    train.labels[id]
                );

                if (!isfinite(loss)) {
                    fprintf(stderr, "Nonfinite loss; try lower LR\n");
                    goto cleanup;
                }

                train_loss += loss;
            }

            network_step(&net, lr, actual);
        }

        // Evaluate training and validation performance.
        float val_loss;
        float val_acc;
        float train_eval_loss;
        float train_acc;

        evaluate(&net, &train, indices, ntrain,
                 &train_eval_loss, &train_acc);

        evaluate(&net, &train, indices + ntrain, nval,
                 &val_loss, &val_acc);

        double elapsed = (double)(clock() - start) / CLOCKS_PER_SEC;
        double epoch_wall_s = monotonic_s() - wall_start;

        printf("Epoch %d/%d train_loss %.4f train_acc %.2f%% "
               "val_loss %.4f val_acc %.2f%% CPU %.2fs\n",
               epoch, epochs, train_loss / ntrain,
               100.0f * train_acc, val_loss,
               100.0f * val_acc, elapsed);

        fprintf(csv, "%d,%.6f,%.6f,%.6f,%.6f,%.9f,%.9f\n",
                epoch, train_eval_loss, train_acc, val_loss, val_acc, elapsed, epoch_wall_s);
        printf("epoch_wall %.9fs\n", epoch_wall_s);

        fflush(csv);
    }

    // Evaluate the trained network on the test dataset.
    {
        float loss, acc;

        evaluate(&net, &test, NULL, test.count, &loss, &acc);

        printf("Test loss %.4f | test accuracy %.2f%%\n",
               loss, 100.0f * acc);
    }

    // Save predictions and a grid of test digits.
    {
        int count = test.count < PREDICTION_SAMPLES
                    ? test.count : PREDICTION_SAMPLES;

        int *sample_ids = malloc((size_t)count * sizeof(int));

        if (!sample_ids)
            goto cleanup;

        FILE *f = exclusive_output(predictions_path);

        if (!f) {
            perror(predictions_path);
            free(sample_ids);
            goto cleanup;
        }

        fprintf(f, "index,true_label,predicted_label,correct\n");

        for (int i = 0; i < count; i++) {

            sample_ids[i] = i;

            int pred = network_predict(
                &net, test.images + (size_t)i * pixels
            );

            fprintf(f, "%d,%d,%d,%d\n",
                    i, test.labels[i], pred,
                    pred == test.labels[i]);
        }

        fclose(f);

        if (save_digit_grid(
                digits_path,
                test.images,
                test.rows,
                test.cols,
                sample_ids,
                count)) {

            fprintf(stderr, "Failed to save digit contact sheet\n");
            free(sample_ids);
            goto cleanup;
        }

        free(sample_ids);
    }

    printf("Saved results under %s\n", out_dir);

    exitcode = 0;

cleanup:
    if (csv)
        fclose(csv);

    free(indices);
    network_free(&net);
    dataset_free(&train);
    dataset_free(&test);

    return exitcode;
}
