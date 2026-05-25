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
#define CPU_LOAD_WORDS 4096

void dump2file(int *adjmatrix, int num_nodes);
void print_vector(int *vector, int num);
void print_vectorf(float *vector, int num);

static void
cpu_private_load(int *buffer, int worker_id, int iterations, bool debug_log)
{
    int *worker_buffer = buffer + worker_id * CPU_LOAD_WORDS;
    for (int repeat = 0; repeat < iterations; ++repeat) {
        for (int index = CPU_LOAD_WORDS - 2; index >= 0; --index) {
            worker_buffer[index + 1] = worker_buffer[index] + repeat + index;
        }
    }

    if (debug_log) {
        fprintf(stdout, "CPU worker %d finished MIS private load\n",
                worker_id);
        fflush(stdout);
    }
}

int
main(int argc, char **argv)
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
    int *s_array = managed_int_array(num_nodes, "s_array");
    int *c_array = managed_int_array(num_nodes, "c_array");
    int *c_array_u = managed_int_array(num_nodes, "c_array_u");
    int *min_array = managed_int_array(num_nodes, "min_array");
    int *stop_d = managed_int_array(1, "stop");

    for (int i = 0; i < num_nodes; ++i) {
        node_value[i] = rand() % RANGE;
        s_array[i] = 0;
        c_array[i] = -1;
        c_array_u[i] = -1;
        min_array[i] = BIGNUM;
    }

    int cpu_workers = resolve_cpu_workers(options);
    bool use_gpu = !options.cpu_only;
    bool use_cpu = !options.gpu_only && cpu_workers > 0;
    if (!use_gpu && !use_cpu) {
        fprintf(stderr, "No CPU or GPU work enabled\n");
        return -1;
    }

    if (options.debug_log) {
        fprintf(stdout,
                "mis mode: cpu_workers=%d gpu=%s gpu_cus=%d\n",
                cpu_workers, use_gpu ? "enabled" : "off",
                resolve_gpu_cus(options));
        fflush(stdout);
    }

    int *cpu_load_buffer = nullptr;
    std::vector<std::thread> cpu_threads;
    if (use_cpu) {
        cpu_load_buffer = static_cast<int *>(
            malloc(static_cast<size_t>(cpu_workers) * CPU_LOAD_WORDS *
                   sizeof(int)));
        if (cpu_load_buffer == nullptr) {
            fprintf(stderr, "Failed to allocate cpu_load_buffer\n");
            return -1;
        }

        for (int i = 0; i < cpu_workers * CPU_LOAD_WORDS; ++i) {
            cpu_load_buffer[i] = i;
        }

        cpu_threads.reserve(cpu_workers);
    }

#ifdef GEM5_FUSION
    m5_work_begin(0, 0);
#endif

#ifdef GEM5_FS
    m5op_addr = 0xFFFF0000;
    map_m5_mem();
    m5_work_begin_addr(0, 0);
#endif

    if (use_cpu) {
        for (int worker = 0; worker < cpu_workers; ++worker) {
            cpu_threads.emplace_back(cpu_private_load, cpu_load_buffer,
                                     worker, num_nodes, options.debug_log);
        }
    }

    int block_size = 128;
    dim3 threads(block_size, 1, 1);
    int iterations = 0;

    if (use_gpu) {
        int num_blocks = (num_nodes + block_size - 1) / block_size;

        hipLaunchKernelGGL(HIP_KERNEL_NAME(init), dim3(num_blocks),
                           dim3(threads), 0, 0, s_array, c_array, c_array_u,
                           num_nodes, num_edges);
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
            *stop_d = 0;

            hipLaunchKernelGGL(HIP_KERNEL_NAME(mis1), dim3(num_blocks),
                               dim3(threads), 0, 0, csr->row_array,
                               csr->col_array, node_value, s_array, c_array,
                               min_array, stop_d, num_nodes, num_edges);
            hipDeviceSynchronize();
            stop |= *stop_d;

            hipLaunchKernelGGL(HIP_KERNEL_NAME(mis2), dim3(num_blocks),
                               dim3(threads), 0, 0, csr->row_array,
                               csr->col_array, node_value, s_array, c_array,
                               c_array_u, min_array, num_nodes, num_edges);
            hipDeviceSynchronize();

            hipLaunchKernelGGL(HIP_KERNEL_NAME(mis3), dim3(num_blocks),
                               dim3(threads), 0, 0, c_array_u, c_array,
                               num_nodes);
            hipDeviceSynchronize();

            iterations++;
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

    hipFree(node_value);
    hipFree(s_array);
    hipFree(c_array);
    hipFree(c_array_u);
    hipFree(min_array);
    hipFree(stop_d);
    if (cpu_load_buffer != nullptr) {
        free(cpu_load_buffer);
    }
    free_managed_csr(csr);

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
