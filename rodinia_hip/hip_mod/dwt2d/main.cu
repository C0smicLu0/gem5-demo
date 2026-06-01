/*
 * Copyright (c) 2009, Jiri Matela
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include "hip/hip_runtime.h"
#include <unistd.h>
#include <error.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <sys/time.h>
#include <pthread.h>
#include <getopt.h>

#ifdef __linux__
#include <sched.h>
#endif

#if defined(GEM5_FUSION) || defined(GEM5_FS)
#include <gem5/m5ops.h>
#endif

#ifdef GEM5_FS
#include <util/m5/src/m5_mmap.h>
#endif

#ifndef DWT2D_TRACE
#define DWT2D_TRACE 1
#endif

#if DWT2D_TRACE
#define DWT2D_LOG(fmt, ...) do { \
    struct timeval _dwt2d_tv; \
    gettimeofday(&_dwt2d_tv, NULL); \
    printf("[DWT2D][%ld.%06ld][%s:%d] " fmt "\n", \
           (long)_dwt2d_tv.tv_sec, (long)_dwt2d_tv.tv_usec, \
           __func__, __LINE__, ##__VA_ARGS__); \
    fflush(stdout); \
} while (0)
#else
#define DWT2D_LOG(fmt, ...) do { } while (0)
#endif

#include "common.h"
#include "components.h"
#include "dwt.h"

#ifndef _COMPONENTS_H
#define _COMPONENTS_H

/* Separate compoents of source 8bit RGB image */
template<typename T>
void rgbToComponents(T *d_r, T *d_g, T *d_b, unsigned char * src, int width, int height);

/* Copy a 8bit source image data into a color compoment of type T */
template<typename T>
void bwToComponent(T *d_c, unsigned char * src, int width, int height);

#endif
struct dwt {
    char * srcFilename;
    char * outFilename;
    unsigned char *srcImg;
    int pixWidth;
    int pixHeight;
    int components;
    int dwtLvls;
};

int getImg(char * srcFilename, unsigned char *srcImg, int inputSize)
{
    DWT2D_LOG("getImg begin: src=%s inputSize=%d", srcFilename, inputSize);
    // printf("Loading ipnput: %s\n", srcFilename);
    char *path = "../../data/dwt2d/";
    char *newSrc = NULL;

    // Only prepend the default dataset path when the user passes a bare filename.
    // If they pass an absolute/relative path (contains '/'), use it as-is.
    if (strchr(srcFilename, '/') == NULL) {
        if ((newSrc = (char *)malloc(strlen(srcFilename) + strlen(path) + 1)) != NULL) {
            newSrc[0] = '\0';
            strcat(newSrc, path);
            strcat(newSrc, srcFilename);
            srcFilename = newSrc;
        }
    }
    printf("Loading ipnput: %s\n", srcFilename);

    //srcFilename = strcat("../../data/dwt2d/",srcFilename);
    //read image
    int i = open(srcFilename, O_RDONLY, 0644);
    if (i == -1) {
        error(0,errno,"cannot access %s", srcFilename);
        free(newSrc);
        return -1;
    }
    DWT2D_LOG("input file opened");
    int ret = read(i, srcImg, inputSize);
    printf("precteno %d, inputsize %d\n", ret, inputSize);
    DWT2D_LOG("input file read complete: read=%d expected=%d", ret, inputSize);
    close(i);
    free(newSrc);

    DWT2D_LOG("getImg end");
    return 0;
}


void usage() {
    printf("dwt [otpions] src_img.rgb <out_img.dwt>\n\
  -d, --dimension\t\tdimensions of src img, e.g. 1920x1080\n\
  -c, --components\t\tnumber of color components, default 3\n\
  -b, --depth\t\t\tbit depth, default 8\n\
  -l, --level\t\t\tDWT level, default 3\n\
  -D, --device\t\t\tcuda device\n\
  -f, --forward\t\t\tforward transform\n\
  -r, --reverse\t\t\treverse transform\n\
  -9, --97\t\t\t9/7 transform\n\
  -5, --53\t\t\t5/3 transform\n\
  -t, --cpu-workers\t\tCPU dummy worker threads before the real GPU DWT\n\
  -u, --gpu-cus\t\t\tGPU CU count used to size the post-DWT GPU dummy phase\n\
  -w  --write-visual\t\twrite output in visual (tiled) fashion instead of the linear\n");
}

template <typename T>
void processDWT(struct dwt *d, int forward, int writeVisual)
{
    int componentSize = d->pixWidth*d->pixHeight*sizeof(T);
    DWT2D_LOG("processDWT begin: width=%d height=%d components=%d levels=%d forward=%d writeVisual=%d sizeof(T)=%zu componentSize=%d",
              d->pixWidth, d->pixHeight, d->components, d->dwtLvls,
              forward, writeVisual, sizeof(T), componentSize);

	T *c_r_out, *backup ;
	// 原来：c_r_out/backup 等在 device，host 端还有一份数据，需要 hipMemcpy(H2D/D2H)
	// 现在：统一内存 managed 分配，CPU/GPU 共享同一份数据，省去显式拷贝
    DWT2D_LOG("alloc c_r_out begin");
	c_r_out = (T *)checked_hip_malloc_managed(componentSize);
	cudaCheckError("Alloc device memory");
    DWT2D_LOG("alloc c_r_out end: ptr=%p", (void *)c_r_out);
	hipMemset(c_r_out, 0, componentSize);
	cudaCheckError("Memset device memory");
    DWT2D_LOG("memset c_r_out end");

    DWT2D_LOG("alloc backup begin");
	backup = (T *)checked_hip_malloc_managed(componentSize);
	cudaCheckError("Alloc device memory");
    DWT2D_LOG("alloc backup end: ptr=%p", (void *)backup);
	hipMemset(backup, 0, componentSize);
	cudaCheckError("Memset device memory");
    DWT2D_LOG("memset backup end");

	if (d->components == 3) {
        DWT2D_LOG("enter RGB branch");
		/* Alloc two more buffers for G and B */
		// 原来：c_g_out/c_b_out 与 c_r_out 类似，需要 host/device 两份 + hipMemcpy
		// 现在：统一内存 managed，一份指针贯通 CPU/GPU
		T *c_g_out, *c_b_out;
        DWT2D_LOG("alloc c_g_out begin");
		c_g_out = (T *)checked_hip_malloc_managed(componentSize);
		cudaCheckError("Alloc device memory");
        DWT2D_LOG("alloc c_g_out end: ptr=%p", (void *)c_g_out);
		hipMemset(c_g_out, 0, componentSize);
		cudaCheckError("Memset device memory");
        DWT2D_LOG("memset c_g_out end");

        DWT2D_LOG("alloc c_b_out begin");
		c_b_out = (T *)checked_hip_malloc_managed(componentSize);
		cudaCheckError("Alloc device memory");
        DWT2D_LOG("alloc c_b_out end: ptr=%p", (void *)c_b_out);
		hipMemset(c_b_out, 0, componentSize);
		cudaCheckError("Memset device memory");
        DWT2D_LOG("memset c_b_out end");

		/* Load components */
		// 原来：c_r/c_g/c_b 需要 H2D 拷贝
		// 现在：managed 内存，直接在 GPU kernel 中访问
		T *c_r, *c_g, *c_b;
        DWT2D_LOG("alloc c_r begin");
		c_r = (T *)checked_hip_malloc_managed(componentSize);
		cudaCheckError("Alloc device memory");
        DWT2D_LOG("alloc c_r end: ptr=%p", (void *)c_r);
		hipMemset(c_r, 0, componentSize);
		cudaCheckError("Memset device memory");
        DWT2D_LOG("memset c_r end");

        DWT2D_LOG("alloc c_g begin");
		c_g = (T *)checked_hip_malloc_managed(componentSize);
		cudaCheckError("Alloc device memory");
        DWT2D_LOG("alloc c_g end: ptr=%p", (void *)c_g);
		hipMemset(c_g, 0, componentSize);
		cudaCheckError("Memset device memory");
        DWT2D_LOG("memset c_g end");

        DWT2D_LOG("alloc c_b begin");
		c_b = (T *)checked_hip_malloc_managed(componentSize);
		cudaCheckError("Alloc device memory");
        DWT2D_LOG("alloc c_b end: ptr=%p", (void *)c_b);
		hipMemset(c_b, 0, componentSize);
		cudaCheckError("Memset device memory");
        DWT2D_LOG("memset c_b end");

        DWT2D_LOG("rgbToComponents begin");
        rgbToComponents(c_r, c_g, c_b, d->srcImg, d->pixWidth, d->pixHeight);
        DWT2D_LOG("rgbToComponents end");


        /* Compute DWT and always store into file */

        DWT2D_LOG("nStage2dDWT R begin");
        nStage2dDWT(c_r, c_r_out, backup, d->pixWidth, d->pixHeight, d->dwtLvls, forward);
        DWT2D_LOG("nStage2dDWT R end");
        DWT2D_LOG("nStage2dDWT G begin");
        nStage2dDWT(c_g, c_g_out, backup, d->pixWidth, d->pixHeight, d->dwtLvls, forward);
        DWT2D_LOG("nStage2dDWT G end");
        DWT2D_LOG("nStage2dDWT B begin");
        nStage2dDWT(c_b, c_b_out, backup, d->pixWidth, d->pixHeight, d->dwtLvls, forward);
        DWT2D_LOG("nStage2dDWT B end");

        // -------test----------
        // T *h_r_out=(T*)malloc(componentSize);
		// hipMemcpy(h_r_out, c_g_out, componentSize, hipMemcpyDeviceToHost);
        // int ii;
		// for(ii=0;ii<componentSize/sizeof(T);ii++) {
			// fprintf(stderr, "%d ", h_r_out[ii]);
			// if((ii+1) % (d->pixWidth) == 0) fprintf(stderr, "\n");
        // }
        // -------test----------


        /* Store DWT to file */
#ifdef OUTPUT
        DWT2D_LOG("write RGB outputs begin");
        if (writeVisual) {
            writeNStage2DDWT(c_r_out, d->pixWidth, d->pixHeight, d->dwtLvls, d->outFilename, ".r");
            writeNStage2DDWT(c_g_out, d->pixWidth, d->pixHeight, d->dwtLvls, d->outFilename, ".g");
            writeNStage2DDWT(c_b_out, d->pixWidth, d->pixHeight, d->dwtLvls, d->outFilename, ".b");
        } else {
            writeLinear(c_r_out, d->pixWidth, d->pixHeight, d->outFilename, ".r");
            writeLinear(c_g_out, d->pixWidth, d->pixHeight, d->outFilename, ".g");
            writeLinear(c_b_out, d->pixWidth, d->pixHeight, d->outFilename, ".b");
        }
        DWT2D_LOG("write RGB outputs end");
#endif

        DWT2D_LOG("free RGB buffers begin");
        hipFree(c_r);
        cudaCheckError("Cuda free");
        hipFree(c_g);
        cudaCheckError("Cuda free");
        hipFree(c_b);
        cudaCheckError("Cuda free");
        hipFree(c_g_out);
        cudaCheckError("Cuda free");
        hipFree(c_b_out);
        cudaCheckError("Cuda free");
        DWT2D_LOG("free RGB buffers end");

    }
	else if (d->components == 1) {
        DWT2D_LOG("enter single-component branch");
		//Load component
		T *c_r;
        DWT2D_LOG("alloc c_r begin");
		c_r = (T *)checked_hip_malloc_managed(componentSize);
		cudaCheckError("Alloc device memory");
        DWT2D_LOG("alloc c_r end: ptr=%p", (void *)c_r);
		hipMemset(c_r, 0, componentSize);
		cudaCheckError("Memset device memory");
        DWT2D_LOG("memset c_r end");

        DWT2D_LOG("bwToComponent begin");
        bwToComponent(c_r, d->srcImg, d->pixWidth, d->pixHeight);
        DWT2D_LOG("bwToComponent end");

        // Compute DWT
        DWT2D_LOG("nStage2dDWT single begin");
        nStage2dDWT(c_r, c_r_out, backup, d->pixWidth, d->pixHeight, d->dwtLvls, forward);
        DWT2D_LOG("nStage2dDWT single end");

        // Store DWT to file
// #ifdef OUTPUT
        DWT2D_LOG("write single output begin");
        if (writeVisual) {
            writeNStage2DDWT(c_r_out, d->pixWidth, d->pixHeight, d->dwtLvls, d->outFilename, ".out");
        } else {
            writeLinear(c_r_out, d->pixWidth, d->pixHeight, d->outFilename, ".lin.out");
        }
        DWT2D_LOG("write single output end");
// #endif
        DWT2D_LOG("free single buffer begin");
        hipFree(c_r);
        cudaCheckError("Cuda free");
        DWT2D_LOG("free single buffer end");
    }

    DWT2D_LOG("free base buffers begin");
    hipFree(c_r_out);
    cudaCheckError("Cuda free device");
    hipFree(backup);
    cudaCheckError("Cuda free device");
    DWT2D_LOG("free base buffers end");
    DWT2D_LOG("processDWT end");
}

typedef struct {
    int tid;
    int active_threads;
    volatile unsigned char *shared_read;
    size_t shared_bytes;
    unsigned int *private_write;
    size_t private_elems;
    unsigned int sink;
} dwt2d_cpu_dummy_arg_t;

static volatile int dwt2d_cpu_ready_count = 0;
static volatile int dwt2d_cpu_start_flag = 0;

#ifndef DWT2D_CPU_SHARED_STRIDE
#define DWT2D_CPU_SHARED_STRIDE 16ULL
#endif

#ifndef DWT2D_CPU_READ_LIMIT
#define DWT2D_CPU_READ_LIMIT (1ULL << 20)
#endif

#ifndef DWT2D_CPU_PRIVATE_ELEMS
#define DWT2D_CPU_PRIVATE_ELEMS 1024ULL
#endif

#ifndef DWT2D_CPU_COMPUTE_ROUNDS
#define DWT2D_CPU_COMPUTE_ROUNDS 32
#endif

static void *dwt2d_cpu_dummy_worker(void *opaque)
{
    dwt2d_cpu_dummy_arg_t *a = (dwt2d_cpu_dummy_arg_t *)opaque;
    volatile unsigned char *shared = a->shared_read;
    unsigned int *priv = a->private_write;
    unsigned int acc = (unsigned int)(a->tid + 1);

    __sync_fetch_and_add(&dwt2d_cpu_ready_count, 1);

    while (!dwt2d_cpu_start_flag) {
        sched_yield();
    }

    size_t slice_begin =
        (a->shared_bytes * (size_t)a->tid) / (size_t)a->active_threads;
    size_t slice_end =
        (a->shared_bytes * (size_t)(a->tid + 1)) / (size_t)a->active_threads;
    size_t slice_size = slice_end > slice_begin ? (slice_end - slice_begin) : 0;
    size_t scan_elems =
        slice_size < DWT2D_CPU_READ_LIMIT ? slice_size : DWT2D_CPU_READ_LIMIT;

    for (size_t n = 0; n < scan_elems; n += DWT2D_CPU_SHARED_STRIDE) {
        size_t read_idx = slice_begin + n;
        unsigned int v = (unsigned int)shared[read_idx];
        size_t write_idx = (n / DWT2D_CPU_SHARED_STRIDE) % a->private_elems;
        priv[write_idx] = v + (unsigned int)n + (unsigned int)a->tid;
        acc += priv[write_idx];
        acc = acc * 1664525u + 1013904223u;
    }

    for (int round = 0; round < DWT2D_CPU_COMPUTE_ROUNDS; round++) {
        size_t write_idx = (size_t)round % a->private_elems;
        acc ^= priv[write_idx] + (unsigned int)round;
        acc = acc * 1103515245u + 12345u;
    }

    for (int tail = 0; tail < a->tid; tail++) {
        size_t write_idx = (size_t)(tail + a->tid) % a->private_elems;
        acc ^= priv[write_idx] + (unsigned int)(tail * 17 + a->tid);
        acc = acc * 1664525u + 1013904223u;
    }

    a->sink = acc;
    DWT2D_LOG("CPU dummy worker end: tid=%d slice=%zu..%zu sink=%u",
              a->tid, slice_begin, slice_end, a->sink);
    return NULL;
}

static void dwt2d_cpu_dummy_phase(void *shared, size_t shared_bytes, int worker_count)
{
    DWT2D_LOG("CPU dummy phase enter: shared=%p bytes=%zu workers=%d",
              shared, shared_bytes, worker_count);
    if (worker_count <= 0 || shared == NULL || shared_bytes == 0) {
        DWT2D_LOG("CPU dummy phase skipped");
        return;
    }

    pthread_t *threads =
        (pthread_t *)malloc((size_t)worker_count * sizeof(pthread_t));
    dwt2d_cpu_dummy_arg_t *args =
        (dwt2d_cpu_dummy_arg_t *)malloc((size_t)worker_count *
                                        sizeof(dwt2d_cpu_dummy_arg_t));
    unsigned int *private_buf =
        (unsigned int *)malloc((size_t)worker_count *
                               DWT2D_CPU_PRIVATE_ELEMS *
                               sizeof(unsigned int));

    if (!threads || !args || !private_buf) {
        fprintf(stderr, "dwt2d CPU dummy allocation failed\n");
        free(threads);
        free(args);
        free(private_buf);
        exit(-1);
    }

    for (size_t i = 0;
         i < (size_t)worker_count * DWT2D_CPU_PRIVATE_ELEMS;
         i++) {
        private_buf[i] = 0;
    }

    dwt2d_cpu_ready_count = 0;
    dwt2d_cpu_start_flag = 0;

    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 256 * 1024);
    DWT2D_LOG("CPU dummy pthread stack size set");

    for (int t = 0; t < worker_count; t++) {
        args[t].tid = t;
        args[t].active_threads = worker_count;
        args[t].shared_read = (volatile unsigned char *)shared;
        args[t].shared_bytes = shared_bytes;
        args[t].private_write =
            private_buf + (size_t)t * DWT2D_CPU_PRIVATE_ELEMS;
        args[t].private_elems = DWT2D_CPU_PRIVATE_ELEMS;
        args[t].sink = 0;

        int rc = pthread_create(&threads[t], &attr,
                                dwt2d_cpu_dummy_worker, &args[t]);
        if (rc != 0) {
            fprintf(stderr, "pthread_create failed at thread %d, rc=%d\n", t, rc);
            exit(1);
        }
        DWT2D_LOG("CPU dummy pthread_create ok: tid=%d", t);
    }

    while (dwt2d_cpu_ready_count < worker_count) {
        sched_yield();
    }
    DWT2D_LOG("CPU dummy all workers ready: count=%d", worker_count);
    dwt2d_cpu_start_flag = 1;
    DWT2D_LOG("CPU dummy start flag released");

    for (int t = 0; t < worker_count; t++) {
        DWT2D_LOG("CPU dummy pthread_join begin: tid=%d", t);
        pthread_join(threads[t], NULL);
        DWT2D_LOG("CPU dummy pthread_join end: tid=%d sink=%u", t, args[t].sink);
    }

    pthread_attr_destroy(&attr);
    free(private_buf);
    free(threads);
    free(args);
    DWT2D_LOG("CPU dummy phase exit");
}

__global__ static void dwt2d_gpu_dummy_kernel(int *buf, int n, int repeat)
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

static void dwt2d_gpu_dummy_phase(int num_cus)
{
    DWT2D_LOG("GPU dummy phase enter: requested_cus=%d", num_cus);
    if (num_cus <= 0) {
        DWT2D_LOG("GPU dummy phase skipped");
        return;
    }

    int blocks = num_cus;
    int threads = 256;
    int n = blocks * threads;
    int *buf = NULL;

    hipError_t err =
        hipMallocManaged((void **)&buf, sizeof(int) * (size_t)n, hipMemAttachGlobal);
    if (err != hipSuccess) {
        fprintf(stderr, "hipMallocManaged GPU dummy failed: %s\n",
                hipGetErrorString(err));
        exit(-1);
    }

    for (int i = 0; i < n; i++) {
        buf[i] = i;
    }

    DWT2D_LOG("GPU dummy launch: blocks=%d threads=%d elements=%d repeat=%d",
              blocks, threads, n, 64);
    dwt2d_gpu_dummy_kernel<<<blocks, threads>>>(buf, n, 64);
    err = hipDeviceSynchronize();
    if (err != hipSuccess) {
        fprintf(stderr, "dwt2d GPU dummy failed: %s\n",
                hipGetErrorString(err));
        exit(-1);
    }

    hipFree(buf);
    DWT2D_LOG("GPU dummy phase exit");
}

int main(int argc, char **argv)
{
    DWT2D_LOG("main begin: argc=%d", argc);
    int optindex = 0;
    char ch;
    struct option longopts[] = {
        {"dimension",   required_argument, 0, 'd'}, //dimensions of src img
        {"components",  required_argument, 0, 'c'}, //numger of components of src img
        {"depth",       required_argument, 0, 'b'}, //bit depth of src img
        {"level",       required_argument, 0, 'l'}, //level of dwt
        {"device",      required_argument, 0, 'D'}, //cuda device
        {"forward",     no_argument,       0, 'f'}, //forward transform
        {"reverse",     no_argument,       0, 'r'}, //reverse transform
        {"97",          no_argument,       0, '9'}, //9/7 transform
        {"53",          no_argument,       0, '5' }, //5/3transform
        {"cpu-workers", required_argument, 0, 't'},
        {"gpu-cus",     required_argument, 0, 'u'},
        {"write-visual",no_argument,       0, 'w' }, //write output (subbands) in visual (tiled) order instead of linear
        {"help",        no_argument,       0, 'h'}
    };

    int pixWidth    = 0; //<real pixWidth
    int pixHeight   = 0; //<real pixHeight
    int compCount   = 3; //number of components; 3 for RGB or YUV, 4 for RGBA
    int bitDepth    = 8;
    int dwtLvls     = 3; //default numuber of DWT levels
    int device      = 0;
    int cpuWorkers  = 0;
    int gpuCus      = 0;
    int forward     = 1; //forward transform
    int dwt97       = 1; //1=dwt9/7, 0=dwt5/3 transform
    int writeVisual = 0; //write output (subbands) in visual (tiled) order instead of linear
    char * pos;

    while ((ch = getopt_long(argc, argv, "d:c:b:l:D:fr95t:u:wh", longopts, &optindex)) != -1) {
        switch (ch) {
        case 'd':
            pixWidth = atoi(optarg);
            pos = strstr(optarg, "x");
            if (pos == NULL || pixWidth == 0 || (strlen(pos) >= strlen(optarg))) {
                usage();
                return -1;
            }
            pixHeight = atoi(pos+1);
            break;
        case 'c':
            compCount = atoi(optarg);
            break;
        case 'b':
            bitDepth = atoi(optarg);
            break;
        case 'l':
            dwtLvls = atoi(optarg);
            break;
        case 'D':
            device = atoi(optarg);
            break;
        case 'f':
            forward = 1;
            break;
        case 'r':
            forward = 0;
            break;
        case '9':
            dwt97 = 1;
            break;
        case '5':
            dwt97 = 0;
            break;
        case 't':
            cpuWorkers = atoi(optarg);
            break;
        case 'u':
            gpuCus = atoi(optarg);
            break;
        case 'w':
            writeVisual = 1;
            break;
        case 'h':
            usage();
            return 0;
        case '?':
            return -1;
        default :
            usage();
            return -1;
        }
    }
	argc -= optind;
	argv += optind;

    if (argc == 0) { // at least one filename is expected
        printf("Please supply src file name\n");
        usage();
        return -1;
    }

    if (pixWidth <= 0 || pixHeight <=0) {
        printf("Wrong or missing dimensions\n");
        usage();
        return -1;
    }

    if (forward == 0) {
        writeVisual = 0; //do not write visual when RDWT
    }

    // device init
    int devCount;
    hipGetDeviceCount(&devCount);
    cudaCheckError("Get device count");
    if (devCount == 0) {
        printf("No CUDA enabled device\n");
        return -1;
    }
    if (device < 0 || device > devCount -1) {
        printf("Selected device %d is out of bound. Devices on your system are in range %d - %d\n",
               device, 0, devCount -1);
        return -1;
    }
    hipDeviceProp_t devProp;
    hipGetDeviceProperties(&devProp, device);
    cudaCheckError("Get device properties");
    if (devProp.major < 1) {
        printf("Device %d does not support CUDA\n", device);
        return -1;
    }
    printf("Using device %d: %s\n", device, devProp.name);
    hipSetDevice(device);
    cudaCheckError("Set selected device");

    struct dwt *d;
    d = (struct dwt *)malloc(sizeof(struct dwt));
    d->srcImg = NULL;
    d->pixWidth = pixWidth;
    d->pixHeight = pixHeight;
    d->components = compCount;
    d->dwtLvls  = dwtLvls;

    // file names
    d->srcFilename = (char *)malloc(strlen(argv[0]));
    strcpy(d->srcFilename, argv[0]);
    if (argc == 1) { // only one filename supplyed
        d->outFilename = (char *)malloc(strlen(d->srcFilename)+4);
        strcpy(d->outFilename, d->srcFilename);
        strcpy(d->outFilename+strlen(d->srcFilename), ".dwt");
    } else {
        d->outFilename = strdup(argv[1]);
    }

    //Input review
    printf("Source file:\t\t%s\n", d->srcFilename);
    printf(" Dimensions:\t\t%dx%d\n", pixWidth, pixHeight);
    printf(" Components count:\t%d\n", compCount);
    printf(" Bit depth:\t\t%d\n", bitDepth);
    printf(" DWT levels:\t\t%d\n", dwtLvls);
    printf(" Forward transform:\t%d\n", forward);
    printf(" 9/7 transform:\t\t%d\n", dwt97);
    printf(" CPU dummy workers:\t%d\n", cpuWorkers);
    printf(" GPU dummy CUs:\t\t%d\n", gpuCus);
    DWT2D_LOG("parsed options complete");

    //data sizes
    int inputSize = pixWidth*pixHeight*compCount; //<amount of data (in bytes) to proccess

	// load img source image
	// 原来：srcImg 在 host，GPU 端需要 hipMemcpy
	// 现在：srcImg 用 managed 分配，一份指针直接被后续 GPU kernel 使用
	d->srcImg = (unsigned char *)checked_hip_malloc_managed(inputSize);
	cudaCheckError("Alloc host memory");
    DWT2D_LOG("srcImg allocated: ptr=%p bytes=%d", (void *)d->srcImg, inputSize);
	if (getImg(d->srcFilename, d->srcImg, inputSize) == -1)
		return -1;
    DWT2D_LOG("input image loaded");

#if defined(GEM5_FUSION) || defined(GEM5_FS)
    printf("Before m5_work_begin\n");
    fflush(stdout);
#endif
#ifdef GEM5_FUSION
    m5_work_begin(0, 0);
#endif
#ifdef GEM5_FS
    map_m5_mem();
    m5_work_begin_addr(0, 0);
#endif
#if defined(GEM5_FUSION) || defined(GEM5_FS)
    printf("After m5_work_begin\n");
    fflush(stdout);
#endif

    /* CPU dummy first: shared input reads with per-thread private writes,
       following the same broad shape as the lavaMD helper phase. */
    printf("CPU dummy phase begin\n");
    fflush(stdout);
    dwt2d_cpu_dummy_phase(d->srcImg, (size_t)inputSize, cpuWorkers);
    printf("CPU dummy phase end\n");
    fflush(stdout);
    DWT2D_LOG("CPU dummy phase completed");

    /* After the CPU dummy phase drains, execute the original GPU DWT path. */

    /* DWT */
    if (forward == 1) {
        if(dwt97 == 1 )
            processDWT<float>(d, forward, writeVisual);
        else // 5/3
            processDWT<int>(d, forward, writeVisual);
    }
    DWT2D_LOG("real GPU DWT path completed");
    else { // reverse
        if(dwt97 == 1 )
            processDWT<float>(d, forward, writeVisual);
        else // 5/3
            processDWT<int>(d, forward, writeVisual);
    }

    /* Finally, run a separate GPU-only dummy phase sized by the requested CU
       count, following the lavaMD post-kernel filler pattern. */
    printf("GPU dummy phase begin\n");
    fflush(stdout);
    dwt2d_gpu_dummy_phase(gpuCus);
    printf("GPU dummy phase end\n");
    fflush(stdout);
    DWT2D_LOG("GPU dummy phase completed");

#if defined(GEM5_FUSION) || defined(GEM5_FS)
    printf("Before m5_work_end\n");
    fflush(stdout);
#endif
#ifdef GEM5_FUSION
    m5_work_end(0, 0);
#endif
#ifdef GEM5_FS
    map_m5_mem();
    m5_work_end_addr(0, 0);
#endif
#if defined(GEM5_FUSION) || defined(GEM5_FS)
    printf("After m5_work_end\n");
    fflush(stdout);
#endif

    //writeComponent(r_cuda, pixWidth, pixHeight, srcFilename, ".g");
    //writeComponent(g_wave_cuda, 512000, ".g");
    //writeComponent(g_cuda, componentSize, ".g");
    //writeComponent(b_wave_cuda, componentSize, ".b");
	hipFree(d->srcImg);
	cudaCheckError("Cuda free host");
    DWT2D_LOG("srcImg freed");

    printf("PASSED!\n");
    DWT2D_LOG("main end");

    return 0;
}
