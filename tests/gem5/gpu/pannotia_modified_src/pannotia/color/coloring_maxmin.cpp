#include "hip/hip_runtime.h"

#include <algorithm>
#include <errno.h>
#include <limits.h>
#include <pthread.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <vector>

#include "../graph_parser/parse.h"
#include "../graph_parser/util.h"
#include "../pannotia_common.h"
#include "kernel_maxmin.h"

#if defined(GEM5_FUSION) || defined(GEM5_FS)
#include <stdint.h>
#include <gem5/m5ops.h>
#endif

#ifdef GEM5_FS
#include <util/m5/src/m5_mmap.h>
#endif

#define CHECK(cmd) \
{ \
    hipError_t error  = cmd; \
    if (error != hipSuccess) { \
        fprintf(stderr, "error: '%s'(%d) at %s:%d\n", \
                hipGetErrorString(error), error, __FILE__, __LINE__); \
        exit(EXIT_FAILURE); \
    } \
}

#define RANGE 2048
#define CPU_SHARED_LOAD_ROUNDS 4

void print_vector(int *vector, int num);

struct CpuLoadPlan
{
    const csr_array *csr = NULL;
    const int *node_value = NULL;
    int num_nodes = 0;
    int num_edges = 0;
    volatile long long *sinks = NULL;
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
    const int worker_count = plan->actual_workers;
    const int begin =
        (plan->num_nodes * state->worker_id) / worker_count;
    const int end =
        (plan->num_nodes * (state->worker_id + 1)) / worker_count;
    long long local = 0;

    printf("CPU worker %d started shared load [%d, %d)\n",
           state->worker_id, begin, end);
    fflush(stdout);

    // Spread workers across the vertex set so every worker touches the same
    // shared graph inputs without writing any coloring state. Run a few rounds
    // to give the CPU phase a moderate amount of work before the GPU takes over.
    for (int round = 0; round < CPU_SHARED_LOAD_ROUNDS; ++round) {
        for (int tid = begin; tid < end; ++tid) {
            int start = plan->csr->row_array[tid];
            int edge_end =
                (tid + 1 < plan->num_nodes) ? plan->csr->row_array[tid + 1]
                                            : plan->num_edges;
            local += plan->node_value[tid] + round;
            for (int edge = start; edge < edge_end; ++edge) {
                local += plan->csr->col_array[edge] & 1;
            }
        }
    }

    plan->sinks[state->worker_id] = local;

    printf("CPU worker %d finished shared load [%d, %d)\n",
           state->worker_id, begin, end);
    fflush(stdout);
    return NULL;
}

int main(int argc, char **argv)
{
    char *tmpchar;
    int num_nodes;
    int num_edges;
    int file_format = 1;
    bool directed = 0;
    hipError_t err = hipSuccess;
    PannotiaOptions options;

    if (argc >= 3) {
        tmpchar = argv[1];
        file_format = atoi(argv[2]);
        parse_pannotia_options(argc, argv, 3, &options);
    } else {
        fprintf(stderr, "Usage: %s <graph_file> <format> [options]\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    if (options.cpu_only) {
        fprintf(stderr, "--cpu-only is not supported in color_maxmin\n");
        exit(EXIT_FAILURE);
    }

    srand(7);

    csr_array *csr = NULL;
    if (file_format == 1) {
        csr = parseMetis(tmpchar, &num_nodes, &num_edges, directed);
    } else if (file_format == 0) {
        csr = parseCOO(tmpchar, &num_nodes, &num_edges, directed);
    } else {
        fprintf(stderr, "reserve for future\n");
        exit(EXIT_FAILURE);
    }

    int *node_value = (int *)malloc(num_nodes * sizeof(int));
    int *color = (int *)malloc(num_nodes * sizeof(int));
    if (!node_value || !color) {
        fprintf(stderr, "host malloc failed\n");
        exit(EXIT_FAILURE);
    }

    for (int i = 0; i < num_nodes; ++i) {
        color[i] = -1;
        node_value[i] = rand() % RANGE;
    }

    int cpu_workers = resolve_cpu_workers(options);
    const int planned_workers = std::min(cpu_workers, num_nodes);
    const bool run_gpu = !options.gpu_only;

    int *row_d = NULL;
    int *col_d = NULL;
    int *max_d = NULL;
    int *min_d = NULL;
    int *color_d = NULL;
    int *node_value_d = NULL;
    int *stop_d = NULL;

    if (run_gpu) {
        CHECK(hipMalloc(&row_d, num_nodes * sizeof(int)));
        CHECK(hipMalloc(&col_d, num_edges * sizeof(int)));
        CHECK(hipMalloc(&stop_d, sizeof(int)));
        CHECK(hipMalloc(&color_d, num_nodes * sizeof(int)));
        CHECK(hipMalloc(&node_value_d, num_nodes * sizeof(int)));
        CHECK(hipMalloc(&max_d, num_nodes * sizeof(int)));
        CHECK(hipMalloc(&min_d, num_nodes * sizeof(int)));
    }

    std::vector<pthread_t> cpu_threads(planned_workers);
    std::vector<CpuWorkerState> cpu_states(planned_workers);
    std::vector<long long> cpu_sinks(planned_workers, 0);
    CpuLoadPlan cpu_plan;
    cpu_plan.csr = csr;
    cpu_plan.node_value = node_value;
    cpu_plan.num_nodes = num_nodes;
    cpu_plan.num_edges = num_edges;
    cpu_plan.sinks = cpu_sinks.data();
    cpu_plan.actual_workers = planned_workers;
    cpu_plan.debug_log = options.debug_log;
    size_t created_workers = 0;

    if (options.debug_log) {
        printf("color_maxmin split: nodes=%d gpu_compute=[0, %d) "
               "cpu_requested=%d cpu_planned=%d cpu_shared_load=blocked-full-graph "
               "roi_order=cpu-then-gpu gpu_cus=%d\n",
               num_nodes, run_gpu ? num_nodes : 0, cpu_workers,
               planned_workers, resolve_gpu_cus(options));
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

    // Run the CPU shared-load phase first so CPU and GPU do not touch the
    // shared inputs concurrently, while still keeping both phases inside ROI.
    printf("Before CPU worker creation\n");
    fflush(stdout);
    for (int worker = 0; worker < planned_workers; ++worker) {
        cpu_states[worker].plan = &cpu_plan;
        cpu_states[worker].worker_id = worker;
        int create_status = pthread_create(&cpu_threads[worker], NULL,
                                           cpu_shared_load_entry,
                                           &cpu_states[worker]);
        if (create_status != 0) {
            printf("Failed to create CPU worker %d/%d: %s\n",
                   worker, cpu_workers, strerror(create_status));
            fflush(stdout);
            break;
        }
        ++created_workers;
    }

    printf("Created %zu/%d CPU workers\n", created_workers, cpu_workers);
    fflush(stdout);
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
        // After the CPU phase drains, execute the original GPU coloring path.
        CHECK(hipMemcpy(color_d, color, num_nodes * sizeof(int),
                        hipMemcpyHostToDevice));
        CHECK(hipMemcpy(row_d, csr->row_array, num_nodes * sizeof(int),
                        hipMemcpyHostToDevice));
        CHECK(hipMemcpy(col_d, csr->col_array, num_edges * sizeof(int),
                        hipMemcpyHostToDevice));
        CHECK(hipMemcpy(node_value_d, node_value, num_nodes * sizeof(int),
                        hipMemcpyHostToDevice));

        const int block_size = 64;
        const int min_blocks = (num_nodes + block_size - 1) / block_size;
        const int gpu_cus = options.gpu_cus > 0 ? resolve_gpu_cus(options) : 1;
        // Overdecompose the launch so a small graph still creates enough
        // blocks to keep many CUs active.
        const int num_blocks = std::max(min_blocks, gpu_cus * 4);
        dim3 threads(block_size, 1, 1);
        dim3 grid(num_blocks, 1, 1);
        int stop = 1;
        int graph_color = 1;

        hipLaunchKernelGGL(ini, dim3(grid), dim3(threads), 0, 0, max_d, min_d,
                           0, num_nodes, num_nodes);

        printf("Before GPU kernel launch\n");
        fflush(stdout);
        while (stop) {
            stop = 0;
            CHECK(hipMemcpy(stop_d, &stop, sizeof(int),
                            hipMemcpyHostToDevice));

            hipLaunchKernelGGL(color1, dim3(grid), dim3(threads), 0, 0, row_d,
                               col_d, node_value_d, color_d, stop_d, max_d,
                               min_d, graph_color, 0, num_nodes, num_nodes,
                               num_edges);

            hipLaunchKernelGGL(color2, dim3(grid), dim3(threads), 0, 0,
                               node_value_d, color_d, max_d, min_d,
                               graph_color, num_nodes, num_edges, 0,
                               num_nodes);

            CHECK(hipMemcpy(&stop, stop_d, sizeof(int),
                            hipMemcpyDeviceToHost));
            graph_color = graph_color + 2;
        }
        printf("After GPU kernel launch\n");
        fflush(stdout);

        printf("Before hipDeviceSynchronize\n");
        fflush(stdout);
        CHECK(hipDeviceSynchronize());
        printf("After hipDeviceSynchronize\n");
        fflush(stdout);

        CHECK(hipMemcpy(color, color_d, num_nodes * sizeof(int),
                        hipMemcpyDeviceToHost));

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

        printf("total number of colors used: %d\n", graph_color);
        fflush(stdout);
    }

    print_vector(color, num_nodes);

    free(node_value);
    free(color);
    csr->freeArrays();
    free(csr);

    if (run_gpu) {
        CHECK(hipFree(row_d));
        CHECK(hipFree(col_d));
        CHECK(hipFree(max_d));
        CHECK(hipFree(min_d));
        CHECK(hipFree(color_d));
        CHECK(hipFree(node_value_d));
        CHECK(hipFree(stop_d));
    }

    printf("PASSED!\n");
    fflush(stdout);
    return 0;
}

void print_vector(int *vector, int num)
{
    FILE * fp = fopen("result.out", "w");
    if (!fp) {
        printf("ERROR: unable to open result.txt\n");
        return;
    }

    for (int i = 0; i < num; i++) {
        fprintf(fp, "%d: %d\n", i + 1, vector[i]);
    }

    fclose(fp);
}
