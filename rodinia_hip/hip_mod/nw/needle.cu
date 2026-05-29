#define LIMIT -999
#include <stdlib.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

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

#define NW_TRACE(...) do {       \
    printf("[nw][trace] ");      \
    printf(__VA_ARGS__);         \
    printf("\n");               \
    fflush(stdout);              \
} while (0)

// ---- CPU multithread phase injected for heterogeneous MT experiments ----
typedef struct {
    int tid;
    int iters;
    unsigned int seed;
    volatile unsigned int sink;
} rodinia_mt_arg_t;

static int rodinia_mt_threads = 4;
static int rodinia_mt_work_percent = 8;
static unsigned int rodinia_mt_seed = 1;
static int rodinia_mt_inited = 0;

static inline unsigned int rodinia_mt_xorshift32(unsigned int *state) {
    unsigned int x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x ? x : 1u;
    return *state;
}

static int rodinia_parse_threads_from_cmdline(void) {
    FILE *cmd_fp = fopen("/proc/self/cmdline", "rb");
    if (!cmd_fp) return -1;

    char buf[8192];
    size_t nread = fread(buf, 1, sizeof(buf) - 1, cmd_fp);
    fclose(cmd_fp);
    if (nread == 0) return -1;
    buf[nread] = '\0';

    size_t i = 0;
    while (i < nread) {
        const char *arg = &buf[i];
        size_t len = strlen(arg);
        if (len == 0) break;

        if (strcmp(arg, "--cpu-workers") == 0) {
            size_t j = i + len + 1;
            if (j < nread) {
                int v = atoi(&buf[j]);
                if (v > 0) return v;
            }
        } else if (strcmp(arg, "-n") == 0 || strcmp(arg, "-t") == 0) {
            size_t j = i + len + 1;
            if (j < nread) {
                int v = atoi(&buf[j]);
                if (v > 0) return v;
            }
        } else if (strncmp(arg, "--cpu-workers=", 17) == 0) {
            int v = atoi(arg + 17);
            if (v > 0) return v;
        }

        i += len + 1;
    }
    return -1;
}

static void rodinia_mt_init_cfg(void) {
    if (rodinia_mt_inited) return;
    const char *s_work = getenv("RODINIA_SHARE_PERCENT");
    const char *s_seed = getenv("RODINIA_SHARE_SEED");

    // Thread count is controlled by workload options arg: --cpu-workers <threads>.
    int parsed_threads = rodinia_parse_threads_from_cmdline();
    if (parsed_threads > 0) {
        rodinia_mt_threads = parsed_threads;
    }
    if (s_work) rodinia_mt_work_percent = atoi(s_work);
    if (s_seed) rodinia_mt_seed = (unsigned int)atoi(s_seed);
    if (rodinia_mt_threads <= 0) rodinia_mt_threads = 1;
    if (rodinia_mt_work_percent < 0) rodinia_mt_work_percent = 0;
    if (rodinia_mt_work_percent > 100) rodinia_mt_work_percent = 100;
    if (rodinia_mt_seed == 0) rodinia_mt_seed = 1;
    rodinia_mt_inited = 1;
}

static void rodinia_mt_set_threads(int n) {
    if (n > 0) {
        rodinia_mt_threads = n;
    }
}

static void *rodinia_mt_worker(void *p) {
    rodinia_mt_arg_t *a = (rodinia_mt_arg_t *)p;
    unsigned int s = a->seed ^ (unsigned int)(a->tid + 1) * 0x9e3779b9u;
    volatile unsigned int acc = 0;

    for (int i = 0; i < a->iters; i++) {
        acc += rodinia_mt_xorshift32(&s);
    }

    a->sink = acc;
    return NULL;
}

static void rodinia_mt_cpu_phase(void) {
    rodinia_mt_init_cfg();
    NW_TRACE("cpu cfg: threads=%d work_percent=%d seed=%u",
         rodinia_mt_threads, rodinia_mt_work_percent, rodinia_mt_seed);

    if (rodinia_mt_work_percent <= 0) {
        NW_TRACE("cpu phase skipped: work_percent=%d", rodinia_mt_work_percent);
        return;
    }
    int n = rodinia_mt_threads;
    pthread_t *ths = (pthread_t *)malloc((size_t)n * sizeof(pthread_t));
    rodinia_mt_arg_t *args = (rodinia_mt_arg_t *)malloc((size_t)n * sizeof(rodinia_mt_arg_t));
    int base_iters = 5000 * rodinia_mt_work_percent;

    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 64 * 1024);

    NW_TRACE("cpu phase begin: workers=%d base_iters=%d", n, base_iters);

    for (int t = 0; t < n; t++) {
        args[t].tid = t;
        args[t].iters = base_iters;
        args[t].seed = rodinia_mt_seed ^ (unsigned int)(t + 1);
        args[t].sink = 0;

        int rc = pthread_create(&ths[t], &attr, rodinia_mt_worker, &args[t]);
        NW_TRACE("cpu worker created: tid=%d iters=%d", t, args[t].iters);
        if (rc != 0) {
            fprintf(stderr, "pthread_create failed: tid=%d rc=%d\n", t, rc);
            exit(1);
        }
    }

    pthread_attr_destroy(&attr);
    for (int t = 0; t < n; t++) {
        pthread_join(ths[t], NULL);
        NW_TRACE("cpu worker joined: tid=%d sink=%u", t, args[t].sink);
    }
    NW_TRACE("cpu phase end: workers=%d", n);
    free(ths);
    free(args);
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

// Program main
int
main( int argc, char** argv) 
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

    srand ( 7 );
	
	
    for (int i = 0 ; i < max_cols; i++){
		for (int j = 0 ; j < max_rows; j++){
			input_itemsets[i*max_cols+j] = 0;
		}
	}
	
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

    NW_TRACE("before cpu phase");
    rodinia_mt_cpu_phase();
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
        dimGrid.x = i;
        dimGrid.y = 1;
        needle_cuda_shared_1<<<dimGrid, dimBlock>>>(referrence_cuda, matrix_cuda,
                                            max_cols, penalty, i, block_width); 
        HIP_CHECK(hipGetLastError());
        HIP_CHECK(hipDeviceSynchronize());
    }

	NW_TRACE("gpu bottom-right begin: block_width=%d", block_width);
    //process bottom-right matrix
	for( int i = block_width - 1  ; i >= 1 ; i--){
		dimGrid.x = i;
		dimGrid.y = 1;
		needle_cuda_shared_2<<<dimGrid, dimBlock>>>(referrence_cuda, matrix_cuda
		                                      ,max_cols, penalty, i, block_width); 
        HIP_CHECK(hipGetLastError());
        HIP_CHECK(hipDeviceSynchronize());
	}

#ifdef  TIMING
    gettimeofday(&tv_kernel_end, NULL);
    tvsub(&tv_kernel_end, &tv_kernel_start, &tv);
    kernel_time += tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;
#endif

	HIP_CHECK(hipDeviceSynchronize());
	// 原来：通过 hipMemcpy D2H 取回结果
	// 现在：managed 内存下只需同步后 memcpy（或直接读 matrix_cuda）
	memcpy(output_itemsets, matrix_cuda, sizeof(int) * size);
	
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
