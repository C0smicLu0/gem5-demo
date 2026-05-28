/************************************************************************************\
 *                                                                                  *
 * Copyright ?2014 Advanced Micro Devices, Inc.                                     *
 * Copyright (c) 2015 Mark D. Hill and David A. Wood                                *
 * Copyright (c) 2021 Gaurav Jain and Matthew D. Sinclair                           *
 * All rights reserved.                                                             *
 *                                                                                  *
\************************************************************************************/

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

#include "BC.h"
#include "../graph_parser/util.h"
#include "kernel.h"

#if defined(GEM5_FUSION) || defined(GEM5_FS)
#include <stdint.h>
#include <gem5/m5ops.h>
#endif

#ifdef GEM5_FS
#include <util/m5/src/m5_mmap.h>
#endif

#if defined(GEM5_FUSION) || defined(GEM5_FS)
#define MAX_ITERS 150
#else
#include <stdint.h>
#define MAX_ITERS INT32_MAX
#endif

#define CHECK(cmd) \
{ \
    hipError_t error = cmd; \
    if (error != hipSuccess) { \
        fprintf(stderr, "error: '%s'(%d) at %s:%d\n", \
                hipGetErrorString(error), error, __FILE__, __LINE__); \
        exit(EXIT_FAILURE); \
    } \
}

void print_vector(int *vector, int num);
void print_vectorf(float *vector, int num);

struct BcOptions
{
    const char *graph_file = NULL;
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
            "Usage: %s <graph_file> [options]\n"
            "  --cpu-workers N  CPU worker thread count. Default: 0.\n"
            "  --cpu-stack-kb N Per-worker pthread stack size in KiB. "
            "Default: 64.\n"
            "  --gpu-cus N      GPU CU count for CPU+GPU compatibility.\n"
            "  --cpu-only       Unsupported in GPU-only BC mode.\n"
            "  --gpu-only       Run the original GPU BC path only.\n"
            "  --debug-log      Print phase and completion logs.\n",
            program);
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
parse_options(int argc, char **argv, BcOptions *options)
{
    for (int arg = 1; arg < argc; ++arg) {
        if (strcmp(argv[arg], "--cpu-workers") == 0) {
            if (++arg >= argc ||
                !parse_int_value(argv[arg], &options->cpu_workers)) {
                fprintf(stderr,
                        "--cpu-workers requires a non-negative integer\n");
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
        } else if (argv[arg][0] == '-') {
            fprintf(stderr, "unknown option: %s\n", argv[arg]);
            usage(argv[0]);
            exit(EXIT_FAILURE);
        } else if (options->graph_file == NULL) {
            options->graph_file = argv[arg];
        } else {
            fprintf(stderr, "unexpected argument: %s\n", argv[arg]);
            usage(argv[0]);
            exit(EXIT_FAILURE);
        }
    }

    if (options->graph_file == NULL) {
        usage(argv[0]);
        exit(EXIT_FAILURE);
    }

    if (options->cpu_only && options->gpu_only) {
        fprintf(stderr, "--cpu-only and --gpu-only cannot be combined\n");
        exit(EXIT_FAILURE);
    }

    if (options->cpu_only) {
        fprintf(stderr, "--cpu-only is not supported in GPU-only BC mode\n");
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

struct CpuLoadPlan
{
    const csr_array *csr = NULL;
    int num_nodes = 0;
    int num_edges = 0;
    volatile unsigned long long *sinks = NULL;
    std::atomic<bool> start;
    int actual_workers = 0;
    bool debug_log = false;
};

static const int CPU_EDGE_SAMPLE_LIMIT = 8;

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
    const int begin =
        (plan->num_nodes * state->worker_id) / worker_count;
    const int end =
        (plan->num_nodes * (state->worker_id + 1)) / worker_count;
    unsigned long long local = 0;

    printf("CPU worker %d started shared load [%d, %d)\n",
           state->worker_id, begin, end);
    fflush(stdout);

    // Spread workers across the vertex set so every worker touches the same
    // shared graph inputs without writing any BC state.
    for (int tid = begin; tid < end; ++tid) {
        int start = plan->csr->row_array[tid];
        int stop = (tid + 1 < plan->num_nodes) ?
            plan->csr->row_array[tid + 1] : plan->num_edges;
        local += static_cast<unsigned long long>(start);
        int edge_limit = std::min(stop, start + CPU_EDGE_SAMPLE_LIMIT);
        for (int edge = start; edge < edge_limit; ++edge) {
            local += static_cast<unsigned long long>(
                plan->csr->col_array[edge] & 1);
        }
    }

    plan->sinks[state->worker_id] = local;

    printf("CPU worker %d finished shared load [%d, %d)\n",
           state->worker_id, begin, end);
    fflush(stdout);
    return NULL;
}

int
main(int argc, char **argv)
{
    BcOptions options;
    parse_options(argc, argv, &options);
    printf("BC options: cpu_workers=%d cpu_stack_kb=%d gpu_cus=%d "
           "gpu_only=%d\n",
           options.cpu_workers, options.cpu_stack_kb, options.gpu_cus,
           options.gpu_only ? 1 : 0);
    fflush(stdout);

    int num_nodes;
    int num_edges;
    bool directed = 1;

    csr_array *csr = parseCOO(const_cast<char *>(options.graph_file),
                              &num_nodes, &num_edges, directed);
    fprintf(stderr, "CHK after parse\n");
    fflush(stderr);

    float *bc_h = static_cast<float *>(malloc(num_nodes * sizeof(float)));
    if (!bc_h) {
        fprintf(stderr, "malloc failed bc_h\n");
        exit(EXIT_FAILURE);
    }

    const bool run_gpu = !options.cpu_only;
    const size_t max_useful_workers =
        std::min(static_cast<size_t>(num_nodes),
                 static_cast<size_t>(INT_MAX));
    const int planned_workers =
        static_cast<int>(std::min(static_cast<size_t>(options.cpu_workers),
                                  max_useful_workers));
    std::vector<pthread_t> cpu_threads(planned_workers);
    std::vector<CpuWorkerState> cpu_states(planned_workers);
    std::vector<unsigned long long> cpu_sinks(planned_workers, 0);
    CpuLoadPlan cpu_plan;
    cpu_plan.csr = csr;
    cpu_plan.num_nodes = num_nodes;
    cpu_plan.num_edges = num_edges;
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

    hipDeviceProp_t props;
    fprintf(stderr, "CHK before hipGetDeviceProperties\n");
    fflush(stderr);
    CHECK(hipGetDeviceProperties(&props, 0));
    fprintf(stderr, "CHK after hipGetDeviceProperties\n");
    fflush(stderr);
    printf("info: running on device %s\n", props.name);
    fflush(stdout);

    const int max_sources = std::min(num_nodes, MAX_ITERS);
    const int gpu_dummy_rounds = 8;
    int gpu_dummy_blocks = 0;
    if (run_gpu) {
        const int gpu_capacity =
            options.gpu_cus > 0 ? options.gpu_cus : props.multiProcessorCount;
        gpu_dummy_blocks = std::max(1, gpu_capacity);
    }

    if (options.debug_log) {
        printf("BC split: sources=%d gpu_compute=[0, %d) "
               "cpu_requested=%d cpu_planned=%d cpu_shared_load=graph-read-only "
               "gpu_dummy_blocks=%d gpu_dummy_rounds=%d roi_order=cpu-then-gpu\n",
               num_nodes, max_sources, options.cpu_workers, planned_workers,
               gpu_dummy_blocks, gpu_dummy_rounds);
        fflush(stdout);
    }

    float *bc_d = NULL;
    float *sigma_d = NULL;
    float *rho_d = NULL;
    int *dist_d = NULL;
    int *stop_d = NULL;
    int *row_d = NULL;
    int *col_d = NULL;
    int *row_trans_d = NULL;
    int *col_trans_d = NULL;
    unsigned int *gpu_dummy_d = NULL;
    int gpu_dummy_entries = 0;

    if (run_gpu) {
        CHECK(hipMalloc(&bc_d, num_nodes * sizeof(float)));
        CHECK(hipMalloc(&dist_d, num_nodes * sizeof(int)));
        CHECK(hipMalloc(&sigma_d, num_nodes * sizeof(float)));
        CHECK(hipMalloc(&rho_d, num_nodes * sizeof(float)));
        CHECK(hipMalloc(&stop_d, sizeof(int)));
        CHECK(hipMalloc(&row_d, (num_nodes + 1) * sizeof(int)));
        CHECK(hipMalloc(&col_d, num_edges * sizeof(int)));
        CHECK(hipMalloc(&row_trans_d, (num_nodes + 1) * sizeof(int)));
        CHECK(hipMalloc(&col_trans_d, num_edges * sizeof(int)));
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

    // Run the CPU shared-load phase first so CPU and GPU do not touch the
    // shared graph inputs concurrently, while still keeping both phases in ROI.
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

    // After the CPU phase drains, execute the original GPU BC path.
    if (run_gpu) {
        printf("Before GPU input copies\n");
        fflush(stdout);
        CHECK(hipMemcpy(row_d, csr->row_array,
                        (num_nodes + 1) * sizeof(int),
                        hipMemcpyHostToDevice));
        CHECK(hipMemcpy(col_d, csr->col_array,
                        num_edges * sizeof(int),
                        hipMemcpyHostToDevice));
        CHECK(hipMemcpy(row_trans_d, csr->row_array_t,
                        (num_nodes + 1) * sizeof(int),
                        hipMemcpyHostToDevice));
        CHECK(hipMemcpy(col_trans_d, csr->col_array_t,
                        num_edges * sizeof(int),
                        hipMemcpyHostToDevice));

        int local_worksize = 128;
        dim3 threads(local_worksize, 1, 1);
        int real_blocks = (num_nodes + local_worksize - 1) / local_worksize;
        dim3 grid(real_blocks, 1, 1);
        gpu_dummy_entries = gpu_dummy_blocks * local_worksize;
        CHECK(hipMalloc(&gpu_dummy_d,
                        gpu_dummy_entries * sizeof(unsigned int)));
        CHECK(hipMemset(gpu_dummy_d, 0,
                        gpu_dummy_entries * sizeof(unsigned int)));

        printf("Before GPU kernel launch\n");
        fflush(stdout);
        if (options.debug_log) {
            printf("GPU launch config: real_blocks=%d "
                   "dummy_blocks=%d dummy_entries=%d dummy_rounds=%d\n",
                   real_blocks, gpu_dummy_blocks,
                   gpu_dummy_entries, gpu_dummy_rounds);
            fflush(stdout);
        }
        hipLaunchKernelGGL(HIP_KERNEL_NAME(clean_bc), dim3(grid),
                           dim3(threads), 0, 0, bc_d, num_nodes);
        CHECK(hipDeviceSynchronize());
        if (options.debug_log) {
            printf("Completed clean_bc\n");
            fflush(stdout);
        }

        // Preserve the original single-source BC traversal while padding the
        // launch grid with dummy-only blocks so otherwise idle CUs can execute
        // independent work during each GPU phase.
        for (int source = 0; source < max_sources; ++source) {
            if (options.debug_log) {
                printf("Starting iteration %d\n", source);
                fflush(stdout);
            }
            hipLaunchKernelGGL(HIP_KERNEL_NAME(clean_1d_array), dim3(grid),
                               dim3(threads), 0, 0, source, dist_d, sigma_d,
                               rho_d, num_nodes);
            CHECK(hipDeviceSynchronize());
            if (options.debug_log) {
                printf("Iteration %d: completed clean_1d_array\n", source);
                fflush(stdout);
            }

            int dist = 0;
            int stop = 1;
            do {
                stop = 0;
                if (options.debug_log) {
                    printf("Iteration %d: launching bfs dist=%d\n",
                           source, dist);
                    fflush(stdout);
                }
                CHECK(hipMemcpy(stop_d, &stop, sizeof(int),
                                hipMemcpyHostToDevice));
                hipLaunchKernelGGL(HIP_KERNEL_NAME(bfs_kernel), dim3(grid),
                                   dim3(threads), 0, 0, row_d, col_d, dist_d,
                                   rho_d, stop_d, num_nodes, num_edges, dist);
                CHECK(hipDeviceSynchronize());
                CHECK(hipMemcpy(&stop, stop_d, sizeof(int),
                                hipMemcpyDeviceToHost));
                if (options.debug_log) {
                    printf("Iteration %d: completed bfs dist=%d stop=%d\n",
                           source, dist, stop);
                    fflush(stdout);
                }
                dist++;
            } while (stop);

            if (options.debug_log) {
                printf("Iteration %d: bfs finished with dist=%d\n",
                       source, dist);
                fflush(stdout);
            }

            while (dist) {
                if (options.debug_log) {
                    printf("Iteration %d: launching backtrack dist=%d\n",
                           source, dist);
                    fflush(stdout);
                }
                hipLaunchKernelGGL(HIP_KERNEL_NAME(backtrack_kernel),
                                   dim3(grid), dim3(threads), 0, 0,
                                   row_trans_d, col_trans_d, dist_d, rho_d,
                                   sigma_d, num_nodes, num_edges, dist, source,
                                   bc_d);
                CHECK(hipDeviceSynchronize());
                if (options.debug_log) {
                    printf("Iteration %d: completed backtrack dist=%d\n",
                           source, dist);
                    fflush(stdout);
                }
                dist--;
            }
            fprintf(stdout, "Completed iteration %d\n", source);
            fflush(stdout);
        }

        printf("Before GPU dummy fill\n");
        fflush(stdout);
        if (options.debug_log) {
            printf("BC GPU dummy config: dummy_blocks=%d dummy_threads=%d "
                   "dummy_entries=%d dummy_rounds=%d\n",
                   gpu_dummy_blocks, local_worksize,
                   gpu_dummy_entries, gpu_dummy_rounds);
            fflush(stdout);
        }
        hipLaunchKernelGGL(HIP_KERNEL_NAME(bc_dummy_fill_kernel),
                           dim3(gpu_dummy_blocks), dim3(threads), 0, 0,
                           row_d, col_d, num_nodes, num_edges, gpu_dummy_d,
                           gpu_dummy_entries, gpu_dummy_rounds);
        CHECK(hipDeviceSynchronize());
        printf("After GPU dummy fill\n");
        fflush(stdout);

        CHECK(hipDeviceSynchronize());
        printf("After hipDeviceSynchronize\n");
        fflush(stdout);

        CHECK(hipMemcpy(bc_h, bc_d, num_nodes * sizeof(float),
                        hipMemcpyDeviceToHost));
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
    unmap_m5_mem();
#endif

    printf("Before result check\n");
    fflush(stdout);
    print_vectorf(bc_h, num_nodes);

    free(bc_h);
    free(csr->row_array);
    free(csr->col_array);
    free(csr->data_array);
    free(csr->row_array_t);
    free(csr->col_array_t);
    free(csr->data_array_t);
    free(csr);

    if (run_gpu) {
        hipFree(bc_d);
        hipFree(dist_d);
        hipFree(sigma_d);
        hipFree(rho_d);
        hipFree(stop_d);
        hipFree(row_d);
        hipFree(col_d);
        hipFree(row_trans_d);
        hipFree(col_trans_d);
        if (gpu_dummy_d) {
            hipFree(gpu_dummy_d);
        }
    }

    printf("PASS\n");
    fflush(stdout);
    return 0;
}

void print_vector(int *vector, int num)
{
    for (int i = 0; i < num; i++)
        printf("%d: %d \n", i + 1, vector[i]);
    printf("\n");
}

void print_vectorf(float *vector, int num)
{
    FILE *fp = fopen("result.out", "w");
    if (!fp) {
        printf("ERROR: unable to open result.txt\n");
        return;
    }

    for (int i = 0; i < num; i++) {
        fprintf(fp, "%f\n", vector[i]);
    }

    fclose(fp);
}
