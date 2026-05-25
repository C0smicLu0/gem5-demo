/*
Copyright (c) 2015-2016 Advanced Micro Devices, Inc. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include "hip/hip_runtime.h"

#include <errno.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <system_error>
#include <thread>
#include <unistd.h>
#include <vector>

#if defined(GEM5_FUSION) || defined(GEM5_FS)
#include <stdint.h>
#include <gem5/m5ops.h>
#endif

#ifdef GEM5_FS
#include <util/m5/src/m5_mmap.h>
#endif

#define CHECK(cmd) \
{\
    hipError_t error  = cmd;\
    if (error != hipSuccess) { \
        fprintf(stderr, "error: '%s'(%d) at %s:%d\n", \
                hipGetErrorString(error), error, __FILE__, __LINE__); \
        exit(EXIT_FAILURE);\
    }\
}

struct SquareOptions
{
    size_t elements = 1000000;
    int cpu_workers = 0;
    int gpu_cus = -1;
    bool cpu_only = false;
    bool gpu_only = false;
    bool debug_log = false;
};

static void
usage(const char *program)
{
    fprintf(stderr,
            "Usage: %s [options]\n"
            "  --cpu-workers N  CPU worker thread count. Default: 0.\n"
            "  --gpu-cus N      GPU CU weight for CPU+GPU range split.\n"
            "  --elements N     Number of input elements. Default: 1000000.\n"
            "  --cpu-only       Unsupported in GPU-only compute mode.\n"
            "  --gpu-only       Run all element work on the GPU.\n"
            "  --debug-log      Print range assignment and completion logs.\n",
            program);
}

static bool
parse_size_value(const char *value, size_t *parsed)
{
    char *end = NULL;
    errno = 0;
    unsigned long long number = strtoull(value, &end, 10);

    if (errno != 0 || end == value || *end != '\0' || number == 0) {
        return false;
    }

    *parsed = static_cast<size_t>(number);
    return static_cast<unsigned long long>(*parsed) == number;
}

static bool
parse_int_value(const char *value, int *parsed)
{
    char *end = NULL;
    errno = 0;
    long number = strtol(value, &end, 10);

    if (errno != 0 || end == value || *end != '\0' ||
        number < 0 || number > INT_MAX) {
        return false;
    }

    *parsed = static_cast<int>(number);
    return true;
}

static void
direct_log(const char *message)
{
    size_t len = strlen(message);
    while (len > 0) {
        ssize_t written = write(STDERR_FILENO, message, len);
        if (written <= 0) {
            return;
        }
        message += written;
        len -= static_cast<size_t>(written);
    }
}

static void
parse_options(int argc, char **argv, SquareOptions *options)
{
    for (int arg = 1; arg < argc; ++arg) {
        if (strcmp(argv[arg], "--cpu-workers") == 0) {
            if (++arg >= argc ||
                !parse_int_value(argv[arg], &options->cpu_workers)) {
                fprintf(stderr, "--cpu-workers requires a non-negative integer\n");
                usage(argv[0]);
                exit(EXIT_FAILURE);
            }
        } else if (strcmp(argv[arg], "--gpu-cus") == 0) {
            if (++arg >= argc ||
                !parse_int_value(argv[arg], &options->gpu_cus) ||
                options->gpu_cus == 0) {
                fprintf(stderr, "--gpu-cus requires a positive integer\n");
                usage(argv[0]);
                exit(EXIT_FAILURE);
            }
        } else if (strcmp(argv[arg], "--elements") == 0) {
            if (++arg >= argc ||
                !parse_size_value(argv[arg], &options->elements)) {
                fprintf(stderr, "--elements requires a positive integer\n");
                usage(argv[0]);
                exit(EXIT_FAILURE);
            }
        } else if (strcmp(argv[arg], "--cpu-only") == 0) {
            options->cpu_only = true;
        } else if (strcmp(argv[arg], "--gpu-only") == 0) {
            options->gpu_only = true;
        } else if (strcmp(argv[arg], "--debug-log") == 0) {
            options->debug_log = true;
        } else if (strcmp(argv[arg], "-h") == 0 ||
                   strcmp(argv[arg], "--help") == 0) {
            usage(argv[0]);
            exit(EXIT_SUCCESS);
        } else {
            fprintf(stderr, "unknown option: %s\n", argv[arg]);
            usage(argv[0]);
            exit(EXIT_FAILURE);
        }
    }

    if (options->cpu_only && options->gpu_only) {
        fprintf(stderr, "--cpu-only and --gpu-only cannot be combined\n");
        exit(EXIT_FAILURE);
    }

    if (options->cpu_only) {
        fprintf(stderr, "--cpu-only is not supported in GPU-only compute mode\n");
        exit(EXIT_FAILURE);
    }

    if (!options->cpu_only && !options->gpu_only &&
        options->cpu_workers > 0 && options->gpu_cus <= 0) {
        fprintf(stderr,
                "CPU+GPU mode requires explicit --gpu-cus N when "
                "--cpu-workers is non-zero\n");
        exit(EXIT_FAILURE);
    }
}

template <typename T>
__global__ void
vector_square(T *C_d, const T *A_d, size_t range_begin, size_t range_end)
{
    size_t offset = range_begin +
        (hipBlockIdx_x * hipBlockDim_x + hipThreadIdx_x);
    size_t stride = hipBlockDim_x * hipGridDim_x;

    for (size_t i = offset; i < range_end; i += stride) {
        C_d[i] = A_d[i] * A_d[i];
    }
}

static void
cpu_shared_load_range(const float *A, size_t elements, int worker_count,
                      volatile float *sink, int worker_id, bool debug_log)
{
    char message[160];
    float local = 0.0f;
    const size_t begin =
        (elements * static_cast<size_t>(worker_id)) / worker_count;
    const size_t end =
        (elements * static_cast<size_t>(worker_id + 1)) / worker_count;

    snprintf(message, sizeof(message),
             "CPU worker %d started shared load [%zu, %zu)\n",
             worker_id, begin, end);
    direct_log(message);

    for (size_t i = begin; i < end; ++i) {
        local += A[i] * 0.000001f;
    }

    sink[worker_id] = local;

    snprintf(message, sizeof(message),
             "CPU worker %d finished shared load [%zu, %zu)\n",
             worker_id, begin, end);
    direct_log(message);
}

int
main(int argc, char *argv[])
{
    SquareOptions options;
    parse_options(argc, argv, &options);

    float *A_h = NULL;
    float *C_h = NULL;
    if (options.elements > SIZE_MAX / sizeof(float)) {
        fprintf(stderr, "--elements is too large\n");
        exit(EXIT_FAILURE);
    }
    size_t Nbytes = options.elements * sizeof(float);

    hipDeviceProp_t props;
    CHECK(hipGetDeviceProperties(&props, 0));
    printf("info: running on device %s\n", props.name);
#ifdef __HIP_PLATFORM_HCC__
    printf("info: architecture on AMD GPU device is: %d\n", props.gcnArch);
#endif
    printf("info: allocate managed mem (%6.2f MB)\n",
           2 * Nbytes / 1024.0 / 1024.0);
    CHECK(hipMallocManaged(reinterpret_cast<void **>(&A_h), Nbytes));
    CHECK(hipMallocManaged(reinterpret_cast<void **>(&C_h), Nbytes));

    for (size_t i = 0; i < options.elements; ++i) {
        A_h[i] = 1.618f + i;
        C_h[i] = 0.0f;
    }

    const unsigned blocks = 512;
    const unsigned threads_per_block = 256;
    const size_t gpu_end = options.cpu_only ? 0 : options.elements;
    const bool run_gpu = gpu_end > 0;
    std::vector<std::thread> cpu_threads;
    cpu_threads.reserve(options.cpu_workers);
    std::vector<float> cpu_sinks(options.cpu_workers, 0.0f);

    if (options.debug_log) {
        fprintf(stdout,
                "Square split: elements=%zu gpu_compute=[0, %zu) "
                "cpu_workers=%d cpu_shared_load=blocked-full-array "
                "roi_order=cpu-then-gpu\n",
                options.elements, gpu_end, options.cpu_workers);
        fflush(stdout);
    }

#if defined(GEM5_FUSION)
    m5_work_begin(0, 0);
#elif defined(GEM5_FS)
    map_m5_mem();
    m5_work_begin_addr(0, 0);
#endif

    for (int worker = 0; worker < options.cpu_workers; ++worker) {
        try {
            cpu_threads.emplace_back(cpu_shared_load_range, A_h,
                                     options.elements, options.cpu_workers,
                                     cpu_sinks.data(), worker,
                                     options.debug_log);
        } catch (const std::system_error &error) {
            char message[192];
            snprintf(message, sizeof(message),
                     "Failed to create CPU worker %d/%d: %s\n",
                     worker, options.cpu_workers, error.what());
            direct_log(message);
            break;
        }
    }

    {
        char message[160];
        snprintf(message, sizeof(message), "Created %zu/%d CPU workers\n",
                 cpu_threads.size(), options.cpu_workers);
        direct_log(message);
    }

    if (options.debug_log) {
        fprintf(stdout, "Before CPU workers join\n");
        fflush(stdout);
    }

    for (std::thread &thread : cpu_threads) {
        thread.join();
    }

    if (options.debug_log) {
        fprintf(stdout, "CPU workers joined\n");
        fflush(stdout);
    }

    if (run_gpu) {
        printf("info: launch 'vector_square' kernel\n");
        hipLaunchKernelGGL(vector_square, dim3(blocks), dim3(threads_per_block),
                           0, 0, C_h, A_h, static_cast<size_t>(0),
                           options.elements);
        CHECK(hipGetLastError());
    }

    if (run_gpu) {
        CHECK(hipDeviceSynchronize());
        if (options.debug_log) {
            fprintf(stdout, "GPU finished [0, %zu)\n", gpu_end);
            fflush(stdout);
        }
    }

#if defined(GEM5_FUSION)
    m5_work_end(0, 0);
#elif defined(GEM5_FS)
    m5_work_end_addr(0, 0);
#endif

    printf("info: check result\n");
    if (!run_gpu) {
        fprintf(stderr, "--cpu-only is not supported in GPU-only square mode\n");
        exit(EXIT_FAILURE);
    }
    for (size_t i = 0; i < options.elements; ++i) {
        if (C_h[i] != A_h[i] * A_h[i]) {
            fprintf(stderr, "result mismatch at element %zu\n", i);
            CHECK(hipErrorUnknown);
        }
    }

    CHECK(hipFree(A_h));
    CHECK(hipFree(C_h));
    printf("PASSED!\n");
    return 0;
}
