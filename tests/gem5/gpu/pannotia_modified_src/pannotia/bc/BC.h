/************************************************************************************\ 
 *                                                                                  *
 * Copyright � 2014 Advanced Micro Devices, Inc.                                    *
 * Copyright (c) 2015 Mark D. Hill and David A. Wood                                *
 * Copyright (c) 2021 Gaurav Jain and Matthew D. Sinclair                           *
 * All rights reserved.                                                             *
 *                                                                                  *
 * Redistribution and use in source and binary forms, with or without               *
 * modification, are permitted provided that the following are met:                 *
 *                                                                                  *
 * You must reproduce the above copyright notice.                                   *
 *                                                                                  *
 * Neither the name of the copyright holder nor the names of its contributors       *
 * may be used to endorse or promote products derived from this software            *
 * without specific, prior, written permission from at least the copyright holder.  *
 *                                                                                  *
 * You must include the following terms in your license and/or other materials      *
 * provided with the software.                                                      *
 *                                                                                  *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"      *
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE        *
 * IMPLIED WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT, AND FITNESS FOR A       *
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER        *
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,         *
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT  *
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS      *
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN          *
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING  *
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY   *
 * OF SUCH DAMAGE.                                                                  *
 *                                                                                  *
 * Without limiting the foregoing, the software may implement third party           *
 * technologies for which you must obtain licenses from parties other than AMD.     *
 * You agree that AMD has not obtained or conveyed to you, and that you shall       *
 * be responsible for obtaining the rights to use and/or distribute the applicable  *
 * underlying intellectual property rights related to the third party technologies. *
 * These third party technologies are not licensed hereunder.                       *
 *                                                                                  *
 * If you use the software (in whole or in part), you shall adhere to all           *
 * applicable U.S., European, and other export laws, including but not limited to   *
 * the U.S. Export Administration Regulations ("EAR") (15 C.F.R Sections 730-774),  *
 * and E.U. Council Regulation (EC) No 428/2009 of 5 May 2009.  Further, pursuant   *
 * to Section 740.6 of the EAR, you hereby certify that, except pursuant to a       *
 * license granted by the United States Department of Commerce Bureau of Industry   *
 * and Security or as otherwise permitted pursuant to a License Exception under     *
 * the U.S. Export Administration Regulations ("EAR"), you will not (1) export,     *
 * re-export or release to a national of a country in Country Groups D:1, E:1 or    *
 * E:2 any restricted technology, software, or source code you receive hereunder,   *
 * or (2) export to Country Groups D:1, E:1 or E:2 the direct product of such       *
 * technology or software, if such foreign produced direct product is subject to    *
 * national security controls as identified on the Commerce Control List (currently *
 * found in Supplement 1 to Part 774 of EAR).  For the most current Country Group   *
 * listings, or for additional information about the EAR or your obligations under  *
 * those regulations, please refer to the U.S. Bureau of Industry and Security's    *
 * website at http://www.bis.doc.gov/.                                              *
 *                                                                                  *
\************************************************************************************/

#include "hip/hip_runtime.h"
#include <stdio.h>
#include <stdlib.h>

static void checkedHipMallocManagedInt(int **ptr, size_t count,
                                       const char *name)
{
    hipError_t err = hipMallocManaged((void **)ptr, count * sizeof(int));
    if (err != hipSuccess) {
        fprintf(stderr, "ERROR: hipMallocManaged %s %s\n", name,
                hipGetErrorString(err));
        exit(1);
    }
}

typedef struct csr_array_t {

    int *row_array;
    int *col_array;
    int *data_array;

    int *row_array_t;
    int *col_array_t;
    int *data_array_t;

} csr_array;

static csr_array *allocateCSR(int num_nodes, int num_edges, const char *name)
{
    csr_array *csr = (csr_array *)calloc(1, sizeof(csr_array));
    if (!csr) {
        fprintf(stderr, "ERROR: malloc csr %s\n", name);
        exit(1);
    }

    char buffer[128];
    snprintf(buffer, sizeof(buffer), "%s.row_array", name);
    checkedHipMallocManagedInt(&csr->row_array, num_nodes + 1, buffer);
    snprintf(buffer, sizeof(buffer), "%s.col_array", name);
    checkedHipMallocManagedInt(&csr->col_array, num_edges, buffer);
    snprintf(buffer, sizeof(buffer), "%s.data_array", name);
    checkedHipMallocManagedInt(&csr->data_array, num_edges, buffer);

    snprintf(buffer, sizeof(buffer), "%s.row_array_t", name);
    checkedHipMallocManagedInt(&csr->row_array_t, num_nodes + 1, buffer);
    snprintf(buffer, sizeof(buffer), "%s.col_array_t", name);
    checkedHipMallocManagedInt(&csr->col_array_t, num_edges, buffer);
    snprintf(buffer, sizeof(buffer), "%s.data_array_t", name);
    checkedHipMallocManagedInt(&csr->data_array_t, num_edges, buffer);

    return csr;
}

static void checkedHipMemcpyInt(int *dst, const int *src, size_t count,
                                const char *name)
{
    hipError_t err =
        hipMemcpy(dst, src, count * sizeof(int), hipMemcpyDefault);
    if (err != hipSuccess) {
        fprintf(stderr, "ERROR: hipMemcpy %s %s\n", name,
                hipGetErrorString(err));
        exit(1);
    }
}

static void copyCSR(csr_array *dst, const csr_array *src, int num_nodes,
                    int num_edges)
{
    checkedHipMemcpyInt(dst->row_array, src->row_array, num_nodes + 1,
                        "row_array");
    checkedHipMemcpyInt(dst->col_array, src->col_array, num_edges,
                        "col_array");
    checkedHipMemcpyInt(dst->data_array, src->data_array, num_edges,
                        "data_array");
    checkedHipMemcpyInt(dst->row_array_t, src->row_array_t, num_nodes + 1,
                        "row_array_t");
    checkedHipMemcpyInt(dst->col_array_t, src->col_array_t, num_edges,
                        "col_array_t");
    checkedHipMemcpyInt(dst->data_array_t, src->data_array_t, num_edges,
                        "data_array_t");

    hipError_t err = hipDeviceSynchronize();
    if (err != hipSuccess) {
        fprintf(stderr, "ERROR: hipDeviceSynchronize copyCSR %s\n",
                hipGetErrorString(err));
        exit(1);
    }
}

static void freeCSR(csr_array *csr)
{
    if (!csr) {
        return;
    }

    if (csr->row_array) {
        hipFree(csr->row_array);
    }
    if (csr->col_array) {
        hipFree(csr->col_array);
    }
    if (csr->data_array) {
        hipFree(csr->data_array);
    }
    if (csr->row_array_t) {
        hipFree(csr->row_array_t);
    }
    if (csr->col_array_t) {
        hipFree(csr->col_array_t);
    }
    if (csr->data_array_t) {
        hipFree(csr->data_array_t);
    }
    free(csr);
}


typedef struct cooedgetuple {
    int row;
    int col;
    int val;
} CooTuple;

bool compare(
    CooTuple elem1,
    CooTuple elem2)
{
    if (elem1.row < elem2.row)
        return true;
    return false;
}

void transform(CooTuple *tuple_array, int num_edges, int *row_array, int *col_array, int *data_array)
{

    int row_cnt = 0;
    int prev = -1;
    int idx;

    for (idx = 0; idx < num_edges; idx++) {
        int curr = tuple_array[idx].row;
        if (curr != prev) {
            row_array[row_cnt++] = idx;
            prev = curr;
        }

        col_array[idx]  = tuple_array[idx].col;
        data_array[idx] = tuple_array[idx].val;

    }
    row_array[row_cnt] = idx;
}

csr_array * parseCOO(char* tmpchar, int *p_num_nodes, int *p_num_edges, bool directed)
{
    int cnt = 0;
    int cnt1 = 0;
    unsigned int lineno = 0;
    char sp[2], a, p;
    char * line = (char *)malloc(8192 * sizeof(char));
    int num_nodes = 0, num_edges = 0;

    FILE *fptr;
    CooTuple *tuple_array   = NULL;
    CooTuple *tuple_array_t = NULL;

    fptr = fopen(tmpchar, "r");
    if (!fptr) {
        fprintf(stderr, "Error when opennning file: %s\n", tmpchar);
        perror("ERROR: ");
        exit(1);
    }

    printf("Opening file: %s\n", tmpchar);

    while (fgets(line, 8192, fptr)) {
        int head, tail, weight;
        switch (line[0]) {
        case 'c':
            break;
        case 'p':
            sscanf(line, "%c %s %d %d", &p, sp, p_num_nodes, p_num_edges);

            if (!directed) {
                *p_num_edges = *p_num_edges * 2;
                printf("This is an undirected graph\n");
            } else {
                printf("This is a directed graph\n");
            }

            num_nodes  =  *p_num_nodes;
            num_edges =   *p_num_edges;

            printf("Read from file: num_nodes = %d, num_edges = %d\n", num_nodes, num_edges);

            tuple_array       = (CooTuple *)malloc(sizeof(CooTuple) * num_edges);
            if (!tuple_array) printf("malloc failed\n");
            tuple_array_t     = (CooTuple *)malloc(sizeof(CooTuple) * num_edges);
            if (!tuple_array_t) printf("malloc failed\n");

            break;

        case 'a':
            sscanf(line, "%c %d %d %d", &a, &head, &tail, &weight);

            if (tail == head) printf("reporting self loop\n");

            CooTuple temp, temp1;

            temp.row = head - 1;
            temp.col = tail - 1;
            temp.val = weight;

            temp1.row = tail - 1;
            temp1.col = head - 1;
            temp1.val = weight;

            tuple_array[cnt++]   = temp;
            tuple_array_t[cnt1++] = temp1;

            if (!directed) {

                temp.row = tail - 1;
                temp.col = head - 1;
                temp.val = weight;

                temp1.row = head - 1;
                temp1.col = tail - 1;
                temp1.val = weight;

                tuple_array[cnt++]   = temp;
                tuple_array_t[cnt1++] = temp1;

            }

            break;
        default:
            fprintf(stderr, "exiting loop\n");
            break;
        }
        lineno++;
    }

    std::stable_sort(tuple_array,   tuple_array   + num_edges, compare);
    std::stable_sort(tuple_array_t, tuple_array_t + num_edges, compare);

    csr_array *csr = allocateCSR(num_nodes, num_edges, "cpu_csr");

    transform(tuple_array,   num_edges, csr->row_array,   csr->col_array,
              csr->data_array);
    transform(tuple_array_t, num_edges, csr->row_array_t, csr->col_array_t,
              csr->data_array_t);

    fclose(fptr);
    free(tuple_array);
    free(tuple_array_t);

    free(line);

    return csr;
}
