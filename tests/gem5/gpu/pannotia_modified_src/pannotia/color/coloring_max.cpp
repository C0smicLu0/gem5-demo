#include "hip/hip_runtime.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <thread>
#include <vector>
#include "../graph_parser/parse.h"
#include "../graph_parser/util.h"
#include "../pannotia_common.h"
#include "kernel_max.h"

#if defined(GEM5_FUSION) || defined(GEM5_FS)
#include <stdint.h>
#include <gem5/m5ops.h>
#endif

#ifdef GEM5_FS
#include <util/m5/src/m5_mmap.h>
#endif

#define RANGE 2048

void print_vector(int *vector, int num);

static void
cpu_color1_range(const csr_array *csr, int *node_value, int *color_array,
                 int *max_array, int color, int num_nodes, int num_edges,
                 VertexRange range, int *local_stop)
{
    for (int tid = range.begin; tid < range.end; ++tid) {
        if (color_array[tid] == -1) {
            int start = csr->row_array[tid];
            int end = (tid + 1 < num_nodes) ?
                csr->row_array[tid + 1] : num_edges;
            int maximum = -1;

            for (int edge = start; edge < end; ++edge) {
                if (color_array[csr->col_array[edge]] == -1 &&
                    start != end - 1) {
                    *local_stop = 1;
                    if (node_value[csr->col_array[edge]] > maximum) {
                        maximum = node_value[csr->col_array[edge]];
                    }
                }
            }
            max_array[tid] = maximum;
        }
    }
}

static void
cpu_color2_range(int *node_value, int *color_array, int *max_array,
                 int color, VertexRange range)
{
    for (int tid = range.begin; tid < range.end; ++tid) {
        if (color_array[tid] == -1 && node_value[tid] >= max_array[tid]) {
            color_array[tid] = color;
        }
    }
}

int main(int argc, char **argv)
{
    char *tmpchar;
    int num_nodes;
    int num_edges;
    int file_format;
    bool directed = 0;
    hipError_t err = hipSuccess;
    PannotiaOptions options;

    if (argc >= 3) {
        tmpchar = argv[1];
        file_format = atoi(argv[2]);
        parse_pannotia_options(argc, argv, 3, &options);
    } else {
        fprintf(stderr, "Usage: %s <graph_file> <format> [options]\n", argv[0]);
        exit(1);
    }

    srand(7);

    csr_array *csr;
    if (file_format == 1) {
        csr = parseMetis(tmpchar, &num_nodes, &num_edges, directed);
    } else if (file_format == 0) {
        csr = parseCOO(tmpchar, &num_nodes, &num_edges, directed);
    } else {
        fprintf(stderr, "reserve for future\n");
        exit(1);
    }
    int *node_value = managed_int_array(num_nodes, "node_value");
    int *color = managed_int_array(num_nodes, "color");
    int *max_array = managed_int_array(num_nodes, "max_array");
    int *stop_d = managed_int_array(1, "stop");

    for (int i = 0; i < num_nodes; i++) {
        color[i] = -1;
        max_array[i] = -1;
        node_value[i] = rand() % RANGE;
    }

    int cpu_workers = resolve_cpu_workers(options);
    bool use_gpu = !options.cpu_only;
    bool use_cpu = !options.gpu_only && cpu_workers > 0;
    if (!use_gpu && !use_cpu) {
        fprintf(stderr, "No CPU or GPU work enabled\n");
        return -1;
    }

    int active_workers = use_cpu ? std::min(cpu_workers, num_nodes) : 0;
    int gpu_cus = resolve_gpu_cus(options);
    int gpu_end = compute_gpu_range_end(num_nodes, use_gpu, active_workers,
                                        gpu_cus);
    std::vector<VertexRange> cpu_ranges =
        make_cpu_ranges(gpu_end, num_nodes, active_workers);

    if (options.debug_log) {
        fprintf(stdout,
                "color_max mode: cpu_workers=%d active=%zu gpu=%s "
                "gpu_range=[0,%d) gpu_cus=%d\n",
                cpu_workers, cpu_ranges.size(), use_gpu ? "enabled" : "off",
                gpu_end, gpu_cus);
        fflush(stdout);
    }

#ifdef GEM5_FUSION
    m5_work_begin(0, 0);
#endif

#ifdef GEM5_FS
    m5op_addr = 0xFFFF0000;
    map_m5_mem();
    m5_work_begin_addr(0, 0);
#endif

    int block_size = 256;
    dim3 threads(block_size, 1, 1);
    int stop = 1;
    int graph_color = 1;

    while (stop) {
        stop = 0;
        *stop_d = 0;

        std::vector<int> cpu_stops(cpu_ranges.size(), 0);
        std::vector<std::thread> cpu_threads;
        for (size_t i = 0; i < cpu_ranges.size(); ++i) {
            cpu_threads.emplace_back(cpu_color1_range, csr, node_value, color,
                                     max_array, graph_color, num_nodes,
                                     num_edges, cpu_ranges[i],
                                     &cpu_stops[i]);
        }

        if (use_gpu && gpu_end > 0) {
            int gpu_nodes = gpu_end;
            int num_blocks = (gpu_nodes + block_size - 1) / block_size;
            hipLaunchKernelGGL(HIP_KERNEL_NAME(color1), dim3(num_blocks),
                               dim3(threads), 0, 0, csr->row_array,
                               csr->col_array, node_value, color, stop_d,
                               max_array, graph_color, 0, gpu_end,
                               num_nodes, num_edges);
        }
        if (use_gpu) {
            hipDeviceSynchronize();
        }
        for (auto &thread : cpu_threads) {
            thread.join();
        }
        for (int local_stop : cpu_stops) {
            stop |= local_stop;
        }
        stop |= *stop_d;

        cpu_threads.clear();
        for (VertexRange range : cpu_ranges) {
            cpu_threads.emplace_back(cpu_color2_range, node_value, color,
                                     max_array, graph_color, range);
        }
        if (use_gpu && gpu_end > 0) {
            int gpu_nodes = gpu_end;
            int num_blocks = (gpu_nodes + block_size - 1) / block_size;
            hipLaunchKernelGGL(HIP_KERNEL_NAME(color2), dim3(num_blocks),
                               dim3(threads), 0, 0, node_value, color,
                               max_array, graph_color, 0, gpu_end,
                               num_nodes, num_edges);
        }
        if (use_gpu) {
            hipDeviceSynchronize();
        }
        for (auto &thread : cpu_threads) {
            thread.join();
        }

        graph_color++;
    }

#ifdef GEM5_FUSION
    m5_work_end(0, 0);
#endif

#ifdef GEM5_FS
    m5_work_end_addr(0, 0);
    unmap_m5_mem();
#endif

    printf("total number of colors used: %d\n", graph_color);

#if 1
    print_vector(color, num_nodes);
#endif

    hipFree(node_value);
    hipFree(color);
    hipFree(max_array);
    hipFree(stop_d);
    free_managed_csr(csr);

    return 0;
}

void print_vector(int *vector, int num)
{
    FILE * fp = fopen("result.out", "w");
    if (!fp) {
        printf("ERROR: unable to open result.txt\n");
    }

    for (int i = 0; i < num; i++) {
        fprintf(fp, "%d: %d\n", i + 1, vector[i]);
    }

    fclose(fp);
}
