#include "hip/hip_runtime.h"
/***********************************************************************************
  Implementing Breadth first search on CUDA using algorithm given in HiPC'07
  paper "Accelerating Large Graph Algorithms on the GPU using CUDA"

  Copyright (c) 2008 International Institute of Information Technology - Hyderabad. 
  All rights reserved.

  Permission to use, copy, modify and distribute this software and its documentation for 
  educational purpose is hereby granted without fee, provided that the above copyright 
  notice and this permission notice appear in all copies of this software and that you do 
  not sell the software.

  THE SOFTWARE IS PROVIDED "AS IS" AND WITHOUT WARRANTY OF ANY KIND,EXPRESS, IMPLIED OR 
  OTHERWISE.

  Created by Pawan Harish.
 ************************************************************************************/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <hip/hip_runtime.h>

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

#ifdef TIMING
#include "timing.h"
#endif

#define MAX_THREADS_PER_BLOCK 512
static const int BFS_REAL_BLOCK_CHUNK = 12;

int no_of_nodes;
int edge_list_size;
FILE *fp;

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

//Structure to hold a node information
struct Node
{
	int starting;
	int no_of_edges;
};

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


__global__ void bfs_gpu_keepalive_kernel(int *buf, int n, int repeat)
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

static void bfs_gpu_keepalive(int num_cus)
{
    if (num_cus <= 0)
        return;

    int warmup_threads = MAX_THREADS_PER_BLOCK;
    int warmup_blocks = num_cus;
    int warmup_n = warmup_blocks * warmup_threads;

    int *warmup_buf = NULL;

    hipError_t err = hipMallocManaged((void **)&warmup_buf,
                                      sizeof(int) * warmup_n,
                                      hipMemAttachGlobal);
    if (err != hipSuccess) {
        fprintf(stderr, "BFS keepalive hipMallocManaged failed: %s\n",
                hipGetErrorString(err));
        exit(-1);
    }

    for (int i = 0; i < warmup_n; i++)
        warmup_buf[i] = i;

    printf("BFS_MT: GPU dummy blocks=%d threads=%d repeat=%d\n",
           warmup_blocks, warmup_threads, 64);

    bfs_gpu_keepalive_kernel<<<warmup_blocks, warmup_threads>>>(
        warmup_buf, warmup_n, 64);

    err = hipDeviceSynchronize();
    if (err != hipSuccess) {
        fprintf(stderr, "BFS GPU keepalive failed: %s\n",
                hipGetErrorString(err));
        exit(-1);
    }

    hipFree(warmup_buf);
}

#include "kernel.cu"
#include "kernel2.cu"

void BFSGraph(int argc, char** argv);

////////////////////////////////////////////////////////////////////////////////
// Main Program
////////////////////////////////////////////////////////////////////////////////
int main( int argc, char** argv) 
{
	no_of_nodes=0;
	edge_list_size=0;
	BFSGraph( argc, argv);
	printf("PASSED!\n");
	return 0;
}

void Usage(int argc, char**argv){

fprintf(stderr,"Usage: %s <input_file>\n", argv[0]);

}
////////////////////////////////////////////////////////////////////////////////
//Apply BFS on a Graph using CUDA
////////////////////////////////////////////////////////////////////////////////
void BFSGraph( int argc, char** argv) 
{

    char *input_f;
	int num_cus = 0;
	for (int ai = 2; ai < argc; ai++) {
		if (strcmp(argv[ai], "--cpu-workers") == 0 && ai + 1 < argc) {
			ai++;  // skip value (no-op, no rodinia_mt)
		} else if (strcmp(argv[ai], "--gpu-cus") == 0 && ai + 1 < argc) {
			num_cus = atoi(argv[++ai]);
		}
	}
	if(argc<2){
	Usage(argc, argv);
	exit(0);
	}

	input_f = argv[1];
	printf("Reading File\n");
	//Read in Graph from a file
	fp = fopen(input_f,"r");
	if(!fp)
	{
		printf("Error Reading graph file\n");
		return;
	}

	int source = 0;

	fscanf(fp,"%d",&no_of_nodes);

	int num_of_blocks = 1;
	int num_of_threads_per_block = no_of_nodes;

	//Make execution Parameters according to the number of nodes
	//Distribute threads across multiple Blocks if necessary
	if(no_of_nodes>MAX_THREADS_PER_BLOCK)
	{
		num_of_blocks = (int)ceil(no_of_nodes/(double)MAX_THREADS_PER_BLOCK); 
		num_of_threads_per_block = MAX_THREADS_PER_BLOCK; 
	}
	if (num_cus > 0 && num_of_blocks > num_cus) num_of_blocks = num_cus;

	// allocate host memory
	// 原来：h_graph_* 在 host，d_graph_* 在 device，需要 hipMemcpy(H2D)
	// 现在：统一内存 managed 分配，一份指针贯通 CPU 初始化和 GPU 访问
	Node* h_graph_nodes = (Node*)checked_hip_malloc_managed(sizeof(Node)*no_of_nodes);
	bool *h_graph_mask = (bool*)checked_hip_malloc_managed(sizeof(bool)*no_of_nodes);
	bool *h_updating_graph_mask = (bool*)checked_hip_malloc_managed(sizeof(bool)*no_of_nodes);
	bool *h_graph_visited = (bool*)checked_hip_malloc_managed(sizeof(bool)*no_of_nodes);

	int start, edgeno;   
	// initalize the memory
	for( unsigned int i = 0; i < no_of_nodes; i++) 
	{
		fscanf(fp,"%d %d",&start,&edgeno);
		h_graph_nodes[i].starting = start;
		h_graph_nodes[i].no_of_edges = edgeno;
		h_graph_mask[i]=false;
		h_updating_graph_mask[i]=false;
		h_graph_visited[i]=false;
	}

	//read the source node from the file
	fscanf(fp,"%d",&source);
	source=0;

	//set the source node as true in the mask
	h_graph_mask[source]=true;
	h_graph_visited[source]=true;

	fscanf(fp,"%d",&edge_list_size);

	int id,cost;
	// 原来：边表 host 分配 + device 复制
	// 现在：边表直接用 managed 内存
	int* h_graph_edges = (int*)checked_hip_malloc_managed(sizeof(int)*edge_list_size);
	for(int i=0; i < edge_list_size ; i++)
	{
		fscanf(fp,"%d",&id);
		fscanf(fp,"%d",&cost);
		h_graph_edges[i] = id;
	}

	if(fp)
		fclose(fp);    

	printf("Read File\n");

#ifdef  TIMING
    gettimeofday(&tv_total_start, NULL);
#endif
	//Copy the Node list to device memory
	// 统一内存下，device 指针就是同一个 managed 指针（不再 hipMalloc/hipMemcpy）
	Node* d_graph_nodes = h_graph_nodes;

	//Copy the Edge List to device Memory
	int* d_graph_edges = h_graph_edges;

	//Copy the Mask to device memory
	bool* d_graph_mask = h_graph_mask;

	bool* d_updating_graph_mask = h_updating_graph_mask;

	//Copy the Visited nodes array to device memory
	bool* d_graph_visited = h_graph_visited;

	// allocate mem for the result on host side
	// 原来：h_cost 与 d_cost 分离，kernel 结束后 hipMemcpy(D2H)
	// 现在：h_cost/d_cost 共享同一份 managed 内存
	int* h_cost = (int*)checked_hip_malloc_managed(sizeof(int)*no_of_nodes);
	for(int i=0;i<no_of_nodes;i++)
		h_cost[i]=-1;
	h_cost[source]=0;
	
	// allocate device memory for result
	int* d_cost = h_cost;

	// Device-side convergence flag. Keep CPU polling on a local host bool
	// so we do not add managed-memory accesses every BFS iteration.
	bool *d_over = NULL;
	hipError_t over_alloc_err = hipMalloc((void **)&d_over, sizeof(bool));
	if (over_alloc_err != hipSuccess) {
		fprintf(stderr, "hipMalloc d_over failed: %s\n",
		        hipGetErrorString(over_alloc_err));
		exit(-1);
	}
#ifdef  TIMING
    gettimeofday(&tv_mem_alloc_end, NULL);
    tvsub(&tv_mem_alloc_end, &tv_total_start, &tv);
    h2d_time = tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;
#endif

	printf("Copied Everything to GPU memory\n");

	// setup execution parameters
	dim3  grid( num_of_blocks, 1, 1);
	dim3  threads( num_of_threads_per_block, 1, 1);

	int k=0;
	printf("Start traversing the tree\n");
	bool stop;

	printf("[bfs] before m5_work_begin\n");
	fflush(stdout);
#if defined(GEM5_FUSION)
	m5_work_begin(0, 0);
#elif defined(GEM5_FS)
	map_m5_mem();
	m5_work_begin_addr(0, 0);
#endif
	printf("[bfs] after m5_work_begin\n");
	fflush(stdout);

	//Call the Kernel untill all the elements of Frontier are not false
	do
	{
		//if no thread changes this value then the loop stops
		stop=false;
#ifdef  TIMING
		gettimeofday(&tv_h2d_start, NULL);
#endif
		hipError_t over_reset_err = hipMemset(d_over, 0, sizeof(bool));
		if (over_reset_err != hipSuccess) {
			fprintf(stderr, "hipMemset d_over failed: %s\n",
			        hipGetErrorString(over_reset_err));
			exit(-1);
		}
#ifdef  TIMING
		gettimeofday(&tv_h2d_end, NULL);
		tvsub(&tv_h2d_end, &tv_h2d_start, &tv);
		h2d_time += tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;
#endif

		for (int block_base = 0; block_base < num_of_blocks;
		     block_base += BFS_REAL_BLOCK_CHUNK) {
			int remaining_blocks = num_of_blocks - block_base;
			int launch_blocks = remaining_blocks < BFS_REAL_BLOCK_CHUNK ?
				remaining_blocks : BFS_REAL_BLOCK_CHUNK;
			dim3 batch_grid(launch_blocks, 1, 1);

			Kernel<<< batch_grid, threads, 0 >>>(d_graph_nodes,
				d_graph_edges, d_graph_mask, d_updating_graph_mask,
				d_graph_visited, d_cost, no_of_nodes, block_base,
				num_of_blocks);
			hipDeviceSynchronize();
		}

		for (int block_base = 0; block_base < num_of_blocks;
		     block_base += BFS_REAL_BLOCK_CHUNK) {
			int remaining_blocks = num_of_blocks - block_base;
			int launch_blocks = remaining_blocks < BFS_REAL_BLOCK_CHUNK ?
				remaining_blocks : BFS_REAL_BLOCK_CHUNK;
			dim3 batch_grid(launch_blocks, 1, 1);

			Kernel2<<< batch_grid, threads, 0 >>>(d_graph_mask,
				d_updating_graph_mask, d_graph_visited, d_over, no_of_nodes,
				block_base, num_of_blocks);
			hipDeviceSynchronize();
		}
		// check if kernel execution generated and error

#ifdef  TIMING
		hipDeviceSynchronize();
		gettimeofday(&tv_kernel_end, NULL);
		tvsub(&tv_kernel_end, &tv_h2d_end, &tv);
		kernel_time += tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;
#endif

		hipError_t over_copy_err = hipMemcpy(&stop, d_over, sizeof(bool), hipMemcpyDeviceToHost);
		if (over_copy_err != hipSuccess) {
			fprintf(stderr, "hipMemcpy d_over failed: %s\n",
			        hipGetErrorString(over_copy_err));
			exit(-1);
		}
#ifdef  TIMING
		gettimeofday(&tv_d2h_end, NULL);
		tvsub(&tv_d2h_end, &tv_kernel_end, &tv);
		d2h_time += tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;
#endif

		k++;
	}
	while(stop);

	printf("[bfs] before m5_work_end\n");
	fflush(stdout);
#if defined(GEM5_FUSION)
	m5_work_end(0, 0);
#elif defined(GEM5_FS)
	m5_work_end_addr(0, 0);
	unmap_m5_mem();
#endif
	printf("[bfs] after m5_work_end\n");
	fflush(stdout);

	printf("Kernel Executed %d times\n",k);

	bfs_gpu_keepalive(num_cus);

	// copy result from device to host
#ifdef  TIMING
	gettimeofday(&tv_d2h_start, NULL);
#endif
	// 统一内存下，这里只需要同步即可（无需 D2H memcpy）
	hipDeviceSynchronize();
#ifdef  TIMING
	gettimeofday(&tv_d2h_end, NULL);
	tvsub(&tv_d2h_end, &tv_d2h_start, &tv);
	d2h_time += tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;
#endif

	// Store the result only when explicitly requested. The default path
	// skips this CPU-heavy walk to keep BFS CPU samples focused on real work.
	const char *write_result = getenv("BFS_WRITE_RESULT");
	if (write_result && strcmp(write_result, "0") != 0) {
		FILE *fpo = fopen("result.txt", "w");
		if (!fpo) {
			fprintf(stderr, "Error opening result.txt for write\n");
			exit(1);
		}
		for (int i = 0; i < no_of_nodes; i++)
			fprintf(fpo, "%d) cost:%d\n", i, h_cost[i]);
		fclose(fpo);
		printf("Result stored in result.txt\n");
	} else {
		printf("Result output skipped (set BFS_WRITE_RESULT=1 to enable)\n");
	}


	// cleanup memory
	hipFree(h_graph_nodes);
	hipFree(h_graph_edges);
	hipFree(h_graph_mask);
	hipFree(h_updating_graph_mask);
	hipFree(h_graph_visited);
	hipFree(h_cost);
#ifdef  TIMING
    gettimeofday(&tv_close_start, NULL);
#endif
	hipFree(d_over);

#ifdef  TIMING
	gettimeofday(&tv_close_end, NULL);
	tvsub(&tv_close_end, &tv_close_start, &tv);
	close_time = tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;
	tvsub(&tv_close_end, &tv_total_start, &tv);
	total_time = tv.tv_sec * 1000.0 + (float) tv.tv_usec / 1000.0;

	printf("Init: %f\n", init_time);
	printf("MemAlloc: %f\n", mem_alloc_time);
	printf("HtoD: %f\n", h2d_time);
	printf("Exec: %f\n", kernel_time);
	printf("DtoH: %f\n", d2h_time);
	printf("Close: %f\n", close_time);
	printf("Total: %f\n", total_time);
#endif
}
