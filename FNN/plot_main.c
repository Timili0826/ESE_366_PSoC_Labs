#include <stdio.h>
#include "predictions.h"

int main(void)
{
    if (plot_training_metrics(
            "outputs/metrics.csv",
            "outputs/figures") != 0) {
        fprintf(stderr, "Plot generation failed.\n");
        return 1;
    }

    printf("Plots saved to outputs/figures/\n");
    return 0;
}
