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

#include <algorithm>
#include <atomic>
#include <errno.h>
#include <limits.h>
#include <pthread.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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
    int cpu_stack_kb = 64;
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
            "  --cpu-stack-kb N Per-worker pthread stack size in KiB. "
            "Default: 64.\n"
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
        } else if (strcmp(argv[arg], "--cpu-stack-kb") == 0) {
            if (++arg >= argc ||
                !parse_int_value(argv[arg], &options->cpu_stack_kb) ||
                options->cpu_stack_kb == 0) {
                fprintf(stderr,
                        "--cpu-stack-kb requires a positive integer\n");
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

struct CpuLoadPlan
{
    const float *A = NULL;
    size_t elements = 0;
    volatile float *sinks = NULL;
    std::atomic<bool> start;
    int actual_workers = 0;
    bool debug_log = false;
};

struct CpuWorkerState
{
    CpuLoadPlan *plan = NULL;
    int worker_id = 0;
};

static void *
cpu_shared_load_entry(void *opaque)
{
    CpuWorkerState *state = static_cast<CpuWorkerState *>(opaque);
    CpuLoadPlan *plan = state->plan;

    while (!plan->start.load(std::memory_order_acquire)) {
        sched_yield();
    }

    const int worker_count = plan->actual_workers;
    const size_t begin =
        (plan->elements * static_cast<size_t>(state->worker_id)) /
        static_cast<size_t>(worker_count);
    const size_t end =
        (plan->elements * static_cast<size_t>(state->worker_id + 1)) /
        static_cast<size_t>(worker_count);
    float local = 0.0f;

    printf("CPU worker %d started shared load [%zu, %zu)\n",
           state->worker_id, begin, end);
    fflush(stdout);

    for (size_t i = begin; i < end; ++i) {
        local += plan->A[i] * 0.000001f;
    }

    const size_t range_size = end - begin;
    const size_t extra_window = range_size < 1024 ? range_size : 1024;
    const int extra_rounds = state->worker_id % 4;
    for (int round = 0; round < extra_rounds; ++round) {
        for (size_t i = 0; i < extra_window; ++i) {
            local += plan->A[begin + i] * 0.0000001f;
        }
    }

    plan->sinks[state->worker_id] = local;

    printf("CPU worker %d finished shared load [%zu, %zu)\n",
           state->worker_id, begin, end);
    fflush(stdout);
    return NULL;
}

int
main(int argc, char *argv[])
{
    SquareOptions options;
    parse_options(argc, argv, &options);
    printf("Square options: elements=%zu cpu_workers=%d cpu_stack_kb=%d "
           "gpu_cus=%d gpu_only=%d\n",
           options.elements, options.cpu_workers, options.cpu_stack_kb,
           options.gpu_cus, options.gpu_only ? 1 : 0);
    fflush(stdout);

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
    const size_t max_useful_workers =
        std::min(options.elements, static_cast<size_t>(INT_MAX));
    const int planned_workers =
        static_cast<int>(std::min(static_cast<size_t>(options.cpu_workers),
                                  max_useful_workers));
    std::vector<pthread_t> cpu_threads(planned_workers);
    std::vector<CpuWorkerState> cpu_states(planned_workers);
    std::vector<float> cpu_sinks(planned_workers, 0.0f);
    CpuLoadPlan cpu_plan;
    cpu_plan.A = A_h;
    cpu_plan.elements = options.elements;
    cpu_plan.sinks = cpu_sinks.data();
    cpu_plan.start.store(false, std::memory_order_relaxed);
    cpu_plan.actual_workers = 0;
    cpu_plan.debug_log = options.debug_log;
    size_t created_workers = 0;
    pthread_attr_t thread_attr;
    int attr_status = pthread_attr_init(&thread_attr);
    if (attr_status != 0) {
        fprintf(stderr, "pthread_attr_init failed: %s\n",
                strerror(attr_status));
        exit(EXIT_FAILURE);
    }
    size_t stack_bytes = static_cast<size_t>(options.cpu_stack_kb) * 1024;
    if (stack_bytes < PTHREAD_STACK_MIN) {
        stack_bytes = PTHREAD_STACK_MIN;
    }
    attr_status = pthread_attr_setstacksize(&thread_attr, stack_bytes);
    if (attr_status != 0) {
        fprintf(stderr, "pthread_attr_setstacksize(%zu) failed: %s\n",
                stack_bytes, strerror(attr_status));
        pthread_attr_destroy(&thread_attr);
        exit(EXIT_FAILURE);
    }

    if (options.debug_log) {
        printf("Square split: elements=%zu gpu_compute=[0, %zu) "
               "cpu_requested=%d cpu_planned=%d cpu_shared_load=blocked-full-array "
               "roi_order=cpu-then-gpu\n",
               options.elements, gpu_end, options.cpu_workers, planned_workers);
        fflush(stdout);
    }

#if defined(GEM5_FUSION)
    printf("Before m5_work_begin\n");
    fflush(stdout);
    m5_work_begin(0, 0);
    printf("After m5_work_begin\n");
    fflush(stdout);
#elif defined(GEM5_FS)
    map_m5_mem();
    printf("Before m5_work_begin\n");
    fflush(stdout);
    m5_work_begin_addr(0, 0);
    printf("After m5_work_begin\n");
    fflush(stdout);
#endif

    printf("Before CPU worker creation\n");
    fflush(stdout);
    for (int worker = 0; worker < planned_workers; ++worker) {
        cpu_states[worker].plan = &cpu_plan;
        cpu_states[worker].worker_id = worker;
        int create_status = pthread_create(&cpu_threads[worker], &thread_attr,
                                           cpu_shared_load_entry,
                                           &cpu_states[worker]);
        if (create_status != 0) {
            printf("Failed to create CPU worker %d/%d: %s\n",
                   worker, options.cpu_workers, strerror(create_status));
            fflush(stdout);
            break;
        }
        ++created_workers;
    }
    pthread_attr_destroy(&thread_attr);

    cpu_plan.actual_workers = static_cast<int>(created_workers);
    if (created_workers > 0) {
        cpu_plan.start.store(true, std::memory_order_release);
    }

    printf("Created %zu/%d CPU workers\n", created_workers,
           options.cpu_workers);
    fflush(stdout);
    if (created_workers == 0 && options.cpu_workers > 0) {
        printf("CPU shared load skipped because no worker threads were created\n");
        fflush(stdout);
    }

    printf("Before CPU workers join\n");
    fflush(stdout);

    for (size_t index = 0; index < created_workers; ++index) {
        printf("Joining CPU worker thread %zu\n", index);
        fflush(stdout);
        int join_status = pthread_join(cpu_threads[index], NULL);
        if (join_status != 0) {
            fprintf(stderr, "pthread_join(%zu) failed: %s\n",
                    index, strerror(join_status));
            exit(EXIT_FAILURE);
        }
        printf("Joined CPU worker thread %zu\n", index);
        fflush(stdout);
    }

    printf("CPU workers joined\n");
    fflush(stdout);

    if (run_gpu) {
        printf("Before GPU kernel launch\n");
        fflush(stdout);
        printf("info: launch 'vector_square' kernel\n");
        fflush(stdout);
        hipLaunchKernelGGL(vector_square, dim3(blocks), dim3(threads_per_block),
                           0, 0, C_h, A_h, static_cast<size_t>(0),
                           options.elements);
        CHECK(hipGetLastError());
        printf("After GPU kernel launch\n");
        fflush(stdout);
    }

    if (run_gpu) {
        printf("Before hipDeviceSynchronize\n");
        fflush(stdout);
        CHECK(hipDeviceSynchronize());
        printf("After hipDeviceSynchronize\n");
        fflush(stdout);
        if (options.debug_log) {
            printf("GPU finished [0, %zu)\n", gpu_end);
            fflush(stdout);
        }
    }

#if defined(GEM5_FUSION)
    printf("Before m5_work_end\n");
    fflush(stdout);
    m5_work_end(0, 0);
    printf("After m5_work_end\n");
    fflush(stdout);
#elif defined(GEM5_FS)
    printf("Before m5_work_end\n");
    fflush(stdout);
    m5_work_end_addr(0, 0);
    printf("After m5_work_end\n");
    fflush(stdout);
#endif

    printf("Before result check\n");
    fflush(stdout);
    printf("info: check result\n");
    fflush(stdout);
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
    printf("After hipFree A_h/C_h\n");
    fflush(stdout);
    printf("PASSED!\n");
    fflush(stdout);
    return 0;
}
