/***********************************************************************
 	graphgpu
	Authors: Koichi Shirahata, Hitoshi Sato, Toyotaro Suzumura, and Satoshi Matsuoka

This software is licensed under Apache License, Version 2.0 (the  "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
***********************************************************************/

#ifndef __REDUCE1_CU__
#define __REDUCE1_CU__

#include "MarsInc.h"
#include "global.h"

//#define __NO_REDUCE__
// #define _DEBUG_REDUCE
// #define _OUTPUT_REDUCE

__device__ void REDUCE_COUNT_FUNC1//(void* key, void* vals, size_t keySize, size_t valCount)
{
  for(int i = 0; i < valCount; i++) {
    EMIT_COUNT_FUNC(sizeof(int), sizeof(PR_VAL_T));
  }
}

__device__ void REDUCE_FUNC1//(void* key, void* vals, size_t keySize, size_t valCount)
{
  int i;
  float cur_rank = 0;
  
  int *dst_nodes_list = NULL;
  size_t valSize = valCount * sizeof(int); 
  if(valSize > cudaLimitMallocHeapSize) {
    //printf("Too large valSize on reduce of PageRank1\n");
    //return;
  }

  dst_nodes_list = (int*)malloc(valSize);
  //int dst_nodes_list[4096];
  int dst_nodes_list_size = 0;
  
  for(i = 0; i < valCount; i++) {
    PR_VAL_T* iVal = (PR_VAL_T*)GET_VAL_FUNC(vals, i);
    if(iVal->is_v == true) { // vector : VALUE
      cur_rank = iVal->dst;
    }
    else {  // edge ROWID
      dst_nodes_list[dst_nodes_list_size] = (int)iVal->dst;
      dst_nodes_list_size++;
    }
  }
  
  // add random coeff
  PR_VAL_T* o_val = (PR_VAL_T*)GET_OUTPUT_BUF(0);
  o_val->is_v = false;
  o_val->dst = cur_rank;

#ifdef _OUTPUT_REDUCE
  printf("%d, %f\n", *(PR_KEY_T*)key, o_val->dst);
#endif
  EMIT_FUNC(key, o_val, sizeof(PR_KEY_T), sizeof(PR_VAL_T));

  int outdeg = dst_nodes_list_size;
  if(outdeg > 0) {
    cur_rank = cur_rank / (float)outdeg;
  }

#ifdef _DEBUG_REDUCE
  printf("outdeg = %d, valCount = %d\n", outdeg, valCount);
#endif

  for(i = 0; i < outdeg; i++) {
    PR_VAL_T* o_val = (PR_VAL_T*)GET_OUTPUT_BUF(0);
    o_val->is_v = true;
    o_val->dst = cur_rank;	  
#ifdef _OUTPUT_REDUCE
    printf("%d, %f\n", dst_nodes_list[i], o_val->dst);
#endif
    EMIT_FUNC(&dst_nodes_list[i], o_val, sizeof(PR_KEY_T), sizeof(PR_VAL_T));
  }

  free(dst_nodes_list);

}

#endif //__REDUCE1_CU__
