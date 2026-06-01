#include "hip/hip_runtime.h"
#include <stdio.h>					// (in path known to compiler)			needed by printf
#include <stdlib.h>
#include <stdbool.h>				// (in path known to compiler)			needed by true/false
#include <string.h>
#include <time.h>
#include <stddef.h>
#include <pthread.h>
#include <sched.h>
#include <stdatomic.h>
#if defined(__has_include)
#if __has_include(<gem5/m5ops.h>)
#include <gem5/m5ops.h>
#endif
#if __has_include(<gem5/m5_mmap.h>)
#include <gem5/m5_mmap.h>
#endif
#if !defined(m5_work_begin) && __has_include("../../../include/gem5/m5ops.h")
#include "../../../include/gem5/m5ops.h"
#endif
#if !defined(map_m5_mem) && __has_include("../../../include/gem5/m5_mmap.h")
#include "../../../include/gem5/m5_mmap.h"
#endif
#endif

#ifndef m5_work_begin
#define m5_work_begin(a, b) ((void)0)
#endif

#ifndef m5_work_end
#define m5_work_end(a, b) ((void)0)
#endif

#ifndef m5_work_begin_addr
#define m5_work_begin_addr(a, b, c) ((void)0)
#endif

#ifndef m5_work_end_addr
#define m5_work_end_addr(a, b, c) ((void)0)
#endif

#ifndef map_m5_mem
static inline void map_m5_mem(void) {}
#endif

#ifndef unmap_m5_mem
static inline void unmap_m5_mem(void) {}
#endif

#define LAVAMD_DBG(...) do {                          \
    char _buf[512];                                   \
    snprintf(_buf, sizeof(_buf), __VA_ARGS__);        \
    fprintf(stdout, "[LAVAMD_DBG] %s\n", _buf);      \
    fflush(stdout);                                   \
} while (0)

typedef struct {
    int tid;
    int active_threads;
    volatile unsigned char *shared_base;
    size_t shared_elems;
    size_t elem_size;

    volatile unsigned int sink;
} rodinia_mt_arg_t;

static int rodinia_mt_threads = 1;
static atomic_int rodinia_mt_start_flag = 0;
static const size_t RODINIA_MT_CPU_READ_ELEMS_LIMIT = 128;

static void rodinia_mt_set_threads(int n)
{
    if (n > 0)
        rodinia_mt_threads = n;
}

static void *rodinia_mt_worker(void *vp)
{
    rodinia_mt_arg_t *a = (rodinia_mt_arg_t *)vp;

    volatile unsigned int acc = 0;
    volatile unsigned char *shared = a->shared_base;
    size_t shared_elems = a->shared_elems;
    size_t elem_size = a->elem_size;

    LAVAMD_DBG("CPU worker start: tid=%d active_threads=%d shared_elems=%lu elem_size=%lu",
               a->tid,
               a->active_threads,
               (unsigned long)shared_elems,
               (unsigned long)elem_size);

    if (shared == NULL || shared_elems == 0 || elem_size == 0) {
        LAVAMD_DBG("CPU worker early return: tid=%d", a->tid);
        a->sink = 0;
        return NULL;
    }

    while (!atomic_load_explicit(&rodinia_mt_start_flag, memory_order_acquire)) {
        sched_yield();
    }

    size_t elem_begin =
        (shared_elems * (size_t)a->tid) / (size_t)a->active_threads;
    size_t elem_end =
        (shared_elems * (size_t)(a->tid + 1)) / (size_t)a->active_threads;
    size_t elem_count = elem_end > elem_begin ? (elem_end - elem_begin) : 0;
    if (elem_count == 0) {
        elem_begin = 0;
        elem_end = shared_elems;
        elem_count = shared_elems;
    }

    size_t scan_elems =
        elem_count < RODINIA_MT_CPU_READ_ELEMS_LIMIT ?
        elem_count : RODINIA_MT_CPU_READ_ELEMS_LIMIT;
    for (size_t n = 0; n < scan_elems; n++) {
        /* Shared input read: linearly walk a capped element range. */
        size_t elem_idx = elem_begin + n;
        size_t byte_idx = elem_idx * elem_size;
        unsigned int v = 0;
        v += (unsigned int)shared[byte_idx];
        v += (unsigned int)shared[byte_idx + (elem_size / 4)];
        v += (unsigned int)shared[byte_idx + (elem_size / 2)];
        v += (unsigned int)shared[byte_idx + ((elem_size * 3) / 4)];

        acc += v + (unsigned int)n + (unsigned int)a->tid;
        acc = acc * 1664525u + 1013904223u;
    }

    a->sink = acc;

    LAVAMD_DBG("CPU worker end: tid=%d sink=%u", a->tid, a->sink);
    return NULL;
}

static void rodinia_mt_cpu_phase(void *shared, size_t shared_bytes, size_t elem_size, int iters)
{
    LAVAMD_DBG("CPU phase enter: shared=%p elems=%lu elem_size=%lu requested_threads=%d",
               shared,
               (unsigned long)(elem_size ? (shared_bytes / elem_size) : 0),
               (unsigned long)elem_size,
               rodinia_mt_threads);

    if (rodinia_mt_threads <= 0 || shared == NULL || shared_bytes == 0 || elem_size == 0) {
        LAVAMD_DBG("CPU phase skip");
        return;
    }

    int active_threads = rodinia_mt_threads;
    atomic_store_explicit(&rodinia_mt_start_flag, 0, memory_order_release);

    LAVAMD_DBG("CPU phase active_threads=%d requested_threads=%d",
               active_threads, rodinia_mt_threads);

    pthread_t *ths =
        (pthread_t *)malloc((size_t)active_threads * sizeof(pthread_t));
    rodinia_mt_arg_t *args =
        (rodinia_mt_arg_t *)malloc((size_t)active_threads * sizeof(rodinia_mt_arg_t));

    if (!ths || !args) {
        LAVAMD_DBG("CPU phase malloc failed: ths=%p args=%p",
                   (void *)ths, (void *)args);
        free(ths);
        free(args);
        exit(-1);
    }

    LAVAMD_DBG("CPU phase before pthread_create loop");

    for (int t = 0; t < active_threads; t++) {
        args[t].tid = t;
        args[t].active_threads = active_threads;
        args[t].shared_base = (volatile unsigned char *)shared;
        args[t].shared_elems = shared_bytes / elem_size;
        args[t].elem_size = elem_size;
        args[t].sink = 0;

        LAVAMD_DBG("CPU phase before pthread_create: t=%d", t);

        int ret = pthread_create(&ths[t], NULL, rodinia_mt_worker, &args[t]);
        if (ret != 0) {
            LAVAMD_DBG("pthread_create failed: t=%d ret=%d", t, ret);
            exit(-1);
        }

        LAVAMD_DBG("CPU phase after pthread_create: t=%d", t);
    }

    atomic_store_explicit(&rodinia_mt_start_flag, 1, memory_order_release);

    LAVAMD_DBG("CPU phase before pthread_join loop");

    for (int t = 0; t < active_threads; t++) {
        LAVAMD_DBG("CPU phase before pthread_join: t=%d", t);

        int ret = pthread_join(ths[t], NULL);
        if (ret != 0) {
            LAVAMD_DBG("pthread_join failed: t=%d ret=%d", t, ret);
            exit(-1);
        }

        LAVAMD_DBG("CPU phase after pthread_join: t=%d sink=%u",
                   t, args[t].sink);
    }

    LAVAMD_DBG("CPU phase all workers joined");

    free(ths);
    free(args);

    LAVAMD_DBG("CPU phase exit");
}


//======================================================================================================================================================150
//	UTILITIES
//======================================================================================================================================================150

#include "./util/timer/timer.h"			// (in path specified here)
#include "./util/num/num.h"				// (in path specified here)


//======================================================================================================================================================150
//	MAIN FUNCTION HEADER
//======================================================================================================================================================150

#include "./main.h"						// (in the current directory)

//======================================================================================================================================================150
//	KERNEL
//======================================================================================================================================================150

#include "./kernel/kernel_gpu_cuda_wrapper.h"	// (in library path specified here)

//======================================================================================================================================================150
//	MANAGED MEMORY
//======================================================================================================================================================150

static void *
checked_hip_malloc_managed(size_t size)
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

int main(int argc, char *argv [])
{
	LAVAMD_DBG("thread block size of kernel = %d ", NUMBER_THREADS);

	LAVAMD_DBG("main enter: argc=%d", argc);

	for (int ai = 0; ai < argc; ai++) {
		LAVAMD_DBG("argv[%d]=%s", ai, argv[ai]);
	}

	// timer
	long long time0;

	time0 = get_time();

	// timer
	long long time1;
	long long time2;
	long long time3;
	long long time4;
	long long time5;
	long long time6;
	long long time7;

	// counters
	int i, j, k, l, m, n;

	// system memory
	par_str par_cpu;
	dim_str dim_cpu;
	box_str* box_cpu;
	FOUR_VECTOR* rv_cpu;
	fp* qv_cpu;
	FOUR_VECTOR* fv_cpu;
	int nh;

	time1 = get_time();

	//======================================================================================================================================================150
	//	CHECK INPUT ARGUMENTS
	//======================================================================================================================================================150

	// assing default values
	dim_cpu.boxes1d_arg = 1;
	int mt_threads = 0;
	int num_cus = 0;

	// go through arguments
	for(dim_cpu.cur_arg=1; dim_cpu.cur_arg<argc; dim_cpu.cur_arg++){
		// check if -boxes1d
		if(strcmp(argv[dim_cpu.cur_arg], "-boxes1d")==0){
			// check if value provided
			if (dim_cpu.cur_arg + 1 < argc) {
				// check if value is a number
				if(isInteger(argv[dim_cpu.cur_arg+1])==1){
					dim_cpu.boxes1d_arg = atoi(argv[dim_cpu.cur_arg+1]);
					if(dim_cpu.boxes1d_arg <= 0){
						LAVAMD_DBG("ERROR: Wrong value to -boxes1d parameter, cannot be <=0");
						return 0;
					}
					dim_cpu.cur_arg = dim_cpu.cur_arg+1;
				}
				// value is not a number
				else{
					LAVAMD_DBG("ERROR: Value to -boxes1d parameter in not a number");
					return 0;
				}
			}
			// value not provided
			else{
				LAVAMD_DBG("ERROR: Missing value to -boxes1d parameter");
				return 0;
			}
		}
		else if (strcmp(argv[dim_cpu.cur_arg], "--cpu-workers") == 0) {
			if (dim_cpu.cur_arg + 1 < argc) {
				mt_threads = atoi(argv[dim_cpu.cur_arg + 1]);
				dim_cpu.cur_arg++;
			} else {
				LAVAMD_DBG("ERROR: Missing value to --cpu-workers parameter");
				return 0;
			}
		}
		else if (strcmp(argv[dim_cpu.cur_arg], "--gpu-cus") == 0) {
			if (dim_cpu.cur_arg + 1 < argc) {
				num_cus = atoi(argv[dim_cpu.cur_arg + 1]);
				dim_cpu.cur_arg++;
			} else {
				LAVAMD_DBG("ERROR: Missing value to --gpu-cus parameter");
				return 0;
			}
		}
		// unknown
		else{
			LAVAMD_DBG("ERROR: Unknown parameter");
			return 0;
		}
	}

	// Print configuration
	LAVAMD_DBG("Configuration used: boxes1d = %d", dim_cpu.boxes1d_arg);

	if (mt_threads <= 0)
    mt_threads = 1;

	if (num_cus < 0)
		num_cus = 0;

	LAVAMD_DBG("args parsed: boxes1d=%d cpu_workers=%d gpu_cus=%d",
           dim_cpu.boxes1d_arg, mt_threads, num_cus);

	rodinia_mt_set_threads(mt_threads);

	time2 = get_time();

	//======================================================================================================================================================150
	//	INPUTS
	//======================================================================================================================================================150

	par_cpu.alpha = 0.5;

	time3 = get_time();

	//======================================================================================================================================================150
	//	DIMENSIONS
	//======================================================================================================================================================150

	// total number of boxes
	dim_cpu.number_boxes = dim_cpu.boxes1d_arg * dim_cpu.boxes1d_arg * dim_cpu.boxes1d_arg;

	// how many particles space has in each direction
	dim_cpu.space_elem = dim_cpu.number_boxes * NUMBER_PAR_PER_BOX;
	dim_cpu.space_mem = dim_cpu.space_elem * sizeof(FOUR_VECTOR);
	dim_cpu.space_mem2 = dim_cpu.space_elem * sizeof(fp);

	LAVAMD_DBG("dimensions done: number_boxes=%ld space_elem=%ld space_mem=%ld space_mem2=%ld box_mem=%ld",
           (long)dim_cpu.number_boxes,
           (long)dim_cpu.space_elem,
           (long)dim_cpu.space_mem,
           (long)dim_cpu.space_mem2,
           (long)dim_cpu.box_mem);

	// box array
	dim_cpu.box_mem = dim_cpu.number_boxes * sizeof(box_str);

	time4 = get_time();

	//======================================================================================================================================================150
	//	SYSTEM MEMORY
	//======================================================================================================================================================150

	//====================================================================================================100
	//	BOX
	//====================================================================================================100

	// allocate boxes
	// 原来：box_cpu 在 host，GPU 端需要 hipMalloc + hipMemcpy
	// 现在：统一内存 managed 分配，一份指针贯通 CPU 初始化与 GPU kernel
	LAVAMD_DBG("before alloc box_cpu: bytes=%ld", (long)dim_cpu.box_mem);
	box_cpu = (box_str*)checked_hip_malloc_managed(dim_cpu.box_mem);
	LAVAMD_DBG("after alloc box_cpu: ptr=%p", (void *)box_cpu);

	// initialize number of home boxes
	nh = 0;

	LAVAMD_DBG("box init begin");

	// home boxes in z direction
	for(i=0; i<dim_cpu.boxes1d_arg; i++){
		// home boxes in y direction
		for(j=0; j<dim_cpu.boxes1d_arg; j++){
			// home boxes in x direction
			for(k=0; k<dim_cpu.boxes1d_arg; k++){

				// current home box
				box_cpu[nh].x = k;
				box_cpu[nh].y = j;
				box_cpu[nh].z = i;
				box_cpu[nh].number = nh;
				box_cpu[nh].offset = nh * NUMBER_PAR_PER_BOX;

				// initialize number of neighbor boxes
				box_cpu[nh].nn = 0;

				// neighbor boxes in z direction
				for(l=-1; l<2; l++){
					// neighbor boxes in y direction
					for(m=-1; m<2; m++){
						// neighbor boxes in x direction
						for(n=-1; n<2; n++){

							// check if (this neighbor exists) and (it is not the same as home box)
							if(		(((i+l)>=0 && (j+m)>=0 && (k+n)>=0)==true && ((i+l)<dim_cpu.boxes1d_arg && (j+m)<dim_cpu.boxes1d_arg && (k+n)<dim_cpu.boxes1d_arg)==true)	&&
									(l==0 && m==0 && n==0)==false	){

								// current neighbor box
								box_cpu[nh].nei[box_cpu[nh].nn].x = (k+n);
								box_cpu[nh].nei[box_cpu[nh].nn].y = (j+m);
								box_cpu[nh].nei[box_cpu[nh].nn].z = (i+l);
								box_cpu[nh].nei[box_cpu[nh].nn].number =	(box_cpu[nh].nei[box_cpu[nh].nn].z * dim_cpu.boxes1d_arg * dim_cpu.boxes1d_arg) + 
																			(box_cpu[nh].nei[box_cpu[nh].nn].y * dim_cpu.boxes1d_arg) + 
																			 box_cpu[nh].nei[box_cpu[nh].nn].x;
								box_cpu[nh].nei[box_cpu[nh].nn].offset = box_cpu[nh].nei[box_cpu[nh].nn].number * NUMBER_PAR_PER_BOX;

								// increment neighbor box
								box_cpu[nh].nn = box_cpu[nh].nn + 1;

							}

						} // neighbor boxes in x direction
					} // neighbor boxes in y direction
				} // neighbor boxes in z direction

				// increment home box
				nh = nh + 1;

			} // home boxes in x direction
		} // home boxes in y direction
	} // home boxes in z direction
	LAVAMD_DBG("box init end: nh=%d expected=%ld", nh, (long)dim_cpu.number_boxes);
	//====================================================================================================100
	//	PARAMETERS, DISTANCE, CHARGE AND FORCE
	//====================================================================================================100

	// random generator seed set to random value - time in this case
	srand(time(NULL));

	// input (distances)
	// 原来：rv_cpu 在 host，GPU 端需要 hipMalloc + hipMemcpy
	// 现在：统一内存 managed 分配，GPU 直接访问同一份数据

	LAVAMD_DBG("before alloc rv_cpu: bytes=%ld", (long)dim_cpu.space_mem);
	rv_cpu = (FOUR_VECTOR*)checked_hip_malloc_managed(dim_cpu.space_mem);
	LAVAMD_DBG("after alloc rv_cpu: ptr=%p", (void *)rv_cpu);

	for(i=0; i<dim_cpu.space_elem; i=i+1){
		rv_cpu[i].v = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
		rv_cpu[i].x = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
		rv_cpu[i].y = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
		rv_cpu[i].z = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
	}

	// input (charge)
	// 原来：qv_cpu 在 host，GPU 端需要 hipMalloc + hipMemcpy
	// 现在：统一内存 managed 分配，GPU 直接访问同一份数据
	LAVAMD_DBG("before alloc qv_cpu: bytes=%ld", (long)dim_cpu.space_mem2);
	qv_cpu = (fp*)checked_hip_malloc_managed(dim_cpu.space_mem2);
	LAVAMD_DBG("after alloc qv_cpu: ptr=%p", (void *)qv_cpu);
	for(i=0; i<dim_cpu.space_elem; i=i+1){
		qv_cpu[i] = (rand()%10 + 1) / 10.0;			// get a number in the range 0.1 - 1.0
	}

	// output (forces)
	// 原来：fv_cpu 在 host，GPU 端需要 hipMalloc + hipMemcpy
	// 现在：统一内存 managed 分配，GPU 直接写回同一份数据
	LAVAMD_DBG("before alloc fv_cpu: bytes=%ld", (long)dim_cpu.space_mem);
	fv_cpu = (FOUR_VECTOR*)checked_hip_malloc_managed(dim_cpu.space_mem);
	LAVAMD_DBG("after alloc fv_cpu: ptr=%p", (void *)fv_cpu);
	for(i=0; i<dim_cpu.space_elem; i=i+1){
		fv_cpu[i].v = 0;								// set to 0, because kernels keeps adding to initial value
		fv_cpu[i].x = 0;								// set to 0, because kernels keeps adding to initial value
		fv_cpu[i].y = 0;								// set to 0, because kernels keeps adding to initial value
		fv_cpu[i].z = 0;								// set to 0, because kernels keeps adding to initial value
	}

	LAVAMD_DBG("LAVAMD_MT: cpu_workers=%d gpu_cus=%d boxes1d=%d number_boxes=%ld",
       rodinia_mt_threads, num_cus, dim_cpu.boxes1d_arg, dim_cpu.number_boxes);

	/* ROI: CPU dummy phase first, then real GPU task, then GPU dummy phase. */
#if defined(GEM5_FUSION)
	LAVAMD_DBG("before m5_work_begin");
	m5_work_begin(0, 0);
	LAVAMD_DBG("after m5_work_begin");
#elif defined(GEM5_FS)
	map_m5_mem();
	LAVAMD_DBG("before m5_work_begin");
	m5_work_begin_addr(0, 0);
	LAVAMD_DBG("after m5_work_begin");
#endif

	LAVAMD_DBG("LAVAMD_MT: CPU dummy phase before GPU kernel");
	LAVAMD_DBG("before CPU phase host shared read/private write: shared=%p bytes=%lu",
			(void *)rv_cpu, (unsigned long)dim_cpu.space_mem);
	rodinia_mt_cpu_phase(qv_cpu, (size_t)dim_cpu.space_mem2, sizeof(fp), 1);
	LAVAMD_DBG("after CPU phase host shared read/private write");

	time5 = get_time();

	LAVAMD_DBG("before kernel_gpu_cuda_wrapper");
	kernel_gpu_cuda_wrapper(num_cus, par_cpu,
							dim_cpu,
							box_cpu,
							rv_cpu,
							qv_cpu,
								fv_cpu);
	LAVAMD_DBG("after kernel_gpu_cuda_wrapper");

#if defined(GEM5_FUSION)
	LAVAMD_DBG("before m5_work_end");
	m5_work_end(0, 0);
	LAVAMD_DBG("after m5_work_end");
#elif defined(GEM5_FS)
	LAVAMD_DBG("before m5_work_end");
	m5_work_end_addr(0, 0);
	LAVAMD_DBG("after m5_work_end");
	unmap_m5_mem();
#endif

	time6 = get_time();

	//======================================================================================================================================================150
	//	SYSTEM MEMORY DEALLOCATION
	//======================================================================================================================================================150

	// dump results
#ifdef OUTPUT
        FILE *fptr;
	fptr = fopen("result.txt", "w");	
	for(i=0; i<dim_cpu.space_elem; i=i+1){
        	fprintf(fptr, "%f, %f, %f, %f\n", fv_cpu[i].v, fv_cpu[i].x, fv_cpu[i].y, fv_cpu[i].z);
	}
	fclose(fptr);
#endif       	

	hipFree(rv_cpu);
	hipFree(qv_cpu);
	hipFree(fv_cpu);
	hipFree(box_cpu);

	time7 = get_time();

	//======================================================================================================================================================150
	//	DISPLAY TIMING
	//======================================================================================================================================================150

	// printf("Time spent in different stages of the application:\n");

	// printf("%15.12f s, %15.12f % : VARIABLES\n",						(float) (time1-time0) / 1000000, (float) (time1-time0) / (float) (time7-time0) * 100);
	// printf("%15.12f s, %15.12f % : INPUT ARGUMENTS\n", 					(float) (time2-time1) / 1000000, (float) (time2-time1) / (float) (time7-time0) * 100);
	// printf("%15.12f s, %15.12f % : INPUTS\n",							(float) (time3-time2) / 1000000, (float) (time3-time2) / (float) (time7-time0) * 100);
	// printf("%15.12f s, %15.12f % : dim_cpu\n", 							(float) (time4-time3) / 1000000, (float) (time4-time3) / (float) (time7-time0) * 100);
	// printf("%15.12f s, %15.12f % : SYS MEM: ALO\n",						(float) (time5-time4) / 1000000, (float) (time5-time4) / (float) (time7-time0) * 100);

	// printf("%15.12f s, %15.12f % : KERNEL: COMPUTE\n",					(float) (time6-time5) / 1000000, (float) (time6-time5) / (float) (time7-time0) * 100);

	// printf("%15.12f s, %15.12f % : SYS MEM: FRE\n", 					(float) (time7-time6) / 1000000, (float) (time7-time6) / (float) (time7-time0) * 100);

	// printf("Total time:\n");
	// printf("%.12f s\n", 												(float) (time7-time0) / 1000000);

	LAVAMD_DBG("PASSED!");
	return 0;											// always returns 0.0

}
