## READ ME ##

# Feedforward Neural Network (FNN)

A modular implementation of a fully connected feedforward neural network written in C from scratch.

The project separates neural network components into individual header (`.h`) and source (`.c`) files to support modularity, maintainability, and future development.

## Project Structure

```text
FNN/
├── include/
│   ├── activation.h
│   ├── layer.h
│   ├── network.h
│   └── dataset.h
├── src/
│   ├── activation.c
│   ├── layer.c
│   ├── network.c
│   └── dataset.c
├── data/
├── experiments/
├── main.c
├── Makefile
└── README.md
```

## Modules

### Activation (`activation.h`, `activation.c`)

Implements nonlinear activation functions and their derivatives.

Responsibilities:
- Sigmoid, ReLU, and tanh activation functions.
- Derivatives required for backpropagation.
- Selection of activation functions for individual layers.

### Layer (`layer.h`, `layer.c`)

Defines and manages an individual fully connected neural network layer.

Responsibilities:
- Initialize and store weight matrices.
- Initialize and store bias vectors.
- Allocate and free memory for layer parameters.
- Maintain intermediate activations and gradients.

### Network (`network.h`, `network.c`)

Defines the overall neural network architecture and manages interactions between layers.

Responsibilities:
- Initialize networks with configurable layer sizes.
- Perform forward propagation through successive layers.
- Calculate gradients using backpropagation.
- Update weights and biases using gradient descent.
- Generate predictions from trained parameters.

### Dataset (`dataset.h`, `dataset.c`)

Manages the data used during training and evaluation.

Responsibilities:
- Store input features and target outputs.
- Load datasets from external files.
- Shuffle training samples.
- Provide training and testing examples.

### Main (`main.c`)

Entry point for configuring, training, and evaluating the neural network.

Responsibilities:
- Define network architecture and activation functions.
- Configure learning rate, epochs, and other hyperparameters.
- Initialize the network and dataset.
- Execute the training loop.
- Monitor training loss and evaluate predictions.
- Release allocated memory.

## Neural Network Mathematics

### Forward Propagation

For layer \(l\), the weighted input is

\[
\mathbf{z}^{(l)} =
\mathbf{W}^{(l)}\mathbf{a}^{(l-1)}
+ \mathbf{b}^{(l)}
\]

The activation is

\[
\mathbf{a}^{(l)} = f(\mathbf{z}^{(l)})
\]

where:
- \(\mathbf{W}^{(l)}\) is the weight matrix.
- \(\mathbf{b}^{(l)}\) is the bias vector.
- \(f\) is the activation function.
- \(\mathbf{a}^{(l-1)}\) is the previous layer's output.

### Backpropagation

The gradients of the loss function are calculated using the chain rule.

For gradient descent, the weights are updated as

\[
\mathbf{W}^{(l)} \leftarrow
\mathbf{W}^{(l)} -
\eta \frac{\partial L}{\partial \mathbf{W}^{(l)}}
\]

where \(\eta\) is the learning rate and \(L\) is the loss function.

## Program Workflow

```text
main.c
   |
   +-- dataset.c
   |      Load and prepare training data
   |
   +-- network.c
   |      Initialize neural network
   |      |
   |      +-- layer.c
   |      |      Allocate weights and biases
   |      |
   |      +-- activation.c
   |             Evaluate activation functions
   |
   +-- Training Loop
   |      |
   |      +-- Forward Propagation
   |      +-- Loss Calculation
   |      +-- Backpropagation
   |      +-- Gradient Descent
   |
   +-- Evaluation
   |
   +-- Memory Cleanup
```

## Compilation

Compile the project using the Makefile:

```bash
make
```

Run the neural network:

```bash
./fnn
```

Remove generated object files and executables:

```bash
make clean
```

## Future Development

Additional modules may be implemented as the project expands:

- `loss.h` / `loss.c`: MSE and cross-entropy loss functions.
- `optimizer.h` / `optimizer.c`: SGD, momentum, and Adam optimizers.
- `matrix.h` / `matrix.c`: Matrix multiplication and linear algebra operations.
- `serialization.h` / `serialization.c`: Save and load trained weights.
- `metrics.h` / `metrics.c`: Accuracy, precision, recall, and other evaluation metrics.

The long-term objective is to develop a configurable neural network framework in C with independently implemented mathematical operations, training algorithms, and model architectures.
