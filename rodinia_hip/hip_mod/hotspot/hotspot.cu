#include "hip/hip_runtime.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <assert.h>
#include <string.h>
#include <pthread.h>
#include <math.h>
#include <sched.h>

#ifdef RD_WG_SIZE_0_0                                                            
        #define BLOCK_SIZE RD_WG_SIZE_0_0                                        
#elif defined(RD_WG_SIZE_0)                                                      
        #define BLOCK_SIZE RD_WG_SIZE_0                                          
#elif defined(RD_WG_SIZE)                                                        
        #define BLOCK_SIZE RD_WG_SIZE                                            
#else                                                                                    
        #define BLOCK_SIZE 16                                                            
#endif                                                                                   

#define STR_SIZE 256
static const int HOTSPOT_REAL_BLOCK_CHUNK = 32;

#define HOTSPOT_TRACE(fmt, ...)                                      \
    do {                                                             \
        printf("[hotspot] " fmt "\n", ##__VA_ARGS__);              \
        fflush(stdout);                                              \
    } while (0)

static void *checked_hip_malloc_managed(size_t size)
{
    void *ptr = NULL;
    // 统一内存(hipMallocManaged)：
    // - 原来：host malloc + device hipMalloc，再 hipMemcpy(H2D/D2H) 维护两份内存
    // - 现在：只分配一份 managed 指针，CPU/GPU 共享同一份数据
    hipError_t err = hipMallocManaged(&ptr, size, hipMemAttachGlobal);
    if (err != hipSuccess) {
        fprintf(stderr, "hipMallocManaged failed (%zu bytes): %s\n", size, hipGetErrorString(err));
        exit(-1);
    }
    return ptr;
}




__global__ void hotspot_gpu_keepalive_kernel(int *buf, int n, int repeat)
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

static void hotspot_gpu_keepalive(int num_cus)
{
    if (num_cus <= 0)
        return;

    int warmup_threads = BLOCK_SIZE * BLOCK_SIZE;
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

    printf("HOTSPOT_MT: GPU dummy blocks=%d threads=%d repeat=%d\n",
           warmup_blocks, warmup_threads, 64);

    hotspot_gpu_keepalive_kernel<<<warmup_blocks, warmup_threads>>>(
        warmup_buf, warmup_n, 64);

    err = hipDeviceSynchronize();
    if (err != hipSuccess) {
        fprintf(stderr, "hotspot GPU keepalive failed: %s\n",
                hipGetErrorString(err));
        exit(-1);
    }

    hipFree(warmup_buf);
}

/* maximum power density possible (say 300W for a 10mm x 10mm chip)	*/
#define MAX_PD	(3.0e6)
/* required precision in degrees	*/
#define PRECISION	0.001
#define SPEC_HEAT_SI 1.75e6
#define K_SI 100
/* capacitance fitting factor	*/
#define FACTOR_CHIP	0.5

/* chip parameters	*/
float t_chip = 0.0005;
float chip_height = 0.016;
float chip_width = 0.016;
/* ambient temperature, assuming no package at all	*/
float amb_temp = 80.0;

void run(int argc, char** argv);

typedef struct {
    int tid;
    unsigned int seed;
    volatile unsigned long long loops;
    volatile unsigned int *private_buf;
    size_t private_words;
} rodinia_mt_arg_t;

static int rodinia_mt_threads = 1;
static int rodinia_mt_work_percent = 8;
static unsigned int rodinia_mt_seed = 1;
static int rodinia_mt_inited = 0;
static int rodinia_mt_threads_set_by_arg = 0;
static int num_cus = 0;

static pthread_t *rodinia_mt_pool = NULL;
static rodinia_mt_arg_t *rodinia_mt_args = NULL;

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t  cond;
    int             count;
    int             total;
    int             generation;
} simple_barrier_t;

static simple_barrier_t rodinia_mt_start_barrier;

static volatile float *rodinia_mt_power = NULL;
static volatile float *rodinia_mt_temp0 = NULL;
static volatile float *rodinia_mt_temp1 = NULL;
static int rodinia_mt_items = 0;

static volatile unsigned int *rodinia_mt_private = NULL;
static size_t rodinia_mt_private_words_per_thread = 0;

static void simple_barrier_init(simple_barrier_t *b, int n)
{
    pthread_mutex_init(&b->mutex, NULL);
    pthread_cond_init(&b->cond, NULL);
    b->count = 0;
    b->total = n;
    b->generation = 0;
}

static void simple_barrier_wait(simple_barrier_t *b)
{
    pthread_mutex_lock(&b->mutex);

    int gen = b->generation;
    b->count++;

    if (b->count == b->total) {
        b->count = 0;
        b->generation++;
        pthread_cond_broadcast(&b->cond);
    } else {
        while (gen == b->generation) {
            pthread_cond_wait(&b->cond, &b->mutex);
        }
    }

    pthread_mutex_unlock(&b->mutex);
}

static void simple_barrier_destroy(simple_barrier_t *b)
{
    pthread_cond_destroy(&b->cond);
    pthread_mutex_destroy(&b->mutex);
}

static inline unsigned int rodinia_mt_xorshift32(unsigned int *state)
{
    unsigned int x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x ? x : 1u;
    return *state;
}

static void rodinia_mt_set_threads(int n)
{
    rodinia_mt_threads = (n > 0) ? n : 1;
    rodinia_mt_threads_set_by_arg = 1;
}

static void rodinia_mt_init_cfg(void)
{
    if (rodinia_mt_inited)
        return;

    const char *s_work = getenv("RODINIA_SHARE_PERCENT");
    const char *s_seed = getenv("RODINIA_SHARE_SEED");

    /*
     * Keep the same behavior as Gaussian:
     * - without --cpu-workers, use one worker by default;
     * - with --cpu-workers N, use N workers.
     */
    if (!rodinia_mt_threads_set_by_arg)
        rodinia_mt_threads = 1;

    if (s_work)
        rodinia_mt_work_percent = atoi(s_work);
    if (s_seed)
        rodinia_mt_seed = (unsigned int)atoi(s_seed);

    if (rodinia_mt_threads <= 0)
        rodinia_mt_threads = 1;
    if (rodinia_mt_work_percent < 0)
        rodinia_mt_work_percent = 0;
    if (rodinia_mt_work_percent > 100)
        rodinia_mt_work_percent = 100;
    if (rodinia_mt_seed == 0)
        rodinia_mt_seed = 1;

    HOTSPOT_TRACE("mt cfg: threads=%d work_percent=%d seed=%u",
                  rodinia_mt_threads,
                  rodinia_mt_work_percent,
                  rodinia_mt_seed);

    rodinia_mt_inited = 1;
}

static void *rodinia_mt_worker_once(void *p)
{
    rodinia_mt_arg_t *arg = (rodinia_mt_arg_t *)p;

    simple_barrier_wait(&rodinia_mt_start_barrier);

    unsigned int s = arg->seed ^ (unsigned int)(arg->tid + 1) * 0x9e3779b9u;

    int nitems = rodinia_mt_items;

    if (nitems <= 0 || rodinia_mt_threads <= 0) {
        volatile unsigned int acc = 0;
        for (int i = 0; i < 1024; i++)
            acc += rodinia_mt_xorshift32(&s);
        arg->loops++;
        return NULL;
    }

    int begin = (nitems * arg->tid) / rodinia_mt_threads;
    int end   = (nitems * (arg->tid + 1)) / rodinia_mt_threads;
    int own_count = end - begin;

    if (own_count <= 0) {
        arg->loops++;
        return NULL;
    }

    int sample_count = (own_count * rodinia_mt_work_percent) / 100;
    if (sample_count < 32)
        sample_count = 32;

    int window_start = begin - own_count;
    int window_end   = end + own_count;

    if (window_start < 0)
        window_start = 0;
    if (window_end > nitems)
        window_end = nitems;

    int window_count = window_end - window_start;
    if (window_count <= 0)
        window_count = own_count;

    volatile unsigned int acc = 0;

    /*
     * Phase A-like:
     * random reads from this worker's local range in the managed arrays,
     * writes only to the CPU-private buffer.
     */
    for (int r = 0; r < sample_count; r++) {
        int idx = begin + (int)(rodinia_mt_xorshift32(&s) %
                                (unsigned int)own_count);

        float v = 0.0f;

        if (rodinia_mt_temp0)
            v += rodinia_mt_temp0[idx];

        acc += (unsigned int)(((int)(v * 1000.0f)) ^ idx);

        if (arg->private_buf != NULL && arg->private_words > 0) {
            size_t pidx = (size_t)(rodinia_mt_xorshift32(&s) %
                                   (unsigned int)arg->private_words);
            arg->private_buf[pidx] =
                acc + (unsigned int)arg->tid + (unsigned int)r;
        }
    }

    /*
     * Phase B-like:
     * Keep the neighboring-window behavior, but sample it sparsely so the
     * CPU phase stays present without dominating overall ldst samples.
     */
    for (int r = 0; r < sample_count; r += 4) {
        int idx = window_start + (int)(rodinia_mt_xorshift32(&s) %
                                       (unsigned int)window_count);

        float v = 0.0f;

        if (rodinia_mt_temp1)
            v += rodinia_mt_temp1[idx];

        acc += (unsigned int)(((int)(v * 1000.0f)) ^ idx);
    }

    arg->loops++;
    return NULL;
}

static void rodinia_mt_cpu_phase(float *power, float *temp0, float *temp1, int nitems, int iter)
{
    rodinia_mt_init_cfg();

    if (rodinia_mt_work_percent <= 0) {
        HOTSPOT_TRACE("CPU phase skipped iter=%d work_percent=%d",
                      iter, rodinia_mt_work_percent);
        return;
    }

    rodinia_mt_power = (volatile float *)power;
    rodinia_mt_temp0 = (volatile float *)temp0;
    rodinia_mt_temp1 = (volatile float *)temp1;
    rodinia_mt_items = nitems;

    int n = rodinia_mt_threads;

    simple_barrier_init(&rodinia_mt_start_barrier, n + 1);

    if (rodinia_mt_pool == NULL) {
        rodinia_mt_pool = (pthread_t *)malloc((size_t)n * sizeof(pthread_t));
    }

    if (rodinia_mt_args == NULL) {
        rodinia_mt_args = (rodinia_mt_arg_t *)malloc((size_t)n * sizeof(rodinia_mt_arg_t));
    }

    if (rodinia_mt_private == NULL) {
        rodinia_mt_private_words_per_thread = 8192;
        rodinia_mt_private =
            (volatile unsigned int *)calloc((size_t)n * rodinia_mt_private_words_per_thread,
                                            sizeof(unsigned int));
    }

    if (!rodinia_mt_pool || !rodinia_mt_args || !rodinia_mt_private) {
        fprintf(stderr, "failed to allocate CPU worker data\n");
        exit(1);
    }

    HOTSPOT_TRACE("CPU phase start iter=%d threads=%d total_items=%d work_percent=%d",
                  iter, n, nitems, rodinia_mt_work_percent);

    for (int t = 0; t < n; t++) {
        rodinia_mt_args[t].tid = t;
        rodinia_mt_args[t].seed = rodinia_mt_seed ^ (unsigned int)(t + 1) ^ (unsigned int)iter;
        rodinia_mt_args[t].loops = 0;
        rodinia_mt_args[t].private_buf =
            rodinia_mt_private + (size_t)t * rodinia_mt_private_words_per_thread;
        rodinia_mt_args[t].private_words = rodinia_mt_private_words_per_thread;

        HOTSPOT_TRACE("Creating pthread tid=%d iter=%d", t, iter);

        int rc = pthread_create(&rodinia_mt_pool[t], NULL,
                                rodinia_mt_worker_once,
                                &rodinia_mt_args[t]);

        if (rc != 0) {
            fprintf(stderr,
                    "pthread_create failed tid=%d iter=%d rc=%d\n",
                    t, iter, rc);
            exit(1);
        }

        HOTSPOT_TRACE("pthread_create success tid=%d iter=%d", t, iter);
    }

    HOTSPOT_TRACE("Main thread waiting at CPU start barrier iter=%d", iter);

    simple_barrier_wait(&rodinia_mt_start_barrier);

    HOTSPOT_TRACE("CPU workers released iter=%d", iter);

    /*
     * pthread_join waits until each one-shot worker has completed its CPU work.
     */
    for (int t = 0; t < n; t++) {
        HOTSPOT_TRACE("Joining pthread tid=%d iter=%d", t, iter);

        int rc = pthread_join(rodinia_mt_pool[t], NULL);
        if (rc != 0) {
            fprintf(stderr,
                    "pthread_join failed tid=%d iter=%d rc=%d\n",
                    t, iter, rc);
            exit(1);
        }

        HOTSPOT_TRACE("Joined pthread tid=%d iter=%d loops=%llu",
                      t, iter,
                      (unsigned long long)rodinia_mt_args[t].loops);
    }

    // simple_barrier_destroy(&rodinia_mt_start_barrier);

    rodinia_mt_power = NULL;
    rodinia_mt_temp0 = NULL;
    rodinia_mt_temp1 = NULL;
    rodinia_mt_items = 0;

    HOTSPOT_TRACE("CPU phase completed iter=%d", iter);
}

static void parse_optional_mt_args(int argc, char **argv)
{
    for (int i = 6; i < argc; i++) {
        if (strcmp(argv[i], "--cpu-workers") == 0 && i + 1 < argc) {
            rodinia_mt_set_threads(atoi(argv[++i]));
        } else if (strncmp(argv[i], "--cpu-workers=", 17) == 0) {
            rodinia_mt_set_threads(atoi(argv[i] + 17));
        } else if (strcmp(argv[i], "--gpu-cus") == 0 && i + 1 < argc) {
            num_cus = atoi(argv[++i]);
        } else if (strncmp(argv[i], "--gpu-cus=", 10) == 0) {
            num_cus = atoi(argv[i] + 10);
        } else if (strcmp(argv[i], "--share-percent") == 0 && i + 1 < argc) {
            rodinia_mt_work_percent = atoi(argv[++i]);
        } else if (strncmp(argv[i], "--share-percent=", 16) == 0) {
            rodinia_mt_work_percent = atoi(argv[i] + 16);
        }
    }

    if (rodinia_mt_threads <= 0)
        rodinia_mt_threads = 1;

    if (num_cus < 0)
        num_cus = 0;
}

/* define timer macros */
#define pin_stats_reset()   startCycle()
#define pin_stats_pause(cycles)   stopCycle(cycles)
#define pin_stats_dump(cycles)    printf("timer: %Lu\n", cycles)



void 
fatal(const char *s)
{
	fprintf(stderr, "error: %s\n", s);
}

void writeoutput(float *vect, int grid_rows, int grid_cols, char *file){

	int i,j, index=0;
	FILE *fp;
	char str[STR_SIZE];

	if( (fp = fopen(file, "w" )) == 0 )
          printf( "The file was not opened\n" );

	for (i=0; i < grid_rows; i++) 
	 for (j=0; j < grid_cols; j++)
	 {
		 sprintf(str, "%d\t%g\n", index, vect[i*grid_cols+j]);
		 fputs(str,fp);
		 index++;
	 }
		
      fclose(fp);	
}


void readinput(float *vect, int grid_rows, int grid_cols, char *file)
{
    int i, j;
    FILE *fp;
    char str[STR_SIZE];
    float val;

    fp = fopen(file, "r");
    if (fp == NULL) {
        fprintf(stderr, "error: cannot open input file: %s\n", file);
        perror("fopen");
        exit(1);
    }

    for (i = 0; i < grid_rows; i++) {
        for (j = 0; j < grid_cols; j++) {
            if (fgets(str, STR_SIZE, fp) == NULL) {
                fprintf(stderr,
                        "error: not enough lines in file %s, expected %d lines, failed at line %d\n",
                        file,
                        grid_rows * grid_cols,
                        i * grid_cols + j + 1);
                fclose(fp);
                exit(1);
            }

            if (sscanf(str, "%f", &val) != 1) {
                fprintf(stderr,
                        "error: invalid file format in %s at line %d: %s\n",
                        file,
                        i * grid_cols + j + 1,
                        str);
                fclose(fp);
                exit(1);
            }

            vect[i * grid_cols + j] = val;
        }
    }

    fclose(fp);
}

#define IN_RANGE(x, min, max)   ((x)>=(min) && (x)<=(max))
#define CLAMP_RANGE(x, min, max) x = (x<(min)) ? min : ((x>(max)) ? max : x )
#define MIN(a, b) ((a)<=(b) ? (a) : (b))

__global__ void calculate_temp(int iteration,  //number of iteration
                               float *power,   //power input
                               float *temp_src,    //temperature input/output
                               float *temp_dst,    //temperature input/output
                               int grid_cols,  //Col of grid
                               int grid_rows,  //Row of grid
                               int block_cols,
                               int block_offset,
							   int border_cols,  // border offset 
							   int border_rows,  // border offset
                               float Cap,      //Capacitance
                               float Rx, 
                               float Ry, 
                               float Rz, 
                               float step, 
                               float time_elapsed){
	
        __shared__ float temp_on_cuda[BLOCK_SIZE][BLOCK_SIZE];
        __shared__ float power_on_cuda[BLOCK_SIZE][BLOCK_SIZE];
        __shared__ float temp_t[BLOCK_SIZE][BLOCK_SIZE]; // saving temparary temperature result

	float amb_temp = 80.0;
        float step_div_Cap;
        float Rx_1,Ry_1,Rz_1;
        
	int global_block = blockIdx.x + block_offset;
	int bx = global_block % block_cols;
        int by = global_block / block_cols;

	int tx=threadIdx.x;
	int ty=threadIdx.y;
	
	step_div_Cap=step/Cap;
	
	Rx_1=1/Rx;
	Ry_1=1/Ry;
	Rz_1=1/Rz;
	
        // each block finally computes result for a small block
        // after N iterations. 
        // it is the non-overlapping small blocks that cover 
        // all the input data

        // calculate the small block size
	int small_block_rows = BLOCK_SIZE-iteration*2;//EXPAND_RATE
	int small_block_cols = BLOCK_SIZE-iteration*2;//EXPAND_RATE

        // calculate the boundary for the block according to 
        // the boundary of its small block
        int blkY = small_block_rows*by-border_rows;
        int blkX = small_block_cols*bx-border_cols;
        int blkYmax = blkY+BLOCK_SIZE-1;
        int blkXmax = blkX+BLOCK_SIZE-1;

        // calculate the global thread coordination
	int yidx = blkY+ty;
	int xidx = blkX+tx;

        // load data if it is within the valid input range
	int loadYidx=yidx, loadXidx=xidx;
        int index = grid_cols*loadYidx+loadXidx;
       
	if(IN_RANGE(loadYidx, 0, grid_rows-1) && IN_RANGE(loadXidx, 0, grid_cols-1)){
            temp_on_cuda[ty][tx] = temp_src[index];  // Load the temperature data from global memory to shared memory
            power_on_cuda[ty][tx] = power[index];// Load the power data from global memory to shared memory
	}
	__syncthreads();

        // effective range within this block that falls within 
        // the valid range of the input data
        // used to rule out computation outside the boundary.
        int validYmin = (blkY < 0) ? -blkY : 0;
        int validYmax = (blkYmax > grid_rows-1) ? BLOCK_SIZE-1-(blkYmax-grid_rows+1) : BLOCK_SIZE-1;
        int validXmin = (blkX < 0) ? -blkX : 0;
        int validXmax = (blkXmax > grid_cols-1) ? BLOCK_SIZE-1-(blkXmax-grid_cols+1) : BLOCK_SIZE-1;

        int N = ty-1;
        int S = ty+1;
        int W = tx-1;
        int E = tx+1;
        
        N = (N < validYmin) ? validYmin : N;
        S = (S > validYmax) ? validYmax : S;
        W = (W < validXmin) ? validXmin : W;
        E = (E > validXmax) ? validXmax : E;

        bool computed;
        for (int i=0; i<iteration ; i++){ 
            computed = false;
            if( IN_RANGE(tx, i+1, BLOCK_SIZE-i-2) &&  \
                  IN_RANGE(ty, i+1, BLOCK_SIZE-i-2) &&  \
                  IN_RANGE(tx, validXmin, validXmax) && \
                  IN_RANGE(ty, validYmin, validYmax) ) {
                  computed = true;
                  temp_t[ty][tx] =   temp_on_cuda[ty][tx] + step_div_Cap * (power_on_cuda[ty][tx] + 
	       	         (temp_on_cuda[S][tx] + temp_on_cuda[N][tx] - 2.0*temp_on_cuda[ty][tx]) * Ry_1 + 
		             (temp_on_cuda[ty][E] + temp_on_cuda[ty][W] - 2.0*temp_on_cuda[ty][tx]) * Rx_1 + 
		             (amb_temp - temp_on_cuda[ty][tx]) * Rz_1);
	
            }
            __syncthreads();
            if(i==iteration-1)
                break;
            if(computed)	 //Assign the computation range
                temp_on_cuda[ty][tx]= temp_t[ty][tx];
            __syncthreads();
          }

      // update the global memory
      // after the last iteration, only threads coordinated within the 
      // small block perform the calculation and switch on ``computed''
      if (computed){
          temp_dst[index]= temp_t[ty][tx];		
      }
}

/*
   compute N time steps
*/

int compute_tran_temp(float *MatrixPower,float *MatrixTemp[2], int col, int row, \
		int total_iterations, int num_iterations, int blockCols, int blockRows, int borderCols, int borderRows) 
{
    dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE);
	
	float grid_height = chip_height / row;
	float grid_width = chip_width / col;

	float Cap = FACTOR_CHIP * SPEC_HEAT_SI * t_chip * grid_width * grid_height;
	float Rx = grid_width / (2.0 * K_SI * t_chip * grid_height);
	float Ry = grid_height / (2.0 * K_SI * t_chip * grid_width);
	float Rz = t_chip / (K_SI * grid_height * grid_width);

	float max_slope = MAX_PD / (FACTOR_CHIP * t_chip * SPEC_HEAT_SI);
	float step = PRECISION / max_slope;
	int t;
    float time_elapsed;
	time_elapsed=0.001;

    int src = 1, dst = 0;

	HOTSPOT_TRACE("compute_tran_temp enter total_iterations=%d num_iterations=%d grid=%dx%d",
              total_iterations, num_iterations, blockCols, blockRows);

	for (t = 0; t < total_iterations; t += num_iterations) {
        int temp = src;
        src = dst;
        dst = temp;
        
        HOTSPOT_TRACE("launch calculate_temp t=%d src=%d dst=%d iter=%d",
                  (int)t, src, dst,
                  MIN(num_iterations, total_iterations - t));

        int total_blocks = blockCols * blockRows;
        for (int block_base = 0; block_base < total_blocks;
             block_base += HOTSPOT_REAL_BLOCK_CHUNK) {
            int remaining_blocks = total_blocks - block_base;
            int launch_blocks = remaining_blocks < HOTSPOT_REAL_BLOCK_CHUNK ?
                remaining_blocks : HOTSPOT_REAL_BLOCK_CHUNK;
            dim3 batchGrid(launch_blocks, 1);

            calculate_temp<<<batchGrid, dimBlock>>>(
                MIN(num_iterations, total_iterations - t),
                MatrixPower,
                MatrixTemp[src],
                MatrixTemp[dst],
                col,
                row,
                blockCols,
                block_base,
                borderCols,
                borderRows,
                Cap,
                Rx,
                Ry,
                Rz,
                step,
                time_elapsed);
            hipError_t launch_err = hipGetLastError();
            HOTSPOT_TRACE("after calculate_temp launch t=%d block_base=%d blocks=%d err=%d %s",
                        (int)t, block_base, launch_blocks,
                        launch_err, hipGetErrorString(launch_err));

            if (launch_err != hipSuccess) {
                return dst;
            }

            hipError_t sync_err = hipDeviceSynchronize();
            if (sync_err != hipSuccess) {
                HOTSPOT_TRACE("calculate_temp batch sync failed t=%d block_base=%d err=%d %s",
                            (int)t, block_base,
                            sync_err, hipGetErrorString(sync_err));
                return dst;
            }
        }
    }
    HOTSPOT_TRACE("compute_tran_temp leave dst=%d", dst);
    return dst;
}

void usage(int argc, char **argv)
{
	fprintf(stderr, "Usage: %s <grid_rows/grid_cols> <pyramid_height> <sim_time> <temp_file> <power_file> [output_file] [--cpu-workers N] [--gpu-cus N] [--share-percent P]\n", argv[0]);
	fprintf(stderr, "\t<grid_rows/grid_cols>  - number of rows/cols in the grid (positive integer)\n");
	fprintf(stderr, "\t<pyramid_height> - pyramid heigh(positive integer)\n");
	fprintf(stderr, "\t<sim_time>   - number of iterations\n");
	fprintf(stderr, "\t<temp_file>  - name of the file containing the initial temperature values of each cell\n");
	fprintf(stderr, "\t<power_file> - name of the file containing the dissipated power values of each cell\n");
	fprintf(stderr, "\t<output_file> - name of the output file\n");
	exit(1);
}

int main(int argc, char** argv)
{
    HOTSPOT_TRACE("WG size of kernel = %d X %d", BLOCK_SIZE, BLOCK_SIZE);

    run(argc,argv);

    HOTSPOT_TRACE("PASSED!");

    return EXIT_SUCCESS;
}

void run(int argc, char** argv)
{
    int size;
    int grid_rows,grid_cols;
    float *FilesavingTemp,*FilesavingPower,*MatrixOut; 
    char *tfile, *pfile, *ofile;
    
    int total_iterations = 60;
    int pyramid_height = 1; // number of iterations
	
	if (argc < 6)
		usage(argc, argv);
	if((grid_rows = atoi(argv[1]))<=0||
	   (grid_cols = atoi(argv[1]))<=0||
       (pyramid_height = atoi(argv[2]))<=0||
       (total_iterations = atoi(argv[3]))<=0)
		usage(argc, argv);
		
	tfile=argv[4];
    pfile=argv[5];
    // ofile=argv[6];
	parse_optional_mt_args(argc, argv);
	
    size=grid_rows*grid_cols;

    /* --------------- pyramid parameters --------------- */
    # define EXPAND_RATE 2// add one iteration will extend the pyramid base by 2 per each borderline
    int borderCols = (pyramid_height)*EXPAND_RATE/2;
    int borderRows = (pyramid_height)*EXPAND_RATE/2;
    int smallBlockCol = BLOCK_SIZE-(pyramid_height)*EXPAND_RATE;
    int smallBlockRow = BLOCK_SIZE-(pyramid_height)*EXPAND_RATE;
    int blockCols = grid_cols/smallBlockCol+((grid_cols%smallBlockCol==0)?0:1);
    int blockRows = grid_rows/smallBlockRow+((grid_rows%smallBlockRow==0)?0:1);

    if (num_cus > 0 && blockCols * blockRows < num_cus) {
        int target_side = (int)ceil(sqrt((double)num_cus));

        if (blockCols < target_side)
            blockCols = target_side;

        if (blockRows < target_side)
            blockRows = target_side;

        HOTSPOT_TRACE("expand grid to %d x %d for gpu_cus=%d",
            blockCols, blockRows, num_cus);
    }

    HOTSPOT_TRACE("cpu_workers=%d gpu_cus=%d blockGrid=[%d,%d] blockSize=%dx%d",
        rodinia_mt_threads,
        num_cus,
        blockCols,
        blockRows,
        BLOCK_SIZE,
        BLOCK_SIZE);

    // 原来：FilesavingTemp/FilesavingPower/MatrixOut 在 host，GPU 有对应 device 缓冲区，需要 hipMemcpy
    // 现在：统一内存 managed 分配，一份指针在 CPU/GPU 之间共享
    FilesavingTemp = (float *)checked_hip_malloc_managed(size*sizeof(float));
    FilesavingPower = (float *)checked_hip_malloc_managed(size*sizeof(float));
    MatrixOut = (float *)checked_hip_malloc_managed(size*sizeof(float));

    if( !FilesavingPower || !FilesavingTemp || !MatrixOut)
        fatal("unable to allocate memory");
    memset(MatrixOut, 0, sizeof(float)*size);

    HOTSPOT_TRACE("pyramidHeight: %d gridSize: [%d, %d] border:[%d, %d] blockGrid:[%d, %d] targetBlock:[%d, %d]",\
	pyramid_height, grid_cols, grid_rows, borderCols, borderRows, blockCols, blockRows, smallBlockCol, smallBlockRow);
	
    HOTSPOT_TRACE("Reading input from files %s and %s", tfile, pfile);
    readinput(FilesavingTemp, grid_rows, grid_cols, tfile);
    readinput(FilesavingPower, grid_rows, grid_cols, pfile);

    float *MatrixTemp[2], *MatrixPower;
    // 原来：MatrixTemp/MatrixPower 在 device，Filesaving* 在 host，需要 H2D 拷贝
    // 现在：全部是 managed 内存，memcpy 只是 CPU 侧初始化拷贝
    MatrixTemp[0] = (float *)checked_hip_malloc_managed(sizeof(float)*size);
    MatrixTemp[1] = (float *)checked_hip_malloc_managed(sizeof(float)*size);
    memcpy(MatrixTemp[0], FilesavingTemp, sizeof(float)*size);
    memcpy(MatrixTemp[1], FilesavingTemp, sizeof(float)*size);

    MatrixPower = (float *)checked_hip_malloc_managed(sizeof(float)*size);
    memcpy(MatrixPower, FilesavingPower, sizeof(float)*size);

    HOTSPOT_TRACE("Gaussian-style sequential CPU-then-GPU phase start");

    HOTSPOT_TRACE("CPU batch phase start");
    rodinia_mt_cpu_phase(MatrixPower, MatrixTemp[0], MatrixTemp[1], size, 0);
    HOTSPOT_TRACE("CPU batch phase done");

    HOTSPOT_TRACE("GPU batch phase start");

    int ret = compute_tran_temp(MatrixPower, MatrixTemp, grid_cols, grid_rows,
                                total_iterations, pyramid_height,
                                blockCols, blockRows, borderCols, borderRows);

    hotspot_gpu_keepalive(num_cus);

    HOTSPOT_TRACE("after compute_tran_temp, before hipDeviceSynchronize");

    hipError_t e = hipDeviceSynchronize();

    HOTSPOT_TRACE("after hipDeviceSynchronize err=%d %s",
        e, hipGetErrorString(e));

    HOTSPOT_TRACE("GPU batch phase done");
    HOTSPOT_TRACE("Gaussian-style sequential CPU-then-GPU phase done");

    HOTSPOT_TRACE("Ending simulation");

    memcpy(MatrixOut, MatrixTemp[ret], sizeof(float) * size);

    // writeoutput(MatrixOut,grid_rows, grid_cols, ofile);


    hipFree(MatrixPower);
    hipFree(MatrixTemp[0]);
    hipFree(MatrixTemp[1]);
    hipFree(MatrixOut);
    hipFree(FilesavingTemp);
    hipFree(FilesavingPower);
}
