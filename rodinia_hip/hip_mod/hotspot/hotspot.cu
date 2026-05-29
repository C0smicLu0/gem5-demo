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

#define HOTSPOT_TRACE(fmt, ...)                                      \
    do {                                                             \
        printf("[hotspot][trace] " fmt "\n", ##__VA_ARGS__);         \
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
static int num_cus = 0;

static pthread_t *rodinia_mt_pool = NULL;
static rodinia_mt_arg_t *rodinia_mt_args = NULL;
static volatile int rodinia_mt_stop = 0;
static int rodinia_mt_started = 0;

static volatile float *rodinia_mt_power = NULL;
static volatile float *rodinia_mt_temp0 = NULL;
static volatile float *rodinia_mt_temp1 = NULL;
static int rodinia_mt_items = 0;

static volatile unsigned int *rodinia_mt_private = NULL;
static size_t rodinia_mt_private_words_per_thread = 0;

static unsigned int *hotspot_keepalive_buf = NULL;
static int hotspot_keepalive_n = 0;

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
    if (n > 0)
        rodinia_mt_threads = n;
}

static void *rodinia_mt_worker(void *p)
{
    rodinia_mt_arg_t *arg = (rodinia_mt_arg_t *)p;
    unsigned int s = arg->seed ^ (unsigned int)(arg->tid + 1) * 0x9e3779b9u;

    while (!rodinia_mt_stop) {
        int nitems = rodinia_mt_items;

        if (nitems <= 0 || rodinia_mt_threads <= 0) {
            volatile unsigned int acc = 0;
            for (int i = 0; i < 1024 && !rodinia_mt_stop; i++)
                acc += rodinia_mt_xorshift32(&s);
            arg->loops++;
            continue;
        }

        int begin = (nitems * arg->tid) / rodinia_mt_threads;
        int end   = (nitems * (arg->tid + 1)) / rodinia_mt_threads;
        int own_count = end - begin;

        if (own_count <= 0) {
            arg->loops++;
            continue;
        }

        int sample_count = (own_count * rodinia_mt_work_percent) / 100;
        if (sample_count < 64)
            sample_count = 64;

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

        // Phase A-like: 随机读本线程负责的局部区域，写 CPU 私有区
        for (int r = 0; r < sample_count && !rodinia_mt_stop; r++) {
            int idx = begin + (int)(rodinia_mt_xorshift32(&s) %
                                    (unsigned int)own_count);

            float v = 0.0f;

            if (rodinia_mt_power)
                v += rodinia_mt_power[idx];
            if (rodinia_mt_temp0)
                v += rodinia_mt_temp0[idx];
            if (rodinia_mt_temp1)
                v += rodinia_mt_temp1[idx];

            acc += (unsigned int)(((int)(v * 1000.0f)) ^ idx);

            if (arg->private_buf != NULL && arg->private_words > 0) {
                size_t pidx = (size_t)(rodinia_mt_xorshift32(&s) %
                                       (unsigned int)arg->private_words);
                arg->private_buf[pidx] =
                    acc + (unsigned int)arg->tid + (unsigned int)r;
            }
        }

        // Phase B-like: 随机读邻域窗口，模拟 BFS 的局部邻域访问
        for (int r = 0; r < sample_count && !rodinia_mt_stop; r++) {
            int idx = window_start + (int)(rodinia_mt_xorshift32(&s) %
                                           (unsigned int)window_count);

            float v = 0.0f;

            if (rodinia_mt_power)
                v += rodinia_mt_power[idx];
            if (rodinia_mt_temp0)
                v += rodinia_mt_temp0[idx];
            if (rodinia_mt_temp1)
                v += rodinia_mt_temp1[idx];

            acc += (unsigned int)(((int)(v * 1000.0f)) ^ idx);
        }

        arg->loops++;
    }

    return NULL;
}

static void rodinia_mt_start_pool(float *power, float *temp0, float *temp1, int nitems)
{
    if (rodinia_mt_started || rodinia_mt_work_percent <= 0)
        return;

    const char *s_work = getenv("RODINIA_SHARE_PERCENT");
    const char *s_seed = getenv("RODINIA_SHARE_SEED");

    if (s_work)
        rodinia_mt_work_percent = atoi(s_work);
    if (s_seed)
        rodinia_mt_seed = (unsigned int)atoi(s_seed);

    if (rodinia_mt_work_percent < 0)
        rodinia_mt_work_percent = 0;
    if (rodinia_mt_work_percent > 100)
        rodinia_mt_work_percent = 100;
    if (rodinia_mt_seed == 0)
        rodinia_mt_seed = 1;
    if (rodinia_mt_threads <= 0)
        rodinia_mt_threads = 1;

    rodinia_mt_power = (volatile float *)power;
    rodinia_mt_temp0 = (volatile float *)temp0;
    rodinia_mt_temp1 = (volatile float *)temp1;
    rodinia_mt_items = nitems;

    int n = rodinia_mt_threads;

    rodinia_mt_pool = (pthread_t *)malloc((size_t)n * sizeof(pthread_t));
    rodinia_mt_args = (rodinia_mt_arg_t *)malloc((size_t)n * sizeof(rodinia_mt_arg_t));

    rodinia_mt_private_words_per_thread = 8192;
    rodinia_mt_private =
        (volatile unsigned int *)calloc((size_t)n * rodinia_mt_private_words_per_thread,
                                        sizeof(unsigned int));

    if (!rodinia_mt_pool || !rodinia_mt_args || !rodinia_mt_private) {
        fprintf(stderr, "[rodinia_mt][hotspot] failed to allocate CPU worker data\n");
        exit(1);
    }

    rodinia_mt_stop = 0;

    for (int t = 0; t < n; t++) {
        rodinia_mt_args[t].tid = t;
        rodinia_mt_args[t].seed = rodinia_mt_seed ^ (unsigned int)(t + 1);
        rodinia_mt_args[t].loops = 0;
        rodinia_mt_args[t].private_buf =
            rodinia_mt_private + (size_t)t * rodinia_mt_private_words_per_thread;
        rodinia_mt_args[t].private_words = rodinia_mt_private_words_per_thread;

        int rc = pthread_create(&rodinia_mt_pool[t], NULL,
                                rodinia_mt_worker, &rodinia_mt_args[t]);
        HOTSPOT_TRACE("[rodinia_mt][hotspot] create tid=%d rc=%d", t, rc);

        if (rc != 0) {
            fprintf(stderr, "[rodinia_mt][hotspot] pthread_create failed tid=%d rc=%d\n", t, rc);
            exit(1);
        }
    }

    rodinia_mt_started = 1;
}

static void rodinia_mt_stop_pool(void)
{
    if (!rodinia_mt_started)
        return;

    rodinia_mt_stop = 1;

    for (int t = 0; t < rodinia_mt_threads; t++) {
        pthread_join(rodinia_mt_pool[t], NULL);
    }

    for (int t = 0; t < rodinia_mt_threads; t++) {
        HOTSPOT_TRACE("[rodinia_mt][hotspot] tid=%d loops=%llu",
               t, (unsigned long long)rodinia_mt_args[t].loops);
    }

    free(rodinia_mt_pool);
    free(rodinia_mt_args);
    free((void *)rodinia_mt_private);

    rodinia_mt_pool = NULL;
    rodinia_mt_args = NULL;
    rodinia_mt_private = NULL;
    rodinia_mt_private_words_per_thread = 0;

    rodinia_mt_power = NULL;
    rodinia_mt_temp0 = NULL;
    rodinia_mt_temp1 = NULL;
    rodinia_mt_items = 0;

    rodinia_mt_started = 0;
}

static void rodinia_mt_run_cpu_phase(float *power, float *temp0, float *temp1, int nitems)
{
    rodinia_mt_start_pool(power, temp0, temp1, nitems);

    while (1) {
        int done = 1;
        for (int t = 0; t < rodinia_mt_threads; t++) {
            if (rodinia_mt_args[t].loops < 100) {
                done = 0;
                break;
            }
        }
        if (done)
            break;

        sched_yield();
    }

    rodinia_mt_stop_pool();
}

static void parse_optional_mt_args(int argc, char **argv)
{
    for (int i = 7; i < argc; i++) {
        if (strcmp(argv[i], "--cpu-workers") == 0 && i + 1 < argc) {
            rodinia_mt_set_threads(atoi(argv[++i]));
        } else if (strncmp(argv[i], "--cpu-workers=", 17) == 0) {
            rodinia_mt_set_threads(atoi(argv[i] + 17));
        } else if (strcmp(argv[i], "--gpu-cus") == 0 && i + 1 < argc) {
            num_cus = atoi(argv[++i]);
        } else if (strncmp(argv[i], "--gpu-cus=", 10) == 0) {
            num_cus = atoi(argv[i] + 10);
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


void readinput(float *vect, int grid_rows, int grid_cols, char *file){

  	int i,j;
	FILE *fp;
	char str[STR_SIZE];
	float val;

	if( (fp  = fopen(file, "r" )) ==0 )
        printf( "The file was not opened\n" );

	for (i=0; i <= grid_rows-1; i++) 
	 for (j=0; j <= grid_cols-1; j++)
	 {
		fgets(str, STR_SIZE, fp);
		if (feof(fp))
			fatal("not enough lines in file");
		//if ((sscanf(str, "%d%f", &index, &val) != 2) || (index != ((i-1)*(grid_cols-2)+j-1)))
		if ((sscanf(str, "%f", &val) != 1))
			fatal("invalid file format");
		vect[i*grid_cols+j] = val;
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
        
	int bx = blockIdx.x;
        int by = blockIdx.y;

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

__global__ void hotspot_gpu_keepalive(unsigned int *buf, int n, int rounds)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned int x = (unsigned int)(tid + 1);

    for (int i = 0; i < rounds; i++) {
        x ^= x << 13;
        x ^= x >> 17;
        x ^= x << 5;
    }

    if (tid < n)
        buf[tid] = x;
}

/*
   compute N time steps
*/

int compute_tran_temp(float *MatrixPower,float *MatrixTemp[2], int col, int row, \
		int total_iterations, int num_iterations, int blockCols, int blockRows, int borderCols, int borderRows) 
{
    dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE);
    dim3 dimGrid(blockCols, blockRows);  
	
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

        calculate_temp<<<dimGrid, dimBlock>>>(
            MIN(num_iterations, total_iterations - t),
            MatrixPower,
            MatrixTemp[src],
            MatrixTemp[dst],
            col,
            row,
            borderCols,
            borderRows,
            Cap,
            Rx,
            Ry,
            Rz,
            step,
            time_elapsed);
        hipError_t launch_err = hipGetLastError();
        HOTSPOT_TRACE("after calculate_temp launch t=%d err=%d %s",
                    (int)t, launch_err, hipGetErrorString(launch_err));

        if (launch_err != hipSuccess) {
            return dst;
        }

        if (num_cus > 0 && hotspot_keepalive_buf != NULL) {
            HOTSPOT_TRACE("launch hotspot_gpu_keepalive t=%d num_cus=%d n=%d rounds=%d",
                        (int)t, num_cus, hotspot_keepalive_n, 256);

            hotspot_gpu_keepalive<<<num_cus, 64>>>(
                hotspot_keepalive_buf,
                hotspot_keepalive_n,
                256);

            hipError_t keep_err = hipGetLastError();
            HOTSPOT_TRACE("after keepalive launch t=%d err=%d %s",
                        (int)t, keep_err, hipGetErrorString(keep_err));

            if (keep_err != hipSuccess) {
                return dst;
            }
        }
    }
    HOTSPOT_TRACE("compute_tran_temp leave dst=%d", dst);
    return dst;
}

void usage(int argc, char **argv)
{
	fprintf(stderr, "Usage: %s <grid_rows/grid_cols> <pyramid_height> <sim_time> <temp_file> <power_file> <output_file>\n", argv[0]);
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
	
	if (argc < 7)
		usage(argc, argv);
	if((grid_rows = atoi(argv[1]))<=0||
	   (grid_cols = atoi(argv[1]))<=0||
       (pyramid_height = atoi(argv[2]))<=0||
       (total_iterations = atoi(argv[3]))<=0)
		usage(argc, argv);
		
	tfile=argv[4];
    pfile=argv[5];
    ofile=argv[6];
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

        HOTSPOT_TRACE("[hotspot] expand grid to %d x %d for gpu_cus=%d",
            blockCols, blockRows, num_cus);
    }

    HOTSPOT_TRACE("[hotspot] cpu_workers=%d gpu_cus=%d blockGrid=[%d,%d] blockSize=%dx%d",
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
    
    if (num_cus > 0) {
        hotspot_keepalive_n = num_cus * 64;
        hotspot_keepalive_buf =
            (unsigned int *)checked_hip_malloc_managed(
                sizeof(unsigned int) * hotspot_keepalive_n);
        memset(hotspot_keepalive_buf, 0, sizeof(unsigned int) * hotspot_keepalive_n);
    }

    HOTSPOT_TRACE("Start computing the transient temperature");

    
    rodinia_mt_run_cpu_phase(MatrixPower, MatrixTemp[0], MatrixTemp[1], size);

    HOTSPOT_TRACE("[hotspot] before compute_tran_temp");

    int ret = compute_tran_temp(MatrixPower, MatrixTemp, grid_cols, grid_rows,
                                total_iterations, pyramid_height,
                                blockCols, blockRows, borderCols, borderRows);

    HOTSPOT_TRACE("[hotspot] after compute_tran_temp, before hipDeviceSynchronize");

    hipError_t e = hipDeviceSynchronize();

    HOTSPOT_TRACE("[hotspot] after hipDeviceSynchronize err=%d %s",
        e, hipGetErrorString(e));

    HOTSPOT_TRACE("Ending simulation");

    memcpy(MatrixOut, MatrixTemp[ret], sizeof(float) * size);

    writeoutput(MatrixOut,grid_rows, grid_cols, ofile);

    if (hotspot_keepalive_buf != NULL) {
        hipFree(hotspot_keepalive_buf);
        hotspot_keepalive_buf = NULL;
        hotspot_keepalive_n = 0;
    }

    hipFree(MatrixPower);
    hipFree(MatrixTemp[0]);
    hipFree(MatrixTemp[1]);
    hipFree(MatrixOut);
    hipFree(FilesavingTemp);
    hipFree(FilesavingPower);
}
