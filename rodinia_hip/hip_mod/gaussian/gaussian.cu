#include "hip/hip_runtime.h"

#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>

#ifdef __linux__
#include <sched.h>
#endif

#ifdef TIMING
#include "timing.h"
#endif

#define GAUSS_TRACE(fmt, ...)                                      \
    do {                                                           \
        printf("[gaussian] " fmt "\n", ##__VA_ARGS__);            \
        fflush(stdout);                                            \
    } while (0)

/* ============================================================================
 * Work-group configuration
 * ========================================================================== */

#ifdef RD_WG_SIZE_0_0
#define MAXBLOCKSIZE RD_WG_SIZE_0_0
#elif defined(RD_WG_SIZE_0)
#define MAXBLOCKSIZE RD_WG_SIZE_0
#elif defined(RD_WG_SIZE)
#define MAXBLOCKSIZE RD_WG_SIZE
#else
#define MAXBLOCKSIZE 64
#endif

#ifdef RD_WG_SIZE_1_0
#define BLOCK_SIZE_XY RD_WG_SIZE_1_0
#elif defined(RD_WG_SIZE_1)
#define BLOCK_SIZE_XY RD_WG_SIZE_1
#elif defined(RD_WG_SIZE)
#define BLOCK_SIZE_XY RD_WG_SIZE
#else
#define BLOCK_SIZE_XY 4
#endif

/* ============================================================================
 * Global Gaussian state
 * ========================================================================== */

int Size;
float *a;
float *b;
float *m;
float *finalVec;

int num_cus = 0;
unsigned int totalKernelTime = 0;

FILE *fp;

#ifdef TIMING
struct timeval tv;
struct timeval tv_total_start, tv_total_end;
struct timeval tv_h2d_start, tv_h2d_end;
struct timeval tv_d2h_start, tv_d2h_end;
struct timeval tv_kernel_start, tv_kernel_end;
struct timeval tv_mem_alloc_start, tv_mem_alloc_end;
struct timeval tv_close_start, tv_close_end;

float init_time = 0;
float mem_alloc_time = 0;
float h2d_time = 0;
float kernel_time = 0;
float d2h_time = 0;
float close_time = 0;
float total_time = 0;
#endif

/* ============================================================================
 * CPU multithread phase for heterogeneous MT experiments
 * ========================================================================== */

typedef struct {
    int tid;
    unsigned int seed;
    volatile unsigned long long loops;
    volatile unsigned int *private_buf;
    size_t private_words;
} rodinia_mt_arg_t;

typedef struct {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    int count;
    int total;
    int generation;
} simple_barrier_t;

static simple_barrier_t rodinia_mt_start_barrier;

static int rodinia_mt_threads = 4;
static int rodinia_mt_work_percent = 8;
static unsigned int rodinia_mt_seed = 1;
static int rodinia_mt_inited = 0;
static int rodinia_mt_threads_set_by_arg = 0;

static pthread_t *rodinia_mt_pool = NULL;
static rodinia_mt_arg_t *rodinia_mt_args = NULL;

static volatile float *rodinia_mt_a = NULL;
static volatile float *rodinia_mt_m = NULL;
static volatile float *rodinia_mt_b = NULL;
static int rodinia_mt_size = 0;

static volatile unsigned int *rodinia_mt_private = NULL;
static size_t rodinia_mt_private_words_per_thread = 0;

/* ============================================================================
 * Function declarations
 * ========================================================================== */

static void print_usage_and_exit(void);
static void parse_arguments(int argc, char **argv, int *verbose);

static void *checked_hip_malloc_managed(size_t size);
static void init_problem_by_size(int size);
void InitProblemOnce(char *filename);
void InitPerRun(void);

static void simple_barrier_init(simple_barrier_t *barrier, int total);
static void simple_barrier_wait(simple_barrier_t *barrier);
static void simple_barrier_destroy(simple_barrier_t *barrier);

static inline unsigned int rodinia_mt_xorshift32(unsigned int *state);
static void rodinia_mt_init_cfg(void);
void rodinia_mt_set_threads(int n);
static void *rodinia_mt_worker_once(void *p);
static void rodinia_mt_cpu_phase(float *a_ptr, float *m_ptr, float *b_ptr,
                                 int size, int iter);

void ForwardSub(void);
void BackSub(void);

__global__ void Fan1(float *m_cuda, float *a_cuda, int Size, int t);
__global__ void Fan2(float *m_cuda, float *a_cuda, float *b_cuda, int Size,
                     int j1, int t);

void create_matrix(float *m, int size);
void InitMat(float *ary, int nrow, int ncol);
void InitAry(float *ary, int ary_size);
void PrintMat(float *ary, int nrow, int ncolumn);
void PrintAry(float *ary, int ary_size);
void PrintDeviceProperties(void);
void checkCUDAError(const char *msg);

/* ============================================================================
 * Small utilities
 * ========================================================================== */

static void print_usage_and_exit(void)
{
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
    printf("4\n\n");
    printf("-0.6\t-0.5\t0.7\t0.3\n");
    printf("-0.3\t-0.9\t0.3\t0.7\n");
    printf("-0.4\t-0.5\t-0.3\t-0.8\n");
    printf("0.0\t-0.1\t0.2\t0.9\n\n");
    printf("-0.85\t-0.68\t0.24\t-0.53\n\n");
    printf("0.7\t0.0\t-0.4\t-0.5\n");
    exit(0);
}

static void *checked_hip_malloc_managed(size_t size)
{
    void *ptr = NULL;
    hipError_t err = hipMallocManaged(&ptr, size, hipMemAttachGlobal);

    if (err != hipSuccess) {
        fprintf(stderr, "hipMallocManaged failed (%zu bytes): %s\n",
                size, hipGetErrorString(err));
        exit(-1);
    }

    return ptr;
}

static void parse_arguments(int argc, char **argv, int *verbose)
{
    int mt_threads = 0;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--cpu-workers") == 0 && i + 1 < argc) {
            mt_threads = atoi(argv[++i]);
            continue;
        }

        if (strcmp(argv[i], "--gpu-cus") == 0 && i + 1 < argc) {
            num_cus = atoi(argv[++i]);
            continue;
        }

        if (argv[i][0] != '-') {
            continue;
        }

        switch (argv[i][1]) {
        case 's':
            if (i + 1 >= argc) {
                print_usage_and_exit();
            }
            init_problem_by_size(atoi(argv[++i]));
            break;

        case 'f':
            if (i + 1 >= argc) {
                print_usage_and_exit();
            }
            GAUSS_TRACE("Read file from %s", argv[i + 1]);
            InitProblemOnce(argv[++i]);
            break;

        case 'q':
            *verbose = 0;
            break;

        default:
            break;
        }
    }

    if (mt_threads > 0) {
        rodinia_mt_set_threads(mt_threads);
    }

    GAUSS_TRACE("after arg parse: Size=%d mt_threads=%d num_cus=%d",
                Size, mt_threads, num_cus);
}

/* ============================================================================
 * CPU-side synthetic load phase
 * ========================================================================== */

static void simple_barrier_init(simple_barrier_t *barrier, int total)
{
    pthread_mutex_init(&barrier->mutex, NULL);
    pthread_cond_init(&barrier->cond, NULL);

    barrier->count = 0;
    barrier->total = total;
    barrier->generation = 0;
}

static void simple_barrier_wait(simple_barrier_t *barrier)
{
    pthread_mutex_lock(&barrier->mutex);

    int generation = barrier->generation;
    barrier->count++;

    if (barrier->count == barrier->total) {
        barrier->count = 0;
        barrier->generation++;
        pthread_cond_broadcast(&barrier->cond);
    } else {
        while (generation == barrier->generation) {
            pthread_cond_wait(&barrier->cond, &barrier->mutex);
        }
    }

    pthread_mutex_unlock(&barrier->mutex);
}

static void simple_barrier_destroy(simple_barrier_t *barrier)
{
    pthread_cond_destroy(&barrier->cond);
    pthread_mutex_destroy(&barrier->mutex);
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

static void rodinia_mt_init_cfg(void)
{
    if (rodinia_mt_inited) {
        return;
    }

    const char *s_work = getenv("RODINIA_SHARE_PERCENT");
    const char *s_seed = getenv("RODINIA_SHARE_SEED");

    if (!rodinia_mt_threads_set_by_arg) {
        rodinia_mt_threads = 1;
    }

    if (s_work) {
        rodinia_mt_work_percent = atoi(s_work);
    }
    if (s_seed) {
        rodinia_mt_seed = (unsigned int)atoi(s_seed);
    }

    if (rodinia_mt_threads <= 0) {
        rodinia_mt_threads = 1;
    }
    if (rodinia_mt_work_percent < 0) {
        rodinia_mt_work_percent = 0;
    }
    if (rodinia_mt_work_percent > 100) {
        rodinia_mt_work_percent = 100;
    }
    if (rodinia_mt_seed == 0) {
        rodinia_mt_seed = 1;
    }

    GAUSS_TRACE("mt cfg: threads=%d work_percent=%d seed=%u",
                rodinia_mt_threads, rodinia_mt_work_percent, rodinia_mt_seed);

    rodinia_mt_inited = 1;
}

void rodinia_mt_set_threads(int n)
{
    rodinia_mt_threads = (n > 0) ? n : 1;
    rodinia_mt_threads_set_by_arg = 1;
}

static void *rodinia_mt_worker_once(void *p)
{
    rodinia_mt_arg_t *arg = (rodinia_mt_arg_t *)p;

    simple_barrier_wait(&rodinia_mt_start_barrier);

    unsigned int s = arg->seed ^ (unsigned int)(arg->tid + 1) * 0x9e3779b9u;

    int size = rodinia_mt_size;
    int total = size * size;

    if (size <= 0 || total <= 0 || rodinia_mt_threads <= 0) {
        volatile unsigned int acc = 0;

        for (int i = 0; i < 1024; i++) {
            acc += rodinia_mt_xorshift32(&s);
        }

        arg->loops++;
        return NULL;
    }

    int begin = (total * arg->tid) / rodinia_mt_threads;
    int end = (total * (arg->tid + 1)) / rodinia_mt_threads;
    int own_count = end - begin;

    if (own_count <= 0) {
        arg->loops++;
        return NULL;
    }

    int sample_count = (own_count * rodinia_mt_work_percent) / 100;
    if (sample_count < 64) {
        sample_count = 64;
    }

    int window_start = begin - own_count;
    int window_end = end + own_count;

    if (window_start < 0) {
        window_start = 0;
    }
    if (window_end > total) {
        window_end = total;
    }

    int window_count = window_end - window_start;
    if (window_count <= 0) {
        window_count = own_count;
    }

    volatile unsigned int acc = 0;

    for (int r = 0; r < sample_count; r++) {
        int idx = begin + (int)(rodinia_mt_xorshift32(&s) %
                                (unsigned int)own_count);
        float value = 0.0f;

        if (rodinia_mt_a) {
            value += rodinia_mt_a[idx];
        }
        if (rodinia_mt_m) {
            value += rodinia_mt_m[idx];
        }
        if (rodinia_mt_b) {
            value += rodinia_mt_b[idx % size];
        }

        acc += (unsigned int)(((int)(value * 1000.0f)) ^ idx);

        if (arg->private_buf && arg->private_words > 0) {
            size_t pidx = (size_t)(rodinia_mt_xorshift32(&s) %
                                   (unsigned int)arg->private_words);
            arg->private_buf[pidx] =
                acc + (unsigned int)arg->tid + (unsigned int)r;
        }
    }

    for (int r = 0; r < sample_count; r++) {
        int idx = window_start + (int)(rodinia_mt_xorshift32(&s) %
                                       (unsigned int)window_count);
        float value = 0.0f;

        if (rodinia_mt_a) {
            value += rodinia_mt_a[idx];
        }
        if (rodinia_mt_m) {
            value += rodinia_mt_m[idx];
        }
        if (rodinia_mt_b) {
            value += rodinia_mt_b[idx % size];
        }

        acc += (unsigned int)(((int)(value * 1000.0f)) ^ idx);
    }

    arg->loops++;
    return NULL;
}

static void rodinia_mt_cpu_phase(float *a_ptr, float *m_ptr, float *b_ptr,
                                 int size, int iter)
{
    rodinia_mt_init_cfg();

    if (rodinia_mt_work_percent <= 0) {
        return;
    }

    rodinia_mt_a = (volatile float *)a_ptr;
    rodinia_mt_m = (volatile float *)m_ptr;
    rodinia_mt_b = (volatile float *)b_ptr;
    rodinia_mt_size = size;

    int n = rodinia_mt_threads;

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
            (volatile unsigned int *)calloc(
                (size_t)n * rodinia_mt_private_words_per_thread,
                sizeof(unsigned int));
    }

    if (!rodinia_mt_pool || !rodinia_mt_args || !rodinia_mt_private) {
        fprintf(stderr,
                "[rodinia_mt][gaussian] failed to allocate CPU worker data\n");
        exit(1);
    }

    GAUSS_TRACE("CPU phase start iter=%d threads=%d size=%d", iter, n, size);

    for (int t = 0; t < n; t++) {
        rodinia_mt_args[t].tid = t;
        rodinia_mt_args[t].seed =
            rodinia_mt_seed ^ (unsigned int)(t + 1) ^ (unsigned int)iter;
        rodinia_mt_args[t].loops = 0;
        rodinia_mt_args[t].private_buf =
            rodinia_mt_private +
            (size_t)t * rodinia_mt_private_words_per_thread;
        rodinia_mt_args[t].private_words = rodinia_mt_private_words_per_thread;

        GAUSS_TRACE("Creating pthread tid=%d iter=%d", t, iter);

        int rc = pthread_create(&rodinia_mt_pool[t], NULL,
                                rodinia_mt_worker_once, &rodinia_mt_args[t]);

        if (rc != 0) {
            fprintf(stderr,
                    "[rodinia_mt][gaussian] pthread_create failed "
                    "tid=%d iter=%d rc=%d\n",
                    t, iter, rc);
            exit(1);
        }

        GAUSS_TRACE("pthread_create success tid=%d iter=%d", t, iter);
    }

    GAUSS_TRACE("Main thread waiting at CPU start barrier iter=%d", iter);
    simple_barrier_wait(&rodinia_mt_start_barrier);
    GAUSS_TRACE("CPU workers released iter=%d", iter);

    for (int t = 0; t < n; t++) {
        GAUSS_TRACE("Joining pthread tid=%d iter=%d", t, iter);

        int rc = pthread_join(rodinia_mt_pool[t], NULL);
        if (rc != 0) {
            fprintf(stderr,
                    "[rodinia_mt][gaussian] pthread_join failed "
                    "tid=%d iter=%d rc=%d\n",
                    t, iter, rc);
            exit(1);
        }

        GAUSS_TRACE("Joined pthread tid=%d iter=%d loops=%llu",
                    t, iter,
                    (unsigned long long)rodinia_mt_args[t].loops);
    }

    /*
     * Keep the original lifecycle behavior: the old code did not destroy this
     * barrier here. This avoids changing synchronization/resource behavior while
     * still making the phase structure explicit.
     */
    /* simple_barrier_destroy(&rodinia_mt_start_barrier); */

    GAUSS_TRACE("CPU phase completed iter=%d", iter);
}

/* ============================================================================
 * Matrix initialization and input
 * ========================================================================== */

void create_matrix(float *m, int size)
{
    int i, j;
    float lamda = -0.01;
    float coe[2 * size - 1];
    float coe_i = 0.0;

    for (i = 0; i < size; i++) {
        coe_i = 10 * exp(lamda * i);

        j = size - 1 + i;
        coe[j] = coe_i;

        j = size - 1 - i;
        coe[j] = coe_i;
    }

    for (i = 0; i < size; i++) {
        for (j = 0; j < size; j++) {
            m[i * size + j] = coe[size - 1 - i + j];
        }
    }
}

static void init_problem_by_size(int size)
{
    Size = size;

    GAUSS_TRACE("Create matrix internally in parse, size = %d", Size);

    a = (float *)checked_hip_malloc_managed(
        sizeof(float) * (size_t)Size * (size_t)Size);
    create_matrix(a, Size);

    b = (float *)checked_hip_malloc_managed(sizeof(float) * (size_t)Size);
    for (int j = 0; j < Size; j++) {
        b[j] = 1.0f;
    }

    m = (float *)checked_hip_malloc_managed(
        sizeof(float) * (size_t)Size * (size_t)Size);
}

void InitProblemOnce(char *filename)
{
    fp = fopen(filename, "r");
    if (!fp) {
        GAUSS_TRACE("ERROR: fopen failed, filename=%s", filename);
        exit(1);
    }

    GAUSS_TRACE("before fscanf Size");

    if (fscanf(fp, "%d", &Size) != 1) {
        GAUSS_TRACE("ERROR: failed to read Size from %s", filename);
        fclose(fp);
        exit(1);
    }

    GAUSS_TRACE("InitProblemOnce: filename=%s Size=%d", filename, Size);

    GAUSS_TRACE("before malloc a, bytes=%zu",
                sizeof(float) * (size_t)Size * (size_t)Size);
    a = (float *)checked_hip_malloc_managed(
        sizeof(float) * (size_t)Size * (size_t)Size);
    GAUSS_TRACE("after malloc a");

    GAUSS_TRACE("before InitMat");
    InitMat(a, Size, Size);
    GAUSS_TRACE("after InitMat");

    GAUSS_TRACE("before malloc b, bytes=%zu", sizeof(float) * (size_t)Size);
    b = (float *)checked_hip_malloc_managed(sizeof(float) * (size_t)Size);
    GAUSS_TRACE("after malloc b");

    GAUSS_TRACE("before InitAry");
    InitAry(b, Size);
    GAUSS_TRACE("after InitAry");

    GAUSS_TRACE("before malloc m, bytes=%zu",
                sizeof(float) * (size_t)Size * (size_t)Size);
    m = (float *)checked_hip_malloc_managed(
        sizeof(float) * (size_t)Size * (size_t)Size);
    GAUSS_TRACE("after malloc m");

    fclose(fp);
}

void InitPerRun(void)
{
    for (int i = 0; i < Size * Size; i++) {
        m[i] = 0.0f;
    }
}

void InitMat(float *ary, int nrow, int ncol)
{
    for (int i = 0; i < nrow; i++) {
        if (i % 64 == 0) {
            GAUSS_TRACE("InitMat progress row=%d/%d", i, nrow);
        }

        for (int j = 0; j < ncol; j++) {
            int ret = fscanf(fp, "%f", ary + Size * i + j);
            if (ret != 1) {
                GAUSS_TRACE("ERROR: InitMat fscanf failed at i=%d j=%d", i, j);
                exit(1);
            }
        }
    }

    GAUSS_TRACE("InitMat done rows=%d cols=%d", nrow, ncol);
}

void InitAry(float *ary, int ary_size)
{
    for (int i = 0; i < ary_size; i++) {
        int ret = fscanf(fp, "%f", &ary[i]);
        if (ret != 1) {
            GAUSS_TRACE("ERROR: InitAry fscanf failed at i=%d", i);
            exit(1);
        }
    }

    GAUSS_TRACE("InitAry done size=%d", ary_size);
}

/* ============================================================================
 * HIP kernels
 * ========================================================================== */

__global__ void Fan1(float *m_cuda, float *a_cuda, int Size, int t)
{
    int idx = threadIdx.x + blockIdx.x * blockDim.x;

    if (idx >= Size - 1 - t) {
        return;
    }

    float pivot = a_cuda[Size * t + t];

    if (pivot == 0.0f) {
        m_cuda[Size * (idx + t + 1) + t] = 0.0f;
        return;
    }

    m_cuda[Size * (idx + t + 1) + t] =
        a_cuda[Size * (idx + t + 1) + t] / pivot;
}

__global__ void Fan2(float *m_cuda, float *a_cuda, float *b_cuda, int Size,
                     int j1, int t)
{
    int xidx = blockIdx.x * blockDim.x + threadIdx.x;
    int yidx = blockIdx.y * blockDim.y + threadIdx.y;

    if (xidx >= Size - 1 - t) {
        return;
    }

    if (yidx >= Size - t) {
        return;
    }

    a_cuda[Size * (xidx + 1 + t) + (yidx + t)] -=
        m_cuda[Size * (xidx + 1 + t) + t] *
        a_cuda[Size * t + (yidx + t)];

    if (yidx == 0) {
        b_cuda[xidx + 1 + t] -=
            m_cuda[Size * (xidx + 1 + t) + (yidx + t)] * b_cuda[t];
    }
}

/* ============================================================================
 * Gaussian elimination phases
 * ========================================================================== */

typedef struct {
    int block_size_1d;
    int grid_size_1d;
    int block_size_2d;
    int grid_size_2d;
    dim3 dim_block_1d;
    dim3 dim_grid_1d;
    dim3 dim_block_2d;
    dim3 dim_grid_2d;
} gaussian_launch_config_t;

static gaussian_launch_config_t make_launch_config(void)
{
    gaussian_launch_config_t cfg;

    cfg.block_size_1d = MAXBLOCKSIZE;
    cfg.grid_size_1d =
        (Size / cfg.block_size_1d) + ((Size % cfg.block_size_1d) ? 1 : 0);

    if (num_cus > 0 && cfg.grid_size_1d < num_cus) {
        cfg.grid_size_1d = num_cus;
    }

    cfg.block_size_2d = BLOCK_SIZE_XY;
    cfg.grid_size_2d = (Size + cfg.block_size_2d - 1) / cfg.block_size_2d;

    if (num_cus > 0) {
        int needed_2d = (int)ceil(sqrt((double)num_cus));
        if (cfg.grid_size_2d < needed_2d) {
            cfg.grid_size_2d = needed_2d;
        }
    }

    cfg.dim_block_1d = dim3(cfg.block_size_1d);
    cfg.dim_grid_1d = dim3(cfg.grid_size_1d);
    cfg.dim_block_2d = dim3(cfg.block_size_2d, cfg.block_size_2d);
    cfg.dim_grid_2d = dim3(cfg.grid_size_2d, cfg.grid_size_2d);

    return cfg;
}

static void run_cpu_batch(float *a_cuda, float *m_cuda, float *b_cuda)
{
    GAUSS_TRACE("CPU batch phase start");
    rodinia_mt_cpu_phase(a_cuda, m_cuda, b_cuda, Size, 0);
    GAUSS_TRACE("CPU batch phase done");
}

static void run_gpu_batch(float *a_cuda, float *m_cuda, float *b_cuda,
                          const gaussian_launch_config_t *cfg)
{
    GAUSS_TRACE("GPU batch phase start");

    for (int t = 0; t < Size - 1; t++) {
        if (t % 16 == 0) {
            GAUSS_TRACE("GPU iter=%d/%d before Fan1", t, Size - 1);
        }

        Fan1<<<cfg->dim_grid_1d, cfg->dim_block_1d>>>(m_cuda, a_cuda, Size, t);
        GAUSS_TRACE("GPU iter=%d after Fan1 launch", t);

        hipError_t e1 = hipDeviceSynchronize();
        GAUSS_TRACE("GPU iter=%d after Fan1 sync err=%s",
                    t, hipGetErrorString(e1));
        if (e1 != hipSuccess) {
            exit(1);
        }

        Fan2<<<cfg->dim_grid_2d, cfg->dim_block_2d>>>(
            m_cuda, a_cuda, b_cuda, Size, Size - t, t);
        GAUSS_TRACE("GPU iter=%d after Fan2 launch", t);

        hipError_t e2 = hipDeviceSynchronize();
        GAUSS_TRACE("GPU iter=%d after Fan2 sync err=%s",
                    t, hipGetErrorString(e2));
        if (e2 != hipSuccess) {
            exit(1);
        }
    }

    GAUSS_TRACE("GPU batch phase done");
}

void ForwardSub(void)
{
    float *m_cuda = m;
    float *a_cuda = a;
    float *b_cuda = b;

    gaussian_launch_config_t cfg = make_launch_config();

    GAUSS_TRACE("ForwardSub enter: Size=%d num_cus=%d block_size=%d grid_size=%d",
                Size, num_cus, cfg.block_size_1d, cfg.grid_size_1d);
    GAUSS_TRACE("2D config: blockSize2d=%d gridSize2d=%d dimGridXY=%d x %d",
                cfg.block_size_2d, cfg.grid_size_2d,
                cfg.grid_size_2d, cfg.grid_size_2d);

#ifdef TIMING
    gettimeofday(&tv_kernel_start, NULL);
#endif

    struct timeval time_start;
    gettimeofday(&time_start, NULL);

    GAUSS_TRACE("Gaussian sequential CPU-then-GPU phase start");

    run_cpu_batch(a_cuda, m_cuda, b_cuda);
    run_gpu_batch(a_cuda, m_cuda, b_cuda, &cfg);

    GAUSS_TRACE("Gaussian sequential CPU-then-GPU phase done");

    struct timeval time_end;
    gettimeofday(&time_end, NULL);

    totalKernelTime =
        (time_end.tv_sec * 1000000 + time_end.tv_usec) -
        (time_start.tv_sec * 1000000 + time_start.tv_usec);

#ifdef TIMING
    tvsub(&time_end, &tv_kernel_start, &tv);
    kernel_time += tv.tv_sec * 1000.0 + (float)tv.tv_usec / 1000.0;
#endif
}

void BackSub(void)
{
    finalVec = (float *)malloc(Size * sizeof(float));

    for (int i = 0; i < Size; i++) {
        int row = Size - i - 1;

        finalVec[row] = b[row];

        for (int j = 0; j < i; j++) {
            int col = Size - j - 1;
            finalVec[row] -= a[Size * row + col] * finalVec[col];
        }

        finalVec[row] = finalVec[row] / a[Size * row + row];
    }

    free(finalVec);
}

/* ============================================================================
 * Printing and HIP diagnostics
 * ========================================================================== */

void PrintDeviceProperties(void)
{
    hipDeviceProp_t deviceProp;
    int nDevCount = 0;

    hipGetDeviceCount(&nDevCount);
    GAUSS_TRACE("Total Device found: %d", nDevCount);

    for (int nDeviceIdx = 0; nDeviceIdx < nDevCount; ++nDeviceIdx) {
        memset(&deviceProp, 0, sizeof(deviceProp));

        if (hipSuccess == hipGetDeviceProperties(&deviceProp, nDeviceIdx)) {
            printf("\nDevice Name \t\t - %s ", deviceProp.name);
            printf("\n**************************************");
            printf("\nTotal Global Memory\t\t\t - %lu KB",
                   deviceProp.totalGlobalMem / 1024);
            printf("\nShared memory available per block \t - %lu KB",
                   deviceProp.sharedMemPerBlock / 1024);
            printf("\nNumber of registers per thread block \t - %d",
                   deviceProp.regsPerBlock);
            printf("\nWarp size in threads \t\t\t - %d", deviceProp.warpSize);
            printf("\nMemory Pitch \t\t\t\t - %zu bytes", deviceProp.memPitch);
            printf("\nMaximum threads per block \t\t - %d",
                   deviceProp.maxThreadsPerBlock);
            printf("\nMaximum Thread Dimension (block) \t - %d %d %d",
                   deviceProp.maxThreadsDim[0], deviceProp.maxThreadsDim[1],
                   deviceProp.maxThreadsDim[2]);
            printf("\nMaximum Thread Dimension (grid) \t - %d %d %d",
                   deviceProp.maxGridSize[0], deviceProp.maxGridSize[1],
                   deviceProp.maxGridSize[2]);
            printf("\nTotal constant memory \t\t\t - %zu bytes",
                   deviceProp.totalConstMem);
            printf("\nCUDA ver \t\t\t\t - %d.%d",
                   deviceProp.major, deviceProp.minor);
            printf("\nClock rate \t\t\t\t - %d KHz", deviceProp.clockRate);
            printf("\nTexture Alignment \t\t\t - %zu bytes",
                   deviceProp.textureAlignment);
            printf("\nNumber of Multi processors \t\t - %d\n\n",
                   deviceProp.multiProcessorCount);
        } else {
            printf("\n%s", hipGetErrorString(hipGetLastError()));
        }
    }
}

void PrintMat(float *ary, int nrow, int ncol)
{
    for (int i = 0; i < nrow; i++) {
        for (int j = 0; j < ncol; j++) {
            printf("%8.2f ", ary[Size * i + j]);
        }
        printf("\n");
    }

    printf("\n");
}

void PrintAry(float *ary, int ary_size)
{
    for (int i = 0; i < ary_size; i++) {
        printf("%.2f ", ary[i]);
    }

    printf("\n\n");
}

void checkCUDAError(const char *msg)
{
    hipError_t err = hipGetLastError();

    if (hipSuccess != err) {
        fprintf(stderr, "Cuda error: %s: %s.\n",
                msg, hipGetErrorString(err));
        exit(EXIT_FAILURE);
    }
}

/* ============================================================================
 * Main
 * ========================================================================== */

int main(int argc, char *argv[])
{
    GAUSS_TRACE("WG size of kernel 1 = %d, WG size of kernel 2= %d X %d",
                MAXBLOCKSIZE, BLOCK_SIZE_XY, BLOCK_SIZE_XY);

    if (argc < 2) {
        print_usage_and_exit();
    }

    int verbose = 0;

    PrintDeviceProperties();
    parse_arguments(argc, argv, &verbose);

    InitPerRun();
    GAUSS_TRACE("after InitPerRun");

    struct timeval time_start;
    gettimeofday(&time_start, NULL);

    ForwardSub();

    struct timeval time_end;
    gettimeofday(&time_end, NULL);

    unsigned int time_total =
        (time_end.tv_sec * 1000000 + time_end.tv_usec) -
        (time_start.tv_sec * 1000000 + time_start.tv_usec);

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
        PrintAry(finalVec, Size);
    }

    GAUSS_TRACE("Time total (including memory transfers)\t%f sec",
                time_total * 1e-6);
    GAUSS_TRACE("Time for CUDA kernels:\t%f sec", totalKernelTime * 1e-6);

    hipFree(m);
    hipFree(a);
    hipFree(b);

#ifdef TIMING
    printf("Exec: %f\n", kernel_time);
#endif

    GAUSS_TRACE("PASSED!");
    return 0;
}
