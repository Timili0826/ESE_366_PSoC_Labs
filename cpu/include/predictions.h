#ifndef PREDICTIONS_H
#define PREDICTIONS_H

/* Generate training and validation plots from metrics.csv */
int plot_training_metrics(const char *csv_path,
                          const char *output_dir);

#endif
