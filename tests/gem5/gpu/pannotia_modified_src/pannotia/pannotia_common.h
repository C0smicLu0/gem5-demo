#ifndef PANNOTIA_COMMON_H
#define PANNOTIA_COMMON_H

#include "hip/hip_runtime.h"
#include <algorithm>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <thread>
#include <vector>

struct PannotiaOptions
{
    int cpu_workers = 0;
    int gpu_cus = -1;
    bool cpu_only = false;
    bool gpu_only = false;
    bool debug_log = false;
};

struct VertexRange
{
    int begin;
    int end;
};

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

static void parse_pannotia_options(int argc, char **argv, int first_option,
                                   PannotiaOptions *options)
{
    for (int i = first_option; i < argc; ++i) {
        if (strcmp(argv[i], "--cpu-workers") == 0) {
            if (++i >= argc) {
                fprintf(stderr, "Missing value for --cpu-workers\n");
                exit(1);
            }
            options->cpu_workers = parse_int_option(argv[i], "--cpu-workers");
        } else if (strcmp(argv[i], "--gpu-cus") == 0) {
            if (++i >= argc) {
                fprintf(stderr, "Missing value for --gpu-cus\n");
                exit(1);
            }
            options->gpu_cus = parse_positive_int_option(argv[i], "--gpu-cus");
        } else if (strcmp(argv[i], "--cpu-only") == 0) {
            options->cpu_only = true;
        } else if (strcmp(argv[i], "--gpu-only") == 0) {
            options->gpu_only = true;
        } else if (strcmp(argv[i], "--debug-log") == 0) {
            options->debug_log = true;
        } else {
            fprintf(stderr, "Unknown option: %s\n", argv[i]);
            exit(1);
        }
    }

    if (options->cpu_only && options->gpu_only) {
        fprintf(stderr, "--cpu-only and --gpu-only cannot be used together\n");
        exit(1);
    }

    if (options->cpu_only && options->cpu_workers == 0) {
        fprintf(stderr,
                "--cpu-only requires --cpu-workers N with N > 0\n");
        exit(1);
    }

    if (!options->cpu_only && !options->gpu_only &&
        options->cpu_workers > 0 && options->gpu_cus <= 0) {
        fprintf(stderr,
                "CPU+GPU mode requires explicit --gpu-cus N when "
                "--cpu-workers is non-zero\n");
        exit(1);
    }
}

static void *checked_hip_malloc_managed(size_t bytes, const char *name)
{
    void *ptr = nullptr;
    hipError_t err = hipMallocManaged(&ptr, bytes);
    if (err != hipSuccess) {
        fprintf(stderr, "ERROR: hipMallocManaged %s %s\n", name,
                hipGetErrorString(err));
        exit(1);
    }
    return ptr;
}

static int *managed_int_array(size_t count, const char *name)
{
    return (int *)checked_hip_malloc_managed(count * sizeof(int), name);
}

static void free_managed_csr(csr_array *csr)
{
    if (csr->row_array) {
        hipFree(csr->row_array);
    }
    if (csr->col_array) {
        hipFree(csr->col_array);
    }
    if (csr->data_array) {
        hipFree(csr->data_array);
    }
    if (csr->col_cnt) {
        hipFree(csr->col_cnt);
    }
    free(csr);
}

static int resolve_cpu_workers(const PannotiaOptions &options)
{
    int workers = options.cpu_workers;
    if (options.gpu_only) {
        workers = 0;
    }
    return workers;
}

static int resolve_gpu_cus(const PannotiaOptions &options)
{
    return options.gpu_cus;
}

static int compute_gpu_range_end(int num_nodes, bool use_gpu,
                                 int active_workers, int gpu_cus)
{
    if (!use_gpu) {
        return 0;
    }
    if (active_workers <= 0) {
        return num_nodes;
    }

    long long weighted =
        (long long)num_nodes * (long long)gpu_cus;
    int gpu_end = (int)(weighted / (gpu_cus + active_workers));
    if (gpu_end < 0) {
        return 0;
    }
    if (gpu_end > num_nodes) {
        return num_nodes;
    }
    return gpu_end;
}

static std::vector<VertexRange> make_cpu_ranges(int begin, int end,
                                                int workers)
{
    std::vector<VertexRange> ranges;
    if (workers <= 0 || begin >= end) {
        return ranges;
    }

    int total = end - begin;
    int active = std::min(workers, total);
    ranges.reserve(active);
    for (int worker = 0; worker < active; ++worker) {
        int rb = begin + (total * worker) / active;
        int re = begin + (total * (worker + 1)) / active;
        ranges.push_back({rb, re});
    }
    return ranges;
}

static void debug_log(const PannotiaOptions &options, const char *message)
{
    if (options.debug_log) {
        fprintf(stdout, "%s\n", message);
        fflush(stdout);
    }
}

#endif
