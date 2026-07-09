#include "hip/hip_runtime.h"
static const int PF_REAL_BLOCK_CHUNK = 12;
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <math.h>
#include <unistd.h>
#include <fcntl.h>
#include <float.h>
#include <sys/time.h>
#include <time.h>
#ifdef __linux__
#include <sched.h>
#endif

#define PF_LOG(fmt, ...) do {                         \
    printf("[particlefilter] " fmt "\n", ##__VA_ARGS__);          \
    fflush(stdout);                                   \
} while (0)

#define HIP_CHECK(cmd) do {                           \
    hipError_t e = (cmd);                             \
    if (e != hipSuccess) {                            \
        fprintf(stderr,                               \
                "[pf] HIP error %s:%d: %s\n",         \
                __FILE__, __LINE__, hipGetErrorString(e)); \
        fflush(stderr);                               \
        exit(1);                                      \
    }                                                 \
} while (0)

#define HIP_KERNEL_CHECK(stage) do {                  \
    HIP_CHECK(hipGetLastError());                     \
    PF_LOG("before sync: %s", stage);                 \
    HIP_CHECK(hipDeviceSynchronize());                \
    PF_LOG("after sync: %s", stage);                  \
} while (0)

// -----------------------------------------------------------------------------
// CPU batch phase, aligned with the gaussian CPU phase
// -----------------------------------------------------------------------------
typedef struct {
    int tid;
    unsigned int seed;
    volatile unsigned long long loops;
    volatile unsigned int *private_buf;
    size_t private_words;
} rodinia_mt_arg_t;

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t  cond;
    int             count;
    int             total;
    int             generation;
} simple_barrier_t;

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

static simple_barrier_t rodinia_mt_start_barrier;

static int rodinia_mt_threads = 4;
static int rodinia_mt_work_percent = 8;
static unsigned int rodinia_mt_seed = 1;
static int rodinia_mt_inited = 0;
static int rodinia_mt_threads_set_by_arg = 0;

static pthread_t *rodinia_mt_pool = NULL;
static rodinia_mt_arg_t *rodinia_mt_args = NULL;
static volatile unsigned int *rodinia_mt_private = NULL;
static size_t rodinia_mt_private_words_per_thread = 0;

static volatile double *rodinia_mt_weights = NULL;
static volatile double *rodinia_mt_arrayX = NULL;
static volatile double *rodinia_mt_arrayY = NULL;
static volatile double *rodinia_mt_CDF = NULL;
static volatile double *rodinia_mt_likelihood = NULL;
static int rodinia_mt_items = 0;

static inline unsigned int rodinia_mt_xorshift32(unsigned int *state)
{
    unsigned int x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x ? x : 1u;
    return *state;
}

static void rodinia_mt_init_cfg(void)
{
    if (rodinia_mt_inited)
        return;

    const char *s_work = getenv("RODINIA_SHARE_PERCENT");
    const char *s_seed = getenv("RODINIA_SHARE_SEED");

    if (!rodinia_mt_threads_set_by_arg) {
        rodinia_mt_threads = 1;
    }

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

    PF_LOG("mt cfg: threads=%d work_percent=%d seed=%u",
           rodinia_mt_threads,
           rodinia_mt_work_percent,
           rodinia_mt_seed);

    rodinia_mt_inited = 1;
}

static void rodinia_mt_set_threads(int n)
{
    rodinia_mt_threads = (n > 0) ? n : 1;
    rodinia_mt_threads_set_by_arg = 1;
}

static inline unsigned int rodinia_mt_accumulate_double(double v, int idx)
{
    return (unsigned int)(((long long)(v * 1000.0)) ^ idx);
}

static inline double rodinia_mt_read_particle_arrays(int idx)
{
    double v = 0.0;

    if (rodinia_mt_weights)
        v += rodinia_mt_weights[idx];
    if (rodinia_mt_arrayX)
        v += rodinia_mt_arrayX[idx];
    if (rodinia_mt_arrayY)
        v += rodinia_mt_arrayY[idx];
    if (rodinia_mt_CDF)
        v += rodinia_mt_CDF[idx];
    if (rodinia_mt_likelihood)
        v += rodinia_mt_likelihood[idx];

    return v;
}

static void *rodinia_mt_worker_once(void *p)
{
    rodinia_mt_arg_t *arg = (rodinia_mt_arg_t *)p;

    simple_barrier_wait(&rodinia_mt_start_barrier);

    unsigned int s = arg->seed ^
                     (unsigned int)(arg->tid + 1) * 0x9e3779b9u;

    int nitems = rodinia_mt_items;
    int nthreads = rodinia_mt_threads;

    if (nitems <= 0 || nthreads <= 0 || rodinia_mt_work_percent <= 0) {
        volatile unsigned int acc = 0;
        for (int i = 0; i < 1024; i++)
            acc += rodinia_mt_xorshift32(&s);
        arg->loops++;
        return NULL;
    }

    int begin = (int)(((long long)nitems * arg->tid) / nthreads);
    int end   = (int)(((long long)nitems * (arg->tid + 1)) / nthreads);
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
    if (window_end > nitems)
        window_end = nitems;

    int window_count = window_end - window_start;
    if (window_count <= 0)
        window_count = own_count;

    volatile unsigned int acc = 0;

    // Same pattern as gaussian: local random reads from the thread-owned range,
    // with writes redirected to a CPU-private buffer.
    for (int r = 0; r < sample_count; r++) {
        int idx = begin +
            (int)(rodinia_mt_xorshift32(&s) % (unsigned int)own_count);

        double v = rodinia_mt_read_particle_arrays(idx);
        acc += rodinia_mt_accumulate_double(v, idx);

        if (arg->private_buf != NULL && arg->private_words > 0) {
            size_t pidx = (size_t)(rodinia_mt_xorshift32(&s) %
                                   (unsigned int)arg->private_words);
            arg->private_buf[pidx] =
                acc + (unsigned int)arg->tid + (unsigned int)r;
        }
    }

    // Same pattern as gaussian: neighborhood random reads. This preserves a
    // multi-sharer behavior while keeping CPU writes away from GPU-owned arrays.
    for (int r = 0; r < sample_count; r++) {
        int idx = window_start +
            (int)(rodinia_mt_xorshift32(&s) % (unsigned int)window_count);

        double v = rodinia_mt_read_particle_arrays(idx);
        acc += rodinia_mt_accumulate_double(v, idx);
    }

    arg->loops++;
    return NULL;
}

static void rodinia_mt_set_shared_data(double *weights,
                                       double *arrayX,
                                       double *arrayY,
                                       double *CDF,
                                       double *likelihood,
                                       int nitems)
{
    rodinia_mt_weights = (volatile double *)weights;
    rodinia_mt_arrayX = (volatile double *)arrayX;
    rodinia_mt_arrayY = (volatile double *)arrayY;
    rodinia_mt_CDF = (volatile double *)CDF;
    rodinia_mt_likelihood = (volatile double *)likelihood;
    rodinia_mt_items = nitems;
}

static void rodinia_mt_clear_shared_data(void)
{
    rodinia_mt_weights = NULL;
    rodinia_mt_arrayX = NULL;
    rodinia_mt_arrayY = NULL;
    rodinia_mt_CDF = NULL;
    rodinia_mt_likelihood = NULL;
    rodinia_mt_items = 0;
}

static void rodinia_mt_cpu_phase_pf_sync(double *weights,
                                         double *arrayX,
                                         double *arrayY,
                                         double *CDF,
                                         double *likelihood,
                                         int nitems,
                                         int iter)
{
    rodinia_mt_init_cfg();

    if (rodinia_mt_work_percent <= 0) {
        PF_LOG("CPU phase skipped iter=%d work_percent=%d",
               iter, rodinia_mt_work_percent);
        return;
    }

    rodinia_mt_set_shared_data(weights, arrayX, arrayY, CDF, likelihood, nitems);

    int n = rodinia_mt_threads;
    if (n <= 0)
        n = 1;

    simple_barrier_init(&rodinia_mt_start_barrier, n + 1);

    if (rodinia_mt_pool == NULL) {
        rodinia_mt_pool = (pthread_t *)malloc((size_t)n * sizeof(pthread_t));
    }

    if (rodinia_mt_args == NULL) {
        rodinia_mt_args =
            (rodinia_mt_arg_t *)malloc((size_t)n * sizeof(rodinia_mt_arg_t));
    }

    if (rodinia_mt_private == NULL) {
        rodinia_mt_private_words_per_thread = 8192;
        rodinia_mt_private =
            (volatile unsigned int *)calloc((size_t)n * rodinia_mt_private_words_per_thread,
                                            sizeof(unsigned int));
    }

    if (!rodinia_mt_pool || !rodinia_mt_args || !rodinia_mt_private) {
        fprintf(stderr,
                "[rodinia_mt][particlefilter] failed to allocate CPU worker data\n");
        fflush(stderr);
        exit(1);
    }

    PF_LOG("CPU phase start iter=%d threads=%d total_items=%d work_percent=%d",
           iter,
           n,
           nitems,
           rodinia_mt_work_percent);

    for (int t = 0; t < n; t++) {
        rodinia_mt_args[t].tid = t;
        rodinia_mt_args[t].seed = rodinia_mt_seed ^
                                  (unsigned int)(t + 1) ^
                                  (unsigned int)iter;
        rodinia_mt_args[t].loops = 0;
        rodinia_mt_args[t].private_buf =
            rodinia_mt_private + (size_t)t * rodinia_mt_private_words_per_thread;
        rodinia_mt_args[t].private_words = rodinia_mt_private_words_per_thread;

        PF_LOG("Creating pthread tid=%d iter=%d", t, iter);

        int rc = pthread_create(&rodinia_mt_pool[t],
                                NULL,
                                rodinia_mt_worker_once,
                                &rodinia_mt_args[t]);

        if (rc != 0) {
            fprintf(stderr,
                    "[rodinia_mt][particlefilter] pthread_create failed tid=%d iter=%d rc=%d (%s)\n",
                    t,
                    iter,
                    rc,
                    strerror(rc));
            fflush(stderr);
            exit(1);
        }

        PF_LOG("pthread_create success tid=%d iter=%d", t, iter);
    }

    PF_LOG("Main thread waiting at CPU start barrier iter=%d", iter);

    simple_barrier_wait(&rodinia_mt_start_barrier);

    PF_LOG("CPU workers released iter=%d", iter);

    for (int t = 0; t < n; t++) {
        PF_LOG("Joining pthread tid=%d iter=%d", t, iter);

        int rc = pthread_join(rodinia_mt_pool[t], NULL);
        if (rc != 0) {
            fprintf(stderr,
                    "[rodinia_mt][particlefilter] pthread_join failed tid=%d iter=%d rc=%d (%s)\n",
                    t,
                    iter,
                    rc,
                    strerror(rc));
            fflush(stderr);
            exit(1);
        }

        PF_LOG("Joined pthread tid=%d iter=%d loops=%llu",
               t,
               iter,
               (unsigned long long)rodinia_mt_args[t].loops);
    }

    // simple_barrier_destroy(&rodinia_mt_start_barrier);

    rodinia_mt_clear_shared_data();

    PF_LOG("CPU phase completed iter=%d", iter);
}

#define BLOCK_X 16
#define BLOCK_Y 16
#define PI 3.1415926535897932

const int threads_per_block = 64;

/**
@var M value for Linear Congruential Generator (LCG); use GCC's value
 */
long M = INT_MAX;
/**
@var A value for LCG
 */
int A = 1103515245;
/**
@var C value for LCG
 */
int C = 12345;

/*****************************
 *GET_TIME
 *returns a long int representing the time
 *****************************/
long long get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (tv.tv_sec * 1000000) +tv.tv_usec;
}
// Returns the number of seconds elapsed between the two specified times

double elapsed_time(long long start_time, long long end_time) {
    return (double) (end_time - start_time) / (1000 * 1000);
}

/*****************************
 * CHECK_ERROR
 * Checks for CUDA errors and prints them to the screen to help with
 * debugging of CUDA related programming
 *****************************/
void check_error(hipError_t e) {
    if (e != hipSuccess) {
        printf("\nCUDA error: %s\n", hipGetErrorString(e));
        exit(1);
    }
}


static void *checked_hip_malloc_managed(size_t size)
{
    void *ptr = NULL;
    // 原来：host malloc + device hipMalloc，再 hipMemcpy(H2D/D2H) 维护两份内存
    // 现在：统一内存 hipMallocManaged，CPU/GPU 共享同一份数据
    hipError_t err = hipMallocManaged(&ptr, size, hipMemAttachGlobal);
    if (err != hipSuccess) {
        printf("\nCUDA error: %s\n", hipGetErrorString(err));
        exit(1);
    }
    return ptr;
}

/********************************
 * CALC LIKELIHOOD SUM
 * DETERMINES THE LIKELIHOOD SUM BASED ON THE FORMULA: SUM( (IK[IND] - 100)^2 - (IK[IND] - 228)^2)/ 100
 * param 1 I 3D matrix
 * param 2 current ind array
 * param 3 length of ind array
 * returns a double representing the sum
 ********************************/
__device__ double calcLikelihoodSum(unsigned char * I, int * ind, int numOnes, int index) {
    double likelihoodSum = 0.0;
    int x;
    for (x = 0; x < numOnes; x++)
        likelihoodSum += (pow((double) (I[ind[index * numOnes + x]] - 100), 2) - pow((double) (I[ind[index * numOnes + x]] - 228), 2)) / 50.0;
    return likelihoodSum;
}

/****************************
CDF CALCULATE
CALCULATES CDF
param1 CDF
param2 weights
param3 Nparticles
 *****************************/
__device__ void cdfCalc(double * CDF, double * weights, int Nparticles) {
    int x;
    CDF[0] = weights[0];
    for (x = 1; x < Nparticles; x++) {
        CDF[x] = weights[x] + CDF[x - 1];
    }
}

/*****************************
 * RANDU
 * GENERATES A UNIFORM DISTRIBUTION
 * returns a double representing a randomily generated number from a uniform distribution with range [0, 1)
 ******************************/
__device__ double d_randu(int * seed, int index) {

    int M = INT_MAX;
    int A = 1103515245;
    int C = 12345;
    int num = A * seed[index] + C;
    seed[index] = num % M;

    return fabs(seed[index] / ((double) M));
}/**
* Generates a uniformly distributed random number using the provided seed and GCC's settings for the Linear Congruential Generator (LCG)
* @see http://en.wikipedia.org/wiki/Linear_congruential_generator
* @note This function is thread-safe
* @param seed The seed array
* @param index The specific index of the seed to be advanced
* @return a uniformly distributed number [0, 1)
*/

double randu(int * seed, int index) {
    int num = A * seed[index] + C;
    seed[index] = num % M;
    return fabs(seed[index] / ((double) M));
}

/**
 * Generates a normally distributed random number using the Box-Muller transformation
 * @note This function is thread-safe
 * @param seed The seed array
 * @param index The specific index of the seed to be advanced
 * @return a double representing random number generated using the Box-Muller algorithm
 * @see http://en.wikipedia.org/wiki/Normal_distribution, section computing value for normal random distribution
 */
double randn(int * seed, int index) {
    /*Box-Muller algorithm*/
    double u = randu(seed, index);
    double v = randu(seed, index);
    double cosine = cos(2 * PI * v);
    double rt = -2 * log(u);
    return sqrt(rt) * cosine;
}

double test_randn(int * seed, int index) {
    //Box-Muller algortihm
    double pi = 3.14159265358979323846;
    double u = randu(seed, index);
    double v = randu(seed, index);
    double cosine = cos(2 * pi * v);
    double rt = -2 * log(u);
    return sqrt(rt) * cosine;
}

__device__ double d_randn(int * seed, int index) {
    //Box-Muller algortihm
    double pi = 3.14159265358979323846;
    double u = d_randu(seed, index);
    double v = d_randu(seed, index);
    double cosine = cos(2 * pi * v);
    double rt = -2 * log(u);
    return sqrt(rt) * cosine;
}

__global__ void normalize_weights_only_kernel(
    double *weights,
    int Nparticles,
    double *total_sum,
    int block_offset
) {
    int block_id = blockIdx.x + block_offset;
    int i = blockDim.x * block_id + threadIdx.x;

    if (i < Nparticles) {
        weights[i] = weights[i] / total_sum[0];
    }
}

__global__ void cdf_u0_kernel(
    double *weights,
    int Nparticles,
    double *CDF,
    double *u,
    int *seed
) {
    CDF[0] = weights[0];

    for (int x = 1; x < Nparticles; x++) {
        CDF[x] = CDF[x - 1] + weights[x];
    }

    u[0] = (1.0 / ((double)Nparticles)) * d_randu(seed, 0);
}

__global__ void fill_u_kernel(
    double *u,
    int Nparticles,
    int block_offset
) {
    int block_id = blockIdx.x + block_offset;
    int i = blockDim.x * block_id + threadIdx.x;

    if (i < Nparticles) {
        double u1 = u[0];
        u[i] = u1 + i / ((double)Nparticles);
    }
}

/****************************
UPDATE WEIGHTS
UPDATES WEIGHTS
param1 weights
param2 likelihood
param3 Nparcitles
 ****************************/
__device__ double updateWeights(double * weights, double * likelihood, int Nparticles) {
    int x;
    double sum = 0;
    for (x = 0; x < Nparticles; x++) {
        weights[x] = weights[x] * exp(likelihood[x]);
        sum += weights[x];
    }
    return sum;
}

__device__ int findIndexBin(double * CDF, int beginIndex, int endIndex, double value) {
    if (endIndex < beginIndex)
        return -1;
    int middleIndex;
    while (endIndex > beginIndex) {
        middleIndex = beginIndex + ((endIndex - beginIndex) / 2);
        if (CDF[middleIndex] >= value) {
            if (middleIndex == 0)
                return middleIndex;
            else if (CDF[middleIndex - 1] < value)
                return middleIndex;
            else if (CDF[middleIndex - 1] == value) {
                while (CDF[middleIndex] == value && middleIndex >= 0)
                    middleIndex--;
                middleIndex++;
                return middleIndex;
            }
        }
        if (CDF[middleIndex] > value)
            endIndex = middleIndex - 1;
        else
            beginIndex = middleIndex + 1;
    }
    return -1;
}

/** added this function. was missing in original double version.
 * Takes in a double and returns an integer that approximates to that double
 * @return if the mantissa < .5 => return value < input value; else return value > input value
 */
__device__ double dev_round_double(double value) {
    int newValue = (int) (value);
    if (value - newValue < .5f)
        return newValue;
    else
        return newValue++;
}

__device__ int lower_bound_cdf(double *CDF, int Nparticles, double value) {
    int lo = 0;
    int hi = Nparticles - 1;

    while (lo < hi) {
        int mid = lo + (hi - lo) / 2;
        if (CDF[mid] >= value) {
            hi = mid;
        } else {
            lo = mid + 1;
        }
    }

    return lo;
}

/*****************************
 * CUDA Find Index Kernel Function to replace FindIndex
 * param1: arrayX
 * param2: arrayY
 * param3: CDF
 * param4: u
 * param5: xj
 * param6: yj
 * param7: weights
 * param8: Nparticles
 *****************************/
__global__ void find_index_kernel(
    double *arrayX,
    double *arrayY,
    double *CDF,
    double *u,
    double *xj,
    double *yj,
    double *weights,
    int Nparticles,
    int block_offset
) {
    int block_id = blockIdx.x + block_offset;
    int i = blockDim.x * block_id + threadIdx.x;

    if (i < Nparticles) {
        int index = lower_bound_cdf(CDF, Nparticles, u[i]);

        if (index < 0) {
            index = 0;
        }
        if (index >= Nparticles) {
            index = Nparticles - 1;
        }

        xj[i] = arrayX[index];
        yj[i] = arrayY[index];
    }
}

__global__ void normalize_weights_kernel(double * weights, int Nparticles, double* partial_sums, double * CDF, double * u, int * seed) {
    int block_id = blockIdx.x;
    int i = blockDim.x * block_id + threadIdx.x;
    __shared__ double u1, sumWeights;
    
    if(0 == threadIdx.x)
        sumWeights = partial_sums[0];
    
    __syncthreads();
    
    if (i < Nparticles) {
        weights[i] = weights[i] / sumWeights;
    }
    
    __syncthreads(); 
    
    if (i == 0) {
        cdfCalc(CDF, weights, Nparticles);
        u[0] = (1 / ((double) (Nparticles))) * d_randu(seed, i); // do this to allow all threads in all blocks to use the same u1
    }
    
    __syncthreads();
    
    if(0 == threadIdx.x) 
        u1 = u[0];
    
    __syncthreads();
        
    if (i < Nparticles) {
        u[i] = u1 + i / ((double) (Nparticles));
    }
}

__global__ void sum_kernel_parallel(double *partial_sums, double *total_sum, int num_blocks, int block_offset) {
    __shared__ double buf[256];

    int tid = threadIdx.x;
    int block_id = blockIdx.x + block_offset;
    int idx = block_id * blockDim.x + threadIdx.x;

    double v = 0.0;
    if (idx < num_blocks) {
        v = partial_sums[idx];
    }

    buf[tid] = v;
    __syncthreads();

    for (int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            buf[tid] += buf[tid + s];
        }
        __syncthreads();
    }

    if (tid == 0) {
        atomicAdd(total_sum, buf[0]);
    }
}

/*****************************
 * CUDA Likelihood Kernel Function to replace FindIndex
 * param1: arrayX
 * param2: arrayY
 * param2.5: CDF
 * param3: ind
 * param4: objxy
 * param5: likelihood
 * param6: I
 * param6.5: u
 * param6.75: weights
 * param7: Nparticles
 * param8: countOnes
 * param9: max_size
 * param10: k
 * param11: IszY
 * param12: Nfr
 *****************************/
__global__ void likelihood_kernel(double * arrayX, double * arrayY, double * xj, double * yj, double * CDF, int * ind, int * objxy, double * likelihood, unsigned char * I, double * u, double * weights, int Nparticles, int countOnes, int max_size, int k, int IszY, int Nfr, int *seed, double* partial_sums, int block_offset) {
    int block_id = blockIdx.x + block_offset;
    int i = blockDim.x * block_id + threadIdx.x;
    int y;
    
    int indX, indY; 
    __shared__ double buffer[512];
    if (i < Nparticles) {
        arrayX[i] = xj[i]; 
        arrayY[i] = yj[i]; 

        weights[i] = 1 / ((double) (Nparticles)); //Donnie - moved this line from end of find_index_kernel to prevent all weights from being reset before calculating position on final iteration.

        arrayX[i] = arrayX[i] + 1.0 + 5.0 * d_randn(seed, i);
        arrayY[i] = arrayY[i] - 2.0 + 2.0 * d_randn(seed, i);
        
    }

    __syncthreads();

    if (i < Nparticles) {
        for (y = 0; y < countOnes; y++) {
            //added dev_round_double() to be consistent with roundDouble
            indX = dev_round_double(arrayX[i]) + objxy[y * 2 + 1];
            indY = dev_round_double(arrayY[i]) + objxy[y * 2];
            
            ind[i * countOnes + y] = abs(indX * IszY * Nfr + indY * Nfr + k);
            if (ind[i * countOnes + y] >= max_size)
                ind[i * countOnes + y] = 0;
        }
        likelihood[i] = calcLikelihoodSum(I, ind, countOnes, i);
        
        likelihood[i] = likelihood[i] / countOnes;
        
        weights[i] = weights[i] * exp(likelihood[i]); //Donnie Newell - added the missing exponential function call
    }

    buffer[threadIdx.x] = 0.0;

    __syncthreads();

    if (i < Nparticles) {

        buffer[threadIdx.x] = weights[i];
    }

    __syncthreads();

    //this doesn't account for the last block that isn't full
    for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (threadIdx.x < s) {
            buffer[threadIdx.x] += buffer[threadIdx.x + s];
        }
        
        __syncthreads();
            
    }
    if (threadIdx.x == 0) {
        partial_sums[block_id] = buffer[0];
    }
    
    __syncthreads();

}

/** 
 * Takes in a double and returns an integer that approximates to that double
 * @return if the mantissa < .5 => return value < input value; else return value > input value
 */
double roundDouble(double value) {
    int newValue = (int) (value);
    if (value - newValue < .5)
        return newValue;
    else
        return newValue++;
}

/**
 * Set values of the 3D array to a newValue if that value is equal to the testValue
 * @param testValue The value to be replaced
 * @param newValue The value to replace testValue with
 * @param array3D The image vector
 * @param dimX The x dimension of the frame
 * @param dimY The y dimension of the frame
 * @param dimZ The number of frames
 */
void setIf(int testValue, int newValue, unsigned char * array3D, int * dimX, int * dimY, int * dimZ) {
    int x, y, z;
    for (x = 0; x < *dimX; x++) {
        for (y = 0; y < *dimY; y++) {
            for (z = 0; z < *dimZ; z++) {
                if (array3D[x * *dimY * *dimZ + y * *dimZ + z] == testValue)
                    array3D[x * *dimY * *dimZ + y * *dimZ + z] = newValue;
            }
        }
    }
}

/**
 * Sets values of 3D matrix using randomly generated numbers from a normal distribution
 * @param array3D The video to be modified
 * @param dimX The x dimension of the frame
 * @param dimY The y dimension of the frame
 * @param dimZ The number of frames
 * @param seed The seed array
 */
void addNoise(unsigned char * array3D, int * dimX, int * dimY, int * dimZ, int * seed) {
    int x, y, z;
    for (x = 0; x < *dimX; x++) {
        for (y = 0; y < *dimY; y++) {
            for (z = 0; z < *dimZ; z++) {
                array3D[x * *dimY * *dimZ + y * *dimZ + z] = array3D[x * *dimY * *dimZ + y * *dimZ + z] + (unsigned char) (5 * randn(seed, 0));
            }
        }
    }
}

/**
 * Fills a radius x radius matrix representing the disk
 * @param disk The pointer to the disk to be made
 * @param radius  The radius of the disk to be made
 */
void strelDisk(int * disk, int radius) {
    int diameter = radius * 2 - 1;
    int x, y;
    for (x = 0; x < diameter; x++) {
        for (y = 0; y < diameter; y++) {
            double distance = sqrt(pow((double) (x - radius + 1), 2) + pow((double) (y - radius + 1), 2));
            if (distance < radius)
                disk[x * diameter + y] = 1;
            else
                disk[x * diameter + y] = 0;
        }
    }
}

/**
 * Dilates the provided video
 * @param matrix The video to be dilated
 * @param posX The x location of the pixel to be dilated
 * @param posY The y location of the pixel to be dilated
 * @param poxZ The z location of the pixel to be dilated
 * @param dimX The x dimension of the frame
 * @param dimY The y dimension of the frame
 * @param dimZ The number of frames
 * @param error The error radius
 */
void dilate_matrix(unsigned char * matrix, int posX, int posY, int posZ, int dimX, int dimY, int dimZ, int error) {
    int startX = posX - error;
    while (startX < 0)
        startX++;
    int startY = posY - error;
    while (startY < 0)
        startY++;
    int endX = posX + error;
    while (endX > dimX)
        endX--;
    int endY = posY + error;
    while (endY > dimY)
        endY--;
    int x, y;
    for (x = startX; x < endX; x++) {
        for (y = startY; y < endY; y++) {
            double distance = sqrt(pow((double) (x - posX), 2) + pow((double) (y - posY), 2));
            if (distance < error)
                matrix[x * dimY * dimZ + y * dimZ + posZ] = 1;
        }
    }
}

/**
 * Dilates the target matrix using the radius as a guide
 * @param matrix The reference matrix
 * @param dimX The x dimension of the video
 * @param dimY The y dimension of the video
 * @param dimZ The z dimension of the video
 * @param error The error radius to be dilated
 * @param newMatrix The target matrix
 */
void imdilate_disk(unsigned char * matrix, int dimX, int dimY, int dimZ, int error, unsigned char * newMatrix) {
    int x, y, z;
    for (z = 0; z < dimZ; z++) {
        for (x = 0; x < dimX; x++) {
            for (y = 0; y < dimY; y++) {
                if (matrix[x * dimY * dimZ + y * dimZ + z] == 1) {
                    dilate_matrix(newMatrix, x, y, z, dimX, dimY, dimZ, error);
                }
            }
        }
    }
}

/**
 * Fills a 2D array describing the offsets of the disk object
 * @param se The disk object
 * @param numOnes The number of ones in the disk
 * @param neighbors The array that will contain the offsets
 * @param radius The radius used for dilation
 */
void getneighbors(int * se, int numOnes, int * neighbors, int radius) {
    int x, y;
    int neighY = 0;
    int center = radius - 1;
    int diameter = radius * 2 - 1;
    for (x = 0; x < diameter; x++) {
        for (y = 0; y < diameter; y++) {
            if (se[x * diameter + y]) {
                neighbors[neighY * 2] = (int) (y - center);
                neighbors[neighY * 2 + 1] = (int) (x - center);
                neighY++;
            }
        }
    }
}

/**
 * The synthetic video sequence we will work with here is composed of a
 * single moving object, circular in shape (fixed radius)
 * The motion here is a linear motion
 * the foreground intensity and the background intensity is known
 * the image is corrupted with zero mean Gaussian noise
 * @param I The video itself
 * @param IszX The x dimension of the video
 * @param IszY The y dimension of the video
 * @param Nfr The number of frames of the video
 * @param seed The seed array used for number generation
 */
void videoSequence(unsigned char * I, int IszX, int IszY, int Nfr, int * seed) {
    int k;
    int max_size = IszX * IszY * Nfr;
    /*get object centers*/
    int x0 = (int) roundDouble(IszY / 2.0);
    int y0 = (int) roundDouble(IszX / 2.0);
    I[x0 * IszY * Nfr + y0 * Nfr + 0] = 1;

    /*move point*/
    int xk, yk, pos;
    for (k = 1; k < Nfr; k++) {
        xk = abs(x0 + (k-1));
        yk = abs(y0 - 2 * (k-1));
        pos = yk * IszY * Nfr + xk * Nfr + k;
        if (pos >= max_size)
            pos = 0;
        I[pos] = 1;
    }

    /*dilate matrix*/
    unsigned char * newMatrix = (unsigned char *) malloc(sizeof (unsigned char) * IszX * IszY * Nfr);
    imdilate_disk(I, IszX, IszY, Nfr, 5, newMatrix);
    int x, y;
    for (x = 0; x < IszX; x++) {
        for (y = 0; y < IszY; y++) {
            for (k = 0; k < Nfr; k++) {
                I[x * IszY * Nfr + y * Nfr + k] = newMatrix[x * IszY * Nfr + y * Nfr + k];
            }
        }
    }
    free(newMatrix);

    /*define background, add noise*/
    setIf(0, 100, I, &IszX, &IszY, &Nfr);
    setIf(1, 228, I, &IszX, &IszY, &Nfr);
    /*add noise*/
    addNoise(I, &IszX, &IszY, &Nfr, seed);

}

/**
 * Finds the first element in the CDF that is greater than or equal to the provided value and returns that index
 * @note This function uses sequential search
 * @param CDF The CDF
 * @param lengthCDF The length of CDF
 * @param value The value to be found
 * @return The index of value in the CDF; if value is never found, returns the last index
 */
int findIndex(double * CDF, int lengthCDF, double value) {
    int index = -1;
    int x;
    for (x = 0; x < lengthCDF; x++) {
        if (CDF[x] >= value) {
            index = x;
            break;
        }
    }
    if (index == -1) {
        return lengthCDF - 1;
    }
    return index;
}

/**
 * The implementation of the particle filter using OpenMP for many frames
 * @see http://openmp.org/wp/
 * @note This function is designed to work with a video of several frames. In addition, it references a provided MATLAB function which takes the video, the objxy matrix and the x and y arrays as arguments and returns the likelihoods
 * @param I The video to be run
 * @param IszX The x dimension of the video
 * @param IszY The y dimension of the video
 * @param Nfr The number of frames
 * @param seed The seed array used for random number generation
 * @param Nparticles The number of particles to be used
 */
void particleFilter(unsigned char * I, int IszX, int IszY, int Nfr, int * seed, int Nparticles, int num_cus) {
    int max_size = IszX * IszY*Nfr;
    //original particle centroid
    double xe = roundDouble(IszY / 2.0);
    double ye = roundDouble(IszX / 2.0);

    //expected object locations, compared to center
    int radius = 5;
    int diameter = radius * 2 - 1;
    int * disk = (int*) malloc(diameter * diameter * sizeof (int));
    strelDisk(disk, radius);
    int countOnes = 0;
    int x, y;
    for (x = 0; x < diameter; x++) {
        for (y = 0; y < diameter; y++) {
            if (disk[x * diameter + y] == 1)
                countOnes++;
        }
    }
    // 原来：objxy/weights/likelihood/arrayX/... 在 host，GPU 端还要 hipMalloc + hipMemcpy
    // 现在：统一内存 managed 分配，一份指针贯通 CPU 初始化与 GPU kernel
    int * objxy = (int *)checked_hip_malloc_managed(countOnes * 2 * sizeof (int));
    getneighbors(disk, countOnes, objxy, radius);
    //initial weights are all equal (1/Nparticles)
    double * weights = (double *)checked_hip_malloc_managed(sizeof (double) *Nparticles);
    for (x = 0; x < Nparticles; x++) {
        weights[x] = 1 / ((double) (Nparticles));
    }

    //initial likelihood to 0.0
    double * likelihood = (double *)checked_hip_malloc_managed(sizeof (double) *Nparticles);
    double * arrayX = (double *)checked_hip_malloc_managed(sizeof (double) *Nparticles);
    double * arrayY = (double *)checked_hip_malloc_managed(sizeof (double) *Nparticles);
    double * xj = (double *)checked_hip_malloc_managed(sizeof (double) *Nparticles);
    double * yj = (double *)checked_hip_malloc_managed(sizeof (double) *Nparticles);
    double * CDF = (double *)checked_hip_malloc_managed(sizeof (double) *Nparticles);

    //GPU copies of arrays
    double * arrayX_GPU;
    double * arrayY_GPU;
    double * xj_GPU;
    double * yj_GPU;
    double * CDF_GPU;
    double * likelihood_GPU;
    unsigned char * I_GPU;
    double * weights_GPU;
    int * objxy_GPU;

    int * ind = (int*)checked_hip_malloc_managed(sizeof (int) *countOnes * Nparticles);
    int * ind_GPU;
    double * u = (double *)checked_hip_malloc_managed(sizeof (double) *Nparticles);
    double * u_GPU;
    int * seed_GPU;
    double* partial_sums;

    // 统一内存别名：
    // 原来：*_GPU 是 device 指针，需显式 H2D/D2H
    // 现在：*_GPU 直接指向 managed 指针，CPU/GPU 同指针直用
    arrayX_GPU = arrayX;
    arrayY_GPU = arrayY;
    xj_GPU = xj;
    yj_GPU = yj;
    CDF_GPU = CDF;
    u_GPU = u;
    likelihood_GPU = likelihood;
    weights_GPU = weights;
    I_GPU = I;
    objxy_GPU = objxy;
    ind_GPU = ind;
    seed_GPU = seed;
    int alloc_blocks = (num_cus > Nparticles) ? num_cus : Nparticles;
    partial_sums = (double *)checked_hip_malloc_managed(sizeof (double) * alloc_blocks);
    memset(likelihood_GPU, 0, sizeof (double) *Nparticles);


    //Donnie - this loop is different because in this kernel, arrayX and arrayY
    //  are set equal to xj before every iteration, so effectively, arrayX and 
    //  arrayY will be set to xe and ye before the first iteration.
    for (x = 0; x < Nparticles; x++) {

        xj[x] = xe;
        yj[x] = ye;

        arrayX[x] = xe;
        arrayY[x] = ye;
        CDF[x] = ((double)(x + 1)) / ((double)Nparticles);
        likelihood[x] = 0.0;
    }

    int k;
    int indX, indY;
    //start send
    long long send_start = get_time();
    long long send_end = get_time();
    printf("TIME TO SEND TO GPU: %f\n", elapsed_time(send_start, send_end));
    int num_blocks = (Nparticles + threads_per_block - 1) / threads_per_block;

    if (num_blocks != num_cus) {
        printf("[pf] warning: num_blocks=%d, gpu_cus=%d\n", num_blocks, num_cus);
    }

    printf("[pf] Nparticles=%d threads_per_block=%d gpu_cus=%d num_blocks=%d\n",
        Nparticles, threads_per_block, num_cus, num_blocks);
    
    double *total_sum;
    total_sum = (double *)checked_hip_malloc_managed(sizeof(double));


    PF_LOG("Gaussian-style sequential CPU-then-GPU phase start");

    PF_LOG("CPU batch phase start");
    rodinia_mt_cpu_phase_pf_sync(weights_GPU,
                                arrayX_GPU,
                                arrayY_GPU,
                                CDF_GPU,
                                likelihood_GPU,
                                Nparticles,
                                0);
    PF_LOG("CPU batch phase done");

    PF_LOG("GPU batch phase start");

    for (k = 1; k < Nfr; k++) {
        PF_LOG("GPU iter=%d/%d begin", k, Nfr - 1);

        PF_LOG("GPU iter=%d/%d before likelihood_kernel", k, Nfr - 1);

        *total_sum = 0.0;

        for (int block_base = 0; block_base < num_blocks;
             block_base += PF_REAL_BLOCK_CHUNK) {
            int remaining_blocks = num_blocks - block_base;
            int launch_blocks = remaining_blocks < PF_REAL_BLOCK_CHUNK ?
                remaining_blocks : PF_REAL_BLOCK_CHUNK;

            likelihood_kernel <<< launch_blocks, threads_per_block >>> (
                arrayX_GPU,
                arrayY_GPU,
                xj_GPU,
                yj_GPU,
                CDF_GPU,
                ind_GPU,
                objxy_GPU,
                likelihood_GPU,
                I_GPU,
                u_GPU,
                weights_GPU,
                Nparticles,
                countOnes,
                max_size,
                k,
                IszY,
                Nfr,
                seed_GPU,
                partial_sums,
                block_base
            );
            HIP_KERNEL_CHECK("likelihood_kernel");
        }

        PF_LOG("GPU iter=%d/%d before sum_kernel_parallel", k, Nfr - 1);

        for (int block_base = 0; block_base < num_blocks;
             block_base += PF_REAL_BLOCK_CHUNK) {
            int remaining_blocks = num_blocks - block_base;
            int launch_blocks = remaining_blocks < PF_REAL_BLOCK_CHUNK ?
                remaining_blocks : PF_REAL_BLOCK_CHUNK;

            sum_kernel_parallel <<< launch_blocks, threads_per_block >>> (
                partial_sums,
                total_sum,
                num_blocks,
                block_base
            );

            HIP_KERNEL_CHECK("sum_kernel_parallel");
        }

        PF_LOG("GPU iter=%d/%d before normalize_weights_only_kernel", k, Nfr - 1);

        for (int block_base = 0; block_base < num_blocks;
             block_base += PF_REAL_BLOCK_CHUNK) {
            int remaining_blocks = num_blocks - block_base;
            int launch_blocks = remaining_blocks < PF_REAL_BLOCK_CHUNK ?
                remaining_blocks : PF_REAL_BLOCK_CHUNK;

            normalize_weights_only_kernel <<< launch_blocks, threads_per_block >>> (
                weights_GPU,
                Nparticles,
                total_sum,
                block_base
            );

            HIP_KERNEL_CHECK("normalize_weights_only_kernel");
        }

        PF_LOG("GPU iter=%d/%d before cdf_u0_kernel", k, Nfr - 1);

        cdf_u0_kernel <<< 1, 1 >>> (
            weights_GPU,
            Nparticles,
            CDF_GPU,
            u_GPU,
            seed_GPU
        );

        HIP_KERNEL_CHECK("cdf_u0_kernel");

        PF_LOG("GPU iter=%d/%d before fill_u_kernel", k, Nfr - 1);

        for (int block_base = 0; block_base < num_blocks;
             block_base += PF_REAL_BLOCK_CHUNK) {
            int remaining_blocks = num_blocks - block_base;
            int launch_blocks = remaining_blocks < PF_REAL_BLOCK_CHUNK ?
                remaining_blocks : PF_REAL_BLOCK_CHUNK;

            fill_u_kernel <<< launch_blocks, threads_per_block >>> (
                u_GPU,
                Nparticles,
                block_base
            );

            HIP_KERNEL_CHECK("fill_u_kernel");
        }

        PF_LOG("GPU iter=%d/%d before find_index_kernel", k, Nfr - 1);

        for (int block_base = 0; block_base < num_blocks;
             block_base += PF_REAL_BLOCK_CHUNK) {
            int remaining_blocks = num_blocks - block_base;
            int launch_blocks = remaining_blocks < PF_REAL_BLOCK_CHUNK ?
                remaining_blocks : PF_REAL_BLOCK_CHUNK;

            find_index_kernel <<< launch_blocks, threads_per_block >>> (
                arrayX_GPU,
                arrayY_GPU,
                CDF_GPU,
                u_GPU,
                xj_GPU,
                yj_GPU,
                weights_GPU,
                Nparticles,
                block_base
            );

            HIP_KERNEL_CHECK("find_index_kernel");
        }

        PF_LOG("GPU iter=%d/%d end", k, Nfr - 1);

    }

    PF_LOG("GPU batch phase done");
    PF_LOG("Gaussian-style sequential CPU-then-GPU phase done");

    // 原来：D2H memcpy 隐式同步
    // 现在：managed 内存下显式同步确保 CPU 可读
    hipDeviceSynchronize();
    long long back_time = get_time();

    long long free_time = get_time();
    long long arrayX_time = get_time();
    long long arrayY_time = get_time();
    long long back_end_time = get_time();
    printf("GPU Execution: %lf\n", elapsed_time(send_end, back_time));
    printf("FREE TIME: %lf\n", elapsed_time(back_time, free_time));
    printf("TIME TO SEND BACK: %lf\n", elapsed_time(back_time, back_end_time));
    printf("SEND ARRAY X BACK: %lf\n", elapsed_time(free_time, arrayX_time));
    printf("SEND ARRAY Y BACK: %lf\n", elapsed_time(arrayX_time, arrayY_time));
    printf("SEND WEIGHTS BACK: %lf\n", elapsed_time(arrayY_time, back_end_time));

    xe = 0;
    ye = 0;
    // estimate the object location by expected values
    for (x = 0; x < Nparticles; x++) {
        xe += arrayX[x] * weights[x];
        ye += arrayY[x] * weights[x];
    }
    printf("XE: %lf\n", xe);
    printf("YE: %lf\n", ye);
    double distance = sqrt(pow((double) (xe - (int) roundDouble(IszY / 2.0)), 2) + pow((double) (ye - (int) roundDouble(IszX / 2.0)), 2));
    printf("%lf\n", distance);

    //CUDA freeing of memory
    hipFree(weights);
    hipFree(arrayY);
    hipFree(arrayX);
    hipFree(xj);
    hipFree(yj);
    hipFree(CDF);
    hipFree(ind);
    hipFree(u);
    hipFree(likelihood);
    hipFree(objxy);
    hipFree(partial_sums);
    hipFree(total_sum);

    //free regular memory
    free(disk);
}

int main(int argc, char * argv[]) {

    const char* usage = "double.out -x <dimX> -y <dimY> -z <Nfr> -np <Nparticles> --cpu-workers <N> --gpu-cus <M>";
    //check number of arguments
    if (argc != 13) {
        printf("%s\n", usage);
        return 0;
    }
    //check args deliminators
    if (strcmp(argv[1], "-x") || strcmp(argv[3], "-y") || strcmp(argv[5], "-z") || strcmp(argv[7], "-np")) {
        printf("%s\n", usage);
        return 0;
    }

    int IszX, IszY, Nfr, Nparticles;

    //converting a string to a integer
    if (sscanf(argv[2], "%d", &IszX) == EOF) {
        printf("ERROR: dimX input is incorrect");
        return 0;
    }

    if (IszX <= 0) {
        printf("dimX must be > 0\n");
        return 0;
    }

    //converting a string to a integer
    if (sscanf(argv[4], "%d", &IszY) == EOF) {
        printf("ERROR: dimY input is incorrect");
        return 0;
    }

    if (IszY <= 0) {
        printf("dimY must be > 0\n");
        return 0;
    }

    //converting a string to a integer
    if (sscanf(argv[6], "%d", &Nfr) == EOF) {
        printf("ERROR: Number of frames input is incorrect");
        return 0;
    }

    if (Nfr <= 0) {
        printf("number of frames must be > 0\n");
        return 0;
    }

    //converting a string to a integer
    if (sscanf(argv[8], "%d", &Nparticles) == EOF) {
        printf("ERROR: Number of particles input is incorrect");
        return 0;
    }

    if (Nparticles <= 0) {
        printf("Number of particles must be > 0\n");
        return 0;
    }

    if (strcmp(argv[9], "--cpu-workers")) {
        printf("%s\n", usage);
        return 0;
    }
    int mt_threads = 0;
    sscanf(argv[10], "%d", &mt_threads);
    if (mt_threads <= 0) {
        printf("cpu-workers must be > 0\n");
        return 0;
    }
    rodinia_mt_set_threads(mt_threads);

    if (strcmp(argv[11], "--gpu-cus")) {
        printf("%s\n", usage);
        return 0;
    }
    int num_cus = 0;
    sscanf(argv[12], "%d", &num_cus);

    if (num_cus <= 0) {
        printf("gpu-cus must be > 0\n");
        return 0;
    }

    int target_particles = num_cus * threads_per_block;

    if (Nparticles != target_particles) {
        printf("[pf] adjust Nparticles from %d to %d for gpu_cus=%d\n",
            Nparticles, target_particles, num_cus);
        Nparticles = target_particles;
    }
    //establish seed
    // 原来：seed/I 在 host，GPU 端需 hipMemcpy
    // 现在：seed/I 用 managed 分配，GPU 直接访问
    int * seed = (int *)checked_hip_malloc_managed(sizeof (int) *Nparticles);
    int i;
    for (i = 0; i < Nparticles; i++)
        seed[i] = time(0) * i;
    //malloc matrix
    unsigned char * I = (unsigned char *)checked_hip_malloc_managed(sizeof (unsigned char) *IszX * IszY * Nfr);
    long long start = get_time();
    //call video sequence
    videoSequence(I, IszX, IszY, Nfr, seed);
    long long endVideoSequence = get_time();
    printf("VIDEO SEQUENCE TOOK %f\n", elapsed_time(start, endVideoSequence));
    //call particle filter
    particleFilter(I, IszX, IszY, Nfr, seed, Nparticles, num_cus);
    long long endParticleFilter = get_time();
    printf("PARTICLE FILTER TOOK %f\n", elapsed_time(endVideoSequence, endParticleFilter));
    printf("ENTIRE PROGRAM TOOK %f\n", elapsed_time(start, endParticleFilter));

    hipFree(seed);
    hipFree(I);
    printf("PASSED!\n");
    return 0;
}
