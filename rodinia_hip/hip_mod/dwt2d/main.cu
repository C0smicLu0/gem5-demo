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
#include <stdint.h>
#ifdef __linux__
#include <sched.h>
#endif
#include <getopt.h>

#ifndef DWT2D_TRACE
#define DWT2D_TRACE 1
#endif

#ifndef DWT2D_TRACE_SYNC
#define DWT2D_TRACE_SYNC 1
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

#define DWT2D_ERR(fmt, ...) do { \
    fprintf(stderr, "[DWT2D-ERR][%s:%d] " fmt "\n", \
            __func__, __LINE__, ##__VA_ARGS__); \
    fflush(stderr); \
} while (0)

#define DWT2D_LASTERR(tag) do { \
    hipError_t _dwt2d_err = hipGetLastError(); \
    DWT2D_LOG("hip last error after %s: %s", tag, hipGetErrorString(_dwt2d_err)); \
    if (_dwt2d_err != hipSuccess) { \
        DWT2D_ERR("hip error after %s: %s", tag, hipGetErrorString(_dwt2d_err)); \
        exit(1); \
    } \
} while (0)

#if DWT2D_TRACE_SYNC
#define DWT2D_SYNC(tag) do { \
    DWT2D_LOG("hipDeviceSynchronize begin: %s", tag); \
    hipError_t _dwt2d_sync_err = hipDeviceSynchronize(); \
    DWT2D_LOG("hipDeviceSynchronize end: %s, err=%s", tag, hipGetErrorString(_dwt2d_sync_err)); \
    if (_dwt2d_sync_err != hipSuccess) { \
        DWT2D_ERR("hipDeviceSynchronize failed at %s: %s", tag, hipGetErrorString(_dwt2d_sync_err)); \
        exit(1); \
    } \
} while (0)
#else
#define DWT2D_SYNC(tag) do { } while (0)
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

int getImg(const char * srcFilename, unsigned char *srcImg, int inputSize)
{
    DWT2D_LOG("getImg begin: srcFilename=%s inputSize=%d", srcFilename, inputSize);
    const char *path = "../../data/dwt2d/";
    char *newSrc = NULL;

    if (strchr(srcFilename, '/') == NULL) {
        DWT2D_LOG("bare filename detected, prepend default path");
        newSrc = (char *)malloc(strlen(srcFilename) + strlen(path) + 1);
        if (newSrc == NULL) {
            fprintf(stderr, "malloc failed\n");
            return -1;
        }

        newSrc[0] = '\0';
        strcat(newSrc, path);
        strcat(newSrc, srcFilename);
        srcFilename = newSrc;
    }

    DWT2D_LOG("resolved input path: %s", srcFilename);

    DWT2D_LOG("open input begin");
    int fd = open(srcFilename, O_RDONLY, 0644);
    if (fd == -1) {
        DWT2D_ERR("open input failed: %s", srcFilename);
        error(0, errno, "cannot access %s", srcFilename);
        free(newSrc);
        return -1;
    }

    if (strstr(srcFilename, ".bmp") != NULL || strstr(srcFilename, ".BMP") != NULL) {
        DWT2D_LOG("BMP input detected, skip 54-byte header");
        off_t off = lseek(fd, 54, SEEK_SET);
        if (off == (off_t)-1) {
            error(0, errno, "lseek failed for %s", srcFilename);
            close(fd);
            free(newSrc);
            return -1;
        }
    } else {
        DWT2D_LOG("raw RGB input detected, no header skip");
    }

    DWT2D_LOG("read input begin");
    ssize_t ret = read(fd, srcImg, inputSize);
    DWT2D_LOG("read input end: read=%ld expected=%d", (long)ret, inputSize);

    if (ret < 0) {
        DWT2D_ERR("read input failed: %s", srcFilename);
        error(0, errno, "read failed for %s", srcFilename);
        close(fd);
        free(newSrc);
        return -1;
    }

    if (ret != inputSize) {
        DWT2D_ERR("input size mismatch: read %ld bytes, expected %d bytes",
                (long)ret, inputSize);
        close(fd);
        free(newSrc);
        return -1;
    }

    DWT2D_LOG("close input");
    close(fd);
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
  -w  --write-visual\t\twrite output in visual (tiled) fashion instead of the linear\n");
}

template <typename T>
void processDWT(struct dwt *d, int forward, int writeVisual)
{
    int componentSize = d->pixWidth*d->pixHeight*sizeof(T);
    DWT2D_LOG("processDWT begin: width=%d height=%d components=%d levels=%d forward=%d writeVisual=%d sizeof(T)=%zu componentSize=%d",
              d->pixWidth, d->pixHeight, d->components, d->dwtLvls, forward, writeVisual,
              sizeof(T), componentSize);
    
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
    DWT2D_SYNC("base buffers initialized");
	
	if (d->components == 3) {
        DWT2D_LOG("enter RGB components branch");
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
        DWT2D_SYNC("RGB output buffers initialized");
		
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
        DWT2D_SYNC("RGB input buffers initialized");

        DWT2D_LOG("rgbToComponents begin");
        rgbToComponents(c_r, c_g, c_b, d->srcImg, d->pixWidth, d->pixHeight);
        DWT2D_LOG("rgbToComponents returned");
        DWT2D_SYNC("rgbToComponents");
		

        /* Compute DWT and always store into file */

        DWT2D_LOG("nStage2dDWT R begin");
        nStage2dDWT(c_r, c_r_out, backup, d->pixWidth, d->pixHeight, d->dwtLvls, forward);
        DWT2D_LOG("nStage2dDWT R returned");
        DWT2D_SYNC("nStage2dDWT R");
        DWT2D_LOG("nStage2dDWT G begin");
        nStage2dDWT(c_g, c_g_out, backup, d->pixWidth, d->pixHeight, d->dwtLvls, forward);
        DWT2D_LOG("nStage2dDWT G returned");
        DWT2D_SYNC("nStage2dDWT G");
        DWT2D_LOG("nStage2dDWT B begin");
        nStage2dDWT(c_b, c_b_out, backup, d->pixWidth, d->pixHeight, d->dwtLvls, forward);
        DWT2D_LOG("nStage2dDWT B returned");
        DWT2D_SYNC("nStage2dDWT B");
        DWT2D_LOG("RGB DWT computation finished");
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
        DWT2D_LOG("OUTPUT enabled, writing RGB DWT results begin");
        DWT2D_LOG("write single component output begin");
        if (writeVisual) {
            writeNStage2DDWT(c_r_out, d->pixWidth, d->pixHeight, d->dwtLvls, d->outFilename, ".r");
            writeNStage2DDWT(c_g_out, d->pixWidth, d->pixHeight, d->dwtLvls, d->outFilename, ".g");
            writeNStage2DDWT(c_b_out, d->pixWidth, d->pixHeight, d->dwtLvls, d->outFilename, ".b");
        } else {
            writeLinear(c_r_out, d->pixWidth, d->pixHeight, d->outFilename, ".r");
            writeLinear(c_g_out, d->pixWidth, d->pixHeight, d->outFilename, ".g");
            writeLinear(c_b_out, d->pixWidth, d->pixHeight, d->outFilename, ".b");
        }
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
        DWT2D_SYNC("single component input buffer initialized");

        DWT2D_LOG("bwToComponent begin");
        bwToComponent(c_r, d->srcImg, d->pixWidth, d->pixHeight);
        DWT2D_LOG("bwToComponent returned");
        DWT2D_SYNC("bwToComponent");

        // Compute DWT 
        DWT2D_LOG("nStage2dDWT single component begin");
        nStage2dDWT(c_r, c_r_out, backup, d->pixWidth, d->pixHeight, d->dwtLvls, forward);
        DWT2D_LOG("nStage2dDWT single component returned");
        DWT2D_SYNC("nStage2dDWT single component");

        // Store DWT to file 
// #ifdef OUTPUT        
        DWT2D_LOG("OUTPUT enabled, writing RGB DWT results begin");
        DWT2D_LOG("write single component output begin");
        if (writeVisual) {
            writeNStage2DDWT(c_r_out, d->pixWidth, d->pixHeight, d->dwtLvls, d->outFilename, ".out");
        } else {
            writeLinear(c_r_out, d->pixWidth, d->pixHeight, d->outFilename, ".lin.out");
        }
// #endif
        DWT2D_LOG("write single component output end");
        DWT2D_LOG("free single component buffer begin");
        hipFree(c_r);
        cudaCheckError("Cuda free");
        DWT2D_LOG("free single component buffer end");
    } else {
        DWT2D_ERR("unsupported component count in processDWT: %d", d->components);
        exit(1);
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
    volatile uint64_t loops;
} rodinia_cpu_worker_arg_t;

static pthread_t *g_mt_threads = NULL;
static rodinia_cpu_worker_arg_t *g_mt_args = NULL;
static volatile int g_mt_started = 0;
static int g_mt_count = 0;
static volatile unsigned char *g_mt_load_ptr = NULL;
static size_t g_mt_load_bytes = 0;

#ifndef RODINIA_CPU_WORKER_ITERS
#define RODINIA_CPU_WORKER_ITERS 20000ULL
#endif

static volatile int g_mt_go = 0;

static void *rodinia_cpu_worker(void *p)
{
    rodinia_cpu_worker_arg_t *a = (rodinia_cpu_worker_arg_t *)p;
    DWT2D_LOG("CPU worker %d created", a->tid);

    __sync_fetch_and_add(&g_mt_started, 1);

    while (!g_mt_go) {
        sched_yield();
    }

    DWT2D_LOG("CPU worker %d starts busy loop", a->tid);
    uint32_t x = (uint32_t)(0x9e3779b9u ^ (uint32_t)(a->tid + 1));
    volatile uint32_t acc = 0;
    volatile unsigned char *load = g_mt_load_ptr;
    size_t bytes = g_mt_load_bytes;

    for (uint64_t outer = 0; outer < RODINIA_CPU_WORKER_ITERS; ++outer) {
        for (int k = 0; k < 64; ++k) {
            x ^= x << 13;
            x ^= x >> 17;
            x ^= x << 5;

            acc += x;

            if (load != NULL && bytes > 0) {
                size_t idx = ((size_t)x) % bytes;
                acc += load[idx];
            }
        }
    }

    a->loops = (uint64_t)acc;
    DWT2D_LOG("CPU worker %d finished: acc=%llu", a->tid, (unsigned long long)a->loops);
    return NULL;
}


static void rodinia_cpu_pool_start(int nthreads)
{
    DWT2D_LOG("CPU pool start requested: nthreads=%d", nthreads);
    if (nthreads <= 0 || g_mt_threads != NULL) {
        DWT2D_LOG("CPU pool start skipped: nthreads=%d g_mt_threads=%p", nthreads, (void *)g_mt_threads);
        return;
    }

    g_mt_threads = (pthread_t *)malloc((size_t)nthreads * sizeof(pthread_t));
    g_mt_args = (rodinia_cpu_worker_arg_t *)malloc((size_t)nthreads * sizeof(rodinia_cpu_worker_arg_t));

    if (!g_mt_threads || !g_mt_args) {
        DWT2D_ERR("CPU pool malloc failed");
        free(g_mt_threads);
        free(g_mt_args);
        g_mt_threads = NULL;
        g_mt_args = NULL;
        return;
    }

    g_mt_started = 0;
    g_mt_go = 0;
    g_mt_count = nthreads;

    pthread_attr_t attr;
    pthread_attr_init(&attr);

    size_t stack_size = 256 * 1024;
    pthread_attr_setstacksize(&attr, stack_size);


    for (int t = 0; t < nthreads; ++t) {
        g_mt_args[t].tid = t;
        g_mt_args[t].loops = 0;

        DWT2D_LOG("pthread_create begin: tid=%d", t);
        int rc = pthread_create(&g_mt_threads[t], NULL, rodinia_cpu_worker, &g_mt_args[t]);
        DWT2D_LOG("pthread_create end: tid=%d rc=%d", t, rc);
        if (rc != 0) {
            fprintf(stderr, "pthread_create failed at thread %d, rc=%d\n", t, rc);
            exit(1);
        }
    }
    DWT2D_LOG("CPU pool start end: created=%d", nthreads);
}

static void rodinia_cpu_pool_join(void)
{
    DWT2D_LOG("CPU pool join begin");
    if (!g_mt_threads) {
        DWT2D_LOG("CPU pool join skipped: no threads");
        return;
    }

    for (int t = 0; t < g_mt_count; ++t) {
        DWT2D_LOG("pthread_join begin: tid=%d", t);
        pthread_join(g_mt_threads[t], NULL);
        DWT2D_LOG("pthread_join end: tid=%d loops=%llu", t, (unsigned long long)g_mt_args[t].loops);
    }

    free(g_mt_threads);
    free(g_mt_args);

    g_mt_threads = NULL;
    g_mt_args = NULL;
    g_mt_count = 0;
    DWT2D_LOG("CPU pool join end");
}

static void rodinia_cpu_pool_wait_started(void)
{
    DWT2D_LOG("wait CPU workers started begin: target=%d", g_mt_count);
    if (!g_mt_threads) {
        DWT2D_LOG("wait CPU workers skipped: no threads");
        return;
    }
    while (g_mt_started < g_mt_count) { }
    DWT2D_LOG("wait CPU workers started end: started=%d target=%d", g_mt_started, g_mt_count);
}

__global__ static void rodinia_cu_warmup_kernel(uint32_t *buf, int iters)
{
    unsigned idx = blockIdx.x * blockDim.x + threadIdx.x;
    uint32_t x = idx + 1u;
    for (int i = 0; i < iters; ++i) {
        x = x * 1664525u + 1013904223u;
    }
    buf[idx] = x;
}

static void rodinia_gpu_cu_warmup(int requested_cus)
{
    DWT2D_LOG("GPU CU warmup begin: requested_cus=%d", requested_cus);
    int cus = (requested_cus > 0) ? requested_cus : 64;
    int blocks = cus * 8;
    int threads = 256;
    size_t n = (size_t)blocks * (size_t)threads;
    size_t bytes = n * sizeof(uint32_t);

    uint32_t *buf = NULL;
    hipError_t err = hipMalloc((void **)&buf, bytes);
    if (err != hipSuccess || !buf) {
        DWT2D_ERR("GPU CU warmup hipMalloc failed: %s", hipGetErrorString(err));
        return;
    }

    DWT2D_LOG("GPU CU warmup launch: blocks=%d threads=%d bytes=%zu", blocks, threads, bytes);
    hipLaunchKernelGGL(rodinia_cu_warmup_kernel, dim3(blocks), dim3(threads), 0, 0, buf, 1024);
    DWT2D_SYNC("GPU CU warmup");
    hipFree(buf);
    DWT2D_LOG("GPU CU warmup end");
}
int num_cus = 0;

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
        {"write-visual",no_argument,       0, 'w' }, //write output (subbands) in visual (tiled) order instead of linear
        {"cpu-workers", required_argument, 0, 't'},
        {"gpu-cus", required_argument, 0, 'u'},
        {"help",        no_argument,       0, 'h'}  
    };
    
    int pixWidth    = 0; //<real pixWidth
    int pixHeight   = 0; //<real pixHeight
    int compCount   = 3; //number of components; 3 for RGB or YUV, 4 for RGBA
    int bitDepth    = 8; 
    int dwtLvls     = 3; //default numuber of DWT levels
    int device      = 0;
    int mt_threads  = 0;
    int forward     = 1; //forward transform
    int dwt97       = 1; //1=dwt9/7, 0=dwt5/3 transform
    int writeVisual = 0; //write output (subbands) in visual (tiled) order instead of linear
    char * pos;

    while ((ch = getopt_long(argc, argv, "d:c:b:l:D:fr95wht:u:", longopts, &optindex)) != -1) {
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
        case 'w':
            writeVisual = 1;
            break;
        case 'h':
            usage();
            return 0;
        case 't':
            mt_threads = atoi(optarg);
            break;
        case 'u':
            num_cus = atoi(optarg);
            break;
        case '?':
            return -1;
        default :
            usage();
            return -1;
        }
    }
	argc -= optind;
	argv += optind;
    DWT2D_LOG("options parsed: remaining_argc=%d width=%d height=%d components=%d bitDepth=%d levels=%d device=%d forward=%d dwt97=%d writeVisual=%d cpu_workers=%d gpu_cus=%d",
              argc, pixWidth, pixHeight, compCount, bitDepth, dwtLvls, device, forward, dwt97, writeVisual, mt_threads, num_cus);

    if (argc == 0) { // at least one filename is expected
        printf("Please supply src file name\n");
        fflush(stdout); 
        usage();
        return -1;
    }

    if (pixWidth <= 0 || pixHeight <=0) {
        DWT2D_ERR("wrong or missing dimensions: %dx%d", pixWidth, pixHeight);
        printf("Wrong or missing dimensions\n");
        fflush(stdout); 
        usage();
        return -1;
    }

    if (compCount != 1 && compCount != 3) {
        DWT2D_ERR("unsupported components count: %d, only 1 or 3 supported", compCount);
        return -1;
    }

    if (bitDepth != 8) {
        DWT2D_ERR("unsupported bit depth: %d, only 8-bit input supported by this reader", bitDepth);
        return -1;
    }

    if (forward == 0) {
        DWT2D_LOG("reverse mode selected: force writeVisual=0");
        writeVisual = 0; //do not write visual when RDWT
    }

    // device init
    DWT2D_LOG("device init begin");
    int devCount;
    hipGetDeviceCount(&devCount);
    cudaCheckError("Get device count");
    DWT2D_LOG("device count: %d", devCount);
    if (devCount == 0) {
        printf("No CUDA enabled device\n");
        fflush(stdout); 
        return -1;
    } 
    if (device < 0 || device > devCount -1) {
        printf("Selected device %d is out of bound. Devices on your system are in range %d - %d\n", 
               device, 0, devCount -1);
        fflush(stdout); 
        return -1;
    }
    hipDeviceProp_t devProp;                                          
    DWT2D_LOG("get device properties begin: device=%d", device);
    hipGetDeviceProperties(&devProp, device);  
    cudaCheckError("Get device properties");
    DWT2D_LOG("get device properties end: name=%s major=%d minor=%d", devProp.name, devProp.major, devProp.minor);
    if (devProp.major < 1) {                                         
        printf("Device %d does not support CUDA\n", device);
        fflush(stdout); 
        return -1;
    }                                                                   
    printf("Using device %d: %s\n", device, devProp.name);
    fflush(stdout); 
    DWT2D_LOG("hipSetDevice begin: device=%d", device);
    hipSetDevice(device);
    cudaCheckError("Set selected device");
    DWT2D_LOG("hipSetDevice end");

    DWT2D_LOG("allocate dwt struct begin");
    struct dwt *d;
    d = (struct dwt *)malloc(sizeof(struct dwt));
    DWT2D_LOG("allocate dwt struct end: ptr=%p", (void *)d);
    d->srcImg = NULL;
    d->pixWidth = pixWidth;
    d->pixHeight = pixHeight;
    d->components = compCount;
    d->dwtLvls  = dwtLvls;

    // file names
    d->srcFilename = (char *)malloc(strlen(argv[0]) + 1);
    strcpy(d->srcFilename, argv[0]);
    if (argc == 1) { // only one filename supplyed
        d->outFilename = (char *)malloc(strlen(d->srcFilename)+5);
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
    
    //data sizes
    int inputSize = pixWidth*pixHeight*compCount;
    DWT2D_LOG("computed inputSize=%d", inputSize); //<amount of data (in bytes) to proccess

	// load img source image
	// 原来：srcImg 在 host，GPU 端需要 hipMemcpy
	// 现在：srcImg 用 managed 分配，一份指针直接被后续 GPU kernel 使用
	DWT2D_LOG("alloc managed srcImg begin: bytes=%d", inputSize);
	d->srcImg = (unsigned char *)checked_hip_malloc_managed(inputSize);
	cudaCheckError("Alloc host memory");
    DWT2D_LOG("alloc managed srcImg end: ptr=%p", (void *)d->srcImg);
	DWT2D_LOG("getImg call begin");
	if (getImg(d->srcFilename, d->srcImg, inputSize) == -1) {
        DWT2D_ERR("getImg failed");
		return -1;
    }
    DWT2D_LOG("getImg call end");

    //writeComponent(r_cuda, pixWidth, pixHeight, srcFilename, ".g");
    //writeComponent(g_wave_cuda, 512000, ".g");
    //writeComponent(g_cuda, componentSize, ".g");
    //writeComponent(b_wave_cuda, componentSize, ".b");
    DWT2D_LOG("CPU phase check: mt_threads=%d", mt_threads);
    if (mt_threads > 0) {
        DWT2D_LOG("CPU phase begin");
        g_mt_load_ptr = (volatile unsigned char *)d->srcImg;
        g_mt_load_bytes = (size_t)inputSize;

        rodinia_cpu_pool_start(mt_threads);
        rodinia_cpu_pool_wait_started();

        DWT2D_LOG("CPU workers all started: %d", mt_threads);

        DWT2D_LOG("CPU workers go signal begin");
        __sync_synchronize();
        __sync_lock_test_and_set(&g_mt_go, 1);
        DWT2D_LOG("CPU workers go signal end");

        rodinia_cpu_pool_join();

        g_mt_load_ptr = NULL;
        g_mt_load_bytes = 0;
        DWT2D_LOG("CPU phase end");
    } else {
        DWT2D_LOG("CPU phase skipped");
    }

    /* DWT */
    DWT2D_LOG("GPU DWT dispatch begin");
    if (forward == 1) {
        if(dwt97 == 1 )
            processDWT<float>(d, forward, writeVisual);
        else // 5/3
            processDWT<int>(d, forward, writeVisual);
    }
    else { // reverse
        if(dwt97 == 1 )
            processDWT<float>(d, forward, writeVisual);
        else // 5/3
            processDWT<int>(d, forward, writeVisual);
    }
    DWT2D_LOG("GPU DWT dispatch end");

    DWT2D_LOG("free srcImg begin");
	hipFree(d->srcImg);
	cudaCheckError("Cuda free host");
    DWT2D_LOG("free srcImg end");
	printf("PASSED!\n");
    fflush(stdout);
    DWT2D_LOG("main end");

    return 0;
}
