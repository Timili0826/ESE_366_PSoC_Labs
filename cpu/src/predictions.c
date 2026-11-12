
#include "predictions.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define MAX_EPOCHS 10000
#define WIDTH 800
#define HEIGHT 500

typedef struct {
    int epoch;
    float train_loss;
    float train_acc;
    float val_loss;
    float val_acc;
} Metric;

static int draw_plot(const char *filename,
                     const Metric *data,
                     int count,
                     int accuracy)
{
    FILE *f = fopen(filename, "w");
    if (!f) return -1;

    const int left = 80;
    const int top = 50;
    const int plot_w = 650;
    const int plot_h = 350;

    float ymin = 0.0f;
    float ymax = accuracy ? 1.0f : 0.0f;

    if (!accuracy) {
        for (int i = 0; i < count; i++) {
            if (data[i].train_loss > ymax)
                ymax = data[i].train_loss;
            if (data[i].val_loss > ymax)
                ymax = data[i].val_loss;
        }
        if (ymax <= 0.0f) ymax = 1.0f;
        ymax *= 1.1f;
    }

    int first_epoch = data[0].epoch;
    int last_epoch = data[count - 1].epoch;
    float dx = (float)(last_epoch - first_epoch);
    if (dx == 0.0f) dx = 1.0f;

    fprintf(f,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" "
        "width=\"%d\" height=\"%d\">\n", WIDTH, HEIGHT);

    fprintf(f, "<rect width=\"100%%\" height=\"100%%\" "
               "fill=\"white\"/>\n");

    fprintf(f,
        "<text x=\"400\" y=\"28\" text-anchor=\"middle\" "
        "font-size=\"20\" font-family=\"Arial\">"
        "%s</text>\n",
        accuracy ? "Training and Validation Accuracy"
                 : "Training and Validation Loss");

    /* Axes */
    fprintf(f,
        "<path d=\"M%d %d V%d H%d\" fill=\"none\" "
        "stroke=\"black\" stroke-width=\"2\"/>\n",
        left, top, top + plot_h, left + plot_w);

    /* Grid and y-axis labels */
    for (int k = 0; k <= 5; k++) {
        float value = ymin + (ymax - ymin) * k / 5.0f;
        float y = top + plot_h - (float)plot_h * k / 5.0f;

        fprintf(f,
            "<line x1=\"%d\" y1=\"%.2f\" "
            "x2=\"%d\" y2=\"%.2f\" "
            "stroke=\"#dddddd\"/>\n",
            left, y, left + plot_w, y);

        fprintf(f,
            "<text x=\"70\" y=\"%.2f\" text-anchor=\"end\" "
            "font-size=\"12\">%.3f</text>\n",
            y + 4, value);
    }

    /* Plot training and validation lines */
    for (int series = 0; series < 2; series++) {
        const char *color = series == 0 ? "#2563eb" : "#dc2626";

        fprintf(f,
            "<polyline fill=\"none\" stroke=\"%s\" "
            "stroke-width=\"2.5\" points=\"", color);

        for (int i = 0; i < count; i++) {
            float value;

            if (accuracy)
                value = series == 0 ? data[i].train_acc
                                    : data[i].val_acc;
            else
                value = series == 0 ? data[i].train_loss
                                    : data[i].val_loss;

            float x = left + plot_w *
                      (data[i].epoch - first_epoch) / dx;

            float y = top + plot_h -
                      plot_h * (value - ymin) / (ymax - ymin);

            fprintf(f, "%.2f,%.2f ", x, y);
        }

        fprintf(f, "\"/>\n");
    }

    /* Axis labels */
    fprintf(f,
        "<text x=\"400\" y=\"455\" text-anchor=\"middle\" "
        "font-size=\"15\">Epoch</text>\n");

    fprintf(f,
        "<text x=\"20\" y=\"230\" text-anchor=\"middle\" "
        "font-size=\"15\" transform=\"rotate(-90 20 230)\">"
        "%s</text>\n",
        accuracy ? "Accuracy" : "Cross-Entropy Loss");

    /* Legend */
    fprintf(f,
        "<line x1=\"290\" y1=\"475\" x2=\"320\" y2=\"475\" "
        "stroke=\"#2563eb\" stroke-width=\"3\"/>\n"
        "<text x=\"325\" y=\"480\" font-size=\"13\">Training</text>\n"
        "<line x1=\"425\" y1=\"475\" x2=\"455\" y2=\"475\" "
        "stroke=\"#dc2626\" stroke-width=\"3\"/>\n"
        "<text x=\"460\" y=\"480\" font-size=\"13\">Validation</text>\n");

    fprintf(f, "</svg>\n");
    fclose(f);
    return 0;
}

int plot_training_metrics(const char *csv_path,
                          const char *output_dir)
{
    FILE *file = fopen(csv_path, "r");

    if (!file) {
        perror("Cannot open metrics CSV");
        return -1;
    }

    Metric *data = malloc(MAX_EPOCHS * sizeof(Metric));

    if (!data) {
        fclose(file);
        return -1;
    }

    char line[512];
    int count = 0;

    /* Skip header */
    if (!fgets(line, sizeof(line), file)) {
        free(data);
        fclose(file);
        return -1;
    }

    while (fgets(line, sizeof(line), file) &&
           count < MAX_EPOCHS) {
        Metric m;

        if (sscanf(line, "%d,%f,%f,%f,%f",
                   &m.epoch,
                   &m.train_loss,
                   &m.train_acc,
                   &m.val_loss,
                   &m.val_acc) == 5) {
            data[count++] = m;
        }
    }

    fclose(file);

    if (count == 0) {
        free(data);
        return -1;
    }

    char path[1024];

    snprintf(path, sizeof(path), "%s/loss.svg", output_dir);
    int loss_status = draw_plot(path, data, count, 0);

    snprintf(path, sizeof(path), "%s/accuracy.svg", output_dir);
    int acc_status = draw_plot(path, data, count, 1);

    free(data);

    return (loss_status == 0 && acc_status == 0) ? 0 : -1;
}
