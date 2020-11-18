/*
The MIT License (MIT)

Copyright (c) 2020 Pierre Lindenbaum

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#ifndef SEL_GT_H
#define SEL_GT_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <htslib/hts.h>
#include <htslib/vcf.h>
#include <htslib/vcfutils.h>
#define BCF_SELECT_GT_VERSION "0.1.0"

#define WHERE do {fprintf(stderr,"[%s:%d]",__FILE__,__LINE__);} while(0)
#define WARNING(...) do { fputs("[WARNING]",stderr);WHERE;fprintf(stderr,__VA_ARGS__);fputc('\n',stderr);} while(0)
#define ERROR(...) do { fputs("[ERROR]",stderr);WHERE;fprintf(stderr,__VA_ARGS__);fputc('\n',stderr);exit(EXIT_FAILURE);} while(0)
#define DEBUG(...) do {fputs("[DEBUG]",stderr);WHERE;fprintf(stderr,__VA_ARGS__);fputc('\n',stderr);} while(0)
//#define DEBUG(...) do {} while(0)

typedef struct int_array_t {
	int size;
	int* data;
	} IntArray,*IntArrayPtr;

IntArrayPtr IntArrayInsert(IntArrayPtr ptr,int sample_idx);
IntArrayPtr IntArrayAdd(IntArrayPtr ptr,int sample_idx);
int IntArrayContains(IntArrayPtr ptr,int sample_idx);
IntArrayPtr IntArrayNew();
void IntArrayFree(IntArrayPtr ptr);
#define IntArraySize(ptr) ((ptr)->size)
#define IntArrayAt(ptr,idx) ((ptr)->data[idx])


#define TYPE_IS_INT 0
#define TYPE_IS_FLOAT 1
typedef struct float_or_int_t {
	int type;
	union {
		int d;
		double f;
		} data;
	} FloatOrInt;


typedef struct checkgt_t {
	int negate;
	int cmp_operator;
	int expect_n_samples;
	IntArrayPtr samples;
	IntArrayPtr gtypes;
	} CheckGt,*CheckGtPtr;

CheckGtPtr CheckGtNew();

typedef struct node_t {
	int type;
	struct node_t* left;
	struct node_t* right;
	CheckGtPtr check;
	} Node,*NodePtr;


NodePtr NodeNew();


#define NODE_TYPE_COMPARE 0
#define NODE_TYPE_AND 1
#define NODE_TYPE_OR 2
#define NODE_TYPE_NOT 3
#endif
