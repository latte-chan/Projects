
/**********************************************************************

   File          : cmpsc473-mm.c

   Description   : Slab allocation and defenses

***********************************************************************/
/**********************************************************************
Copyright (c) 2019 The Pennsylvania State University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of The Pennsylvania State University nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
***********************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <assert.h>
#include <unistd.h>
#include <time.h> 
#include "cmpsc473-format-80.h"   // TASK 1: student-specific
#include "cmpsc473-mm.h"

/* Globals */
heap_t *mmheap;
unsigned int canary;

/* Defines */
#define FREE_ADDR( slab ) ( (unsigned long)slab->start + ( slab->obj_size * slab->bitmap->free ))


/**********************************************************************

    Function    : mm_init
    Description : Initialize slab allocation
    Inputs      : void
    Outputs     : 0 if success, -1 on error

***********************************************************************/

int mm_init( void )
{
	mmheap = (heap_t *)malloc( sizeof(heap_t) );
	if ( !mmheap ) return -1;

	// TASK 2: Initialize heap memory (using regular 'malloc') and 
	//   heap data structures in prep for malloc/free
	unsigned int pageCount = HEAP_SIZE / PAGE_SIZE;
	//mmheap->start = aligned_alloc(PAGE_SIZE, PAGE_SIZE * 20);
	mmheap->start = malloc(HEAP_SIZE);
	mmheap->start = (void *)(((unsigned long int)mmheap->start & PAGE_MASK) + PAGE_SIZE);
	mmheap->size = HEAP_SIZE;
	//printf("heap->start: %x\n",mmheap->start);

	
	mmheap->bitmap = (bitmap_t *)malloc(sizeof(bitmap_t));
	mmheap->bitmap->map = (word_t *)calloc(pageCount / 8, sizeof(word_t));
	mmheap->bitmap->free = 0;
	mmheap->bitmap->size = pageCount * sizeof(word_t);

	unsigned int aSize = sizeof(struct A);
	unsigned int bSize = sizeof(struct B);
	unsigned int cSize = sizeof(struct C);

	mmheap->slabA = (slab_cache_t *)malloc(sizeof(slab_cache_t));
	mmheap->slabA->current = (slab_t *)NULL;
	mmheap->slabA->ct = 0;
	mmheap->slabA->obj_size = aSize;

	mmheap->slabB = (slab_cache_t *)malloc(sizeof(slab_cache_t));
	mmheap->slabB->current = (slab_t *)NULL;
	mmheap->slabB->ct = 0;
	mmheap->slabB->obj_size = bSize;

	mmheap->slabC = (slab_cache_t *)malloc(sizeof(slab_cache_t));
	mmheap->slabC->current = (slab_t *)NULL;
	mmheap->slabC->ct = 0;
	mmheap->slabC->obj_size = cSize;
	// initialize canary
	canary_init();

	return 0;
}


/**********************************************************************

    Function    : my_malloc
    Description : Allocate from slabs
    Inputs      : size: amount of memory to allocate
    Outputs     : address if success, NULL on error

***********************************************************************/

void *my_malloc( unsigned int size )
{
	void *addr = (void *) NULL;

	// TASK 2: implement malloc function for slab allocator
	unsigned int aCount = mmheap->slabA->ct;
	unsigned int bCount = mmheap->slabB->ct;
	unsigned int cCount = mmheap->slabC->ct;

	unsigned int aSize = mmheap->slabA->obj_size;
	unsigned int bSize = mmheap->slabB->obj_size;
	unsigned int cSize = mmheap->slabC->obj_size;

	if(size == aSize) {
		slab_cache_t *slab = mmheap->slabA;
		unsigned int objSize = slab->obj_size;
		unsigned int objPadSize = sizeof(allocA_t);
		unsigned int remainder = objPadSize % SLAB_ALLOC_ALIGN;
		unsigned int objAlignSize = remainder ? objPadSize + (SLAB_ALLOC_ALIGN - remainder) : objPadSize;
		unsigned int objNum = (PAGE_SIZE - sizeof(slab_t)) / objAlignSize;
		void *slabStart = (void *)(mmheap->start + (mmheap->bitmap->free * PAGE_SIZE));
		if(aCount == 0) {
			unsigned int i;
			set_bit(mmheap->bitmap->map, mmheap->bitmap->free);
			for(i = 0; i < mmheap->bitmap->size; i++) {
				if(get_bit(mmheap->bitmap->map, i) == 0) {
					mmheap->bitmap->free = i;
					break;
				}
			}
			slab->current = (slab_t *)(slabStart + (objNum * objAlignSize));
			slab->current->state = SLAB_PARTIAL;
			slab->current->start = slabStart;
			slab->current->next = slab->current;
			slab->current->prev = slab->current;
			slab->current->bitmap = (bitmap_t *)malloc(sizeof(bitmap_t));
			slab->current->bitmap->map = (word_t *)calloc(objNum, sizeof(word_t));
			slab->current->bitmap->free = 1;
			slab->current->bitmap->size = objNum * sizeof(word_t);
			set_bit(slab->current->bitmap->map, 0);
			slab->current->ct = 1;
			slab->current->num_objs = objNum;
			slab->current->obj_size = objAlignSize;
			slab->current->real_size = objSize;
			slab->ct = 1;
			addr = (allocA_t *)(slabStart);
			((allocA_t *)addr)->canary = canary;
			((allocA_t *)addr)->ct = slab->current->ct;
		}
		else if(slab->current->state == SLAB_FULL) {
			slab_t* cSlab = slab->current->next;
			while(cSlab != slab->current) {
				if(cSlab->state == SLAB_PARTIAL) {
					slab->current = cSlab;
					unsigned int i;
					unsigned int freeIndex = slab->current->bitmap->free;
					slab->current->ct += 1;
					addr = (allocA_t *)(slab->current->start + (freeIndex * objAlignSize));
					((allocA_t *)addr)->canary = canary;
					((allocA_t *)addr)->ct = slab->current->ct;
					set_bit(slab->current->bitmap->map, freeIndex);
					for(i = 0; i < slab->current->bitmap->size; i++) {
						if(get_bit(slab->current->bitmap->map, i) == 0) {
							slab->current->bitmap->free = i;
							break;
						}
					}
					slab->current->state = SLAB_FULL;
					for(i = 0; i < slab->current->bitmap->size; i++) {
						if(get_bit(slab->current->bitmap->map, i) != 1) {
							slab->current->state = SLAB_PARTIAL;
							break;
						}
					}
					return addr;
				}
				cSlab = cSlab->next;
			}
			unsigned int i;
			set_bit(mmheap->bitmap->map, mmheap->bitmap->free);
			for(i = 0; i < mmheap->bitmap->size; i++) {
				if(get_bit(mmheap->bitmap->map, i) == 0) {
					mmheap->bitmap->free = i;
					break;
				}
			}
			slab_t *temp = slab->current;
			slab->current = (slab_t *)(slabStart + (objNum * objAlignSize));
			slab->current->state = SLAB_PARTIAL;
			slab->current->start = slabStart;
			slab->current->next = temp->next;
			slab->current->prev = temp;
			temp->next->prev = slab->current;
			temp->next = slab->current;
			slab->current->bitmap = (bitmap_t *)malloc(sizeof(bitmap_t));
			slab->current->bitmap->map = (word_t *)calloc(objNum, sizeof(word_t));
			slab->current->bitmap->free = 1;
			slab->current->bitmap->size = objNum * sizeof(word_t);
			set_bit(slab->current->bitmap->map, 0);
			slab->current->ct = 1;
			slab->current->num_objs = objNum;
			slab->current->obj_size = objAlignSize;
			slab->current->real_size = objSize;
			slab->ct += 1;
			addr = (allocA_t *)(slabStart);
			((allocA_t *)addr)->canary = canary;
			((allocA_t *)addr)->ct = slab->current->ct;
		}
		else {
			unsigned int i;
			unsigned int freeIndex = slab->current->bitmap->free;
			slab->current->state = SLAB_FULL;
			slab->current->ct += 1;
			addr = (allocA_t *)(slab->current->start + (freeIndex * objAlignSize));
			((allocA_t *)addr)->canary = canary;
			((allocA_t *)addr)->ct = slab->current->ct;
			set_bit(slab->current->bitmap->map, freeIndex);
			for(i = 0; i < slab->current->bitmap->size; i++) {
				if(get_bit(slab->current->bitmap->map, i) == 0) {
					slab->current->bitmap->free = i;
					break;
				}
			}
			slab->current->state = SLAB_FULL;
			for(i = 0; i < slab->current->bitmap->size; i++) {
				if(get_bit(slab->current->bitmap->map, i) != 1) {
					slab->current->state = SLAB_PARTIAL;
					break;
				}
			}
		}
	}
	else if(size == bSize) {
		slab_cache_t *slab = mmheap->slabB;
		unsigned int objSize = slab->obj_size;
		unsigned int objPadSize = sizeof(allocB_t);
		unsigned int remainder = objPadSize % SLAB_ALLOC_ALIGN;
		unsigned int objAlignSize = remainder ? objPadSize + (SLAB_ALLOC_ALIGN - remainder) : objPadSize;
		unsigned int objNum = (PAGE_SIZE - sizeof(slab_t)) / objAlignSize;
		void *slabStart = (void *)(mmheap->start + (mmheap->bitmap->free * PAGE_SIZE));
		if(bCount == 0) {
			unsigned int i;
			set_bit(mmheap->bitmap->map, mmheap->bitmap->free);
			for(i = 0; i < mmheap->bitmap->size; i++) {
				if(get_bit(mmheap->bitmap->map, i) == 0) {
					mmheap->bitmap->free = i;
					break;
				}
			}
			slab->current = (slab_t *)(slabStart + (objNum * objAlignSize));
			slab->current->state = SLAB_PARTIAL;
			slab->current->start = slabStart;
			slab->current->next = slab->current;
			slab->current->prev = slab->current;
			slab->current->bitmap = (bitmap_t *)malloc(sizeof(bitmap_t));
			slab->current->bitmap->map = (word_t *)calloc(objNum, sizeof(word_t));
			slab->current->bitmap->free = 1;
			slab->current->bitmap->size = objNum * sizeof(word_t);
			set_bit(slab->current->bitmap->map, 0);
			slab->current->ct = 1;
			slab->current->num_objs = objNum;
			slab->current->obj_size = objAlignSize;
			slab->current->real_size = objSize;
			slab->ct = 1;
			addr = (allocB_t *)(slabStart);
			((allocB_t *)addr)->canary = canary;
			((allocB_t *)addr)->ct = slab->current->ct;
		}
		else if(slab->current->state == SLAB_FULL) {
			slab_t* cSlab = slab->current->next;
			while(cSlab != slab->current) {
				if(cSlab->state == SLAB_PARTIAL) {
					slab->current = cSlab;
					unsigned int i;
					unsigned int freeIndex = slab->current->bitmap->free;
					slab->current->ct += 1;
					addr = (allocB_t *)(slab->current->start + (freeIndex * objAlignSize));
					((allocB_t *)addr)->canary = canary;
					((allocB_t *)addr)->ct = slab->current->ct;
					set_bit(slab->current->bitmap->map, freeIndex);
					for(i = 0; i < slab->current->bitmap->size; i++) {
						if(get_bit(slab->current->bitmap->map, i) == 0) {
							slab->current->bitmap->free = i;
							break;
						}
					}
					slab->current->state = SLAB_FULL;
					for(i = 0; i < slab->current->bitmap->size; i++) {
						if(get_bit(slab->current->bitmap->map, i) != 1) {
							slab->current->state = SLAB_PARTIAL;
							break;
						}
					}
					return addr;
				}
				cSlab = cSlab->next;
			}
			unsigned int i;
			set_bit(mmheap->bitmap->map, mmheap->bitmap->free);
			for(i = 0; i < mmheap->bitmap->size; i++) {
				if(get_bit(mmheap->bitmap->map, i) == 0) {
					mmheap->bitmap->free = i;
					break;
				}
			}
			slab_t *temp = slab->current;
			slab->current = (slab_t *)(slabStart + (objNum * objAlignSize));
			slab->current->state = SLAB_PARTIAL;
			slab->current->start = slabStart;
			slab->current->next = temp->next;
			slab->current->prev = temp;
			temp->next->prev = slab->current;
			temp->next = slab->current;
			slab->current->bitmap = (bitmap_t *)malloc(sizeof(bitmap_t));
			slab->current->bitmap->map = (word_t *)calloc(objNum, sizeof(word_t));
			slab->current->bitmap->free = 1;
			slab->current->bitmap->size = objNum * sizeof(word_t);
			set_bit(slab->current->bitmap->map, 0);
			slab->current->ct = 1;
			slab->current->num_objs = objNum;
			slab->current->obj_size = objAlignSize;
			slab->current->real_size = objSize;
			slab->ct += 1;
			addr = (allocB_t *)(slabStart);
			((allocB_t *)addr)->canary = canary;
			((allocB_t *)addr)->ct = slab->current->ct;
		}
		else {
			unsigned int i;
			unsigned int freeIndex = slab->current->bitmap->free;
			slab->current->ct += 1;
			addr = (allocB_t *)(slab->current->start + (freeIndex * objAlignSize));
			((allocB_t *)addr)->canary = canary;
			((allocB_t *)addr)->ct = slab->current->ct;
			set_bit(slab->current->bitmap->map, freeIndex);
			for(i = 0; i < slab->current->bitmap->size; i++) {
				if(get_bit(slab->current->bitmap->map, i) == 0) {
					slab->current->bitmap->free = i;
					break;
				}
			}
			slab->current->state = SLAB_FULL;
			for(i = 0; i < slab->current->bitmap->size; i++) {
				if(get_bit(slab->current->bitmap->map, i) != 1) {
					slab->current->state = SLAB_PARTIAL;
					break;
				}
			}
		}
	}
	else if(size == cSize) {
		slab_cache_t *slab = mmheap->slabC;
		unsigned int objSize = slab->obj_size;
		unsigned int objPadSize = sizeof(allocC_t);
		unsigned int remainder = objPadSize % SLAB_ALLOC_ALIGN;
		unsigned int objAlignSize = remainder ? objPadSize + (SLAB_ALLOC_ALIGN - remainder) : objPadSize;
		unsigned int objNum = (PAGE_SIZE - sizeof(slab_t)) / objAlignSize;
		void *slabStart = (void *)(mmheap->start + (mmheap->bitmap->free * PAGE_SIZE));
		if(cCount == 0) {
			unsigned int i;
			set_bit(mmheap->bitmap->map, mmheap->bitmap->free);
			for(i = 0; i < mmheap->bitmap->size; i++) {
				if(get_bit(mmheap->bitmap->map, i) == 0) {
					mmheap->bitmap->free = i;
					break;
				}
			}
			slab->current = (slab_t *)(slabStart + (objNum * objAlignSize));
			slab->current->state = SLAB_PARTIAL;
			slab->current->start = slabStart;
			slab->current->next = slab->current;
			slab->current->prev = slab->current;
			slab->current->bitmap = (bitmap_t *)malloc(sizeof(bitmap_t));
			slab->current->bitmap->map = (word_t *)calloc(objNum, sizeof(word_t));
			slab->current->bitmap->free = 1;
			slab->current->bitmap->size = objNum * sizeof(word_t);
			set_bit(slab->current->bitmap->map, 0);
			slab->current->ct = 1;
			slab->current->num_objs = objNum;
			slab->current->obj_size = objAlignSize;
			slab->current->real_size = objSize;
			slab->ct = 1;
			addr = (allocC_t *)(slabStart);
			((allocC_t *)addr)->canary = canary;
			((allocC_t *)addr)->ct = slab->current->ct;
		}
		else if(slab->current->state == SLAB_FULL) {
			slab_t* cSlab = slab->current->next;
			while(cSlab != slab->current) {
				if(cSlab->state == SLAB_PARTIAL) {
					slab->current = cSlab;
					unsigned int i;
					unsigned int freeIndex = slab->current->bitmap->free;
					slab->current->ct += 1;
					addr = (allocC_t *)(slab->current->start + (freeIndex * objAlignSize));
					((allocC_t *)addr)->canary = canary;
					((allocC_t *)addr)->ct = slab->current->ct;
					set_bit(slab->current->bitmap->map, freeIndex);
					for(i = 0; i < slab->current->bitmap->size; i++) {
						if(get_bit(slab->current->bitmap->map, i) == 0) {
							slab->current->bitmap->free = i;
							break;
						}
					}
					slab->current->state = SLAB_FULL;
					for(i = 0; i < slab->current->bitmap->size; i++) {
						if(get_bit(slab->current->bitmap->map, i) != 1) {
							slab->current->state = SLAB_PARTIAL;
							break;
						}
					}
					return addr;
				}
				cSlab = cSlab->next;
			}
			unsigned int i;
			set_bit(mmheap->bitmap->map, mmheap->bitmap->free);
			for(i = 0; i < mmheap->bitmap->size; i++) {
				if(get_bit(mmheap->bitmap->map, i) == 0) {
					mmheap->bitmap->free = i;
					break;
				}
			}
			slab_t *temp = slab->current;
			slab->current = (slab_t *)(slabStart + (objNum * objAlignSize));
			slab->current->state = SLAB_PARTIAL;
			slab->current->start = slabStart;
			slab->current->next = temp->next;
			slab->current->prev = temp;
			temp->next->prev = slab->current;
			temp->next = slab->current;
			slab->current->bitmap = (bitmap_t *)malloc(sizeof(bitmap_t));
			slab->current->bitmap->map = (word_t *)calloc(objNum, sizeof(word_t));
			slab->current->bitmap->free = 1;
			slab->current->bitmap->size = objNum * sizeof(word_t);
			set_bit(slab->current->bitmap->map, 0);
			slab->current->ct = 1;
			slab->current->num_objs = objNum;
			slab->current->obj_size = objAlignSize;
			slab->current->real_size = objSize;
			slab->ct += 1;
			addr = (allocC_t *)(slabStart);
			((allocC_t *)addr)->canary = canary;
			((allocC_t *)addr)->ct = slab->current->ct;
		}
		else {
			unsigned int i;
			unsigned int freeIndex = slab->current->bitmap->free;
			slab->current->ct += 1;
			addr = (allocC_t *)(slab->current->start + (freeIndex * objAlignSize));
			((allocC_t *)addr)->canary = canary;
			((allocC_t *)addr)->ct = slab->current->ct;
			set_bit(slab->current->bitmap->map, freeIndex);
			for(i = 0; i < slab->current->bitmap->size; i++) {
				if(get_bit(slab->current->bitmap->map, i) == 0) {
					slab->current->bitmap->free = i;
					break;
				}
			}
			slab->current->state = SLAB_FULL;
			for(i = 0; i < slab->current->bitmap->size; i++) {
				if(get_bit(slab->current->bitmap->map, i) != 1) {
					slab->current->state = SLAB_PARTIAL;
					break;
				}
			}
		}
	}
	return addr;	
}



/**********************************************************************

    Function    : my_free
    Description : deallocate from slabs
    Inputs      : buf: full pointer (with counter) to deallocate
    Outputs     : address if success, NULL on error

***********************************************************************/

void my_free( void *buf )
{
	//printf("buf: %x\n", buf);
	void *objPtr = NULL;
	if(buf == 0) {
		return;
	}
	void *slabBuf = (void *)((long unsigned int)buf & PAGE_MASK);
	slab_t *currSlab = mmheap->slabA->current;
	slab_cache_t *currCache = mmheap->slabA;
	if(currSlab == NULL) {
		return;
	}
	unsigned int count = 0;
	if(currSlab != NULL) {
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabA->ct) {
				currSlab = NULL;
				break;
			}
		}
	}
	objPtr = USE_A(buf);
	if(currSlab == NULL) {
		currSlab = mmheap->slabB->current;
		currCache = mmheap->slabB;
		count = 0;
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabB->ct) {
				currSlab = NULL;
				break;
			}
		}
		objPtr = USE_B(buf);
	}
	if(currSlab == NULL) {
		currSlab = mmheap->slabC->current;
		currCache = mmheap->slabC;
		count = 0;
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabC->ct) {
				currSlab = NULL;
				break;
			}
		}
		objPtr = USE_C(buf);
	}
	if(currSlab == NULL) {
		return;
	}
	unsigned int index = (((void *)objPtr - currSlab->start) / currSlab->obj_size);
	if(get_bit(currSlab->bitmap->map, index) == 0) {
		return;
	}
	clear_bit(currSlab->bitmap->map, index);
	currSlab->ct -= 1;
	unsigned int i;
	for(i = 0; i < currSlab->bitmap->size; i++) {
		if(get_bit(currSlab->bitmap->map, i) == 0) {
			currSlab->bitmap->free = i;
			break;
		}
	}
	currSlab->state = SLAB_EMPTY;
	if(currSlab->ct > 0) {
		currSlab->state = SLAB_PARTIAL;
	}
	unsigned int heapIndex = (slabBuf - mmheap->start) / PAGE_SIZE;
	if(currSlab->state == SLAB_EMPTY) {
		if(currSlab == currSlab->next) {
			return;
		}
		currSlab->prev->next = currSlab->next;
		currSlab->next->prev = currSlab->prev;
		currSlab->state = SLAB_UNASSIGNED;
		currCache->current = currSlab->prev;
		currCache->ct -= 1;
		clear_bit(mmheap->bitmap->map, heapIndex);
		for(i = 0; i < mmheap->bitmap->size; i++) {
			if(get_bit(mmheap->bitmap->map, i) == 0) {
				mmheap->bitmap->free = i;
				break;
			}
		}
	}
	//printf("bitmap->size after free: %d\n", currSlab->bitmap->size);
	return;
}


/**********************************************************************

    Function    : canary_init
    Description : Generate random number for canary - fresh each time 
    Inputs      : 
    Outputs     : void

***********************************************************************/

void canary_init( void )
{ 
	// This program will create different sequence of  
	// random numbers on every program run  
	srand(time(0)); 
 
	canary = rand();   // fix this 
	printf("canary is %d\n", canary );
} 


/**********************************************************************

    Function    : check_canary
    Description : Find canary for obj and check against program canary
    Inputs      : addr: address of object
                  size: size of object to find cache
    Outputs     : 0 for success, -1 for failure

***********************************************************************/

int check_canary( void *addr)
{
	// TASK 3: Implement canary defense
	unsigned int type = 0;
	void *slabBuf = (void *)((long unsigned int)addr & PAGE_MASK);
	slab_t *currSlab = mmheap->slabA->current;
	unsigned int count = 0;
	if(currSlab != NULL) {
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabA->ct) {
				currSlab = NULL;
				break;
			}
		}
		type = 1;
	}
	if(currSlab == NULL) {
		currSlab = mmheap->slabB->current;
		count = 0;
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabB->ct) {
				currSlab = NULL;
				break;
			}
		}
		type = 2;
	}
	if(currSlab == NULL) {
		currSlab = mmheap->slabC->current;
		count = 0;
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabC->ct) {
				currSlab = NULL;
				break;
			}
		}
		type = 3;
	}
	if(currSlab == NULL) {
		return -1;
	}
	unsigned int index = ((USE(addr) - currSlab->start) / currSlab->obj_size);
	if(get_bit(currSlab->bitmap->map, index) == 0) {
		return -1;
	}
	if(type == 1) {
		allocA_t *obj = USE(addr);
		if(obj->canary != canary) {
			return -1;
		}
	}
	else if(type == 2) {
		allocB_t *obj = USE(addr);
		if(obj->canary != canary) {
			return -1;
		}
	}
	else if(type == 3) {
		allocC_t *obj = USE(addr);
		if(obj->canary != canary) {
			return -1;
		}
	}
	else {
		return -1;
	}

	return 0;
}


/**********************************************************************

    Function    : check_type
    Description : Verify type requested complies with object 
    Inputs      : addr: address of object
                  type: type requested
    Outputs     : 0 on success, -1 on failure

***********************************************************************/

int check_type( void *addr, char type ) 
{
	// TASK 3: Implement type confusion defense
	unsigned int typeInt = 0;
	void *slabBuf = (void *)((long unsigned int)addr & PAGE_MASK);
	slab_t *currSlab = mmheap->slabA->current;
	unsigned int count = 0;
	if(currSlab != NULL) {
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabA->ct) {
				currSlab = NULL;
				break;
			}
		}
		typeInt = 1;
	}
	if(currSlab == NULL) {
		currSlab = mmheap->slabB->current;
		count = 0;
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabB->ct) {
				currSlab = NULL;
				break;
			}
		}
		typeInt = 2;
	}
	if(currSlab == NULL) {
		currSlab = mmheap->slabC->current;
		count = 0;
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabC->ct) {
				currSlab = NULL;
				break;
			}
		}
		typeInt = 3;
	}
	if(currSlab == NULL) {
		return -1;
	}
	unsigned int index = ((USE(addr) - currSlab->start) / currSlab->obj_size);
	if(get_bit(currSlab->bitmap->map, index) == 0) {
		return -1;
	}
	if(typeInt == 1 && type != 'A') {
		return -1;
	}
	else if(typeInt == 2 && type != 'B') {
		return -1;
	}
	else if(typeInt == 3 && type != 'C') {
		return -1;
	}

	return 0;
}


/**********************************************************************

    Function    : check_count
    Description : Verify that pointer count equals object count
    Inputs      : addr: address of pointer (must include metadata in pointer)
    Outputs     : 0 on success, or -1 on failure

***********************************************************************/

int check_count( void *addr ) 
{
	// TASK 3: Implement free count defense
	unsigned int type = 0;
	void *slabBuf = (void *)((long unsigned int)addr & PAGE_MASK);
	slab_t *currSlab = mmheap->slabA->current;
	unsigned int count = 0;
	if(currSlab != NULL) {
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabA->ct) {
				currSlab = NULL;
				break;
			}
		}
		type = 1;
	}
	if(currSlab == NULL) {
		currSlab = mmheap->slabB->current;
		count = 0;
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabB->ct) {
				currSlab = NULL;
				break;
			}
		}
		type = 2;
	}
	if(currSlab == NULL) {
		currSlab = mmheap->slabC->current;
		count = 0;
		while(slabBuf != currSlab->start) {
			currSlab = currSlab->next;
			count++;
			if(count == mmheap->slabC->ct) {
				currSlab = NULL;
				break;
			}
		}
		type = 3;
	}
	if(currSlab == NULL) {
		return -1;
	}
	unsigned int index = ((USE(addr) - currSlab->start) / currSlab->obj_size);
	if(get_bit(currSlab->bitmap->map, index) == 0) {
		return -1;
	}
	if(type == 1) {
		allocA_t *obj = USE(addr);
		if(obj->ct != currSlab->ct) {
			return -1;
		}
	}
	else if(type == 2) {
		allocB_t *obj = USE(addr);
		if(obj->ct != currSlab->ct) {
			return -1;
		}
	}
	else if(type == 3) {
		allocC_t *obj = USE(addr);
		if(obj->ct != currSlab->ct) {
			return -1;
		}
	}
	else {
		return -1;
	}
	

	return 0;
}



/**********************************************************************

    Function    : set/clear/get_bit
    Description : Bit manipulation functions
    Inputs      : words: bitmap 
                  n: index in bitmap
    Outputs     : cache if success, or NULL on failure

***********************************************************************/

void set_bit(word_t *words, int n) {
	words[WORD_OFFSET(n)] |= (1 << BIT_OFFSET(n));
}

void clear_bit(word_t *words, int n) {
	words[WORD_OFFSET(n)] &= ~(1 << BIT_OFFSET(n));
}

int get_bit(word_t *words, int n) {
	word_t bit = words[WORD_OFFSET(n)] & (1 << BIT_OFFSET(n));
	return bit != 0;
}


/**********************************************************************

    Function    : print_cache_slabs
    Description : Print current slab list of cache
    Inputs      : cache: slab cache
    Outputs     : void

***********************************************************************/

int print_cache_slabs( slab_cache_t *cache )
{
	slab_t *slab = cache->current;
	int count=0;
	printf("Cache %p has %d slabs\n", cache, cache->ct );
	do {
		printf("slab: %p; prev: %p; next: %p\n", slab, slab->prev, slab->next );
		count+=1;
		slab = slab->next;
	} while ( slab != cache->current );
	return count;
}


/**********************************************************************

    Function    : get_stats/slab_counts
    Description : Print stats on slab page and object allocations 
    Outputs     : void
**********************************************************************/
void slab_counts( slab_cache_t *cache, unsigned int *slab_count, unsigned int *object_count ){
	slab_t *slab = cache->current;
	int i;
	unsigned int orig_count;
	
	*slab_count = 0;
	*object_count = 0;
	
	if(slab == NULL) {
		return;
	}
	
	do {
		(*slab_count)++;

		// set orig to test objects per slab
		orig_count = *object_count;

		// count objects in slab
		for ( i = 0; i < slab->bitmap->size ; i++ ) {
			if ( get_bit( slab->bitmap->map, i )) {
				(*object_count)++;
			}
		}

		if (( *object_count - orig_count ) != slab->ct ) {
			printf("*** Discrepancy in object count in slab %p: %d:%d\n", 
			       slab, *object_count - orig_count, slab->ct);
		}
			

		slab = slab->next;
	} while ( slab != cache->current );

	if ( *slab_count != cache->ct ) {
		printf("*** Discrepancy in slab page count in cache %p: %d:%d\n", cache, *slab_count, cache->ct);
	}
}

void get_stats(){
	unsigned int slab_count, object_count;

	printf("--- Cache A ---\n");
	slab_counts( mmheap->slabA, &slab_count, &object_count );
	printf("Number of slab pages:objects in Cache A: %d:%d\n", slab_count, object_count );
	printf("--- Cache B ---\n");
	slab_counts( mmheap->slabB, &slab_count, &object_count );
	printf("Number of slab pages:objects in Cache B: %d:%d\n", slab_count, object_count );
	printf("--- Cache C ---\n");
	slab_counts( mmheap->slabC, &slab_count, &object_count );
	printf("Number of slab pages:objects in Cache C: %d:%d\n", slab_count, object_count );
}
