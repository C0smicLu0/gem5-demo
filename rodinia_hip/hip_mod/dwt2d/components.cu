#include "hip/hip_runtime.h"
/* 
 * Copyright (c) 2009, Jiri Matela
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
 
#include <unistd.h>
#include <error.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <assert.h>
#include <string.h>
#include <sys/time.h>

#include "components.h"
#include "common.h"

#ifndef DWT2D_TRACE
#define DWT2D_TRACE 1
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

#define THREADS 256

/* Store 3 RGB float components */
__device__ void storeComponents(float *d_r, float *d_g, float *d_b, float r, float g, float b, int pos)
{
    d_r[pos] = (r/255.0f) - 0.5f;
    d_g[pos] = (g/255.0f) - 0.5f;
    d_b[pos] = (b/255.0f) - 0.5f;
}

/* Store 3 RGB intege components */
__device__ void storeComponents(int *d_r, int *d_g, int *d_b, int r, int g, int b, int pos)
{
    d_r[pos] = r - 128;
    d_g[pos] = g - 128;
    d_b[pos] = b - 128;
} 

/* Store float component */
__device__ void storeComponent(float *d_c, float c, int pos)
{
    d_c[pos] = (c/255.0f) - 0.5f;
}

/* Store integer component */
__device__ void storeComponent(int *d_c, int c, int pos)
{
    d_c[pos] = c - 128;
}

/* Copy img src data into three separated component buffers */
template<typename T>
__global__ void c_CopySrcToComponents(T *d_r, T *d_g, T *d_b, 
                                  unsigned char * d_src, 
                                  int pixels)
{
    int x  = threadIdx.x;
    int gX = blockDim.x*blockIdx.x;

    __shared__ unsigned char sData[THREADS*3];

    /* Copy data to shared mem by 4bytes 
       other checks are not necessary, since 
       d_src buffer is aligned to sharedDataSize */
    if ( (x*4) < THREADS*3 ) {
        float *s = (float *)d_src;
        float *d = (float *)sData;
        d[x] = s[((gX*3)>>2) + x];
    }
    __syncthreads();

    T r, g, b;

    int offset = x*3;
    r = (T)(sData[offset]);
    g = (T)(sData[offset+1]);
    b = (T)(sData[offset+2]);

    int globalOutputPosition = gX + x;
    if (globalOutputPosition < pixels) {
        storeComponents(d_r, d_g, d_b, r, g, b, globalOutputPosition);
    }
}

/* Copy img src data into three separated component buffers */
template<typename T>
__global__ void c_CopySrcToComponent(T *d_c, unsigned char * d_src, int pixels)
{
    int x  = threadIdx.x;
    int gX = blockDim.x*blockIdx.x;

    __shared__ unsigned char sData[THREADS];

    /* Copy data to shared mem by 4bytes 
       other checks are not necessary, since 
       d_src buffer is aligned to sharedDataSize */
    if ( (x*4) < THREADS) {
        float *s = (float *)d_src;
        float *d = (float *)sData;
        d[x] = s[(gX>>2) + x];
    }
    __syncthreads();

    T c;

    c = (T)(sData[x]);

    int globalOutputPosition = gX + x;
    if (globalOutputPosition < pixels) {
        storeComponent(d_c, c, globalOutputPosition);
    }
}


/* Separate compoents of 8bit RGB source image */
template<typename T>
void rgbToComponents(T *d_r, T *d_g, T *d_b, unsigned char * src, int width, int height)
{
    unsigned char * d_src;
    int pixels      = width*height;
    int alignedSize =  DIVANDRND(width*height, THREADS) * THREADS * 3; //aligned to thread block size -- THREADS
    DWT2D_LOG("rgbToComponents enter: width=%d height=%d pixels=%d alignedSize=%d src=%p d_r=%p d_g=%p d_b=%p",
              width, height, pixels, alignedSize, (void *)src,
              (void *)d_r, (void *)d_g, (void *)d_b);

	/* Alloc d_src buffer */
	// 原来：d_src 在 device，src 在 host，需要 hipMemcpy(H2D)
	// 现在：d_src 用 managed 分配，memcpy 是 CPU 侧初始化拷贝
	d_src = (unsigned char *)checked_hip_malloc_managed(alignedSize);
    DWT2D_LOG("rgbToComponents alloc d_src end: ptr=%p", (void *)d_src);
	memset(d_src, 0, alignedSize);
    DWT2D_LOG("rgbToComponents memset d_src end");
	memcpy(d_src, src, pixels*3);
    DWT2D_LOG("rgbToComponents memcpy source end");

    /* Kernel */
    dim3 threads(THREADS);
    dim3 grid(alignedSize/(THREADS*3));
    assert(alignedSize%(THREADS*3) == 0);
    DWT2D_LOG("rgbToComponents kernel launch: grid=%u threads=%u",
              grid.x, threads.x);
    c_CopySrcToComponents<<<grid, threads>>>(d_r, d_g, d_b, d_src, pixels);
    cudaCheckAsyncError("CopySrcToComponents kernel")
    DWT2D_LOG("rgbToComponents kernel launch returned");

	/* Free Memory */
	hipFree(d_src);
	cudaCheckAsyncError("Free memory")
    DWT2D_LOG("rgbToComponents exit");
}
template void rgbToComponents<float>(float *d_r, float *d_g, float *d_b, unsigned char * src, int width, int height);
template void rgbToComponents<int>(int *d_r, int *d_g, int *d_b, unsigned char * src, int width, int height);


/* Copy a 8bit source image data into a color compoment of type T */
template<typename T>
void bwToComponent(T *d_c, unsigned char * src, int width, int height)
{
    unsigned char * d_src;
    int pixels      = width*height;
    int alignedSize =  DIVANDRND(pixels, THREADS) * THREADS; //aligned to thread block size -- THREADS
    DWT2D_LOG("bwToComponent enter: width=%d height=%d pixels=%d alignedSize=%d src=%p d_c=%p",
              width, height, pixels, alignedSize, (void *)src, (void *)d_c);

	/* Alloc d_src buffer */
	// 原来：d_src 在 device，src 在 host，需要 hipMemcpy(H2D)
	// 现在：d_src 用 managed 分配，memcpy 是 CPU 侧初始化拷贝
	d_src = (unsigned char *)checked_hip_malloc_managed(alignedSize);
    DWT2D_LOG("bwToComponent alloc d_src end: ptr=%p", (void *)d_src);
	memset(d_src, 0, alignedSize);
    DWT2D_LOG("bwToComponent memset d_src end");
	memcpy(d_src, src, pixels);
    DWT2D_LOG("bwToComponent memcpy source end");

    /* Kernel */
    dim3 threads(THREADS);
    dim3 grid(alignedSize/(THREADS));
    assert(alignedSize%(THREADS) == 0);
    DWT2D_LOG("bwToComponent kernel launch: grid=%u threads=%u",
              grid.x, threads.x);
    c_CopySrcToComponent<<<grid, threads>>>(d_c, d_src, pixels);
    cudaCheckAsyncError("CopySrcToComponent kernel")
    DWT2D_LOG("bwToComponent kernel launch returned");

    /* Free Memory */
    hipFree(d_src);
    cudaCheckAsyncError("Free memory")
    DWT2D_LOG("bwToComponent exit");
}

template void bwToComponent<float>(float *d_c, unsigned char *src, int width, int height);
template void bwToComponent<int>(int *d_c, unsigned char *src, int width, int height);
