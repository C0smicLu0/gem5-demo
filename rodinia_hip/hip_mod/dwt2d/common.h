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

#ifndef _COMMON_H
#define _COMMON_H

#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

//24-bit multiplication is faster on G80,
//but we must be sure to multiply integers
//only within [-8M, 8M - 1] range
#define IMUL(a, b) __mul24(a, b)

////cuda timing macros
//#define CTIMERINIT  cudaEvent_t cstart, cstop; \
//                    cudaEventCreate(&cstart); \
//                    cudaEventCreate(&cstop); \
//                    float elapsedTime
//#define CTIMERSTART(cstart) cudaEventRecord(cstart,0)
//#define CTIMERSTOP(cstop) cudaEventRecord(cstop,0); \
//                          cudaEventSynchronize(cstop); \
//                          cudaEventElapsedTime(&elapsedTime, cstart, cstop)

//divide and round up macro
#define DIVANDRND(a, b) ((((a) % (b)) != 0) ? ((a) / (b) + 1) : ((a) / (b)))

#  define cudaCheckError( msg )
// #  define cudaCheckError( msg ) {                                            \
    // cudaError_t err = cudaGetLastError();                                    \
    // if( cudaSuccess != err) {                                                \
        // fprintf(stderr, "%s: %i: %s: %s.\n",                                 \
                // __FILE__, __LINE__, msg, cudaGetErrorString( err) );         \
        // exit(-1);                                                            \
    // } }
#  define cudaCheckAsyncError( msg )
// #  define cudaCheckAsyncError( msg ) {                                       \
    // cudaThreadSynchronize();                                                 \
    // cudaCheckError( msg );                                                   \
    // }

static inline void *checked_hip_malloc_managed(size_t size)
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


#endif
