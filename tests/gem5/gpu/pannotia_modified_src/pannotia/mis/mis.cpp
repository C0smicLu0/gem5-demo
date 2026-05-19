#include "hip/hip_runtime.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <thread>
#include <vector>
#include "../graph_parser/parse.h"
#include "../graph_parser/util.h"
#include "../pannotia_common.h"
#include "kernel.h"

#if defined(GEM5_FUSION) || defined(GEM5_FS)
#include <stdint.h>
#include <gem5/m5ops.h>
#endif

#ifdef GEM5_FS
#include <util/m5/src/m5_mmap.h>
#endif

#define RANGE 2048

void dump2file(int *adjmatrix, int num_nodes);
void print_vector(int *vector, int num);
void print_vectorf(float *vector, int num);

static void
cpu_init_range(int *s_array, int *c_array, int *c_array_u,
               VertexRange range)
{
    for (int tid = range.begin; tid < range.end; ++tid) {
        c_array[tid] = -1;
        c_array_u[tid] = -1;
        s_array[tid] = 0;
    }
}

static void
cpu_mis1_range(const csr_array *csr, int *node_value, int *s_array,
               int *c_array, int *min_array, int num_nodes, int num_edges,
               VertexRange range, int *local_stop)
{
    for (int tid = range.begin; tid < range.end; ++tid) {
        if (c_array[tid] == -1) {
            *local_stop = 1;
            int start = csr->row_array[tid];
            int end = (tid + 1 < num_nodes) ?
                csr->row_array[tid + 1] : num_edges;
            int min = BIGNUM;
            for (int edge = start; edge < end; ++edge) {
                int neighbor = csr->col_array[edge];
                if (c_array[neighbor] == -1 &&
                    node_value[neighbor] < min) {
                    min = node_value[neighbor];
                }
            }
            min_array[tid] = min;
        }
    }
}

static void
cpu_mis2_range(const csr_array *csr, int *node_value, int *s_array,
               int *c_array, int *local_update, int *min_array,
               int num_nodes, int num_edges, VertexRange range)
{
    for (int tid = range.begin; tid < range.end; ++tid) {
        if (node_value[tid] <= min_array[tid] && c_array[tid] == -1) {
            s_array[tid] = 2;

            int start = csr->row_array[tid];
            int end = (tid + 1 < num_nodes) ?
                csr->row_array[tid + 1] : num_edges;

            c_array[tid] = -2;

            for (int edge = start; edge < end; ++edge) {
                int neighbor = csr->col_array[edge];
                if (c_array[neighbor] == -1) {
                    local_update[neighbor] = -2;
                }
            }
        }
    }
}

static void
cpu_mis3_range(int *c_array_u, int *c_array, VertexRange range)
{
    for (int tid = range.begin; tid < range.end; ++tid) {
        if (c_array_u[tid] == -2) {
            c_array[tid] = c_array_u[tid];
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
    convert_csr_to_managed(csr, num_nodes, num_edges);

    int *node_value = managed_int_array(num_nodes, "node_value");
    int *s_array = managed_int_array(num_nodes, "s_array");
    int *c_array = managed_int_array(num_nodes, "c_array");
    int *c_array_u = managed_int_array(num_nodes, "c_array_u");
    int *min_array = managed_int_array(num_nodes, "min_array");
    int *stop_d = managed_int_array(1, "stop");

    for (int i = 0; i < num_nodes; i++) {
        node_value[i] = rand() % RANGE;
        min_array[i] = BIGNUM;
    }

    int cpu_workers = resolve_cpu_workers(options);
    bool use_gpu = !options.cpu_only;
    bool use_cpu = !options.gpu_only && cpu_workers > 0;
    if (!use_gpu && !use_cpu) {
        fprintf(stderr, "No CPU or GPU work enabled\n");
        return -1;
    }

    int active_workers = use_cpu ? std::min(cpu_workers, num_nodes) : 0;
    int gpu_end = compute_gpu_range_end(num_nodes, use_gpu, active_workers,
                                        options.gpu_cus);
    std::vector<VertexRange> cpu_ranges =
        make_cpu_ranges(gpu_end, num_nodes, active_workers);

    if (options.debug_log) {
        fprintf(stdout,
                "mis mode: cpu_workers=%d active=%zu gpu=%s "
                "gpu_range=[0,%d) gpu_cus=%d\n",
                cpu_workers, cpu_ranges.size(), use_gpu ? "enabled" : "off",
                gpu_end, options.gpu_cus);
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

    int block_size = 128;
    dim3 threads(block_size, 1, 1);

    if (use_gpu && gpu_end > 0) {
        int num_blocks = (gpu_end + block_size - 1) / block_size;
        hipLaunchKernelGGL(HIP_KERNEL_NAME(init_range), dim3(num_blocks),
                           dim3(threads), 0, 0, s_array, c_array,
                           c_array_u, 0, gpu_end, num_nodes, num_edges);
    }
    std::vector<std::thread> cpu_threads;
    for (VertexRange range : cpu_ranges) {
        cpu_threads.emplace_back(cpu_init_range, s_array, c_array,
                                 c_array_u, range);
    }
    if (use_gpu) {
        hipDeviceSynchronize();
        err = hipGetLastError();
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: init kernel (%s)\n",
                    hipGetErrorString(err));
            return -1;
        }
    }
    for (auto &thread : cpu_threads) {
        thread.join();
    }

    int stop = 1;
    int iterations = 0;
    while (stop) {
        stop = 0;
        *stop_d = 0;

        std::vector<int> cpu_stops(cpu_ranges.size(), 0);
        cpu_threads.clear();
        for (size_t i = 0; i < cpu_ranges.size(); ++i) {
            cpu_threads.emplace_back(cpu_mis1_range, csr, node_value, s_array,
                                     c_array, min_array, num_nodes, num_edges,
                                     cpu_ranges[i], &cpu_stops[i]);
        }

        if (use_gpu && gpu_end > 0) {
            int num_blocks = (gpu_end + block_size - 1) / block_size;
            hipLaunchKernelGGL(HIP_KERNEL_NAME(mis1_range), dim3(num_blocks),
                               dim3(threads), 0, 0, csr->row_array,
                               csr->col_array, node_value, s_array, c_array,
                               min_array, stop_d, 0, gpu_end, num_nodes,
                               num_edges);
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

        std::vector<std::vector<int>> local_updates(
            cpu_ranges.size(), std::vector<int>(num_nodes, -1));
        cpu_threads.clear();
        for (size_t i = 0; i < cpu_ranges.size(); ++i) {
            cpu_threads.emplace_back(cpu_mis2_range, csr, node_value, s_array,
                                     c_array, local_updates[i].data(),
                                     min_array, num_nodes, num_edges,
                                     cpu_ranges[i]);
        }

        if (use_gpu && gpu_end > 0) {
            int num_blocks = (gpu_end + block_size - 1) / block_size;
            hipLaunchKernelGGL(HIP_KERNEL_NAME(mis2_range), dim3(num_blocks),
                               dim3(threads), 0, 0, csr->row_array,
                               csr->col_array, node_value, s_array, c_array,
                               c_array_u, min_array, 0, gpu_end, num_nodes,
                               num_edges);
        }
        if (use_gpu) {
            hipDeviceSynchronize();
        }
        for (auto &thread : cpu_threads) {
            thread.join();
        }

        for (const auto &local_update : local_updates) {
            for (int i = 0; i < num_nodes; ++i) {
                if (local_update[i] == -2) {
                    c_array_u[i] = -2;
                }
            }
        }

        cpu_threads.clear();
        for (VertexRange range : cpu_ranges) {
            cpu_threads.emplace_back(cpu_mis3_range, c_array_u, c_array,
                                     range);
        }
        if (use_gpu && gpu_end > 0) {
            int num_blocks = (gpu_end + block_size - 1) / block_size;
            hipLaunchKernelGGL(HIP_KERNEL_NAME(mis3_range), dim3(num_blocks),
                               dim3(threads), 0, 0, c_array_u, c_array,
                               0, gpu_end, num_nodes);
        }
        if (use_gpu) {
            hipDeviceSynchronize();
        }
        for (auto &thread : cpu_threads) {
            thread.join();
        }

        iterations++;
    }

#ifdef GEM5_FUSION
    m5_work_end(0, 0);
#endif

#ifdef GEM5_FS
    m5_work_end_addr(0, 0);
    unmap_m5_mem();
#endif

    printf("number of iterations: %d\n", iterations);

#if 1
    print_vector(s_array, num_nodes);
#endif

    hipFree(node_value);
    hipFree(s_array);
    hipFree(c_array);
    hipFree(c_array_u);
    hipFree(min_array);
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
        fprintf(fp, "%d\n", vector[i]);
    }

    fclose(fp);
}

void print_vectorf(float *vector, int num)
{
    FILE * fp = fopen("result.out", "w");
    if (!fp) {
        printf("ERROR: unable to open result.txt\n");
    }

    for (int i = 0; i < num; i++) {
        fprintf(fp, "%f\n", vector[i]);
    }

    fclose(fp);
}
