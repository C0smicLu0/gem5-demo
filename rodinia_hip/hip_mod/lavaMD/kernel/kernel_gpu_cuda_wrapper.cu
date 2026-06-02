#include "./../main.h"                                // needed to recognized input parameters
#include <pthread.h>
#include <stdlib.h>
#include "./../util/device/device.h"                  // needed by for device functions
#include "./../util/timer/timer.h"                    // needed by timer
#include "hip/hip_runtime.h"
#include "./kernel_gpu_cuda_wrapper.h"                // (in the current directory)
#include "./kernel_gpu_cuda.cu"                       // GPU kernel
#include <unistd.h>

#ifdef __linux__
#include <sched.h>
#endif

static const int LAVAMD_REAL_BLOCK_CHUNK = 12;

__global__ void lavamd_gpu_keepalive_kernel(int *buf, int n, int repeat)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int stride = blockDim.x * gridDim.x;

    for (int i = tid; i < n; i += stride) {
        int x = buf[i];

        for (int r = 0; r < repeat; r++) {
            x = (x ^ (r + tid)) + 0x9e3779b9;
            x = x * 1664525 + 1013904223;
        }

        buf[i] = x;
    }
}

static void lavamd_gpu_keepalive(int num_cus)
{
    if (num_cus <= 0)
        return;

    int warmup_threads = NUMBER_THREADS;
    int warmup_blocks = num_cus;
    int warmup_n = warmup_blocks * warmup_threads;

    int *warmup_buf = NULL;

    hipError_t err = hipMallocManaged((void **)&warmup_buf,
                                      sizeof(int) * warmup_n,
                                      hipMemAttachGlobal);
    if (err != hipSuccess) {
        fprintf(stderr, "hipMallocManaged warmup_buf failed: %s\n",
                hipGetErrorString(err));
        exit(-1);
    }

    for (int i = 0; i < warmup_n; i++)
        warmup_buf[i] = i;

    printf("LAVAMD_MT: GPU dummy blocks=%d threads=%d repeat=%d\n",
           warmup_blocks, warmup_threads, 64);

    lavamd_gpu_keepalive_kernel<<<warmup_blocks, warmup_threads>>>(
        warmup_buf, warmup_n, 64);

    err = hipDeviceSynchronize();
    if (err != hipSuccess) {
        fprintf(stderr, "LAVAMD GPU keepalive failed: %s\n",
                hipGetErrorString(err));
        exit(-1);
    }

    hipFree(warmup_buf);
}


//========================================================================================================================================================================================================200
//	KERNEL_GPU_CUDA_WRAPPER FUNCTION
//========================================================================================================================================================================================================200

void
kernel_gpu_cuda_wrapper(int num_cus,
                        par_str par_cpu,
                        dim_str dim_cpu,
                        box_str* box_cpu,
                        FOUR_VECTOR* rv_cpu,
                        fp* qv_cpu,
                        FOUR_VECTOR* fv_cpu)
{
    // timer
    long long time0;
    long long time1;
    long long time2;
    long long time3;
    long long time4;
    long long time5;
    long long time6;

    time0 = get_time();

    hipDeviceSynchronize();

    box_str* d_box_gpu;
    FOUR_VECTOR* d_rv_gpu;
    fp* d_qv_gpu;
    FOUR_VECTOR* d_fv_gpu;

    dim3 threads;
    dim3 blocks;

    //====================================================================================================100
    //	EXECUTION PARAMETERS
    //====================================================================================================100

    blocks.x = dim_cpu.number_boxes;
    blocks.y = 1;

    threads.x = NUMBER_THREADS;                                          // define the number of threads in the block
    threads.y = 1;

    time1 = get_time();

    //======================================================================================================================================================150
    //	GPU MEMORY				(MANAGED)
    //======================================================================================================================================================150

    // The host arrays are already managed, so the GPU reuses the same pointers.
    d_box_gpu = box_cpu;
    d_rv_gpu = rv_cpu;
    d_qv_gpu = qv_cpu;
    d_fv_gpu = fv_cpu;

    time2 = get_time();
    time3 = time2;

    //======================================================================================================================================================150
    //	KERNEL
    //======================================================================================================================================================150

    for (int box_base = 0; box_base < dim_cpu.number_boxes;
         box_base += LAVAMD_REAL_BLOCK_CHUNK) {
        int remaining_boxes = dim_cpu.number_boxes - box_base;
        int launch_blocks = remaining_boxes < LAVAMD_REAL_BLOCK_CHUNK ?
            remaining_boxes : LAVAMD_REAL_BLOCK_CHUNK;
        dim3 batch_blocks;
        batch_blocks.x = launch_blocks;
        batch_blocks.y = 1;

        kernel_gpu_cuda<<<batch_blocks, threads>>>(par_cpu,
                                                   dim_cpu,
                                                   box_base,
                                                   d_box_gpu,
                                                   d_rv_gpu,
                                                   d_qv_gpu,
                                                   d_fv_gpu);

        checkCUDAError("Start");
        // Synchronize after each batch so the real work never has more than
        // 12 blocks in flight at once, while still covering every box.
        hipError_t err = hipDeviceSynchronize();
        if (err != hipSuccess) {
            fprintf(stderr, "lavaMD kernel failed: %s\n",
                    hipGetErrorString(err));
            exit(-1);
        }
    }

    lavamd_gpu_keepalive(num_cus);

    time4 = get_time();

    time5 = time4;
    time6 = time5;

    //======================================================================================================================================================150
    //	DISPLAY TIMING
    //======================================================================================================================================================150

    printf("Time spent in different stages of GPU_CUDA KERNEL:\n");

    printf("%15.12f s, %15.12f %% : GPU: SET DEVICE / DRIVER INIT\n",   (float) (time1-time0) / 1000000, (float) (time1-time0) / (float) (time6-time0) * 100);
    printf("%15.12f s, %15.12f %% : GPU MEM: ALO\n",                    (float) (time2-time1) / 1000000, (float) (time2-time1) / (float) (time6-time0) * 100);
    printf("%15.12f s, %15.12f %% : GPU MEM: COPY IN\n",                (float) (time3-time2) / 1000000, (float) (time3-time2) / (float) (time6-time0) * 100);

    printf("%15.12f s, %15.12f %% : GPU: KERNEL\n",                     (float) (time4-time3) / 1000000, (float) (time4-time3) / (float) (time6-time0) * 100);

    printf("%15.12f s, %15.12f %% : GPU MEM: COPY OUT\n",               (float) (time5-time4) / 1000000, (float) (time5-time4) / (float) (time6-time0) * 100);
    printf("%15.12f s, %15.12f %% : GPU MEM: FRE\n",                    (float) (time6-time5) / 1000000, (float) (time6-time5) / (float) (time6-time0) * 100);

    printf("Total time:\n");
    printf("%.12f s\n",                                                 (float) (time6-time0) / 1000000);
}
