#include "hip/hip_runtime.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <sys/time.h>
#include <pthread.h>
#include <hip/hip_runtime.h>

#ifdef TIMING
#include "timing.h"
#endif

#define MAX_THREADS_PER_BLOCK 512

int no_of_nodes;
int edge_list_size;
FILE *fp;

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

struct Node
{
    int starting;
    int no_of_edges;
};

static inline long long bfs_wall_time_us()
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

#include "kernel.cu"
#include "kernel2.cu"

// ============================================================
// 多 CPU 线程共享访问：多 sharer
// ============================================================
static int  *g_cost_shared   = NULL;
static bool *g_mask_shared   = NULL;
static bool *g_visited_shared = NULL;
static int   g_num_nodes     = 0;
static int   g_num_cpu_threads = 4;
static int   g_share_percent = 8;
static unsigned int g_share_seed = 1;

typedef struct {
    int tid;
    int start;
    int end;
    int iter;
} CpuArg;

static inline unsigned int
bfs_xorshift32(unsigned int *state)
{
    unsigned int x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x ? x : 1;
    return *state;
}

// 每个 CPU 线程只随机访问局部邻域，避免所有线程每轮扫描完整数组。
void *cpu_shared_worker(void *arg)
{
    CpuArg *a = (CpuArg *)arg;
    const int own_count = a->end - a->start;
    if (own_count <= 0 || g_num_nodes <= 0 || g_share_percent <= 0)
        return NULL;

    int sample_count = (own_count * g_share_percent) / 100;
    if (sample_count <= 0)
        sample_count = 1;

    int window_start = a->start - own_count;
    int window_end = a->end + own_count;
    if (window_start < 0)
        window_start = 0;
    if (window_end > g_num_nodes)
        window_end = g_num_nodes;
    const int window_count = window_end - window_start;
    if (window_count <= 0)
        return NULL;

    unsigned int state = g_share_seed
        ^ (unsigned int)(a->tid + 1) * 0x9e3779b9u
        ^ (unsigned int)(a->iter + 1) * 0x85ebca6bu;

    volatile int sum = 0;
    for (int n = 0; n < sample_count; n++) {
        int write_idx = a->start + (int)(bfs_xorshift32(&state) %
                                         (unsigned int)own_count);
        int v = g_cost_shared[write_idx];
        g_cost_shared[write_idx] = v;
    }

    for (int n = 0; n < sample_count; n++) {
        int idx = window_start + (int)(bfs_xorshift32(&state) %
                                       (unsigned int)window_count);
        sum += g_cost_shared[idx];
        sum += (int)g_mask_shared[idx];
        sum += (int)g_visited_shared[idx];
    }
    (void)sum;

    return NULL;
}

void BFSGraph(int argc, char** argv);

int main(int argc, char** argv)
{
    no_of_nodes  = 0;
    edge_list_size = 0;
    BFSGraph(argc, argv);
}

void Usage(int argc, char **argv)
{
    fprintf(stderr,
            "Usage: %s <input_file> [num_cpu_threads] [share_percent] [seed]\n",
            argv[0]);
}

void BFSGraph(int argc, char** argv)
{
    const long long t_total_start_us = bfs_wall_time_us();
    long long t_read_start_us = 0, t_read_end_us = 0;
    long long t_setup_end_us  = 0;
    long long t_loop_start_us = 0, t_loop_end_us = 0;

    char *input_f;
    if (argc < 2) {
        Usage(argc, argv);
        exit(0);
    }
    input_f = argv[1];

    // 可选参数：CPU 线程数
    if (argc >= 3)
        g_num_cpu_threads = atoi(argv[2]);
    if (g_num_cpu_threads <= 0)
        g_num_cpu_threads = 1;
    if (argc >= 4)
        g_share_percent = atoi(argv[3]);
    if (g_share_percent < 0)
        g_share_percent = 0;
    if (g_share_percent > 100)
        g_share_percent = 100;
    if (argc >= 5)
        g_share_seed = (unsigned int)atoi(argv[4]);
    if (g_share_seed == 0)
        g_share_seed = 1;
    printf("BFS_MT: cpu_threads=%d share_percent=%d seed=%u\n",
           g_num_cpu_threads, g_share_percent, g_share_seed);

    printf("Reading File\n");
    t_read_start_us = bfs_wall_time_us();

    fp = fopen(input_f, "r");
    if (!fp) {
        printf("Error Reading graph file\n");
        return;
    }

    int source = 0;
    fscanf(fp, "%d", &no_of_nodes);
    g_num_nodes = no_of_nodes;

    int num_of_blocks = 1;
    int num_of_threads_per_block = no_of_nodes;
    if (no_of_nodes > MAX_THREADS_PER_BLOCK) {
        num_of_blocks = (int)ceil(no_of_nodes / (double)MAX_THREADS_PER_BLOCK);
        num_of_threads_per_block = MAX_THREADS_PER_BLOCK;
    }

    Node* h_graph_nodes =
        (Node*)checked_hip_malloc_managed(sizeof(Node) * no_of_nodes);
    bool *h_graph_mask =
        (bool*)checked_hip_malloc_managed(sizeof(bool) * no_of_nodes);
    bool *h_updating_graph_mask =
        (bool*)checked_hip_malloc_managed(sizeof(bool) * no_of_nodes);
    bool *h_graph_visited =
        (bool*)checked_hip_malloc_managed(sizeof(bool) * no_of_nodes);

    int start, edgeno;
    for (unsigned int i = 0; i < no_of_nodes; i++) {
        fscanf(fp, "%d %d", &start, &edgeno);
        h_graph_nodes[i].starting    = start;
        h_graph_nodes[i].no_of_edges = edgeno;
        h_graph_mask[i]              = false;
        h_updating_graph_mask[i]     = false;
        h_graph_visited[i]           = false;
    }

    fscanf(fp, "%d", &source);
    source = 0;
    h_graph_mask[source]    = true;
    h_graph_visited[source] = true;

    fscanf(fp, "%d", &edge_list_size);

    int id, cost;
    int* h_graph_edges =
        (int*)checked_hip_malloc_managed(sizeof(int) * edge_list_size);
    for (int i = 0; i < edge_list_size; i++) {
        fscanf(fp, "%d", &id);
        fscanf(fp, "%d", &cost);
        h_graph_edges[i] = id;
    }
    if (fp) fclose(fp);

    printf("Read File\n");
    t_read_end_us = bfs_wall_time_us();

#ifdef TIMING
    gettimeofday(&tv_total_start, NULL);
#endif

    Node* d_graph_nodes         = h_graph_nodes;
    int*  d_graph_edges         = h_graph_edges;
    bool* d_graph_mask          = h_graph_mask;
    bool* d_updating_graph_mask = h_updating_graph_mask;
    bool* d_graph_visited       = h_graph_visited;

    int* h_cost = (int*)checked_hip_malloc_managed(sizeof(int) * no_of_nodes);
    for (int i = 0; i < no_of_nodes; i++)
        h_cost[i] = -1;
    h_cost[source] = 0;
    int* d_cost = h_cost;

    bool *d_over = (bool*)checked_hip_malloc_managed(sizeof(bool));

    // 共享给 CPU 线程
    g_cost_shared    = h_cost;
    g_mask_shared    = h_graph_mask;
    g_visited_shared = h_graph_visited;

    printf("Copied Everything to GPU memory\n");
    t_setup_end_us = bfs_wall_time_us();

    // ============================================================
    // 准备 CPU 线程池
    // ============================================================
    pthread_t *cpu_threads =
        (pthread_t*)malloc(g_num_cpu_threads * sizeof(pthread_t));
    CpuArg *cpu_args =
        (CpuArg*)malloc(g_num_cpu_threads * sizeof(CpuArg));
    int chunk = no_of_nodes / g_num_cpu_threads;
    for (int t = 0; t < g_num_cpu_threads; t++) {
        cpu_args[t].tid   = t;
        cpu_args[t].start = t * chunk;
        cpu_args[t].end   = (t == g_num_cpu_threads - 1)
                            ? no_of_nodes : (t + 1) * chunk;
        cpu_args[t].iter  = 0;
    }

    dim3 grid(num_of_blocks, 1, 1);
    dim3 threads(num_of_threads_per_block, 1, 1);

    int  k    = 0;
    bool stop = false;
    printf("Start traversing the tree\n");
    t_loop_start_us = bfs_wall_time_us();

    do {
        stop    = false;
        *d_over = false;

        // ------------------------------------------------------------
        // Phase A：多 CPU 线程局部随机读写，制造更温和的共享访问。
        // ------------------------------------------------------------
        for (int t = 0; t < g_num_cpu_threads; t++)
            cpu_args[t].iter = k;
        for (int t = 0; t < g_num_cpu_threads; t++)
            pthread_create(&cpu_threads[t], NULL,
                           cpu_shared_worker, &cpu_args[t]);
        for (int t = 0; t < g_num_cpu_threads; t++)
            pthread_join(cpu_threads[t], NULL);

        // ------------------------------------------------------------
        // Phase B：GPU BFS kernel
        //          读取 CPU 刚写过的数据，制造 CPU-GPU 冲突
        // ------------------------------------------------------------
        Kernel<<< grid, threads, 0 >>>(
            d_graph_nodes, d_graph_edges,
            d_graph_mask, d_updating_graph_mask,
            d_graph_visited, d_cost, no_of_nodes);

        Kernel2<<< grid, threads, 0 >>>(
            d_graph_mask, d_updating_graph_mask,
            d_graph_visited, d_over, no_of_nodes);

        hipDeviceSynchronize();
        stop = *d_over;
        k++;
    } while (stop);

    t_loop_end_us = bfs_wall_time_us();

    printf("Kernel Executed %d times\n", k);
    printf("\n==================== BFS_MT Timing Summary ====================\n");
    printf("[TIMING] cpu_threads:             %d\n",   g_num_cpu_threads);
    printf("[TIMING] share_percent:           %d\n",   g_share_percent);
    printf("[TIMING] share_seed:              %u\n",   g_share_seed);
    printf("[TIMING] read+parse:              %lld us\n", t_read_end_us - t_read_start_us);
    printf("[TIMING] setup (alloc+init):      %lld us\n", t_setup_end_us - t_read_end_us);
    printf("[TIMING] bfs loop (cpu+gpu+sync): %lld us (iters=%d)\n",
           t_loop_end_us - t_loop_start_us, k);
    if (k > 0)
        printf("[TIMING] avg per iter:            %.2f us/iter\n",
               (double)(t_loop_end_us - t_loop_start_us) / (double)k);
    printf("[TIMING] total runtime:           %lld us\n",
           bfs_wall_time_us() - t_total_start_us);
    printf("===============================================================\n");

    hipDeviceSynchronize();

    FILE *fpo = fopen("result.txt", "w");
    for (int i = 0; i < no_of_nodes; i++)
        fprintf(fpo, "%d) cost:%d\n", i, h_cost[i]);
    fclose(fpo);
    printf("Result stored in result.txt\n");

    hipFree(h_graph_nodes);
    hipFree(h_graph_edges);
    hipFree(h_graph_mask);
    hipFree(h_updating_graph_mask);
    hipFree(h_graph_visited);
    hipFree(h_cost);
    hipFree(d_over);
    free(cpu_threads);
    free(cpu_args);
}
