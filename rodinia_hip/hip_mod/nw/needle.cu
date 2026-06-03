#define LIMIT -999
#include <stdlib.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <atomic>

#ifdef __linux__
#include <sched.h>
#endif

#include <math.h>
#include "needle.h"
#include <hip/hip_runtime.h>
#include <sys/time.h>

#include "needle_kernel.cu"

#ifdef TIMING
#include "timing.h"
#endif

#if defined(GEM5_FUSION) || defined(GEM5_FS)
#include <gem5/m5ops.h>
#endif
#if defined(GEM5_FS)
#include <util/m5/src/m5_mmap.h>
#endif
#if !defined(GEM5_FUSION) && !defined(GEM5_FS)
static inline void m5_work_begin(uint64_t, uint64_t) {}
static inline void m5_work_end(uint64_t, uint64_t) {}
static inline void map_m5_mem(void) {}
static inline void unmap_m5_mem(void) {}
static inline void m5_work_begin_addr(uint64_t, uint64_t) {}
static inline void m5_work_end_addr(uint64_t, uint64_t) {}
#endif

#define NW_TRACE(fmt, ...) do {                                      \
    printf("[nw] " fmt "\n", ##__VA_ARGS__);                  \
    fflush(stdout);                                                  \
} while (0)

static const int NW_REAL_BLOCK_CHUNK = 24;

__global__ void nw_gpu_keepalive_kernel(int *buf, int n, int repeat)
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

static void nw_gpu_keepalive(int num_cus)
{
    if (num_cus <= 0)
        return;

    int warmup_threads = BLOCK_SIZE;
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

    NW_TRACE("gpu dummy config: blocks=%d threads=%d repeat=%d",
             warmup_blocks, warmup_threads, 8);

    nw_gpu_keepalive_kernel<<<warmup_blocks, warmup_threads>>>(
        warmup_buf, warmup_n, 8);
    HIP_CHECK(hipGetLastError());
    HIP_CHECK(hipDeviceSynchronize());
    hipFree(warmup_buf);
}

typedef struct {
    const int *input;
    size_t elements;
    volatile long long *sinks;
    std::atomic<bool> start;
    int actual_workers;
} rodinia_mt_plan_t;

typedef struct {
    rodinia_mt_plan_t *plan;
    int worker_id;
} rodinia_mt_worker_state_t;

static int rodinia_mt_threads = 4;

static void rodinia_mt_set_threads(int n) {
    if (n > 0) {
        rodinia_mt_threads = n;
    }
}

static void *rodinia_mt_worker(void *opaque)
{
    rodinia_mt_worker_state_t *state = (rodinia_mt_worker_state_t *)opaque;
    rodinia_mt_plan_t *plan = state->plan;

    while (!plan->start.load(std::memory_order_acquire)) {
        sched_yield();
    }

    size_t begin = (plan->elements * (size_t)state->worker_id) /
                   (size_t)plan->actual_workers;
    size_t end = (plan->elements * (size_t)(state->worker_id + 1)) /
                 (size_t)plan->actual_workers;
    size_t range_size = end - begin;
    size_t extra_window = range_size < 1024 ? range_size : 1024;
    int extra_rounds = state->worker_id % 4;
    long long local = 0;

    for (size_t idx = begin; idx < end; idx++) {
        local += plan->input[idx];
    }

    for (int round = 0; round < extra_rounds; round++) {
        for (size_t offset = 0; offset < extra_window; offset++) {
            local += plan->input[begin + offset];
        }
    }

    plan->sinks[state->worker_id] = local;
    return NULL;
}

static void rodinia_mt_cpu_phase(const int *input, size_t elements)
{
    int n = rodinia_mt_threads;
    if (n <= 0 || !input || elements == 0) {
        return;
    }

    pthread_t *cpu_threads =
        (pthread_t *)malloc((size_t)n * sizeof(pthread_t));
    rodinia_mt_worker_state_t *cpu_states =
        (rodinia_mt_worker_state_t *)malloc((size_t)n *
                                            sizeof(rodinia_mt_worker_state_t));
    volatile long long *cpu_sinks =
        (volatile long long *)calloc((size_t)n, sizeof(long long));

    if (!cpu_threads || !cpu_states || !cpu_sinks) {
        fprintf(stderr, "failed to allocate CPU thread metadata\n");
        exit(1);
    }

    rodinia_mt_plan_t cpu_plan;
    cpu_plan.input = input;
    cpu_plan.elements = elements;
    cpu_plan.sinks = cpu_sinks;
    cpu_plan.actual_workers = n;
    cpu_plan.start.store(false, std::memory_order_relaxed);

    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 64 * 1024);

    NW_TRACE("Before CPU worker creation");
    int created = 0;
    for (int t = 0; t < n; t++) {
        cpu_states[t].plan = &cpu_plan;
        cpu_states[t].worker_id = t;

        int ret = pthread_create(&cpu_threads[t], &attr,
                                 rodinia_mt_worker, &cpu_states[t]);
        if (ret != 0) {
            fprintf(stderr,
                    "pthread_create failed in NW CPU phase at t=%d ret=%d\n",
                    t, ret);
            fflush(stderr);
            exit(1);
        }
        created++;
    }
    pthread_attr_destroy(&attr);
    NW_TRACE("Created %d/%d CPU workers", created, n);

    cpu_plan.start.store(true, std::memory_order_release);

    NW_TRACE("Before CPU workers join");
    for (int t = 0; t < n; t++) {
        NW_TRACE("Joining CPU worker thread %d", t);
        int ret = pthread_join(cpu_threads[t], NULL);
        if (ret != 0) {
            fprintf(stderr,
                    "pthread_join failed in NW CPU phase at t=%d ret=%d\n",
                    t, ret);
            fflush(stderr);
            exit(1);
        }
        NW_TRACE("Joined CPU worker thread %d", t);
    }
    NW_TRACE("CPU workers joined");

    free((void *)cpu_sinks);
    free(cpu_threads);
    free(cpu_states);
}

struct timeval tv;
struct timeval tv_total_start, tv_total_end;
struct timeval tv_h2d_start, tv_h2d_end;
struct timeval tv_d2h_start, tv_d2h_end;
struct timeval tv_kernel_start, tv_kernel_end;
struct timeval tv_mem_alloc_start, tv_mem_alloc_end;
struct timeval tv_close_start, tv_close_end;
float init_time = 0, mem_alloc_time = 0, h2d_time = 0, kernel_time = 0,
      d2h_time = 0, close_time = 0, total_time = 0;

// declaration, forward
void runTest( int argc, char** argv);

static void *checked_hip_malloc_managed(size_t size)
{
	void *ptr = NULL;
	// 原来：host malloc + device hipMalloc，再 hipMemcpy(H2D/D2H) 维护两份内存
	// 现在：统一内存 hipMallocManaged，CPU/GPU 共享同一份数据
	hipError_t err = hipMallocManaged(&ptr, size, hipMemAttachGlobal);
	if (err != hipSuccess) {
		fprintf(stderr, "hipMallocManaged failed (%zu bytes): %s\n", size, hipGetErrorString(err));
		exit(-1);
	}
	return ptr;
}

int blosum62[24][24] = {
{ 4, -1, -2, -2,  0, -1, -1,  0, -2, -1, -1, -1, -1, -2, -1,  1,  0, -3, -2,  0, -2, -1,  0, -4},
{-1,  5,  0, -2, -3,  1,  0, -2,  0, -3, -2,  2, -1, -3, -2, -1, -1, -3, -2, -3, -1,  0, -1, -4},
{-2,  0,  6,  1, -3,  0,  0,  0,  1, -3, -3,  0, -2, -3, -2,  1,  0, -4, -2, -3,  3,  0, -1, -4},
{-2, -2,  1,  6, -3,  0,  2, -1, -1, -3, -4, -1, -3, -3, -1,  0, -1, -4, -3, -3,  4,  1, -1, -4},
{ 0, -3, -3, -3,  9, -3, -4, -3, -3, -1, -1, -3, -1, -2, -3, -1, -1, -2, -2, -1, -3, -3, -2, -4},
{-1,  1,  0,  0, -3,  5,  2, -2,  0, -3, -2,  1,  0, -3, -1,  0, -1, -2, -1, -2,  0,  3, -1, -4},
{-1,  0,  0,  2, -4,  2,  5, -2,  0, -3, -3,  1, -2, -3, -1,  0, -1, -3, -2, -2,  1,  4, -1, -4},
{ 0, -2,  0, -1, -3, -2, -2,  6, -2, -4, -4, -2, -3, -3, -2,  0, -2, -2, -3, -3, -1, -2, -1, -4},
{-2,  0,  1, -1, -3,  0,  0, -2,  8, -3, -3, -1, -2, -1, -2, -1, -2, -2,  2, -3,  0,  0, -1, -4},
{-1, -3, -3, -3, -1, -3, -3, -4, -3,  4,  2, -3,  1,  0, -3, -2, -1, -3, -1,  3, -3, -3, -1, -4},
{-1, -2, -3, -4, -1, -2, -3, -4, -3,  2,  4, -2,  2,  0, -3, -2, -1, -2, -1,  1, -4, -3, -1, -4},
{-1,  2,  0, -1, -3,  1,  1, -2, -1, -3, -2,  5, -1, -3, -1,  0, -1, -3, -2, -2,  0,  1, -1, -4},
{-1, -1, -2, -3, -1,  0, -2, -3, -2,  1,  2, -1,  5,  0, -2, -1, -1, -1, -1,  1, -3, -1, -1, -4},
{-2, -3, -3, -3, -2, -3, -3, -3, -1,  0,  0, -3,  0,  6, -4, -2, -2,  1,  3, -1, -3, -3, -1, -4},
{-1, -2, -2, -1, -3, -1, -1, -2, -2, -3, -3, -1, -2, -4,  7, -1, -1, -4, -3, -2, -2, -1, -2, -4},
{ 1, -1,  1,  0, -1,  0,  0,  0, -1, -2, -2,  0, -1, -2, -1,  4,  1, -3, -2, -2,  0,  0,  0, -4},
{ 0, -1,  0, -1, -1, -1, -1, -2, -2, -1, -1, -1, -1, -2, -1,  1,  5, -2, -2,  0, -1, -1,  0, -4},
{-3, -3, -4, -4, -2, -2, -3, -2, -2, -3, -2, -3, -1,  1, -4, -3, -2, 11,  2, -3, -4, -3, -2, -4},
{-2, -2, -2, -3, -2, -1, -2, -3,  2, -1, -1, -2, -1,  3, -3, -2, -2,  2,  7, -1, -3, -2, -1, -4},
{ 0, -3, -3, -3, -1, -2, -2, -3, -3,  3,  1, -2,  1, -1, -2, -2,  0, -3, -1,  4, -3, -2, -1, -4},
{-2, -1,  3,  4, -3,  0,  1, -1,  0, -3, -4,  0, -3, -3, -2,  0, -1, -4, -3, -3,  4,  1, -1, -4},
{-1,  0,  0,  1, -3,  3,  4, -2,  0, -3, -3,  1, -1, -3, -1,  0, -1, -3, -2, -2,  1,  4, -1, -4},
{ 0, -1, -1, -1, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -2,  0,  0, -2, -1, -1, -1, -1, -1, -4},
{-4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4,  1}
};

double gettime() {
  struct timeval t;
  gettimeofday(&t,NULL);
  return t.tv_sec+t.tv_usec*1e-6;
}

int main( int argc, char** argv) 
{
    printf("WG size of kernel = %d \n", BLOCK_SIZE);

    runTest( argc, argv);
	printf("PASSED!\n");

    return EXIT_SUCCESS;
}

void usage(int argc, char **argv)
{
	fprintf(stderr, "Usage: %s <max_rows/max_cols> <penalty> [--cpu-workers N] [--gpu-cus N]\n", argv[0]);
	fprintf(stderr, "\t<dimension>  - x and y dimensions\n");
	fprintf(stderr, "\t<penalty> - penalty(positive integer)\n");
	exit(1);
}

static int parse_positive_int_opt(const char *s)
{
    char *end = NULL;
    long v = strtol(s, &end, 10);
    if (end == s || *end != '\0' || v <= 0 || v > 1000000000L) {
        return -1;
    }
    return (int)v;
}

static int round_up_multiple(int value, int mult)
{
    if (mult <= 0) return value;
    int rem = value % mult;
    return rem == 0 ? value : (value + mult - rem);
}

void runTest( int argc, char** argv) 
{
    int max_rows, max_cols, penalty;
    int base_dim;
    int mt_threads = -1;
    int num_cus = -1;
    int *input_itemsets, *output_itemsets, *referrence;
	int *matrix_cuda,  *referrence_cuda;
	int size;
	
    if (argc < 3) {
	    usage(argc, argv);
    }

    base_dim = atoi(argv[1]);
    penalty = atoi(argv[2]);
    if (base_dim <= 0 || penalty <= 0) {
	    usage(argc, argv);
    }

    for (int i = 3; i < argc; i++) {
        if (strcmp(argv[i], "--cpu-workers") == 0) {
            if (i + 1 >= argc) usage(argc, argv);
            mt_threads = parse_positive_int_opt(argv[++i]);
            if (mt_threads <= 0) usage(argc, argv);
        } else if (strncmp(argv[i], "--cpu-workers=", 17) == 0) {
            mt_threads = parse_positive_int_opt(argv[i] + 17);
            if (mt_threads <= 0) usage(argc, argv);
        } else if (strcmp(argv[i], "--gpu-cus") == 0) {
            if (i + 1 >= argc) usage(argc, argv);
            num_cus = parse_positive_int_opt(argv[++i]);
            if (num_cus <= 0) usage(argc, argv);
        } else if (strncmp(argv[i], "--gpu-cus=", 10) == 0) {
            num_cus = parse_positive_int_opt(argv[i] + 10);
            if (num_cus <= 0) usage(argc, argv);
        } else {
            usage(argc, argv);
        }
    }

    if (mt_threads > 0) {
        rodinia_mt_set_threads(mt_threads);
    }
    NW_TRACE("parsed args: base_dim=%d penalty=%d mt_threads=%d num_cus=%d",
         base_dim, penalty, mt_threads, num_cus);

    max_rows = base_dim;
    max_cols = base_dim;

    if (num_cus > 0) {
        int scaled_dim = num_cus * BLOCK_SIZE;
        scaled_dim = round_up_multiple(scaled_dim, 16);
        if (max_rows < scaled_dim) {
            max_rows = scaled_dim;
            max_cols = scaled_dim;
        }
    }

    if (max_rows % 16 != 0) {
        max_rows = round_up_multiple(max_rows, 16);
        max_cols = max_rows;
    }

    if (max_rows != base_dim) {
        printf("nw scale override: base_dim=%d -> effective_dim=%d (num_cus=%d)\n",
               base_dim, max_rows, num_cus);
    }

    printf("nw parallelism hint: block_width=%d, mt_threads=%d, num_cus=%d\n",
           max_rows / BLOCK_SIZE, mt_threads, num_cus);

	max_rows = max_rows + 1;
	max_cols = max_cols + 1;
	// 原来：referrence/input/output 在 host，GPU 端还要 hipMalloc + hipMemcpy
	// 现在：统一内存 managed 分配，一份指针贯通 CPU 初始化与 GPU kernel
	referrence = (int *)checked_hip_malloc_managed(max_rows * max_cols * sizeof(int));
    input_itemsets = (int *)checked_hip_malloc_managed(max_rows * max_cols * sizeof(int));
	output_itemsets = (int *)checked_hip_malloc_managed(max_rows * max_cols * sizeof(int));
	
	if (!input_itemsets)
		fprintf(stderr, "error: can not allocate memory");

    memset(referrence, 0, max_rows * max_cols * sizeof(int));
    memset(input_itemsets, 0, max_rows * max_cols * sizeof(int));
    memset(output_itemsets, 0, max_rows * max_cols * sizeof(int));

    srand ( 7 );
	
	printf("Start Needleman-Wunsch\n");
	
	for( int i=1; i< max_rows ; i++){    //please define your own sequence. 
       input_itemsets[i*max_cols] = rand() % 10 + 1;
	}
    for( int j=1; j< max_cols ; j++){    //please define your own sequence.
       input_itemsets[j] = rand() % 10 + 1;
	}


	for (int i = 1 ; i < max_cols; i++){
		for (int j = 1 ; j < max_rows; j++){
		referrence[i*max_cols+j] = blosum62[input_itemsets[i*max_cols]][input_itemsets[j]];
		}
	}

    for( int i = 1; i< max_rows ; i++)
       input_itemsets[i*max_cols] = -i * penalty;
	for( int j = 1; j< max_cols ; j++)
       input_itemsets[j] = -j * penalty;


	size = max_cols * max_rows;
	// 原来：referrence_cuda/matrix_cuda 是 device 指针，需 H2D 复制
	// 现在：直接别名 managed 指针，无需 hipMemcpy
	referrence_cuda = referrence;
	matrix_cuda = input_itemsets;

    dim3 dimGrid;
	dim3 dimBlock(BLOCK_SIZE, 1);
	int block_width = ( max_cols - 1 )/BLOCK_SIZE;

    NW_TRACE("before m5_work_begin");
#if defined(GEM5_FUSION)
    m5_work_begin(0, 0);
#elif defined(GEM5_FS)
    map_m5_mem();
    m5_work_begin_addr(0, 0);
#endif
    NW_TRACE("after m5_work_begin");

    NW_TRACE("before cpu phase");
    rodinia_mt_cpu_phase(referrence, (size_t)size);
    NW_TRACE("after cpu phase, before gpu phase");

#ifdef  TIMING
    gettimeofday(&tv_kernel_start, NULL);
#endif

    NW_TRACE("gpu top-left begin: block_width=%d", block_width);

    /* Run CPU activation/load phase only once.
    * Do not create pthreads in every NW wavefront iteration.
    */

    //process top-left matrix
    for( int i = 1 ; i <= block_width ; i++){
        for (int block_base = 0; block_base < i; block_base += NW_REAL_BLOCK_CHUNK) {
            int launch_blocks = (i - block_base) < NW_REAL_BLOCK_CHUNK ?
                (i - block_base) : NW_REAL_BLOCK_CHUNK;
            dimGrid.x = launch_blocks;
            dimGrid.y = 1;
            needle_cuda_shared_1<<<dimGrid, dimBlock>>>(referrence_cuda, matrix_cuda,
                                                max_cols, penalty, i, block_width,
                                                block_base);
            HIP_CHECK(hipGetLastError());
            HIP_CHECK(hipDeviceSynchronize());
        }
    }

	NW_TRACE("gpu bottom-right begin: block_width=%d", block_width);
    //process bottom-right matrix
	for( int i = block_width - 1  ; i >= 1 ; i--){
		for (int block_base = 0; block_base < i; block_base += NW_REAL_BLOCK_CHUNK) {
			int launch_blocks = (i - block_base) < NW_REAL_BLOCK_CHUNK ?
				(i - block_base) : NW_REAL_BLOCK_CHUNK;
			dimGrid.x = launch_blocks;
			dimGrid.y = 1;
			needle_cuda_shared_2<<<dimGrid, dimBlock>>>(referrence_cuda, matrix_cuda,
			                                      max_cols, penalty, i, block_width,
			                                      block_base); 
        	HIP_CHECK(hipGetLastError());
        	HIP_CHECK(hipDeviceSynchronize());
		}
	}
    NW_TRACE("before gpu dummy");
    nw_gpu_keepalive(num_cus);
    NW_TRACE("after gpu dummy");
    NW_TRACE("before hipDeviceSynchronize");

#ifdef  TIMING
    gettimeofday(&tv_kernel_end, NULL);
    tvsub(&tv_kernel_end, &tv_kernel_start, &tv);
    kernel_time += tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;
#endif

	HIP_CHECK(hipDeviceSynchronize());
	// 原来：通过 hipMemcpy D2H 取回结果
	// 现在：managed 内存下只需同步后 memcpy（或直接读 matrix_cuda）
	memcpy(output_itemsets, matrix_cuda, sizeof(int) * size);

    NW_TRACE("before m5_work_end");
#if defined(GEM5_FUSION)
    m5_work_end(0, 0);
#elif defined(GEM5_FS)
    m5_work_end_addr(0, 0);
    unmap_m5_mem();
#endif
    NW_TRACE("after m5_work_end");
	
//#define TRACEBACK
#ifdef TRACEBACK
	
	FILE *fpo = fopen("result.txt","w");
	fprintf(fpo, "print traceback value GPU:\n");
    
	for (int i = max_rows - 2,  j = max_rows - 2; i>=0, j>=0;){
		int nw, n, w, traceback;
		if ( i == max_rows - 2 && j == max_rows - 2 )
			fprintf(fpo, "%d ", output_itemsets[ i * max_cols + j]); //print the first element
		if ( i == 0 && j == 0 )
           break;
		if ( i > 0 && j > 0 ){
			nw = output_itemsets[(i - 1) * max_cols + j - 1];
		    w  = output_itemsets[ i * max_cols + j - 1 ];
            n  = output_itemsets[(i - 1) * max_cols + j];
		}
		else if ( i == 0 ){
		    nw = n = LIMIT;
		    w  = output_itemsets[ i * max_cols + j - 1 ];
		}
		else if ( j == 0 ){
		    nw = w = LIMIT;
            n  = output_itemsets[(i - 1) * max_cols + j];
		}
		else{
		}

		//traceback = maximum(nw, w, n);
		int new_nw, new_w, new_n;
		new_nw = nw + referrence[i * max_cols + j];
		new_w = w - penalty;
		new_n = n - penalty;
		
		traceback = maximum(new_nw, new_w, new_n);
		if(traceback == new_nw)
			traceback = nw;
		if(traceback == new_w)
			traceback = w;
		if(traceback == new_n)
            traceback = n;
			
		fprintf(fpo, "%d ", traceback);

		if(traceback == nw )
		{i--; j--; continue;}

        else if(traceback == w )
		{j--; continue;}

        else if(traceback == n )
		{i--; continue;}

		else
		;
	}
	
	fclose(fpo);

#endif

	hipFree(referrence);
	hipFree(input_itemsets);
	hipFree(output_itemsets);

#ifdef  TIMING
    printf("Exec: %f\n", kernel_time);
#endif
}
