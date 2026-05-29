#include "hip/hip_runtime.h"
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/time.h>
#include "hip/hip_runtime.h"
#include <string.h>
#include <unistd.h>
#ifdef __linux__
#include <sched.h>
#endif
#include <math.h>

#define GAUSS_TRACE(fmt, ...)                                      \
    do {                                                           \
        printf("[gaussian][trace] " fmt "\n", ##__VA_ARGS__);     \
        fflush(stdout);                                            \
    } while (0)

#ifdef TIMING
#include "timing.h"
#endif

// ---- CPU multithread phase injected for heterogeneous MT experiments ----
typedef struct {
    int tid;
    unsigned int seed;
    volatile unsigned long long loops;
    volatile unsigned int *private_buf;
    size_t private_words;
} rodinia_mt_arg_t;

static int rodinia_mt_threads = 4;
static int rodinia_mt_work_percent = 8;
static unsigned int rodinia_mt_seed = 1;
static int rodinia_mt_inited = 0;
static volatile unsigned char *rodinia_mt_load_ptr = NULL;
static size_t rodinia_mt_load_bytes = 0;

static pthread_t *rodinia_mt_pool = NULL;
static rodinia_mt_arg_t *rodinia_mt_args = NULL;

static volatile float *rodinia_mt_a = NULL;
static volatile float *rodinia_mt_m = NULL;
static volatile float *rodinia_mt_b = NULL;
static int rodinia_mt_size = 0;

static int rodinia_mt_threads_set_by_arg = 0;

static volatile unsigned int *rodinia_mt_private = NULL;
static size_t rodinia_mt_private_words_per_thread = 0;

static inline unsigned int rodinia_mt_xorshift32(unsigned int *state) {
    unsigned int x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x ? x : 1u;
    return *state;
}

static void *rodinia_mt_worker_once(void *p)
{
    rodinia_mt_arg_t *arg = (rodinia_mt_arg_t *)p;
    unsigned int s = arg->seed ^ (unsigned int)(arg->tid + 1) * 0x9e3779b9u;

    int size = rodinia_mt_size;
    int total = size * size;

    if (size <= 0 || total <= 0 || rodinia_mt_threads <= 0) {
        volatile unsigned int acc = 0;
        for (int i = 0; i < 1024; i++)
            acc += rodinia_mt_xorshift32(&s);
        arg->loops++;
        return NULL;
    }

    int begin = (total * arg->tid) / rodinia_mt_threads;
    int end   = (total * (arg->tid + 1)) / rodinia_mt_threads;
    int own_count = end - begin;

    if (own_count <= 0) {
        arg->loops++;
        return NULL;
    }

    int sample_count = (own_count * rodinia_mt_work_percent) / 100;
    if (sample_count < 64)
        sample_count = 64;

    int window_start = begin - own_count;
    int window_end   = end + own_count;

    if (window_start < 0)
        window_start = 0;
    if (window_end > total)
        window_end = total;

    int window_count = window_end - window_start;
    if (window_count <= 0)
        window_count = own_count;

    volatile unsigned int acc = 0;

    // 局部随机读 shared arrays，写 CPU 私有区域
    for (int r = 0; r < sample_count; r++) {
        int idx = begin + (int)(rodinia_mt_xorshift32(&s) %
                                (unsigned int)own_count);

        float v = 0.0f;

        if (rodinia_mt_a)
            v += rodinia_mt_a[idx];
        if (rodinia_mt_m)
            v += rodinia_mt_m[idx];

        int bidx = idx % size;
        if (rodinia_mt_b)
            v += rodinia_mt_b[bidx];

        acc += (unsigned int)(((int)(v * 1000.0f)) ^ idx);

        if (arg->private_buf != NULL && arg->private_words > 0) {
            size_t pidx = (size_t)(rodinia_mt_xorshift32(&s) %
                                   (unsigned int)arg->private_words);
            arg->private_buf[pidx] =
                acc + (unsigned int)arg->tid + (unsigned int)r;
        }
    }

    // 邻域随机读
    for (int r = 0; r < sample_count; r++) {
        int idx = window_start + (int)(rodinia_mt_xorshift32(&s) %
                                       (unsigned int)window_count);

        float v = 0.0f;

        if (rodinia_mt_a)
            v += rodinia_mt_a[idx];
        if (rodinia_mt_m)
            v += rodinia_mt_m[idx];

        int bidx = idx % size;
        if (rodinia_mt_b)
            v += rodinia_mt_b[bidx];

        acc += (unsigned int)(((int)(v * 1000.0f)) ^ idx);
    }

    arg->loops++;
    return NULL;
}

static void rodinia_mt_init_cfg(void)
{
    if (rodinia_mt_inited) return;

    const char *s_work = getenv("RODINIA_SHARE_PERCENT");
    const char *s_seed = getenv("RODINIA_SHARE_SEED");

    if (!rodinia_mt_threads_set_by_arg) {
        rodinia_mt_threads = 1;
    }

    if (s_work) rodinia_mt_work_percent = atoi(s_work);
    if (s_seed) rodinia_mt_seed = (unsigned int)atoi(s_seed);

    if (rodinia_mt_threads <= 0) rodinia_mt_threads = 1;
    if (rodinia_mt_work_percent < 0) rodinia_mt_work_percent = 0;
    if (rodinia_mt_work_percent > 100) rodinia_mt_work_percent = 100;
    if (rodinia_mt_seed == 0) rodinia_mt_seed = 1;

    GAUSS_TRACE("mt cfg: threads=%d work_percent=%d seed=%u",
                rodinia_mt_threads,
                rodinia_mt_work_percent,
                rodinia_mt_seed);

    rodinia_mt_inited = 1;
}

static void rodinia_mt_run_cpu_phase(float *a_ptr,
                                     float *m_ptr,
                                     float *b_ptr,
                                     int size,
                                     int iter)
{
    rodinia_mt_init_cfg();

    if (rodinia_mt_work_percent <= 0)
        return;

    rodinia_mt_a = (volatile float *)a_ptr;
    rodinia_mt_m = (volatile float *)m_ptr;
    rodinia_mt_b = (volatile float *)b_ptr;
    rodinia_mt_size = size;

    int n = rodinia_mt_threads;

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
        fprintf(stderr, "[rodinia_mt][gaussian] failed to allocate CPU worker data\n");
        exit(1);
    }

    GAUSS_TRACE("CPU phase start iter=%d threads=%d size=%d", iter, n, size);

    for (int t = 0; t < n; t++) {
        rodinia_mt_args[t].tid = t;
        rodinia_mt_args[t].seed = rodinia_mt_seed ^ (unsigned int)(t + 1) ^ (unsigned int)iter;
        rodinia_mt_args[t].loops = 0;
        rodinia_mt_args[t].private_buf =
            rodinia_mt_private + (size_t)t * rodinia_mt_private_words_per_thread;
        rodinia_mt_args[t].private_words = rodinia_mt_private_words_per_thread;

        GAUSS_TRACE("Creating pthread tid=%d iter=%d", t, iter);

        int rc = pthread_create(&rodinia_mt_pool[t], NULL,
                                rodinia_mt_worker_once,
                                &rodinia_mt_args[t]);

        if (rc != 0) {
            fprintf(stderr,
                    "[rodinia_mt][gaussian] pthread_create failed tid=%d iter=%d rc=%d\n",
                    t, iter, rc);
            exit(1);
        }

        GAUSS_TRACE("pthread_create success tid=%d iter=%d", t, iter);
    }

    for (int t = 0; t < n; t++) {
        GAUSS_TRACE("Joining pthread tid=%d iter=%d", t, iter);

        int rc = pthread_join(rodinia_mt_pool[t], NULL);

        if (rc != 0) {
            fprintf(stderr,
                    "[rodinia_mt][gaussian] pthread_join failed tid=%d iter=%d rc=%d\n",
                    t, iter, rc);
            exit(1);
        }

        GAUSS_TRACE("Joined pthread tid=%d iter=%d loops=%llu",
                    t,
                    iter,
                    (unsigned long long)rodinia_mt_args[t].loops);
    }

    GAUSS_TRACE("CPU phase completed iter=%d", iter);
}

void rodinia_mt_set_threads(int n)
{
    rodinia_mt_threads = (n > 0) ? n : 1;
    rodinia_mt_threads_set_by_arg = 1;
}

typedef struct {
    int tid;
    int iters;
    unsigned int seed;
    unsigned char *shared;
    size_t shared_bytes;
} rodinia_mt_shared_arg_t;

#ifdef RD_WG_SIZE_0_0
        #define MAXBLOCKSIZE RD_WG_SIZE_0_0
#elif defined(RD_WG_SIZE_0)
        #define MAXBLOCKSIZE RD_WG_SIZE_0
#elif defined(RD_WG_SIZE)
        #define MAXBLOCKSIZE RD_WG_SIZE
#else
        #define MAXBLOCKSIZE 64
#endif

//2D defines. Go from specific to general                                                
#ifdef RD_WG_SIZE_1_0
        #define BLOCK_SIZE_XY RD_WG_SIZE_1_0
#elif defined(RD_WG_SIZE_1)
        #define BLOCK_SIZE_XY RD_WG_SIZE_1
#elif defined(RD_WG_SIZE)
        #define BLOCK_SIZE_XY RD_WG_SIZE
#else
        #define BLOCK_SIZE_XY 4
#endif

#ifdef TIMING
struct timeval tv;
struct timeval tv_total_start, tv_total_end;
struct timeval tv_h2d_start, tv_h2d_end;
struct timeval tv_d2h_start, tv_d2h_end;
struct timeval tv_kernel_start, tv_kernel_end;
struct timeval tv_mem_alloc_start, tv_mem_alloc_end;
struct timeval tv_close_start, tv_close_end;
float init_time = 0, mem_alloc_time = 0, h2d_time = 0, kernel_time = 0,
      d2h_time = 0, close_time = 0, total_time = 0;
#endif

int Size;
float *a, *b, *finalVec;
float *m;

int num_cus = 0;

FILE *fp;

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

void InitProblemOnce(char *filename);
void InitPerRun();
void ForwardSub();
void BackSub();
__global__ void Fan1(float *m, float *a, int Size, int t);
__global__ void Fan2(float *m, float *a, float *b,int Size, int j1, int t);
void InitMat(float *ary, int nrow, int ncol);
void InitAry(float *ary, int ary_size);
void PrintMat(float *ary, int nrow, int ncolumn);
void PrintAry(float *ary, int ary_size);
void PrintDeviceProperties();
void checkCUDAError(const char *msg);

unsigned int totalKernelTime = 0;

// create both matrix and right hand side, Ke Wang 2013/08/12 11:51:06
void
create_matrix(float *m, int size){
  int i,j;
  float lamda = -0.01;
  float coe[2*size-1];
  float coe_i =0.0;

  for (i=0; i < size; i++)
    {
      coe_i = 10*exp(lamda*i); 
      j=size-1+i;     
      coe[j]=coe_i;
      j=size-1-i;     
      coe[j]=coe_i;
    }


  for (i=0; i < size; i++) {
      for (j=0; j < size; j++) {
	m[i*size+j]=coe[size-1-i+j];
      }
  }


}

int main(int argc, char *argv[])
{
    GAUSS_TRACE("WG size of kernel 1 = %d, WG size of kernel 2= %d X %d", MAXBLOCKSIZE, BLOCK_SIZE_XY, BLOCK_SIZE_XY);
    int verbose = 0;
    int i, j;
    char flag;
    if (argc < 2) {
        printf("Usage: gaussian -f filename / -s size [-q]\n\n");
        printf("-q (quiet) suppresses printing the matrix and result values.\n");
        printf("-f (filename) path of input file\n");
        printf("-s (size) size of matrix. Create matrix and rhs in this program \n");
        printf("The first line of the file contains the dimension of the matrix, n.");
        printf("The second line of the file is a newline.\n");
        printf("The next n lines contain n tab separated values for the matrix.");
        printf("The next line of the file is a newline.\n");
        printf("The next line of the file is a 1xn vector with tab separated values.\n");
        printf("The next line of the file is a newline. (optional)\n");
        printf("The final line of the file is the pre-computed solution. (optional)\n");
        printf("Example: matrix4.txt:\n");
        printf("4\n");
        printf("\n");
        printf("-0.6	-0.5	0.7	0.3\n");
        printf("-0.3	-0.9	0.3	0.7\n");
        printf("-0.4	-0.5	-0.3	-0.8\n");	
        printf("0.0	-0.1	0.2	0.9\n");
        printf("\n");
        printf("-0.85	-0.68	0.24	-0.53\n");	
        printf("\n");
        printf("0.7	0.0	-0.4	-0.5\n");
        exit(0);
    }
    
    PrintDeviceProperties();
    //char filename[100];
    //sprintf(filename,"matrices/matrix%d.txt",size);

    int mt_threads = 0;

    for(i = 1;i < argc; i++) {
      if (strcmp(argv[i], "--cpu-workers") == 0 && i + 1 < argc) {
          mt_threads = atoi(argv[++i]);
      } else if (strcmp(argv[i], "--gpu-cus") == 0 && i + 1 < argc) {
          num_cus = atoi(argv[++i]);
      } else if (argv[i][0]=='-') {// flag
        flag = argv[i][1];
          switch (flag) {
            case 's': // platform
              i++;
              Size = atoi(argv[i]);
              GAUSS_TRACE("Create matrix internally in parse, size = %d", Size);
              // 原来：a/b/m 在 host，GPU 端还要 hipMalloc + hipMemcpy
              // 现在：a/b/m 统一内存 managed 分配，一份指针贯通 CPU 初始化和 GPU kernel
              a = (float *)checked_hip_malloc_managed(sizeof(float)*Size*Size);
              create_matrix(a, Size);
					
              b = (float *)checked_hip_malloc_managed(sizeof(float)*Size);
		      //b = (float *) malloc(Size * sizeof(float));
		      for (j =0; j< Size; j++)
		    	b[j]=1.0;
					
              m = (float *)checked_hip_malloc_managed(sizeof(float)*Size*Size);
		      //m = (float *) malloc(Size * Size * sizeof(float));
		      break;
            case 'f': // platform
              i++;
              GAUSS_TRACE("Read file from %s", argv[i]);
              InitProblemOnce(argv[i]);
              break;
            case 'q': // quiet
	          verbose = 0;
              break;
	      }
      }
    }

    if (mt_threads > 0) {
        rodinia_mt_set_threads(mt_threads);
    }

    GAUSS_TRACE("after arg parse: Size=%d mt_threads=%d num_cus=%d",
                Size, mt_threads, num_cus);

    InitPerRun();
    GAUSS_TRACE("after InitPerRun");

    //begin timing
    struct timeval time_start;
    gettimeofday(&time_start, NULL);	
    
    // run kernels
    ForwardSub();
    
    //end timing
    struct timeval time_end;
    gettimeofday(&time_end, NULL);
    unsigned int time_total = (time_end.tv_sec * 1000000 + time_end.tv_usec) - (time_start.tv_sec * 1000000 + time_start.tv_usec);
    
    if (verbose) {
        printf("Matrix m is: \n");
        PrintMat(m, Size, Size);

        printf("Matrix a is: \n");
        PrintMat(a, Size, Size);

        printf("Array b is: \n");
        PrintAry(b, Size);
    }
    BackSub();

    if (verbose) {
        printf("The final solution is: \n");
        PrintAry(finalVec,Size);
    }
    GAUSS_TRACE("\nTime total (including memory transfers)\t%f sec", time_total * 1e-6);
    GAUSS_TRACE("Time for CUDA kernels:\t%f sec",totalKernelTime * 1e-6);
    
    /*printf("%d,%d\n",size,time_total);
    fprintf(stderr,"%d,%d\n",size,time_total);*/

    hipFree(m);
    hipFree(a);
    hipFree(b);

#ifdef TIMING
	printf("Exec: %f\n", kernel_time);
#endif
	GAUSS_TRACE("PASSED!");
	return 0;
}
/*------------------------------------------------------
 ** PrintDeviceProperties
 **-----------------------------------------------------
 */
void PrintDeviceProperties(){
	hipDeviceProp_t deviceProp;  
	int nDevCount = 0;  
	
	hipGetDeviceCount( &nDevCount );  
	GAUSS_TRACE( "Total Device found: %d", nDevCount );  
	for (int nDeviceIdx = 0; nDeviceIdx < nDevCount; ++nDeviceIdx )  
	{  
	    memset( &deviceProp, 0, sizeof(deviceProp));  
	    if( hipSuccess == hipGetDeviceProperties(&deviceProp, nDeviceIdx))  
	        {
				printf( "\nDevice Name \t\t - %s ", deviceProp.name );  
			    printf( "\n**************************************");  
			    printf( "\nTotal Global Memory\t\t\t - %lu KB", deviceProp.totalGlobalMem/1024 );  
			    printf( "\nShared memory available per block \t - %lu KB", deviceProp.sharedMemPerBlock/1024 );  
			    printf( "\nNumber of registers per thread block \t - %d", deviceProp.regsPerBlock );  
			    printf( "\nWarp size in threads \t\t\t - %d", deviceProp.warpSize );  
			    printf( "\nMemory Pitch \t\t\t\t - %zu bytes", deviceProp.memPitch );  
			    printf( "\nMaximum threads per block \t\t - %d", deviceProp.maxThreadsPerBlock );  
			    printf( "\nMaximum Thread Dimension (block) \t - %d %d %d", deviceProp.maxThreadsDim[0], deviceProp.maxThreadsDim[1], deviceProp.maxThreadsDim[2] );  
			    printf( "\nMaximum Thread Dimension (grid) \t - %d %d %d", deviceProp.maxGridSize[0], deviceProp.maxGridSize[1], deviceProp.maxGridSize[2] );  
			    printf( "\nTotal constant memory \t\t\t - %zu bytes", deviceProp.totalConstMem );  
			    printf( "\nCUDA ver \t\t\t\t - %d.%d", deviceProp.major, deviceProp.minor );  
			    printf( "\nClock rate \t\t\t\t - %d KHz", deviceProp.clockRate );  
			    printf( "\nTexture Alignment \t\t\t - %zu bytes", deviceProp.textureAlignment );  
			    // printf( "\nDevice Overlap \t\t\t\t - %s", deviceProp. deviceOverlap?"Allowed":"Not Allowed" );  
			    printf( "\nNumber of Multi processors \t\t - %d\n\n", deviceProp.multiProcessorCount );  
			}  
	    else  
	        printf( "\n%s", hipGetErrorString(hipGetLastError()));  
	}  
}
 
 
/*------------------------------------------------------
 ** InitProblemOnce -- Initialize all of matrices and
 ** vectors by opening a data file specified by the user.
 **
 ** We used dynamic array *a, *b, and *m to allocate
 ** the memory storages.
 **------------------------------------------------------
 */
void InitProblemOnce(char *filename)
{
    fp = fopen(filename, "r");
    if (!fp) {
        GAUSS_TRACE("ERROR: fopen failed, filename=%s", filename);
        exit(1);
    }

    GAUSS_TRACE("before fscanf Size");
    fscanf(fp, "%d", &Size);
    GAUSS_TRACE("InitProblemOnce: filename=%s Size=%d", filename, Size);

    GAUSS_TRACE("before malloc a, bytes=%zu",
                sizeof(float) * (size_t)Size * (size_t)Size);
    a = (float *)checked_hip_malloc_managed(sizeof(float) * (size_t)Size * (size_t)Size);
    GAUSS_TRACE("after malloc a");

    GAUSS_TRACE("before InitMat");
    InitMat(a, Size, Size);
    GAUSS_TRACE("after InitMat");

    GAUSS_TRACE("before malloc b, bytes=%zu",
                sizeof(float) * (size_t)Size);
    b = (float *)checked_hip_malloc_managed(sizeof(float) * (size_t)Size);
    GAUSS_TRACE("after malloc b");

    GAUSS_TRACE("before InitAry");
    InitAry(b, Size);
    GAUSS_TRACE("after InitAry");

    GAUSS_TRACE("before malloc m, bytes=%zu",
                sizeof(float) * (size_t)Size * (size_t)Size);
    m = (float *)checked_hip_malloc_managed(sizeof(float) * (size_t)Size * (size_t)Size);
    GAUSS_TRACE("after malloc m");
}

/*------------------------------------------------------
 ** InitPerRun() -- Initialize the contents of the
 ** multipier matrix **m
 **------------------------------------------------------
 */
void InitPerRun() 
{
	int i;
	for (i=0; i<Size*Size; i++)
			*(m+i) = 0.0;
}

/*-------------------------------------------------------
 ** Fan1() -- Calculate multiplier matrix
 ** Pay attention to the index.  Index i give the range
 ** which starts from 0 to range-1.  The real values of
 ** the index should be adjust and related with the value
 ** of t which is defined on the ForwardSub().
 **-------------------------------------------------------
 */
__global__ void Fan1(float *m_cuda, float *a_cuda, int Size, int t)
{   
	//if(threadIdx.x + blockIdx.x * blockDim.x >= Size-1-t) printf(".");
	//printf("blockIDx.x:%d,threadIdx.x:%d,Size:%d,t:%d,Size-1-t:%d\n",blockIdx.x,threadIdx.x,Size,t,Size-1-t);

	if(threadIdx.x + blockIdx.x * blockDim.x >= Size-1-t) return;
	*(m_cuda+Size*(blockDim.x*blockIdx.x+threadIdx.x+t+1)+t) = *(a_cuda+Size*(blockDim.x*blockIdx.x+threadIdx.x+t+1)+t) / *(a_cuda+Size*t+t);
}

/*-------------------------------------------------------
 ** Fan2() -- Modify the matrix A into LUD
 **-------------------------------------------------------
 */ 

__global__ void Fan2(float *m_cuda, float *a_cuda, float *b_cuda,int Size, int j1, int t)
{
	if(threadIdx.x + blockIdx.x * blockDim.x >= Size-1-t) return;
	if(threadIdx.y + blockIdx.y * blockDim.y >= Size-t) return;
	
	int xidx = blockIdx.x * blockDim.x + threadIdx.x;
	int yidx = blockIdx.y * blockDim.y + threadIdx.y;
	//printf("blockIdx.x:%d,threadIdx.x:%d,blockIdx.y:%d,threadIdx.y:%d,blockDim.x:%d,blockDim.y:%d\n",blockIdx.x,threadIdx.x,blockIdx.y,threadIdx.y,blockDim.x,blockDim.y);
	
	a_cuda[Size*(xidx+1+t)+(yidx+t)] -= m_cuda[Size*(xidx+1+t)+t] * a_cuda[Size*t+(yidx+t)];
	//a_cuda[xidx+1+t][yidx+t] -= m_cuda[xidx+1+t][t] * a_cuda[t][yidx+t];
	if(yidx == 0){
		//printf("blockIdx.x:%d,threadIdx.x:%d,blockIdx.y:%d,threadIdx.y:%d,blockDim.x:%d,blockDim.y:%d\n",blockIdx.x,threadIdx.x,blockIdx.y,threadIdx.y,blockDim.x,blockDim.y);
		//printf("xidx:%d,yidx:%d\n",xidx,yidx);
		b_cuda[xidx+1+t] -= m_cuda[Size*(xidx+1+t)+(yidx+t)] * b_cuda[t];
	}
}

/*------------------------------------------------------
 ** ForwardSub() -- Forward substitution of Gaussian
 ** elimination.
 **------------------------------------------------------
 */
void ForwardSub()
{
	int t;
	// 统一内存路径：
	// - 原来：这里会 hipMalloc m_cuda/a_cuda/b_cuda，并 hipMemcpy(H2D) 把 a/b/m 拷到 device
	// - 现在：m/a/b 已是 managed，GPU 直接使用同一指针
    float *m_cuda = m,*a_cuda = a,*b_cuda = b;
	
	// allocate memory on GPU
	//hipMalloc((void **) &m_cuda, Size * Size * sizeof(float));
	 
	//hipMalloc((void **) &a_cuda, Size * Size * sizeof(float));
	
	//hipMalloc((void **) &b_cuda, Size * sizeof(float));	

	// copy memory to GPU
	//hipMemcpy(m_cuda, m, Size * Size * sizeof(float),hipMemcpyHostToDevice );
	//hipMemcpy(a_cuda, a, Size * Size * sizeof(float),hipMemcpyHostToDevice );
	//hipMemcpy(b_cuda, b, Size * sizeof(float),hipMemcpyHostToDevice );
	
	int block_size,grid_size;
	
	block_size = MAXBLOCKSIZE;
	grid_size = (Size/block_size) + (!(Size%block_size)? 0:1);
	if (num_cus > 0 && grid_size < num_cus) grid_size = num_cus;
	//printf("1d grid size: %d\n",grid_size);


	dim3 dimBlock(block_size);
	dim3 dimGrid(grid_size);
    GAUSS_TRACE("ForwardSub enter: Size=%d num_cus=%d block_size=%d grid_size=%d",
            Size, num_cus, block_size, grid_size);
	//dim3 dimGrid( (N/dimBlock.x) + (!(N%dimBlock.x)?0:1) );
	
	int blockSize2d, gridSize2d;
	blockSize2d = BLOCK_SIZE_XY;
	gridSize2d = (Size + blockSize2d - 1) / blockSize2d;
	if (num_cus > 0) {
	    int needed_2d = (int)ceil(sqrt((double)num_cus));
	    if (gridSize2d < needed_2d) gridSize2d = needed_2d;
	} 
	
	dim3 dimBlockXY(blockSize2d,blockSize2d);
	dim3 dimGridXY(gridSize2d,gridSize2d);

    GAUSS_TRACE("2D config: blockSize2d=%d gridSize2d=%d dimGridXY=%d x %d",
            blockSize2d, gridSize2d, gridSize2d, gridSize2d);

#ifdef  TIMING
	gettimeofday(&tv_kernel_start, NULL);
#endif

    // begin timing kernels
    struct timeval time_start;
    gettimeofday(&time_start, NULL);
    
    GAUSS_TRACE("Gaussian CPU-GPU sequential phase start");

    for (t = 0; t < (Size - 1); t++) {
        // ------------------------------------------------------------
        // Phase A: CPU memory phase
        // ------------------------------------------------------------
        rodinia_mt_run_cpu_phase(a_cuda, m_cuda, b_cuda, Size, t);

        // ------------------------------------------------------------
        // Phase B: GPU Gaussian kernels
        // ------------------------------------------------------------
        if (t < 10 || t % 50 == 0 || t > Size - 10) {
            GAUSS_TRACE("GPU phase start iter=%d valid_rows=%d", t, Size - 1 - t);
        }

        Fan1<<<dimGrid,dimBlock>>>(m_cuda,a_cuda,Size,t);
        hipDeviceSynchronize();
        checkCUDAError("Fan1");

        Fan2<<<dimGridXY,dimBlockXY>>>(m_cuda,a_cuda,b_cuda,Size,Size-t,t);
        hipDeviceSynchronize();
        checkCUDAError("Fan2");

        if (t < 10 || t % 50 == 0 || t > Size - 10) {
            GAUSS_TRACE("GPU phase completed iter=%d", t);
        }
    }

    GAUSS_TRACE("Gaussian CPU-GPU sequential phase done");

	// end timing kernels
	struct timeval time_end;
    gettimeofday(&time_end, NULL);
    totalKernelTime = (time_end.tv_sec * 1000000 + time_end.tv_usec) - (time_start.tv_sec * 1000000 + time_start.tv_usec);
	
#ifdef  TIMING
	tvsub(&time_end, &tv_kernel_start, &tv);
	kernel_time += tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;
#endif

	// copy memory back to CPU
	//hipMemcpy(m, m_cuda, Size * Size * sizeof(float),hipMemcpyDeviceToHost );
	//hipMemcpy(a, a_cuda, Size * Size * sizeof(float),hipMemcpyDeviceToHost );
	//hipMemcpy(b, b_cuda, Size * sizeof(float),hipMemcpyDeviceToHost );
	//hipFree(m_cuda);
	//hipFree(a_cuda);
	//hipFree(b_cuda);
}

/*------------------------------------------------------
 ** BackSub() -- Backward substitution
 **------------------------------------------------------
 */

void BackSub()
{
	// create a new vector to hold the final answer
	finalVec = (float *) malloc(Size * sizeof(float));
	// solve "bottom up"
	int i,j;
	for(i=0;i<Size;i++){
		finalVec[Size-i-1]=b[Size-i-1];
		for(j=0;j<i;j++)
		{
			finalVec[Size-i-1]-=*(a+Size*(Size-i-1)+(Size-j-1)) * finalVec[Size-j-1];
		}
		finalVec[Size-i-1]=finalVec[Size-i-1]/ *(a+Size*(Size-i-1)+(Size-i-1));
	}
}

void InitMat(float *ary, int nrow, int ncol)
{
    int i, j;

    for (i = 0; i < nrow; i++) {
        if (i % 64 == 0) {
            GAUSS_TRACE("InitMat progress row=%d/%d", i, nrow);
        }

        for (j = 0; j < ncol; j++) {
            int ret = fscanf(fp, "%f", ary + Size * i + j);
            if (ret != 1) {
                GAUSS_TRACE("ERROR: InitMat fscanf failed at i=%d j=%d", i, j);
                exit(1);
            }
        }
    }

    GAUSS_TRACE("InitMat done rows=%d cols=%d", nrow, ncol);
}

/*------------------------------------------------------
 ** PrintMat() -- Print the contents of the matrix
 **------------------------------------------------------
 */
void PrintMat(float *ary, int nrow, int ncol)
{
	int i, j;
	
	for (i=0; i<nrow; i++) {
		for (j=0; j<ncol; j++) {
			printf("%8.2f ", *(ary+Size*i+j));
		}
		printf("\n");
	}
	printf("\n");
}

/*------------------------------------------------------
 ** InitAry() -- Initialize the array (vector) by reading
 ** data from the data file
 **------------------------------------------------------
 */
void InitAry(float *ary, int ary_size)
{
    int i;

    for (i = 0; i < ary_size; i++) {
        int ret = fscanf(fp, "%f", &ary[i]);
        if (ret != 1) {
            GAUSS_TRACE("ERROR: InitAry fscanf failed at i=%d", i);
            exit(1);
        }
    }

    GAUSS_TRACE("InitAry done size=%d", ary_size);
}

/*------------------------------------------------------
 ** PrintAry() -- Print the contents of the array (vector)
 **------------------------------------------------------
 */
void PrintAry(float *ary, int ary_size)
{
	int i;
	for (i=0; i<ary_size; i++) {
		printf("%.2f ", ary[i]);
	}
	printf("\n\n");
}
void checkCUDAError(const char *msg)
{
    hipError_t err = hipGetLastError();
    if( hipSuccess != err) 
    {
        fprintf(stderr, "Cuda error: %s: %s.\n", msg, 
                                  hipGetErrorString( err) );
        exit(EXIT_FAILURE);
    }                         
}
