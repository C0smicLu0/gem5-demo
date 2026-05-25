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
#include <thread>
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
    int cpu_max_percent = 10;
    bool cpu_only = false;
    bool gpu_only = false;
    bool debug_log = false;
};

struct ElementRange
{
    size_t begin;
    size_t end;
};

static void
usage(const char *program)
{
    fprintf(stderr,
            "Usage: %s [options]\n"
            "  --cpu-workers N  CPU worker thread count. Default: 0.\n"
            "  --gpu-cus N      GPU CU weight for CPU+GPU range split.\n"
            "  --elements N     Number of input elements. Default: 1000000.\n"
            "  --cpu-max-percent N\n"
            "                   Maximum total CPU element share. Default: 10.\n"
            "  --cpu-only       Run all element work on CPU workers.\n"
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
        } else if (strcmp(argv[arg], "--cpu-max-percent") == 0) {
            if (++arg >= argc ||
                !parse_int_value(argv[arg], &options->cpu_max_percent) ||
                options->cpu_max_percent <= 0 ||
                options->cpu_max_percent > 100) {
                fprintf(stderr,
                        "--cpu-max-percent requires an integer in [1, 100]\n");
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

    if (options->cpu_only && options->cpu_workers == 0) {
        fprintf(stderr, "--cpu-only requires --cpu-workers N with N > 0\n");
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
cpu_square_range(float *C, const float *A, ElementRange range,
                 int worker_id, bool debug_log)
{
    for (size_t i = range.begin; i < range.end; ++i) {
        C[i] = A[i] * A[i];
    }

    if (debug_log) {
        fprintf(stdout, "CPU worker %d finished [%zu, %zu)\n",
                worker_id, range.begin, range.end);
        fflush(stdout);
    }
}

static std::vector<ElementRange>
split_cpu_ranges(ElementRange range, int worker_count)
{
    std::vector<ElementRange> ranges;
    ranges.reserve(worker_count);

    const size_t range_size = range.end - range.begin;
    for (int worker = 0; worker < worker_count; ++worker) {
        size_t begin = range.begin +
            (range_size * static_cast<size_t>(worker)) / worker_count;
        size_t end = range.begin +
            (range_size * static_cast<size_t>(worker + 1)) / worker_count;

        if (begin < end) {
            ranges.push_back({begin, end});
        }
    }

    return ranges;
}

static size_t
gpu_range_end(const SquareOptions &options)
{
    const unsigned long long cpu_worker_weight = 2;

    if (options.cpu_only) {
        return 0;
    }

    if (options.gpu_only || options.cpu_workers == 0) {
        return options.elements;
    }

    unsigned long long total_weight =
        static_cast<unsigned long long>(options.gpu_cus) +
        static_cast<unsigned long long>(options.cpu_workers) *
        cpu_worker_weight;
    unsigned long long gpu_end =
        (static_cast<unsigned long long>(options.elements) *
         static_cast<unsigned long long>(options.gpu_cus)) / total_weight;

    if (gpu_end == 0) {
        gpu_end = 1;
    }

    size_t split_end = static_cast<size_t>(gpu_end);
    size_t cpu_elements = options.elements - split_end;
    size_t max_cpu_elements =
        (options.elements * static_cast<size_t>(options.cpu_max_percent)) /
        100;
    if (max_cpu_elements == 0) {
        max_cpu_elements = 1;
    }
    if (cpu_elements > max_cpu_elements) {
        split_end = options.elements - max_cpu_elements;
    }

    return split_end;
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
    const size_t gpu_end = gpu_range_end(options);
    const bool run_gpu = gpu_end > 0;
    const ElementRange cpu_range = {gpu_end, options.elements};
    std::vector<ElementRange> cpu_ranges =
        split_cpu_ranges(cpu_range, options.cpu_workers);
    std::vector<std::thread> cpu_threads;
    cpu_threads.reserve(cpu_ranges.size());

    if (options.debug_log) {
        fprintf(stdout,
                "Square split: elements=%zu gpu=[0, %zu) "
                "cpu_workers=%zu cpu=[%zu, %zu) cpu_max_percent=%d\n",
                options.elements, gpu_end, cpu_ranges.size(),
                cpu_range.begin, cpu_range.end, options.cpu_max_percent);
        fflush(stdout);
    }

#if defined(GEM5_FUSION)
    m5_work_begin(0, 0);
#elif defined(GEM5_FS)
    map_m5_mem();
    m5_work_begin_addr(0, 0);
#endif

    for (size_t worker = 0; worker < cpu_ranges.size(); ++worker) {
        cpu_threads.emplace_back(cpu_square_range, C_h, A_h,
                                 cpu_ranges[worker], static_cast<int>(worker),
                                 options.debug_log);
    }

    if (run_gpu) {
        printf("info: launch 'vector_square' kernel\n");
        hipLaunchKernelGGL(vector_square, dim3(blocks), dim3(threads_per_block),
                           0, 0, C_h, A_h, static_cast<size_t>(0), gpu_end);
        CHECK(hipGetLastError());
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
