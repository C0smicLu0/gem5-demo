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
#define CPU_EDGE_STRIDE 8

void dump2file(int *adjmatrix, int num_nodes);
void print_vector(int *vector, int num);
void print_vectorf(float *vector, int num);

static void
cpu_shared_load(const csr_array *csr, const int *node_value, int num_nodes,
                int num_edges, int worker_id, int worker_count,
                bool debug_log)
{
    long long local_sum = 0;
    // Spread workers across the vertex set so every worker touches the same
    // shared graph inputs without writing any MIS state.
    for (int tid = worker_id; tid < num_nodes; tid += worker_count) {
        int start = csr->row_array[tid];
        int end = (tid + 1 < num_nodes) ? csr->row_array[tid + 1]
                                        : num_edges;
        local_sum += node_value[tid];
        for (int edge = start; edge < end; edge += CPU_EDGE_STRIDE) {
            local_sum += csr->col_array[edge] & 1;
        }
    }

    if (debug_log) {
        fprintf(stdout,
                "CPU worker %d finished MIS shared load sum=%lld\n",
                worker_id, local_sum);
        fflush(stdout);
    }
}

int
main(int argc, char **argv)
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
    fprintf(stderr, "CHK after parse\n");
    fflush(stderr);

    int cpu_workers = resolve_cpu_workers(options);
    int gpu_cus = resolve_gpu_cus(options);
    bool use_gpu = !options.cpu_only;
    bool use_cpu = !options.gpu_only && cpu_workers > 0;
    if (!use_gpu && !use_cpu) {
        fprintf(stderr, "No CPU or GPU work enabled\n");
        return -1;
    }

    if (options.debug_log) {
        fprintf(stdout,
                "mis mode: cpu_workers=%d gpu=%s gpu_cus=%d\n",
                cpu_workers, use_gpu ? "enabled" : "off", gpu_cus);
        fflush(stdout);
    }

    int *node_value = (int *)malloc(num_nodes * sizeof(int));
    int *s_array = (int *)malloc(num_nodes * sizeof(int));
    if (!node_value || !s_array) {
        fprintf(stderr, "malloc failed for host arrays\n");
        return -1;
    }

    for (int i = 0; i < num_nodes; i++) {
        node_value[i] = rand() % RANGE;
        s_array[i] = 0;
    }

    int *row_d = nullptr;
    int *col_d = nullptr;
    int *c_array_d = nullptr;
    int *c_array_u_d = nullptr;
    int *s_array_d = nullptr;
    int *node_value_d = nullptr;
    int *min_array_d = nullptr;
    int *stop_d = nullptr;

    if (use_gpu) {
        err = hipMalloc(&row_d, num_nodes * sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMalloc row_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
        err = hipMalloc(&col_d, num_edges * sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMalloc col_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
        err = hipMalloc(&stop_d, sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMalloc stop_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
        err = hipMalloc(&min_array_d, num_nodes * sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMalloc min_array_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
        err = hipMalloc(&c_array_d, num_nodes * sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMalloc c_array_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
        err = hipMalloc(&c_array_u_d, num_nodes * sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMalloc c_array_u_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
        err = hipMalloc(&s_array_d, num_nodes * sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMalloc s_array_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
        err = hipMalloc(&node_value_d, num_nodes * sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMalloc node_value_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
    }

    std::vector<std::thread> cpu_threads;
    if (use_cpu) {
        cpu_threads.reserve(cpu_workers);
    }
    fprintf(stderr, "CHK before cpu worker creation\n");
    fflush(stderr);

#ifdef GEM5_FUSION
    m5_work_begin(0, 0);
#endif

#ifdef GEM5_FS
    m5op_addr = 0xFFFF0000;
    map_m5_mem();
    m5_work_begin_addr(0, 0);
#endif

    // Run the CPU shared-load phase first so CPU and GPU do not touch the
    // shared inputs concurrently, while still keeping both phases inside ROI.
    if (use_cpu) {
        for (int worker = 0; worker < cpu_workers; ++worker) {
            cpu_threads.emplace_back(cpu_shared_load, csr, node_value,
                                     num_nodes, num_edges, worker,
                                     cpu_workers, options.debug_log);
        }
        for (auto &thread : cpu_threads) {
            thread.join();
        }
        cpu_threads.clear();
    }

    int iterations = 0;
    if (use_gpu) {
        // After the CPU phase drains, execute the original GPU MIS path.
        err = hipMemcpy(row_d, csr->row_array, num_nodes * sizeof(int),
                        hipMemcpyHostToDevice);
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMemcpy row_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
        err = hipMemcpy(col_d, csr->col_array, num_edges * sizeof(int),
                        hipMemcpyHostToDevice);
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMemcpy col_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }
        err = hipMemcpy(node_value_d, node_value, num_nodes * sizeof(int),
                        hipMemcpyHostToDevice);
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMemcpy node_value_d => %s\n",
                    hipGetErrorString(err));
            return -1;
        }

        int block_size = 128;
        int num_blocks = (num_nodes + block_size - 1) / block_size;
        dim3 threads(block_size, 1, 1);
        dim3 grid(num_blocks, 1, 1);

        hipLaunchKernelGGL(HIP_KERNEL_NAME(init), dim3(grid), dim3(threads), 0,
                           0, s_array_d, c_array_d, c_array_u_d, num_nodes,
                           num_edges);
        hipDeviceSynchronize();
        err = hipGetLastError();
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: init kernel (%s)\n",
                    hipGetErrorString(err));
            return -1;
        }

        int stop = 1;
        while (stop) {
            stop = 0;
            err = hipMemcpy(stop_d, &stop, sizeof(int), hipMemcpyHostToDevice);
            if (err != hipSuccess) {
                fprintf(stderr, "ERROR: write stop_d variable (%s)\n",
                        hipGetErrorString(err));
                return -1;
            }

            hipLaunchKernelGGL(HIP_KERNEL_NAME(mis1), dim3(grid),
                               dim3(threads), 0, 0, row_d, col_d,
                               node_value_d,
                               s_array_d, c_array_d, min_array_d, stop_d,
                               num_nodes, num_edges);

            hipLaunchKernelGGL(HIP_KERNEL_NAME(mis2), dim3(grid),
                               dim3(threads), 0, 0, row_d, col_d,
                               node_value_d,
                               s_array_d, c_array_d, c_array_u_d, min_array_d,
                               num_nodes, num_edges);

            hipLaunchKernelGGL(HIP_KERNEL_NAME(mis3), dim3(grid),
                               dim3(threads), 0, 0, c_array_u_d, c_array_d,
                               num_nodes);

            err = hipMemcpy(&stop, stop_d, sizeof(int), hipMemcpyDeviceToHost);
            if (err != hipSuccess) {
                fprintf(stderr, "ERROR: read stop_d variable (%s)\n",
                        hipGetErrorString(err));
                return -1;
            }

            iterations++;
        }

        hipDeviceSynchronize();
        err = hipMemcpy(s_array, s_array_d, num_nodes * sizeof(int),
                        hipMemcpyDeviceToHost);
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMemcpy s_array_d failed (%s)\n",
                    hipGetErrorString(err));
            return -1;
        }
    }

    for (auto &thread : cpu_threads) {
        thread.join();
    }

#ifdef GEM5_FUSION
    m5_work_end(0, 0);
#endif

#ifdef GEM5_FS
    m5_work_end_addr(0, 0);
    unmap_m5_mem();
#endif

    printf("number of iterations: %d\n", iterations);
    print_vector(s_array, num_nodes);

    free(node_value);
    free(s_array);
    csr->freeArrays();
    free(csr);

    if (use_gpu) {
        hipFree(row_d);
        hipFree(col_d);
        hipFree(c_array_d);
        hipFree(c_array_u_d);
        hipFree(s_array_d);
        hipFree(node_value_d);
        hipFree(min_array_d);
        hipFree(stop_d);
    }

    printf("PASS\n");
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
        fprintf(fp, "%d\n", vector[i]);
    }

    fclose(fp);
}

void print_vectorf(float *vector, int num)
{
    FILE * fp = fopen("result.out", "w");
    if (!fp) {
        printf("ERROR: unable to open result.txt\n");
        return;
    }

    for (int i = 0; i < num; i++) {
        fprintf(fp, "%f\n", vector[i]);
    }

    fclose(fp);
}
