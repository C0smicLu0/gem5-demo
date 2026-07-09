#include "hip/hip_runtime.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <sys/time.h>
#include <pthread.h>
#include <stdatomic.h>
#include <sched.h>
#include <limits.h>

#ifdef TIMING
#include "timing.h"
#endif

#define MAX_THREADS_PER_BLOCK 128

#define BFS_TRACE(fmt, ...)                                      \
    do {                                                         \
        printf("[bfs] " fmt "\n", ##__VA_ARGS__);              \
        fflush(stdout);                                          \
    } while (0)

// -----------------------------------------------------------------------------
// Original Rodinia BFS data types
// -----------------------------------------------------------------------------
struct Node
{
    int starting;
    int no_of_edges;
};

// Keep these global names for compatibility with the original BFS code style.
int no_of_nodes = 0;
int edge_list_size = 0;
FILE *fp = NULL;

#ifdef TIMING
struct timeval tv;
struct timeval tv_total_start, tv_total_end;
struct timeval tv_h2d_start, tv_h2d_end;
struct timeval tv_d2h_start, tv_d2h_end;
struct timeval tv_kernel_start, tv_kernel_end;
struct timeval tv_mem_alloc_start, tv_mem_alloc_end;
struct timeval tv_close_start, tv_close_end;
float init_time = 0, mem_alloc_time = 0, h2d_time = 0, kernel_time = 0,
      d2h_time = 0, close_time = 0, total_time = 0;
#endif

// Kernels depend on struct Node being visible before the include.
#include "kernel.cu"
#include "kernel2.cu"

// -----------------------------------------------------------------------------
// Utility helpers
// -----------------------------------------------------------------------------
static inline long long bfs_wall_time_us(void)
{
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (tv.tv_sec * 1000000LL) + tv.tv_usec;
}

static void *checked_hip_malloc_managed(size_t size)
{
    void *ptr = NULL;
    hipError_t err = hipMallocManaged(&ptr, size, hipMemAttachGlobal);
    if (err != hipSuccess) {
        fprintf(stderr, "hipMallocManaged failed (%zu bytes): %s\n",
                size, hipGetErrorString(err));
        exit(-1);
    }
    return ptr;
}

static void checked_fscanf_1(FILE *f, const char *fmt, void *p, const char *what)
{
    if (fscanf(f, fmt, p) != 1) {
        fprintf(stderr, "[bfs] failed to read %s\n", what);
        exit(-1);
    }
}

// -----------------------------------------------------------------------------
// Runtime configuration
// -----------------------------------------------------------------------------
typedef struct {
    const char *input_file;
    int gpu_cus;
} bfs_config_t;

static bfs_config_t g_cfg = {
    NULL,   // input_file
    0       // gpu_cus
};

static int rodinia_mt_threads = 4;
static int rodinia_mt_inited = 0;

static void usage(const char *prog)
{
    fprintf(stderr,
            "Usage: %s <input_file> "
            "[--cpu-workers N] [--gpu-cus N]\n",
            prog);
}

static void rodinia_mt_init_cfg(void)
{
    if (rodinia_mt_inited) {
        return;
    }

    if (rodinia_mt_threads <= 0) {
        rodinia_mt_threads = 1;
    }

    rodinia_mt_inited = 1;
}

void rodinia_mt_set_threads(int n)
{
    rodinia_mt_threads = (n > 0) ? n : 1;
}

static void normalize_config(bfs_config_t *cfg)
{
    if (cfg->gpu_cus < 0) {
        cfg->gpu_cus = 0;
    }
}

static void parse_arguments(int argc, char **argv, bfs_config_t *cfg)
{
    if (argc < 2) {
        usage(argv[0]);
        exit(0);
    }

    cfg->input_file = argv[1];

    for (int ai = 2; ai < argc; ai++) {
        if (strcmp(argv[ai], "--cpu-workers") == 0) {
            if (ai + 1 >= argc) {
                fprintf(stderr, "Missing value for --cpu-workers\n");
                usage(argv[0]);
                exit(-1);
            }
            rodinia_mt_set_threads(atoi(argv[++ai]));
        } else if (strcmp(argv[ai], "--gpu-cus") == 0) {
            if (ai + 1 >= argc) {
                fprintf(stderr, "Missing value for --gpu-cus\n");
                usage(argv[0]);
                exit(-1);
            }
            cfg->gpu_cus = atoi(argv[++ai]);
        } else {
            fprintf(stderr, "Unknown argument: %s\n", argv[ai]);
            usage(argv[0]);
            exit(-1);
        }
    }

    normalize_config(cfg);

    BFS_TRACE("after arg parse: input=%s gpu_cus=%d",
              cfg->input_file, cfg->gpu_cus);
}

// -----------------------------------------------------------------------------
// CPU dummy phase
// -----------------------------------------------------------------------------

typedef struct {
    const int *input_edges;
    size_t elements;
    volatile long long *sinks;
    atomic_bool start;
    int actual_workers;
} rodinia_mt_plan_t;

typedef struct {
    rodinia_mt_plan_t *plan;
    int worker_id;
} rodinia_mt_worker_state_t;

static const int *rodinia_mt_edges_input = NULL;
static size_t rodinia_mt_edge_elements = 0;

static void rodinia_mt_set_shared_data(Node *nodes,
                                       int *edges,
                                       int nodes_count,
                                       int edges_count)
{
    (void)nodes;
    (void)nodes_count;

    /*
     * LavaMD-style mapping:
     *   BFS h_graph_edges  <=> LavaMD qv_cpu
     *   BFS edge_list_size <=> LavaMD space_elem
     *
     * CPU workers only read h_graph_edges.
     * They must not touch BFS state arrays such as cost/mask/visited.
     */
    rodinia_mt_edges_input = edges;
    rodinia_mt_edge_elements = (edges_count > 0) ? (size_t)edges_count : 0;
}

static void *rodinia_mt_worker(void *vp)
{
    rodinia_mt_worker_state_t *state = (rodinia_mt_worker_state_t *)vp;
    rodinia_mt_plan_t *plan = state->plan;

    if (plan->input_edges == NULL || plan->elements == 0) {
        plan->sinks[state->worker_id] = 0;
        return NULL;
    }

    while (!atomic_load_explicit(&plan->start, memory_order_acquire)) {
        sched_yield();
    }

    const int worker_count = plan->actual_workers;
    if (worker_count <= 0) {
        plan->sinks[state->worker_id] = 0;
        return NULL;
    }

    const size_t begin =
        (plan->elements * (size_t)state->worker_id) / (size_t)worker_count;

    const size_t end =
        (plan->elements * (size_t)(state->worker_id + 1)) /
        (size_t)worker_count;

    long long local = 0;

    /*
     * Main pass:
     * sequentially scan this worker's own slice.
     */
    for (size_t idx = begin; idx < end; ++idx) {
        int value = plan->input_edges[idx];
        int next =
            (idx + 1 < plan->elements) ? plan->input_edges[idx + 1] : value;

        local += (long long)(value ^ (int)idx);
        local += (long long)(next  ^ (int)(idx + 1));
    }

    /*
     * Small extra pass, similar to LavaMD's extra_window logic.
     * This slightly increases CPU activity without restoring random access.
     */
    {
        const size_t range_size = end - begin;
        const size_t extra_window = range_size < 1024 ? range_size : 1024;
        const int extra_rounds = state->worker_id % 4;

        for (int round = 0; round < extra_rounds; ++round) {
            for (size_t offset = 0; offset < extra_window; ++offset) {
                size_t idx = begin + offset;

                int value = plan->input_edges[idx];
                int next =
                    (idx + 1 < plan->elements) ?
                    plan->input_edges[idx + 1] : value;

                local += (long long)(value ^ next) + round;
            }
        }
    }

    plan->sinks[state->worker_id] = local;
    return NULL;
}

static void rodinia_mt_cpu_phase(void)
{
    rodinia_mt_init_cfg();

    if (rodinia_mt_threads <= 0 ||
        rodinia_mt_edges_input == NULL ||
        rodinia_mt_edge_elements == 0) {
        BFS_TRACE("CPU phase skipped: threads=%d edges=%lu",
                  rodinia_mt_threads,
                  (unsigned long)rodinia_mt_edge_elements);
        return;
    }

    size_t max_useful_workers =
        rodinia_mt_edge_elements < (size_t)INT_MAX ?
        rodinia_mt_edge_elements : (size_t)INT_MAX;

    int planned_workers =
        (int)((size_t)rodinia_mt_threads < max_useful_workers ?
              (size_t)rodinia_mt_threads : max_useful_workers);

    if (planned_workers <= 0) {
        BFS_TRACE("CPU phase skipped: planned_workers=%d", planned_workers);
        return;
    }

    pthread_t *threads =
        (pthread_t *)malloc((size_t)planned_workers * sizeof(pthread_t));

    rodinia_mt_worker_state_t *states =
        (rodinia_mt_worker_state_t *)malloc((size_t)planned_workers *
                                            sizeof(rodinia_mt_worker_state_t));

    long long *sinks =
        (long long *)calloc((size_t)planned_workers, sizeof(long long));

    if (!threads || !states || !sinks) {
        free(threads);
        free(states);
        free(sinks);
        fprintf(stderr, "[bfs] failed to allocate CPU worker metadata\n");
        exit(-1);
    }

    rodinia_mt_plan_t plan;
    plan.input_edges = rodinia_mt_edges_input;
    plan.elements = rodinia_mt_edge_elements;
    plan.sinks = sinks;
    atomic_init(&plan.start, false);
    plan.actual_workers = planned_workers;

    pthread_attr_t thread_attr;
    int attr_status = pthread_attr_init(&thread_attr);
    if (attr_status != 0) {
        fprintf(stderr, "pthread_attr_init failed: %s\n", strerror(attr_status));
        exit(-1);
    }

    {
        size_t stack_bytes = 64 * 1024;
        if (stack_bytes < PTHREAD_STACK_MIN) {
            stack_bytes = PTHREAD_STACK_MIN;
        }

        attr_status = pthread_attr_setstacksize(&thread_attr, stack_bytes);
        if (attr_status != 0) {
            fprintf(stderr, "pthread_attr_setstacksize(%zu) failed: %s\n",
                    stack_bytes, strerror(attr_status));
            pthread_attr_destroy(&thread_attr);
            exit(-1);
        }
    }

    size_t created_workers = 0;

    BFS_TRACE("CPU phase start: requested_workers=%d planned_workers=%d edges=%lu",
              rodinia_mt_threads,
              planned_workers,
              (unsigned long)rodinia_mt_edge_elements);

    for (int worker = 0; worker < planned_workers; ++worker) {
        states[worker].plan = &plan;
        states[worker].worker_id = worker;

        int ret = pthread_create(&threads[worker],
                                 &thread_attr,
                                 rodinia_mt_worker,
                                 &states[worker]);

        if (ret != 0) {
            BFS_TRACE("pthread_create stopped at worker=%d ret=%d",
                      worker, ret);
            break;
        }

        ++created_workers;
    }

    pthread_attr_destroy(&thread_attr);

    plan.actual_workers = (int)created_workers;

    if (created_workers > 0) {
        atomic_store_explicit(&plan.start, true, memory_order_release);
    }

    BFS_TRACE("Created %zu/%d CPU workers",
              created_workers,
              rodinia_mt_threads);

    if (created_workers == 0) {
        BFS_TRACE("CPU phase skipped because no worker threads were created");
        free(threads);
        free(states);
        free(sinks);
        return;
    }

    for (size_t index = 0; index < created_workers; ++index) {
        BFS_TRACE("Joining CPU worker thread %zu", index);

        int ret = pthread_join(threads[index], NULL);
        if (ret != 0) {
            fprintf(stderr,
                    "[bfs] pthread_join failed: worker=%zu ret=%d\n",
                    index, ret);
            exit(-1);
        }

        BFS_TRACE("Joined CPU worker thread %zu sink=%lld",
                  index,
                  sinks[index]);
    }

    BFS_TRACE("CPU workers joined");

    free(threads);
    free(states);
    free(sinks);

    BFS_TRACE("CPU phase completed");
}

// -----------------------------------------------------------------------------
// Managed graph storage
// -----------------------------------------------------------------------------
typedef struct {
    Node *h_graph_nodes;
    int  *h_graph_edges;
    bool *h_graph_mask;
    bool *h_updating_graph_mask;
    bool *h_graph_visited;
    int  *h_cost;
    bool *d_over;
    int source;
} bfs_graph_t;

static void init_empty_graph(bfs_graph_t *g)
{
    memset(g, 0, sizeof(*g));
    g->source = 0;
}

static void free_graph(bfs_graph_t *g)
{
    if (g->h_graph_nodes)
        hipFree(g->h_graph_nodes);
    if (g->h_graph_edges)
        hipFree(g->h_graph_edges);
    if (g->h_graph_mask)
        hipFree(g->h_graph_mask);
    if (g->h_updating_graph_mask)
        hipFree(g->h_updating_graph_mask);
    if (g->h_graph_visited)
        hipFree(g->h_graph_visited);
    if (g->h_cost)
        hipFree(g->h_cost);
    if (g->d_over)
        hipFree(g->d_over);

    init_empty_graph(g);
}

static void read_graph_file(const char *input_file, bfs_graph_t *g)
{
    BFS_TRACE("Opening graph file: %s", input_file);

    fp = fopen(input_file, "r");
    if (!fp) {
        BFS_TRACE("Error Reading graph file");
        exit(-1);
    }

    checked_fscanf_1(fp, "%d", &no_of_nodes, "number of nodes");

    g->h_graph_nodes =
        (Node *)checked_hip_malloc_managed(sizeof(Node) * (size_t)no_of_nodes);
    g->h_graph_mask =
        (bool *)checked_hip_malloc_managed(sizeof(bool) * (size_t)no_of_nodes);
    g->h_updating_graph_mask =
        (bool *)checked_hip_malloc_managed(sizeof(bool) * (size_t)no_of_nodes);
    g->h_graph_visited =
        (bool *)checked_hip_malloc_managed(sizeof(bool) * (size_t)no_of_nodes);

    int start = 0;
    int edgeno = 0;
    for (int i = 0; i < no_of_nodes; i++) {
        checked_fscanf_1(fp, "%d", &start, "node.starting");
        checked_fscanf_1(fp, "%d", &edgeno, "node.no_of_edges");

        g->h_graph_nodes[i].starting = start;
        g->h_graph_nodes[i].no_of_edges = edgeno;
        g->h_graph_mask[i] = false;
        g->h_updating_graph_mask[i] = false;
        g->h_graph_visited[i] = false;
    }

    checked_fscanf_1(fp, "%d", &g->source, "source node");

    // Preserve the original Rodinia BFS behavior used in the provided file.
    g->source = 0;
    g->h_graph_mask[g->source] = true;
    g->h_graph_visited[g->source] = true;

    checked_fscanf_1(fp, "%d", &edge_list_size, "edge list size");

    g->h_graph_edges =
        (int *)checked_hip_malloc_managed(sizeof(int) * (size_t)edge_list_size);

    int id = 0;
    int cost = 0;
    for (int i = 0; i < edge_list_size; i++) {
        checked_fscanf_1(fp, "%d", &id, "edge id");
        checked_fscanf_1(fp, "%d", &cost, "edge cost");
        g->h_graph_edges[i] = id;
    }

    fclose(fp);
    fp = NULL;

    g->h_cost =
        (int *)checked_hip_malloc_managed(sizeof(int) * (size_t)no_of_nodes);
    for (int i = 0; i < no_of_nodes; i++)
        g->h_cost[i] = -1;
    g->h_cost[g->source] = 0;

    g->d_over = (bool *)checked_hip_malloc_managed(sizeof(bool));

    rodinia_mt_set_shared_data(g->h_graph_nodes,
                           g->h_graph_edges,
                           no_of_nodes,
                           edge_list_size);

    BFS_TRACE("Finished reading file: nodes=%d edges=%d source=%d",
              no_of_nodes, edge_list_size, g->source);
}

// -----------------------------------------------------------------------------
// GPU launch configuration and BFS loop
// -----------------------------------------------------------------------------
typedef struct {
    dim3 grid;
    dim3 threads;
    int num_blocks;
    int threads_per_block;
} bfs_launch_config_t;

static bfs_launch_config_t make_launch_config(int nodes, int gpu_cus)
{
    bfs_launch_config_t lc;

    lc.threads_per_block = MAX_THREADS_PER_BLOCK;
    lc.num_blocks = (nodes + lc.threads_per_block - 1) / lc.threads_per_block;

    if (gpu_cus > 0) {
        int cu_required_blocks = gpu_cus * 2;
        if (lc.num_blocks < cu_required_blocks)
            lc.num_blocks = cu_required_blocks;
    }

    lc.grid = dim3(lc.num_blocks, 1, 1);
    lc.threads = dim3(lc.threads_per_block, 1, 1);

    BFS_TRACE("BFS_MT: nodes=%d gpu_cus=%d gpu_blocks=%d threads_per_block=%d",
              nodes, gpu_cus, lc.num_blocks, lc.threads_per_block);

    return lc;
}

static int run_gpu_bfs_loop(bfs_graph_t *g, const bfs_launch_config_t *lc)
{
    int k = 0;
    bool stop = false;

    BFS_TRACE("GPU BFS main loop begin");

    do {
        stop = false;
        *(g->d_over) = false;

        BFS_TRACE("Iteration %d: launching GPU kernels", k);

        Kernel<<<lc->grid, lc->threads, 0>>>(
            g->h_graph_nodes,
            g->h_graph_edges,
            g->h_graph_mask,
            g->h_updating_graph_mask,
            g->h_graph_visited,
            g->h_cost,
            no_of_nodes);

        Kernel2<<<lc->grid, lc->threads, 0>>>(
            g->h_graph_mask,
            g->h_updating_graph_mask,
            g->h_graph_visited,
            g->d_over,
            no_of_nodes);

        hipError_t err = hipDeviceSynchronize();
        if (err != hipSuccess) {
            fprintf(stderr, "BFS kernels failed at iter=%d: %s\n",
                    k, hipGetErrorString(err));
            exit(-1);
        }

        BFS_TRACE("GPU kernels completed for iter %d", k);

        stop = *(g->d_over);
        k++;

        BFS_TRACE("Iteration %d finished, stop=%d", k - 1, stop);
    } while (stop);

    BFS_TRACE("GPU BFS main loop done, iterations=%d", k);
    return k;
}

// -----------------------------------------------------------------------------
// Timing summary
// -----------------------------------------------------------------------------
typedef struct {
    long long total_start_us;
    long long read_start_us;
    long long read_end_us;
    long long setup_end_us;
    long long loop_start_us;
    long long loop_end_us;
} bfs_timing_t;

static void print_timing_summary(const bfs_timing_t *tm, int iterations)
{
    printf("Kernel Executed %d times\n", iterations);
    printf("\n==================== BFS_MT Timing Summary ====================\n");
    printf("[TIMING] cpu_threads:             %d\n", rodinia_mt_threads);
    printf("[TIMING] gpu_cus:                 %d\n", g_cfg.gpu_cus);
    printf("[TIMING] read+parse:              %lld us\n",
           tm->read_end_us - tm->read_start_us);
    printf("[TIMING] setup (alloc+init):      %lld us\n",
           tm->setup_end_us - tm->read_end_us);
    printf("[TIMING] bfs loop (cpu+gpu+sync): %lld us (iters=%d)\n",
           tm->loop_end_us - tm->loop_start_us, iterations);

    if (iterations > 0) {
        printf("[TIMING] avg per iter:            %.2f us/iter\n",
               (double)(tm->loop_end_us - tm->loop_start_us) /
               (double)iterations);
    }

    printf("[TIMING] total runtime:           %lld us\n",
           bfs_wall_time_us() - tm->total_start_us);
    printf("===============================================================\n");
}

// -----------------------------------------------------------------------------
// Top-level BFS flow: read graph -> CPU batch -> GPU loop -> cleanup
// -----------------------------------------------------------------------------
void BFSGraph(int argc, char **argv)
{
    bfs_graph_t graph;
    bfs_timing_t timing;

    init_empty_graph(&graph);
    memset(&timing, 0, sizeof(timing));

    timing.total_start_us = bfs_wall_time_us();

    BFS_TRACE("Enter BFSGraph");

    parse_arguments(argc, argv, &g_cfg);

    timing.read_start_us = bfs_wall_time_us();
    read_graph_file(g_cfg.input_file, &graph);
    timing.read_end_us = bfs_wall_time_us();

#ifdef TIMING
    gettimeofday(&tv_total_start, NULL);
#endif

    bfs_launch_config_t launch_cfg = make_launch_config(no_of_nodes, g_cfg.gpu_cus);

    BFS_TRACE("Allocated managed memory and initialized graph data");

    timing.setup_end_us = bfs_wall_time_us();

    BFS_TRACE("CPU-then-GPU phase start");

    timing.loop_start_us = bfs_wall_time_us();

    BFS_TRACE("CPU batch phase start");
    rodinia_mt_cpu_phase();
    BFS_TRACE("CPU batch phase done");

    BFS_TRACE("GPU batch phase start");
    int iterations = run_gpu_bfs_loop(&graph, &launch_cfg);
    timing.loop_end_us = bfs_wall_time_us();
    
    BFS_TRACE("GPU batch phase done");

    BFS_TRACE("sequential CPU-then-GPU phase done");

    print_timing_summary(&timing, iterations);

    hipDeviceSynchronize();

    // FILE *fpo = fopen("result.txt", "w");
    // for (int i = 0; i < no_of_nodes; i++)
    //     fprintf(fpo, "%d) cost:%d\n", i, graph.h_cost[i]);
    // fclose(fpo);
    // printf("Result stored in result.txt\n");

    free_graph(&graph);
}

int main(int argc, char **argv)
{
    no_of_nodes = 0;
    edge_list_size = 0;

    BFSGraph(argc, argv);

    printf("PASSED!\n");
    return 0;
}
