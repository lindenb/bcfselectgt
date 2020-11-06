#ifndef SEL_GT_H
#define SEL_GT_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <htslib/hts.h>
#include <htslib/vcf.h>
#include <htslib/vcfutils.h>

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

typedef struct checkgt_t {
	int negate;
	IntArrayPtr samples;
	IntArrayPtr gtypes;
	} CheckGt,*CheckGtPtr;

typedef struct node_t {
	int type;
	struct node_t* left;
	struct node_t* right;
	CheckGtPtr check;
	} Node,*NodePtr;

NodePtr NodeNew();


#endif
