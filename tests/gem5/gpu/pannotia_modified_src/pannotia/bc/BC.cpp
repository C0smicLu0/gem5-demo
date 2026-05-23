/************************************************************************************\ 
 *                                                                                  *
 * Copyright � 2014 Advanced Micro Devices, Inc.                                    *
 * Copyright (c) 2015 Mark D. Hill and David A. Wood                                *
 * Copyright (c) 2021 Gaurav Jain and Matthew D. Sinclair                           *
 * All rights reserved.                                                             *
 *                                                                                  *
 * Redistribution and use in source and binary forms, with or without               *
 * modification, are permitted provided that the following are met:                 *
 *                                                                                  *
 * You must reproduce the above copyright notice.                                   *
 *                                                                                  *
 * Neither the name of the copyright holder nor the names of its contributors       *
 * may be used to endorse or promote products derived from this software            *
 * without specific, prior, written permission from at least the copyright holder.  *
 *                                                                                  *
 * You must include the following terms in your license and/or other materials      *
 * provided with the software.                                                      *
 *                                                                                  *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"      *
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE        *
 * IMPLIED WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, AND FITNESS FOR A       *
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER        *
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,         *
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT  *
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS      *
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN          *
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING  *
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY   *
 * OF SUCH DAMAGE.                                                                  *
 *                                                                                  *
 * Without limiting the foregoing, the software may implement third party           *
 * technologies for which you must obtain licenses from parties other than AMD.     *
 * You agree that AMD has not obtained or conveyed to you, and that you shall       *
 * be responsible for obtaining the rights to use and/or distribute the applicable  *
 * underlying intellectual property rights related to the third party technologies. *
 * These third party technologies are not licensed hereunder.                       *
 *                                                                                  *
 * If you use the software (in whole or in part), you shall adhere to all           *
 * applicable U.S., European, and other export laws, including but not limited to   *
 * the U.S. Export Administration Regulations ("EAR") (15 C.F.R Sections 730-774),  *
 * and E.U. Council Regulation (EC) No 428/2009 of 5 May 2009.  Further, pursuant   *
 * to Section 740.6 of the EAR, you hereby certify that, except pursuant to a       *
 * license granted by the United States Department of Commerce Bureau of Industry   *
 * and Security or as otherwise permitted pursuant to a License Exception under     *
 * the U.S. Export Administration Regulations ("EAR"), you will not (1) export,     *
 * re-export or release to a national of a country in Country Groups D:1, E:1 or    *
 * E:2 any restricted technology, software, or source code you receive hereunder,   *
 * or (2) export to Country Groups D:1, E:1 or E:2 the direct product of such       *
 * technology or software, if such foreign produced direct product is subject to    *
 * national security controls as identified on the Commerce Control List (currently *
 * found in Supplement 1 to Part 774 of EAR).  For the most current Country Group   *
 * listings, or for additional information about the EAR or your obligations under  *
 * those regulations, please refer to the U.S. Bureau of Industry and Security's    *
 * website at http://www.bis.doc.gov/.                                              *
 *                                                                                  *
\************************************************************************************/

#include "hip/hip_runtime.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//#include <sys/time.h>
#include <algorithm>
#include <atomic>
#include <functional>
#include <limits.h>
#include <thread>
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

void print_vector(int *vector, int num);
void print_vectorf(float *vector, int num);

struct RuntimeOptions
{
    char *graph_file = nullptr;
    int cpu_workers = -1;
    int gpu_cus = -1;
    int source_chunk = 4;
    bool cpu_only = false;
    bool gpu_only = false;
    bool debug_log = false;
};

static void print_usage(const char *program)
{
    fprintf(stderr,
            "Usage: %s <graph_file> [--cpu-workers N] "
            "[--gpu-cus N] [--source-chunk N] "
            "[--cpu-only|--gpu-only] [--debug-log]\n",
            program);
}

static int parse_int_option(const char *value, const char *name)
{
    char *end = nullptr;
    long parsed = strtol(value, &end, 10);
    if (*value == '\0' || *end != '\0' || parsed < 0 || parsed > INT_MAX) {
        fprintf(stderr, "Invalid value for %s: %s\n", name, value);
        exit(1);
    }
    return static_cast<int>(parsed);
}

static int parse_positive_int_option(const char *value, const char *name)
{
    int parsed = parse_int_option(value, name);
    if (parsed <= 0) {
        fprintf(stderr, "%s must be greater than zero\n", name);
        exit(1);
    }
    return parsed;
}

static RuntimeOptions parse_options(int argc, char **argv)
{
    RuntimeOptions options;

    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--cpu-workers") == 0) {
            if (++i >= argc) {
                print_usage(argv[0]);
                exit(1);
            }
            options.cpu_workers = parse_int_option(argv[i], "--cpu-workers");
        } else if (strcmp(argv[i], "--gpu-cus") == 0) {
            if (++i >= argc) {
                print_usage(argv[0]);
                exit(1);
            }
            options.gpu_cus = parse_positive_int_option(argv[i], "--gpu-cus");
        } else if (strcmp(argv[i], "--source-chunk") == 0) {
            if (++i >= argc) {
                print_usage(argv[0]);
                exit(1);
            }
            options.source_chunk =
                parse_positive_int_option(argv[i], "--source-chunk");
        } else if (strcmp(argv[i], "--cpu-only") == 0) {
            options.cpu_only = true;
        } else if (strcmp(argv[i], "--gpu-only") == 0) {
            options.gpu_only = true;
        } else if (strcmp(argv[i], "--debug-log") == 0) {
            options.debug_log = true;
        } else if (argv[i][0] == '-') {
            print_usage(argv[0]);
            exit(1);
        } else if (!options.graph_file) {
            options.graph_file = argv[i];
        } else {
            print_usage(argv[0]);
            exit(1);
        }
    }

    if (!options.graph_file || (options.cpu_only && options.gpu_only)) {
        print_usage(argv[0]);
        exit(1);
    }

    return options;
}

static int online_cpu_count()
{
    FILE *fp = fopen("/sys/devices/system/cpu/online", "r");
    if (fp) {
        int first = 0;
        int last = 0;
        int matched = fscanf(fp, "%d-%d", &first, &last);
        fclose(fp);

        if (matched == 2 && last >= first) {
            return last - first + 1;
        }
        if (matched == 1) {
            return 1;
        }
    }

    unsigned workers = std::thread::hardware_concurrency();
    return workers == 0 ? 1 : static_cast<int>(workers);
}

static int default_cpu_workers(bool cpu_only)
{
    int cpus = online_cpu_count();
    if (cpu_only) {
        return cpus;
    }

    // The original GPU workload already uses several host contexts through
    // the main thread and ROCm/HSA runtime helper threads.
    return std::max(0, cpus - 3);
}

static int detect_gpu_cus(int fallback)
{
    hipDeviceProp_t prop;
    hipError_t err = hipGetDeviceProperties(&prop, 0);
    if (err == hipSuccess && prop.multiProcessorCount > 0) {
        return prop.multiProcessorCount;
    }

    return fallback;
}

static void run_cpu_sources(const csr_array *csr, int num_nodes, int num_edges,
                            int max_sources, int source_chunk,
                            int initial_begin, int initial_end,
                            std::atomic<int> &next_source,
                            int worker_id,
                            bool debug_log,
                            std::vector<float> &local_bc)
{
    std::vector<int> dist(num_nodes);
    std::vector<float> rho(num_nodes);
    std::vector<float> sigma(num_nodes);
    bool initial_done = initial_begin >= initial_end;

    while (true) {
        int chunk_begin;
        int chunk_end;

        if (!initial_done) {
            chunk_begin = initial_begin;
            chunk_end = initial_end;
            initial_done = true;
        } else {
            chunk_begin =
                next_source.fetch_add(source_chunk, std::memory_order_relaxed);
            if (chunk_begin >= max_sources) {
                if (debug_log) {
                    fprintf(stdout,
                            "CPU worker %d no more chunks, next=%d max=%d\n",
                            worker_id, chunk_begin, max_sources);
                    fflush(stdout);
                }
                break;
            }
            chunk_end = std::min(chunk_begin + source_chunk, max_sources);
        }

        for (int source = chunk_begin; source < chunk_end; ++source) {
            std::fill(dist.begin(), dist.end(), -1);
            std::fill(rho.begin(), rho.end(), 0.0f);
            std::fill(sigma.begin(), sigma.end(), 0.0f);

            dist[source] = 0;
            rho[source] = 1.0f;

            int depth = 0;
            bool stop;
            do {
                stop = false;
                for (int tid = 0; tid < num_nodes; ++tid) {
                    if (dist[tid] != depth) {
                        continue;
                    }

                    int start = csr->row_array[tid];
                    int end = (tid + 1 < num_nodes) ?
                        csr->row_array[tid + 1] : num_edges;

                    for (int edge = start; edge < end; ++edge) {
                        int w = csr->col_array[edge];
                        if (dist[w] < 0) {
                            stop = true;
                            dist[w] = depth + 1;
                        }
                        if (dist[w] == depth + 1) {
                            rho[w] += rho[tid];
                        }
                    }
                }
                ++depth;
            } while (stop);

            while (depth) {
                for (int tid = 0; tid < num_nodes; ++tid) {
                    if (dist[tid] != depth - 1) {
                        continue;
                    }

                    int start = csr->row_array_t[tid];
                    int end = (tid + 1 < num_nodes) ?
                        csr->row_array_t[tid + 1] : num_edges;

                    for (int edge = start; edge < end; ++edge) {
                        int w = csr->col_array_t[edge];
                        if (dist[w] == depth - 2 && rho[tid] != 0.0f) {
                            sigma[w] += rho[w] / rho[tid] * (1 + sigma[tid]);
                        }
                    }

                    if (tid != source) {
                        local_bc[tid] += sigma[tid];
                    }
                }
                --depth;
            }

            if (debug_log) {
                fprintf(stdout, "Completed CPU iteration %d\n", source);
                fflush(stdout);
            }
        }
    }

    if (debug_log) {
        fprintf(stdout, "CPU worker %d exiting\n", worker_id);
        fflush(stdout);
    }
}

int main(int argc, char **argv)
{
    RuntimeOptions options = parse_options(argc, argv);
    if (options.debug_log) {
        setvbuf(stdout, NULL, _IONBF, 0);
        setvbuf(stderr, NULL, _IONBF, 0);
    }
    char *tmpchar = options.graph_file;

    int num_nodes;
    int num_edges;
    bool directed = 1;

    hipError_t err;

    // Parse graph and store it in a CSR format
    csr_array *cpu_csr = parseCOO(tmpchar, &num_nodes, &num_edges, directed);
    csr_array *gpu_csr = nullptr;

    int cpu_workers = options.cpu_workers >= 0 ?
        options.cpu_workers : default_cpu_workers(options.cpu_only);
    if (options.gpu_only) {
        cpu_workers = 0;
    }

    bool use_gpu = !options.cpu_only;
    bool use_cpu = !options.gpu_only && cpu_workers > 0;
    if (use_gpu && options.gpu_cus < 0) {
        options.gpu_cus = detect_gpu_cus(16);
    }
    int max_sources = std::min(num_nodes, MAX_ITERS);
    if (!use_gpu && !use_cpu) {
        fprintf(stderr, "CPU-only mode requires at least one CPU worker\n");
        return -1;
    }

    if (options.debug_log) {
        printf("BC mode: weighted chunk scheduling, max_sources=%d, "
               "cpu_workers=%d, gpu=%s, gpu_cus=%d, source_chunk=%d\n",
               max_sources, cpu_workers, use_gpu ? "enabled" : "disabled",
               options.gpu_cus, options.source_chunk);
    }

    // Create managed buffers shared by host and device.
    float *bc_h = nullptr;
    float *bc_d = nullptr, *sigma_d = nullptr, *rho_d = nullptr;
    int *dist_d = nullptr, *stop_d = nullptr;
    int *row_d = nullptr, *col_d = nullptr;
    int *row_trans_d = nullptr, *col_trans_d = nullptr;

    if (use_gpu) {
        gpu_csr = allocateCSR(num_nodes, num_edges, "gpu_csr");
        copyCSR(gpu_csr, cpu_csr, num_nodes, num_edges);
        row_d = gpu_csr->row_array;
        col_d = gpu_csr->col_array;
        row_trans_d = gpu_csr->row_array_t;
        col_trans_d = gpu_csr->col_array_t;

        // Create betweenness centrality buffers
        err = hipMallocManaged((void **)&bc_d, num_nodes * sizeof(float));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMallocManaged bc_d %s\n", hipGetErrorString(err));
            return -1;
        }
        bc_h = bc_d;

        err = hipMallocManaged((void **)&dist_d, num_nodes * sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMallocManaged dist_d %s\n", hipGetErrorString(err));
            return -1;
        }
        err = hipMallocManaged((void **)&sigma_d, num_nodes * sizeof(float));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMallocManaged sigma_d %s\n", hipGetErrorString(err));
            return -1;
        }
        err = hipMallocManaged((void **)&rho_d, num_nodes * sizeof(float));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMallocManaged rho_d %s\n", hipGetErrorString(err));
            return -1;
        }

        // Create termination variable buffer
        err = hipMallocManaged((void **)&stop_d, sizeof(int));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMallocManaged stop_d %s\n", hipGetErrorString(err));
            return -1;
        }
    } else {
        err = hipMallocManaged((void **)&bc_h, num_nodes * sizeof(float));
        if (err != hipSuccess) {
            fprintf(stderr, "ERROR: hipMallocManaged bc_h %s\n", hipGetErrorString(err));
            return -1;
        }
        for (int i = 0; i < num_nodes; ++i) {
            bc_h[i] = 0.0f;
        }
        bc_d = bc_h;
    }

    //double timer1, timer2;
    //double timer3, timer4;

    //timer1 = gettime();

#ifdef GEM5_FUSION
    m5_work_begin(0, 0);
#endif

#ifdef GEM5_FS
    m5op_addr = 0xFFFF0000;
    map_m5_mem();
    m5_work_begin_addr(0, 0);
#endif

    std::vector<std::vector<float>> cpu_bc;
    std::vector<std::thread> cpu_threads;
    auto ceil_div = [](int value, int divisor) {
        return (value + divisor - 1) / divisor;
    };
    int max_source_chunks = ceil_div(max_sources, options.source_chunk);
    int active_workers = use_cpu ? std::min(cpu_workers, max_source_chunks) : 0;
    // Keep CPU initial assignments conservative. Each active worker starts
    // with one chunk and the shared queue redistributes the remaining sources.
    int cpu_initial_end = use_cpu ?
        std::min(max_sources, active_workers * options.source_chunk) : 0;
    int gpu_initial_begin = cpu_initial_end;
    int gpu_initial_sources = use_gpu ?
        std::min(max_sources - gpu_initial_begin,
                 options.gpu_cus * options.source_chunk) : 0;
    int gpu_initial_end = gpu_initial_begin + gpu_initial_sources;
    std::atomic<int> next_source(gpu_initial_end);

    bool cpu_threads_started = false;
    auto start_cpu_threads = [&]() {
        if (cpu_threads_started || !use_cpu || max_sources <= 0) {
            return;
        }

        cpu_bc.resize(active_workers, std::vector<float>(num_nodes, 0.0f));

        for (int worker = 0; worker < active_workers; ++worker) {
            int initial_begin =
                std::min(worker * options.source_chunk, max_sources);
            int initial_end =
                std::min(initial_begin + options.source_chunk, max_sources);
            cpu_threads.emplace_back(run_cpu_sources, cpu_csr, num_nodes,
                                     num_edges, max_sources,
                                     options.source_chunk,
                                     initial_begin, initial_end,
                                     std::ref(next_source),
                                     worker,
                                     options.debug_log,
                                     std::ref(cpu_bc[worker]));
        }
        cpu_threads_started = true;
    };

    if (use_gpu) {
        //timer3 = gettime();

        // Set up kernel dimensions
        int local_worksize = 128;
        dim3 threads(local_worksize, 1, 1);
        int num_blocks = (num_nodes + local_worksize - 1) / local_worksize;
        dim3 grid(num_blocks, 1, 1);

        // Initialization
        hipLaunchKernelGGL(HIP_KERNEL_NAME(clean_bc), dim3(grid), dim3(threads ), 0, 0, bc_d, num_nodes);
        start_cpu_threads();

        auto run_gpu_sources = [&](int chunk_begin, int chunk_end) {
            for (int i = chunk_begin; i < chunk_end; ++i) {
                hipLaunchKernelGGL(HIP_KERNEL_NAME(clean_1d_array), dim3(grid), dim3(threads ), 0, 0, i, dist_d, sigma_d, rho_d,
                                                    num_nodes);

                // Depth of the traversal
                int dist = 0;
                // Termination variable
                int stop = 1;

                // Traverse the graph from the source node i
                do {
                    stop = 0;

                    *stop_d = stop;

                    hipLaunchKernelGGL(HIP_KERNEL_NAME(bfs_kernel), dim3(grid), dim3(threads ), 0, 0, row_d, col_d, dist_d, rho_d, stop_d,
                                                    num_nodes, num_edges, dist);

                    hipDeviceSynchronize();
                    stop = *stop_d;

                    // Another level
                    dist++;

                } while (stop);

                hipDeviceSynchronize();

                // Traverse back from the deepest part of the tree
                while (dist) {
                    hipLaunchKernelGGL(HIP_KERNEL_NAME(backtrack_kernel), dim3(grid), dim3(threads ), 0, 0, row_trans_d, col_trans_d,
                                                        dist_d, rho_d, sigma_d,
                                                        num_nodes, num_edges, dist, i,
                                                        bc_d);

                    // Back one level
                    dist--;
                }
                hipDeviceSynchronize();
                if (options.debug_log) {
                    fprintf(stdout, "Completed GPU iteration %d\n", i);
                    fflush(stdout);
                }
            }
        };

        run_gpu_sources(gpu_initial_begin, gpu_initial_end);

        // Dynamic compensation loop. GPU takes CU-weighted chunks while CPU
        // workers take source_chunk-sized chunks.
        while (true) {
            int chunk_begin = next_source.fetch_add(
                options.gpu_cus * options.source_chunk,
                std::memory_order_relaxed);
            if (chunk_begin >= max_sources) {
                break;
            }
            int chunk_end = std::min(
                chunk_begin + options.gpu_cus * options.source_chunk,
                max_sources);
            run_gpu_sources(chunk_begin, chunk_end);
        }
        hipDeviceSynchronize();
        if (options.debug_log) {
            fprintf(stdout, "GPU finished all chunks\n");
            fflush(stdout);
        }
    }
    start_cpu_threads();

    if (options.debug_log) {
        fprintf(stdout, "Starting CPU joins, threads=%zu\n",
                cpu_threads.size());
        fflush(stdout);
    }
    for (size_t i = 0; i < cpu_threads.size(); ++i) {
        if (options.debug_log) {
            fprintf(stdout, "Joining CPU worker thread %zu\n", i);
            fflush(stdout);
        }
        cpu_threads[i].join();
        if (options.debug_log) {
            fprintf(stdout, "Joined CPU worker thread %zu\n", i);
            fflush(stdout);
        }
    }
    if (options.debug_log) {
        fprintf(stdout, "CPU joins done\n");
        fflush(stdout);
    }
    //timer4 = gettime();

    if (options.debug_log) {
        fprintf(stdout, "Starting CPU BC merge\n");
        fflush(stdout);
    }
    for (const auto &local_bc : cpu_bc) {
        for (int i = 0; i < num_nodes; ++i) {
            bc_h[i] += local_bc[i];
        }
    }
    if (options.debug_log) {
        fprintf(stdout, "CPU BC merge done\n");
        fflush(stdout);
    }

#ifdef GEM5_FUSION
    if (options.debug_log) {
        fprintf(stdout, "Before m5_work_end\n");
        fflush(stdout);
    }
    m5_work_end(0, 0);
    if (options.debug_log) {
        fprintf(stdout, "After m5_work_end\n");
        fflush(stdout);
    }
#endif

#ifdef GEM5_FS
    if (options.debug_log) {
        fprintf(stdout, "Before m5_work_end_addr\n");
        fflush(stdout);
    }
    m5_work_end_addr(0, 0);
    if (options.debug_log) {
        fprintf(stdout, "After m5_work_end_addr\n");
        fflush(stdout);
        fprintf(stdout, "Before unmap_m5_mem\n");
        fflush(stdout);
    }
    unmap_m5_mem();
    if (options.debug_log) {
        fprintf(stdout, "After unmap_m5_mem\n");
        fflush(stdout);
    }
#endif

    //timer2 = gettime();

    //printf("kernel + memcopy time = %lf ms\n", (timer4 - timer3) * 1000);
    //printf("kernel execution time = %lf ms\n", (timer2 - timer1) * 1000);

#if 1
    //dump the results to the file
    if (options.debug_log) {
        fprintf(stdout, "Before print_vectorf\n");
        fflush(stdout);
    }
    print_vectorf(bc_h, num_nodes);
    if (options.debug_log) {
        fprintf(stdout, "After print_vectorf\n");
        fflush(stdout);
    }
#endif

    // Clean up the host-side buffers
    if (options.debug_log) {
        fprintf(stdout, "Before hipFree bc_h\n");
        fflush(stdout);
    }
    hipFree(bc_h);
    if (options.debug_log) {
        fprintf(stdout, "After hipFree bc_h\n");
        fflush(stdout);
        fprintf(stdout, "Before hipFree CSR arrays\n");
        fflush(stdout);
    }
    freeCSR(cpu_csr);
    freeCSR(gpu_csr);
    if (options.debug_log) {
        fprintf(stdout, "After hipFree CSR arrays\n");
        fflush(stdout);
    }

    // Clean up the device-side buffers
    if (use_gpu) {
        if (options.debug_log) {
            fprintf(stdout, "Before hipFree GPU work buffers\n");
            fflush(stdout);
        }
        if (bc_d != bc_h) {
            hipFree(bc_d);
        }
        hipFree(dist_d);
        hipFree(sigma_d);
        hipFree(rho_d);
        hipFree(stop_d);
        if (options.debug_log) {
            fprintf(stdout, "After hipFree GPU work buffers\n");
            fflush(stdout);
        }
    }

    if (options.debug_log) {
        fprintf(stdout, "BC workload finished\n");
        fflush(stdout);
    }
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

    FILE * fp = fopen("result.out", "w");
    if (!fp) {
        printf("ERROR: unable to open result.txt\n");
    }

    for (int i = 0; i < num; i++) {
        fprintf(fp, "%f\n", vector[i]);
    }

    fclose(fp);

}
