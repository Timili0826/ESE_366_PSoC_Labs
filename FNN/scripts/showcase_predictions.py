import csv
import os
from PIL import Image
import matplotlib.pyplot as plt

# -----------------------------
# Configuration
# -----------------------------
PRED_CSV = "outputs/predictions.csv"
GRID_IMG = "outputs/test_digits.png"
OUT_DIR = "outputs/figures"

OUT_PNG = os.path.join(OUT_DIR, "classification_showcase_paper.png")
OUT_PDF = os.path.join(OUT_DIR, "classification_showcase_paper.pdf")
OUT_SVG = os.path.join(OUT_DIR, "classification_showcase_paper.svg")

DIGIT_W = 28
DIGIT_H = 28
GRID_COLS = 10
NUM_EXAMPLES = 3


# -----------------------------
# Load prediction table
# -----------------------------
rows = []
with open(PRED_CSV, "r", newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        row["index"] = int(row["index"])
        row["true_label"] = int(row["true_label"])
        row["predicted_label"] = int(row["predicted_label"])
        row["correct"] = int(row["correct"])
        rows.append(row)

if not rows:
    raise RuntimeError("No rows found in outputs/predictions.csv")

correct_rows = [r for r in rows if r["correct"] == 1]
wrong_rows = [r for r in rows if r["correct"] == 0]

sample_acc = sum(r["correct"] for r in rows) / len(rows)


# -----------------------------
# Select examples
# Prefer distinct true labels
# -----------------------------
def select_distinct_examples(candidates, n):
    selected = []
    seen_labels = set()

    for r in candidates:
        if r["true_label"] not in seen_labels:
            selected.append(r)
            seen_labels.add(r["true_label"])
        if len(selected) == n:
            return selected

    for r in candidates:
        if r not in selected:
            selected.append(r)
        if len(selected) == n:
            return selected

    return selected


# For current case, likely all examples are correct.
selected = select_distinct_examples(correct_rows, NUM_EXAMPLES)

if len(selected) < NUM_EXAMPLES:
    extra = select_distinct_examples(rows, NUM_EXAMPLES - len(selected))
    for r in extra:
        if r not in selected:
            selected.append(r)

selected = selected[:NUM_EXAMPLES]

if len(selected) == 0:
    raise RuntimeError("Could not select any examples for plotting.")


# -----------------------------
# Load digit grid image
# -----------------------------
img = Image.open(GRID_IMG).convert("L")


def crop_digit(index):
    gx = index % GRID_COLS
    gy = index // GRID_COLS

    left = gx * DIGIT_W
    upper = gy * DIGIT_H
    right = left + DIGIT_W
    lower = upper + DIGIT_H

    return img.crop((left, upper, right, lower))


# -----------------------------
# Plot figure
# -----------------------------
plt.rcParams.update({
    "font.family": "serif",
    "font.size": 10,
    "axes.titlesize": 10,
    "figure.titlesize": 11
})

fig, axes = plt.subplots(1, len(selected), figsize=(6.4, 2.4), dpi=300)

if len(selected) == 1:
    axes = [axes]

panel_labels = ["(a)", "(b)", "(c)", "(d)", "(e)", "(f)"]

for ax, item, panel in zip(axes, selected, panel_labels):
    digit = crop_digit(item["index"])

    ax.imshow(digit, cmap="gray", vmin=0, vmax=255)
    ax.set_xticks([])
    ax.set_yticks([])

    # Thin border for a paper-style panel
    for spine in ax.spines.values():
        spine.set_linewidth(0.8)
        spine.set_color("black")

    ax.set_title(panel, loc="left", pad=2)

    true_label = item["true_label"]
    pred_label = item["predicted_label"]
    is_correct = item["correct"] == 1

    status = "Correct" if is_correct else "Incorrect"

    label_text = (
        f"True: {true_label}\n"
        f"Predicted: {pred_label}\n"
        f"{status}"
    )

    ax.text(
        0.5, -0.18, label_text,
        transform=ax.transAxes,
        ha="center", va="top",
        fontsize=9
    )

fig.suptitle(
    "Representative MNIST classification examples",
    y=0.98
)

fig.text(
    0.5, 0.02,
    f"Sample shown: {len(rows)} test digits | "
    f"Sample accuracy: {100.0 * sample_acc:.1f}%",
    ha="center",
    fontsize=9
)

plt.subplots_adjust(top=0.80, bottom=0.35, wspace=0.45)

os.makedirs(OUT_DIR, exist_ok=True)
# fig.savefig(OUT_PNG, bbox_inches="tight")
# fig.savefig(OUT_PDF, bbox_inches="tight")
fig.savefig(OUT_SVG, bbox_inches="tight")
plt.close(fig)

print(f"Saved {OUT_PNG}")
print(f"Saved {OUT_PDF}")
print(f"Saved {OUT_SVG}")
