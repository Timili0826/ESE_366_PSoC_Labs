// ESE 366: plain CUDA baseline for the existing C/MNIST FNN.
// CPU reference: Timili0826/ESE_366_PSoC_Labs/FNN, see README.md.
// Each GEMM output has one thread with a serial dot product. No tiling,
// unrolling pragma, cuBLAS, fast-math, or mixed precision in this baseline.
#include <cuda_runtime.h>

extern "C" {
#include "dataset.h"
#include "network.h"
#include "loss.h"
}

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>
#include <sys/stat.h>
#include <cerrno>

static void cuda_check(cudaError_t e, const char* expr, int line) {
    if (e != cudaSuccess)
        throw std::runtime_error(std::string("CUDA line ") + std::to_string(line) +
                                 " (" + expr + "): " + cudaGetErrorString(e));
}
#define CUDA(expr) cuda_check((expr), #expr, __LINE__)
#define LAUNCH_CHECK() CUDA(cudaGetLastError())

template<class T> struct Buffer {
    T* p = nullptr;
    size_t count = 0;
    Buffer() = default;
    explicit Buffer(size_t n) { allocate(n); }
    Buffer(const Buffer&) = delete;
    Buffer& operator=(const Buffer&) = delete;
    Buffer(Buffer&& b) noexcept : p(b.p), count(b.count) { b.p = nullptr; b.count = 0; }
    Buffer& operator=(Buffer&& b) noexcept {
        if (this != &b) {
            if (p) cudaFree(p);
            p = b.p; count = b.count; b.p = nullptr; b.count = 0;
        }
        return *this;
    }
    void allocate(size_t n) {
        if (p || !n || n > std::numeric_limits<size_t>::max() / sizeof(T))
            throw std::runtime_error("Invalid buffer allocation");
        CUDA(cudaMalloc(reinterpret_cast<void**>(&p), n * sizeof(T)));
        count = n;
    }
    ~Buffer() { if (p) cudaFree(p); }
    void upload(const T* x, size_t n) {
        if (n > count) throw std::runtime_error("Buffer upload overflow");
        CUDA(cudaMemcpy(p, x, n * sizeof(T), cudaMemcpyHostToDevice));
    }
    std::vector<T> read(size_t n) const {
        if (n > count) throw std::runtime_error("Buffer read overflow");
        std::vector<T> out(n);
        CUDA(cudaMemcpy(out.data(), p, n * sizeof(T), cudaMemcpyDeviceToHost));
        return out;
    }
};

struct Event {
    cudaEvent_t e = nullptr;
    Event() { CUDA(cudaEventCreate(&e)); }
    ~Event() { if (e) cudaEventDestroy(e); }
    Event(const Event&) = delete;
    Event& operator=(const Event&) = delete;
};

// OPTIMIZATION: this row-major GEMM is the main candidate for shared-memory
// tiling. Adjacent threads compute adjacent output columns. Transpose flags
// change indexing; no separate global-memory transpose buffer is needed.
__global__ void matmul_naive(const float* a, const float* b, float* c,
                             int m, int n, int k, bool transpose_a, bool transpose_b) {
    size_t id = static_cast<size_t>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (id >= static_cast<size_t>(m) * n) return;
    int row = static_cast<int>(id / n), col = static_cast<int>(id % n);
    float sum = 0.0f;
    for (int t = 0; t < k; ++t) {
        float av = transpose_a ? a[static_cast<size_t>(t) * m + row]
                               : a[static_cast<size_t>(row) * k + t];
        float bv = transpose_b ? b[static_cast<size_t>(col) * k + t]
                               : b[static_cast<size_t>(t) * n + col];
        sum += av * bv;
    }
    c[id] = sum;
}

// OPTIMIZATION: later fuse bias/activation with the GEMM epilogue to avoid
// materializing a separate GEMM result. Keep z for the ReLU backward mask.
__global__ void bias_activation(float* z, float* out, const float* bias,
                                int batch, int width, bool relu) {
    size_t id = static_cast<size_t>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (id >= static_cast<size_t>(batch) * width) return;
    float v = z[id] + bias[id % width];
    z[id] = v;
    out[id] = relu ? fmaxf(v, 0.0f) : v;
}

__global__ void activation_backward(const float* z, float* gradient, int count) {
    int id = blockIdx.x * blockDim.x + threadIdx.x;
    if (id < count && z[id] <= 0.0f) gradient[id] = 0.0f;
}

// OPTIMIZATION: one thread per sample is intentionally simple. For many
// classes, investigate parallel max/sum reductions. Standard expf/logf are
// used here; approximate math needs a separate accuracy experiment.
__global__ void loss_gradient(const float* logits, const unsigned char* labels,
                              float* delta, float* losses, int* predictions,
                              int batch, int classes) {
    int row = blockIdx.x * blockDim.x + threadIdx.x;
    if (row >= batch) return;
    const float* z = logits + static_cast<size_t>(row) * classes;
    float maxv = z[0];
    int predicted = 0;
    for (int j = 1; j < classes; ++j) {
        if (z[j] > maxv) { maxv = z[j]; predicted = j; }
    }
    float sum = 0.0f;
    for (int j = 0; j < classes; ++j) sum += expf(z[j] - maxv);
    losses[row] = maxv + logf(sum) - z[labels[row]];
    predictions[row] = predicted;
    for (int j = 0; j < classes; ++j)
        delta[static_cast<size_t>(row) * classes + j] =
            expf(z[j] - maxv) / sum - (j == labels[row] ? 1.0f : 0.0f);
}

// Each parameter-gradient output is overwritten for this batch. We do not
// need atomics or a separate zero-gradient pass for the GEMM outputs.
__global__ void bias_gradient(const float* delta, float* db, int batch, int width) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    if (col >= width) return;
    float sum = 0.0f;
    for (int row = 0; row < batch; ++row) sum += delta[row * width + col];
    db[col] = sum;
}

// OPTIMIZATION: investigate elements/thread and unrolling only after timing.
// Dividing by the actual batch size handles a partial final batch correctly.
__global__ void sgd_update(float* parameter, const float* gradient,
                           size_t count, float learning_rate, float inv_batch) {
    size_t id = static_cast<size_t>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (id < count) parameter[id] -= learning_rate * inv_batch * gradient[id];
}

// Keep all dataset pixels resident. Only shuffled indices are uploaded each
// epoch. Neighboring threads gather neighboring pixels of the same sample.
__global__ void gather_batch(const float* images, const unsigned char* labels,
                             const int* indices, int offset, int batch, int width,
                             float* out, unsigned char* out_labels) {
    size_t id = static_cast<size_t>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (id >= static_cast<size_t>(batch) * width) return;
    int row = static_cast<int>(id / width), col = static_cast<int>(id % width);
    int sample = indices ? indices[offset + row] : offset + row;
    out[id] = images[static_cast<size_t>(sample) * width + col];
    if (col == 0) out_labels[row] = labels[sample];
}

// Monitoring reduction only; no per-batch D2H transfer. A single thread sums
// this small batch in a deterministic order, with double accumulation.
// OPTIMIZATION: consider a parallel reduction if this becomes a bottleneck.
__global__ void accumulate_metrics(const float* losses, const int* predictions,
                                   const unsigned char* labels, double* totals, int batch) {
    if (blockIdx.x || threadIdx.x) return;
    double loss = 0.0, correct = 0.0;
    for (int i = 0; i < batch; ++i) {
        loss += losses[i];
        correct += predictions[i] == labels[i];
    }
    totals[0] += loss;
    totals[1] += correct;
}

static int grid_size(size_t n, int threads) {
    size_t blocks = (n + threads - 1) / threads;
    if (!blocks || blocks > 2147483647u) throw std::runtime_error("Invalid grid size");
    return static_cast<int>(blocks);
}

struct CpuNetwork {
    Network n{};
    CpuNetwork(const std::vector<int>& widths, unsigned seed) {
        std::vector<ActivationType> acts(widths.size() - 1, RELU);
        acts.back() = LINEAR;
        std::srand(seed);
        if (network_init(&n, widths.data(), acts.data(), static_cast<int>(widths.size())))
            throw std::runtime_error("CPU reference initialization failed");
    }
    ~CpuNetwork() { network_free(&n); }
    CpuNetwork(const CpuNetwork&) = delete;
    CpuNetwork& operator=(const CpuNetwork&) = delete;
};

struct GpuLayer {
    int in, out;
    // CPU stores W[out,in]. GPU stores its transpose W[in,out] so that
    // forward GEMM can read adjacent output columns with adjacent threads.
    Buffer<float> w, b, z, output, delta, dw, db;
    GpuLayer(int input, int outputs, int capacity)
        : in(input), out(outputs), w(static_cast<size_t>(input) * outputs), b(outputs),
          z(static_cast<size_t>(capacity) * outputs),
          output(static_cast<size_t>(capacity) * outputs),
          delta(static_cast<size_t>(capacity) * outputs),
          dw(static_cast<size_t>(input) * outputs), db(outputs) {}
};

struct GpuNetwork {
    std::vector<GpuLayer> layers;
    int capacity, threads, input_width, classes;
    Buffer<float> input, losses;
    Buffer<unsigned char> labels;
    Buffer<int> predictions;
    Buffer<double> totals;

    GpuNetwork(const Network& reference, int batch_capacity, int block_threads)
        : capacity(batch_capacity), threads(block_threads),
          input_width(reference.layers[0].input_size),
          classes(reference.layers[reference.num_layers - 1].output_size),
          input(static_cast<size_t>(capacity) * input_width), losses(capacity),
          labels(capacity), predictions(capacity), totals(2) {
        layers.reserve(reference.num_layers);
        for (int l = 0; l < reference.num_layers; ++l) {
            const Layer& cpu = reference.layers[l];
            layers.emplace_back(cpu.input_size, cpu.output_size, capacity);
            auto& g = layers.back();
            std::vector<float> transposed(g.w.count);
            for (int i = 0; i < g.in; ++i)
                for (int j = 0; j < g.out; ++j)
                    transposed[static_cast<size_t>(i) * g.out + j] =
                        cpu.weights[static_cast<size_t>(j) * g.in + i];
            g.w.upload(transposed.data(), transposed.size());
            g.b.upload(cpu.biases, g.out);
        }
    }

    void gemm(const float* a, const float* b, float* c,
              int m, int n, int k, bool ta = false, bool tb = false) {
        matmul_naive<<<grid_size(static_cast<size_t>(m) * n, threads), threads>>>
            (a, b, c, m, n, k, ta, tb);
        LAUNCH_CHECK();
    }
    void forward(int batch) {
        if (batch < 1 || batch > capacity) throw std::runtime_error("Invalid batch");
        const float* a = input.p;
        for (size_t l = 0; l < layers.size(); ++l) {
            auto& g = layers[l];
            gemm(a, g.w.p, g.z.p, batch, g.out, g.in);
            bias_activation<<<grid_size(static_cast<size_t>(batch) * g.out, threads), threads>>>
                (g.z.p, g.output.p, g.b.p, batch, g.out, l + 1 < layers.size());
            LAUNCH_CHECK();
            a = g.output.p;
        }
    }
    void loss(int batch) {
        auto& last = layers.back();
        loss_gradient<<<grid_size(batch, threads), threads>>>
            (last.output.p, labels.p, last.delta.p, losses.p, predictions.p, batch, classes);
        LAUNCH_CHECK();
    }
    void backward(int batch) {
        // All layers use OLD weights. Only after the entire backward pass
        // completes are parameters updated, preserving backprop dependencies.
        for (int l = static_cast<int>(layers.size()) - 1; l >= 0; --l) {
            auto& g = layers[l];
            const float* a = l == 0 ? input.p : layers[l - 1].output.p;
            // dW = A^T * delta. Gradients are sums, not means, until update().
            gemm(a, g.delta.p, g.dw.p, g.in, g.out, batch, true, false);
            bias_gradient<<<grid_size(g.out, threads), threads>>>
                (g.delta.p, g.db.p, batch, g.out);
            LAUNCH_CHECK();
            if (l > 0) {
                auto& prev = layers[l - 1];
                // dA_previous = delta * W^T, then ReLU's derivative.
                gemm(g.delta.p, g.w.p, prev.delta.p, batch, g.in, g.out, false, true);
                int count = batch * g.in;
                activation_backward<<<grid_size(count, threads), threads>>>
                    (prev.z.p, prev.delta.p, count);
                LAUNCH_CHECK();
            }
        }
    }
    void update(int batch, float lr) {
        for (auto& g : layers) {
            sgd_update<<<grid_size(g.w.count, threads), threads>>>
                (g.w.p, g.dw.p, g.w.count, lr, 1.0f / batch);
            LAUNCH_CHECK();
            sgd_update<<<grid_size(g.out, threads), threads>>>
                (g.b.p, g.db.p, g.out, lr, 1.0f / batch);
            LAUNCH_CHECK();
        }
    }
    void reset_metrics() { CUDA(cudaMemset(totals.p, 0, 2 * sizeof(double))); }
    void add_metrics(int batch) {
        accumulate_metrics<<<1, 1>>>(losses.p, predictions.p, labels.p, totals.p, batch);
        LAUNCH_CHECK();
    }
};

struct DeviceDataset {
    Buffer<float> images;
    Buffer<unsigned char> labels;
    explicit DeviceDataset(const Dataset& d)
        : images(static_cast<size_t>(d.count) * d.rows * d.cols), labels(d.count) {
        images.upload(d.images, images.count);
        labels.upload(d.labels, labels.count);
    }
};

static void gather(GpuNetwork& net, const DeviceDataset& d, const int* indices,
                   int offset, int batch) {
    gather_batch<<<grid_size(static_cast<size_t>(batch) * net.input_width, net.threads), net.threads>>>
        (d.images.p, d.labels.p, indices, offset, batch, net.input_width, net.input.p, net.labels.p);
    LAUNCH_CHECK();
}

struct Metrics { double loss, accuracy; };
static Metrics get_metrics(GpuNetwork& net, int count) {
    auto t = net.totals.read(2);
    if (!std::isfinite(t[0])) throw std::runtime_error("Nonfinite loss detected");
    return {t[0] / count, t[1] / count};
}
static Metrics evaluate(GpuNetwork& net, const DeviceDataset& d, const int* indices,
                        int offset, int count) {
    net.reset_metrics();
    for (int pos = 0; pos < count; pos += net.capacity) {
        int batch = std::min(net.capacity, count - pos);
        gather(net, d, indices, offset + pos, batch);
        net.forward(batch);
        net.loss(batch);
        net.add_metrics(batch);
    }
    return get_metrics(net, count);
}

// Uses mixed absolute/relative tolerance per value, not bitwise equality:
// CUDA FMA and summation order can differ from the C reference.
static bool compare(const std::string& name, const std::vector<float>& expected,
                     const std::vector<float>& actual, float atol = 3e-5f,
                     float rtol = 5e-4f) {
    if (expected.size() != actual.size()) throw std::runtime_error("Comparison shape mismatch");
    size_t bad = 0;
    double max_abs = 0.0, worst_scaled = 0.0;
    for (size_t i = 0; i < expected.size(); ++i) {
        double err = std::fabs(static_cast<double>(actual[i]) - expected[i]);
        double tol = atol + rtol * std::fabs(expected[i]);
        if (!std::isfinite(actual[i]) || !std::isfinite(expected[i]) || err > tol) ++bad;
        max_abs = std::max(max_abs, err);
        worst_scaled = std::max(worst_scaled, err / tol);
    }
    std::cout << "  " << name << ": " << (bad ? "FAIL" : "PASS")
              << " max_abs=" << max_abs << " max_error/tolerance=" << worst_scaled
              << " mismatches=" << bad << '/' << expected.size() << '\n';
    return bad == 0;
}

static std::vector<float> cpu_weight_layout(const GpuLayer& g, const Buffer<float>& buffer) {
    auto transposed = buffer.read(buffer.count);
    std::vector<float> out(buffer.count);
    for (int j = 0; j < g.out; ++j)
        for (int i = 0; i < g.in; ++i)
            out[static_cast<size_t>(j) * g.in + i] = transposed[static_cast<size_t>(i) * g.out + j];
    return out;
}

static bool check_case(const std::vector<int>& widths, int capacity, int batch, int threads) {
    CpuNetwork cpu(widths, 39u);
    GpuNetwork gpu(cpu.n, capacity, threads);
    std::vector<float> x(static_cast<size_t>(batch) * widths.front());
    std::vector<unsigned char> y(batch);
    for (size_t i = 0; i < x.size(); ++i) x[i] = static_cast<float>((i * 17u + 13u) % 101u) / 100.0f;
    for (int i = 0; i < batch; ++i) y[i] = static_cast<unsigned char>((i * 7 + 1) % widths.back());
    gpu.input.upload(x.data(), x.size());
    gpu.labels.upload(y.data(), y.size());
    std::cout << "Check widths=";
    for (int w : widths) std::cout << w << ' ';
    std::cout << "capacity=" << capacity << " actual_batch=" << batch << '\n';
    gpu.forward(batch);
    gpu.loss(batch);
    gpu.backward(batch);
    CUDA(cudaDeviceSynchronize());

    std::vector<std::vector<float>> expected_z(cpu.n.num_layers), expected_a(cpu.n.num_layers);
    for (int l = 0; l < cpu.n.num_layers; ++l) {
        expected_z[l].resize(static_cast<size_t>(batch) * widths[l + 1]);
        expected_a[l].resize(expected_z[l].size());
    }
    std::vector<float> loss(batch), delta(static_cast<size_t>(batch) * widths.back());
    network_zero_grad(&cpu.n);
    for (int row = 0; row < batch; ++row) {
        loss[row] = network_accumulate(&cpu.n, x.data() + static_cast<size_t>(row) * widths.front(), y[row]);
        for (int l = 0; l < cpu.n.num_layers; ++l) {
            const Layer& c = cpu.n.layers[l];
            std::copy(c.z, c.z + c.output_size, expected_z[l].begin() + static_cast<size_t>(row) * c.output_size);
            std::copy(c.outputs, c.outputs + c.output_size, expected_a[l].begin() + static_cast<size_t>(row) * c.output_size);
        }
        cross_entropy_logits(cpu.n.layers[cpu.n.num_layers - 1].outputs, widths.back(), y[row],
                             delta.data() + static_cast<size_t>(row) * widths.back());
    }
    bool ok = compare("sample losses", loss, gpu.losses.read(batch));
    ok &= compare("dLoss/dLogits", delta, gpu.layers.back().delta.read(delta.size()));
    for (int l = 0; l < cpu.n.num_layers; ++l) {
        Layer& c = cpu.n.layers[l];
        auto& g = gpu.layers[l];
        std::string tag = "layer " + std::to_string(l);
        ok &= compare(tag + " preactivation", expected_z[l], g.z.read(expected_z[l].size()));
        ok &= compare(tag + " output", expected_a[l], g.output.read(expected_a[l].size()));
        ok &= compare(tag + " dW", std::vector<float>(c.grad_weights, c.grad_weights + g.w.count), cpu_weight_layout(g, g.dw));
        ok &= compare(tag + " db", std::vector<float>(c.grad_biases, c.grad_biases + c.output_size), g.db.read(g.out));
    }
    network_step(&cpu.n, 0.01f, batch);
    gpu.update(batch, 0.01f);
    for (int l = 0; l < cpu.n.num_layers; ++l) {
        Layer& c = cpu.n.layers[l];
        auto& g = gpu.layers[l];
        std::string tag = "layer " + std::to_string(l);
        ok &= compare(tag + " updated W", std::vector<float>(c.weights, c.weights + g.w.count), cpu_weight_layout(g, g.w));
        ok &= compare(tag + " updated b", std::vector<float>(c.biases, c.biases + c.output_size), g.b.read(g.out));
    }
    // A second pass checks that the updated network is also evaluated correctly.
    gpu.forward(batch);
    std::vector<float> expected(static_cast<size_t>(batch) * widths.back());
    for (int row = 0; row < batch; ++row) {
        const float* p = network_forward(&cpu.n, x.data() + static_cast<size_t>(row) * widths.front());
        std::copy(p, p + widths.back(), expected.begin() + static_cast<size_t>(row) * widths.back());
    }
    ok &= compare("post-update logits", expected, gpu.layers.back().output.read(expected.size()));
    return ok;
}

static void make_directory(const std::string& path) {
    if (path.empty()) throw std::runtime_error("Empty output directory");
    for (size_t i = 1; i <= path.size(); ++i) {
        if (i != path.size() && path[i] != '/') continue;
        std::string part = path.substr(0, i);
        if (mkdir(part.c_str(), 0755) && errno != EEXIST)
            throw std::runtime_error("Cannot create directory: " + part);
    }
}

static int positive_int(const char* s, const char* name) {
    char* end = nullptr;
    errno = 0;
    long value = std::strtol(s, &end, 10);
    if (errno || end == s || *end || value < 1 || value > 1000000)
        throw std::runtime_error(std::string("Invalid ") + name);
    return static_cast<int>(value);
}

struct HostData {
    Dataset train{}, test{};
    int* indices = nullptr;
    ~HostData() { dataset_free(&train); dataset_free(&test); std::free(indices); }
};
using Clock = std::chrono::steady_clock;
static double seconds(Clock::time_point t) {
    return std::chrono::duration<double>(Clock::now() - t).count();
}

static int train(int argc, char** argv, const cudaDeviceProp& prop) {
    if (argc > 7) throw std::runtime_error("Too many arguments; run --help");
    std::string data_dir = argc > 1 ? argv[1] : "../data/mnist";
    int epochs = argc > 2 ? positive_int(argv[2], "epochs") : 20;
    char* end = nullptr;
    float lr = argc > 3 ? std::strtof(argv[3], &end) : 0.01f;
    if (!std::isfinite(lr) || lr <= 0.0f || (argc > 3 && (end == argv[3] || *end)))
        throw std::runtime_error("Invalid learning rate");
    int batch = argc > 4 ? positive_int(argv[4], "batch size") : 32;
    std::string out_dir = argc > 5 ? argv[5] : "../outputs/cuda_baseline";
    int threads = argc > 6 ? positive_int(argv[6], "threads/block") : 128;
    if (threads > prop.maxThreadsPerBlock || threads % 32)
        throw std::runtime_error("threads/block must be a multiple of 32 within the device limit");
    constexpr unsigned seed = 39u;
    auto total_start = Clock::now();
    HostData host;
    auto path = [&](const char* name) { return data_dir + "/" + name; };
    if (dataset_load_mnist(&host.train, path("train-images-idx3-ubyte").c_str(), path("train-labels-idx1-ubyte").c_str()) ||
        dataset_load_mnist(&host.test, path("t10k-images-idx3-ubyte").c_str(), path("t10k-labels-idx1-ubyte").c_str()))
        throw std::runtime_error("Dataset loading failed");
    if (host.train.rows != 28 || host.train.cols != 28 || host.test.rows != 28 || host.test.cols != 28)
        throw std::runtime_error("This baseline expects MNIST 28x28 images");
    int ntrain = 0;
    if (dataset_split_indices(host.train.count, 0.8f, seed, &host.indices, &ntrain))
        throw std::runtime_error("Dataset split failed");
    int nval = host.train.count - ntrain;
    if (batch > ntrain) throw std::runtime_error("batch size exceeds training sample count");
    CpuNetwork reference({784, 128, 64, 10}, seed);
    GpuNetwork gpu(reference.n, batch, threads);
    DeviceDataset train_data(host.train), test_data(host.test);
    Buffer<int> indices(host.train.count);
    indices.upload(host.indices, host.train.count);
    make_directory(out_dir);
    // Never overwrite this run's files. Use a different output folder to repeat.
    const std::string metric_path = out_dir + "/metrics.csv";
    if (std::ifstream(metric_path).good())
        throw std::runtime_error("Output metrics already exist; choose a new output directory");
    std::ofstream csv(metric_path);
    std::ofstream info(out_dir + "/run_info.txt");
    if (!csv || !info) throw std::runtime_error("Cannot create output files");
    info << "implementation=plain CUDA FP32\narchitecture=784,128,64,10\nseed=" << seed
         << "\nepochs=" << epochs << "\nlr=" << lr << "\nbatch=" << batch
         << "\nthreads=" << threads << "\ngpu=" << prop.name
         << "\nsource_cpu_commit=62e4aee6af94989494c78b25bf62a49c138df2fc\n";
    csv << "epoch,train_loss,train_accuracy,val_loss,val_accuracy,online_train_loss,train_gpu_ms,eval_wall_s,epoch_wall_s\n";
    std::cout << "Training " << ntrain << ", validation " << nval << ", test " << host.test.count
              << " | 28x28 | architecture 784-128-64-10\n"
              << "FP32; SGD lr=" << lr << "; batch=" << batch << "; seed=" << seed
              << "; threads/block=" << threads << "\n";

    // Warm up forward/backward kernels WITHOUT changing any weights. Inputs
    // are overwritten by the first real batch; every gradient is overwritten.
    gather(gpu, train_data, indices.p, 0, std::min(batch, ntrain));
    gpu.forward(std::min(batch, ntrain));
    gpu.loss(std::min(batch, ntrain));
    gpu.backward(std::min(batch, ntrain));
    CUDA(cudaDeviceSynchronize());
    unsigned state = seed + 1u;
    Event start, stop;
    auto training_start = Clock::now();
    for (int epoch = 1; epoch <= epochs; ++epoch) {
        auto epoch_start = Clock::now();
        dataset_shuffle_indices(host.indices, ntrain, &state);
        indices.upload(host.indices, host.train.count);
        gpu.reset_metrics();
        // This event range includes gather, loss monitoring, forward, backward
        // and update, plus any device-idle gaps while the host submits work.
        // It excludes epoch index upload and all evaluation, not "GEMM only".
        CUDA(cudaEventRecord(start.e));
        for (int offset = 0; offset < ntrain; offset += batch) {
            int actual = std::min(batch, ntrain - offset);
            gather(gpu, train_data, indices.p, offset, actual);
            gpu.forward(actual);
            gpu.loss(actual);
            gpu.add_metrics(actual);
            gpu.backward(actual);
            gpu.update(actual, lr);
        }
        CUDA(cudaEventRecord(stop.e));
        CUDA(cudaEventSynchronize(stop.e));
        float train_ms = 0.0f;
        CUDA(cudaEventElapsedTime(&train_ms, start.e, stop.e));
        Metrics online = get_metrics(gpu, ntrain);
        auto eval_start = Clock::now();
        Metrics tr = evaluate(gpu, train_data, indices.p, 0, ntrain);
        Metrics val = evaluate(gpu, train_data, indices.p, ntrain, nval);
        double eval_s = seconds(eval_start), epoch_s = seconds(epoch_start);
        std::cout << std::fixed << std::setprecision(4)
                  << "Epoch " << epoch << '/' << epochs << " online_train_loss " << online.loss
                  << " train_acc " << std::setprecision(2) << 100 * tr.accuracy << '%'
                  << " val_loss " << std::setprecision(4) << val.loss
                  << " val_acc " << std::setprecision(2) << 100 * val.accuracy << '%'
                  << " train_GPU " << train_ms << "ms eval_wall " << eval_s
                  << "s epoch_wall " << epoch_s << "s\n";
        csv << std::setprecision(10) << epoch << ',' << tr.loss << ',' << tr.accuracy
            << ',' << val.loss << ',' << val.accuracy << ',' << online.loss
            << ',' << train_ms << ',' << eval_s << ',' << epoch_s << '\n';
        csv.flush();
        if (!csv) throw std::runtime_error("Writing metrics failed");
    }
    double train_eval_s = seconds(training_start);
    auto test_start = Clock::now();
    Metrics test = evaluate(gpu, test_data, nullptr, 0, host.test.count);
    double test_s = seconds(test_start);
    std::cout << std::setprecision(4) << "Test loss " << test.loss
              << " | test accuracy " << std::setprecision(2) << 100 * test.accuracy << "%\n";
    info << std::setprecision(12) << "test_loss=" << test.loss << "\ntest_accuracy=" << test.accuracy
         << "\ntrain_and_epoch_evaluation_wall_s=" << train_eval_s
         << "\nfinal_test_wall_s=" << test_s << '\n';
    std::ofstream predictions(out_dir + "/predictions.csv");
    if (!predictions) throw std::runtime_error("Cannot create predictions.csv");
    predictions << "index,true_label,predicted_label,correct\n";
    int count = std::min(100, host.test.count);
    for (int offset = 0; offset < count; offset += batch) {
        int actual = std::min(batch, count - offset);
        gather(gpu, test_data, nullptr, offset, actual);
        gpu.forward(actual);
        gpu.loss(actual);
        auto pred = gpu.predictions.read(actual);
        for (int i = 0; i < actual; ++i) {
            int id = offset + i, label = host.test.labels[id];
            predictions << id << ',' << label << ',' << pred[i] << ',' << (pred[i] == label) << '\n';
        }
    }
    CUDA(cudaDeviceSynchronize());
    double total_s = seconds(total_start);
    info << "total_wall_s_before_cleanup=" << total_s << '\n';
    if (!predictions || !info) throw std::runtime_error("Writing results failed");
    std::cout << "Train + epoch evaluations wall: " << train_eval_s << "s\n"
              << "Final test wall: " << test_s << "s\n"
              << "Total wall before cleanup (includes loading/setup/warm-up/export): " << total_s << "s\n"
              << "Saved results under " << out_dir << '\n'
              << "This baseline does not yet save model weights or resume training.\n";
    return 0;
}

int main(int argc, char** argv) {
    std::cout << std::unitbuf;
    try {
        if (argc == 2 && std::string(argv[1]) == "--help") {
            std::cout << "Usage:\n  ./fnn_cuda --check\n"
                      << "  ./fnn_cuda [data_dir] [epochs] [lr] [batch] [output_dir] [threads]\n"
                      << "Defaults: ../data/mnist 20 0.01 32 ../outputs/cuda_baseline 128\n";
            return 0;
        }
        int device = 0;
        CUDA(cudaGetDevice(&device));
        cudaDeviceProp prop{};
        CUDA(cudaGetDeviceProperties(&prop, device));
        std::cout << "GPU: " << prop.name << " | CC " << prop.major << '.' << prop.minor
                  << " | SMs " << prop.multiProcessorCount << '\n';
        if (argc == 2 && std::string(argv[1]) == "--check") {
            bool ok = true;
            ok &= check_case({7, 5, 4, 3}, 8, 7, 128);
            ok &= check_case({784, 128, 64, 10}, 32, 1, 128);
            ok &= check_case({784, 128, 64, 10}, 32, 7, 128);
            ok &= check_case({784, 128, 64, 10}, 32, 32, 128);
            CUDA(cudaDeviceSynchronize());
            std::cout << "Overall CPU/GPU check: " << (ok ? "PASS" : "FAIL") << '\n';
            return ok ? 0 : 2;
        }
        return train(argc, argv, prop);
    } catch (const std::exception& e) {
        std::cerr << "ERROR: " << e.what() << '\n';
        return 1;
    }
}
