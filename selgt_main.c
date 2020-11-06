#include <getopt.h>
#include <unistd.h>
#include "selgt.h"
#include "lex.yy.h"

extern int yyparse();

NodePtr g_node = NULL;
bcf_hdr_t *g_header;

static int eval_variant(IntArrayPtr gts,NodePtr node) {
	int i,j;
	assert(gts!=NULL);
	assert(node!=NULL);
	switch(node->type) {
		case 0:
			if(node->check->negate==1) {
				for(i=0; i< node->check->samples->size;i++) {
					int sample_index=  node->check->samples->data[i];
					int sample_gt= gts->data[ sample_index];
					for(j=0;j< node->check->gtypes->size;j++) {
						if( sample_gt == node->check->gtypes->data[j]) {
							break;
							}
						}
					if (j!=node->check->gtypes->size) {
						return 0;
						}
					}
				return 1;
				}
			else
				{
				for(i=0; i< node->check->samples->size;i++) {
					int sample_index=  node->check->samples->data[i];
					int sample_gt= gts->data[ sample_index];
					for(j=0;j< node->check->gtypes->size;j++) {
						if( sample_gt == node->check->gtypes->data[j]) {
							break;
							}
						}
					if (j==node->check->gtypes->size) {
						DEBUG("FAIL didn't got sample idx:%d GT=%d",sample_index,sample_gt);
						return 0;
						}
					}
				return 1;
				}
			
		case 1:
			return eval_variant(gts,node->left)==1 && eval_variant(gts,node->right)==1;
		case 2:
			return eval_variant(gts,node->left)==1 || eval_variant(gts,node->right)==1;
		case 3:
			DEBUG("####negate of %d\n",eval_variant(gts,node->left));
			return eval_variant(gts,node->left)!=1;
		default: ERROR("bad state"); abort(); break;
		}
	return 0;
	}


NodePtr NodeNew() {
	NodePtr ptr = (NodePtr)malloc(sizeof(Node));
	if(ptr==NULL) ERROR("out of memory");
	memset((void*)ptr,0,sizeof(Node));
	return ptr;
	}

IntArrayPtr IntArrayNew() {
	IntArrayPtr ptr = (IntArrayPtr)malloc(sizeof(IntArray));
	if(ptr==NULL) ERROR("out of memory");
	ptr->data= 0;
	ptr->size=0;
	return ptr;
	}

IntArrayPtr IntArrayAdd(IntArrayPtr ptr,int sample_idx) {
	ptr->data = (int*)realloc((void*)ptr->data,sizeof(int)*(ptr->size+1));
	if( (ptr->data) == NULL) ERROR("out of memory");
	ptr->data[ptr->size] = sample_idx;
	ptr->size++;
	return ptr;
	}


IntArrayPtr IntArrayInsert(IntArrayPtr ptr,int sample_idx) {
	int i;
	for(i=0;i< ptr->size ; i++) {
		if(ptr->data[i] == sample_idx) return ptr;
		}
	return IntArrayAdd(ptr,sample_idx);
	}


void IntArrayFree(IntArrayPtr ptr) {
	if(ptr==NULL) return;
	free(ptr->data);
	free(ptr);
	}

static void usage(const char* name,FILE* out) {
    fprintf(out,"%s: Compiled %s %s. Pierre Lindenbaum\n",name,__DATE__,__TIME__);
    fprintf(out,"Usage: %s [ -O (o|v|z) ] [-o fileout] -d <distance> (stdin|bcf)\n",name);
    fprintf(out,"Options:\n");
    fprintf(out,"  -h print help\n");
    fprintf(out,"  -d (int) distance\n");
    fprintf(out,"  -o (file) output file (default stdout)\n");
    fprintf(out,"  -O (char) output format z:gzip vcf v:vcf b:bcf (default v)\n");
    fprintf(out,"\n");
    }
    
int main(int argc,char** argv) {
 int c;
 int ret=0;
 int i;
 char* fileout=NULL;
 char format[3]={'v','w',0};
 char* user_expr_str = NULL;
 while ((c = getopt (argc, argv, "o:O:e:h")) != -1)
    switch (c)
      {
      case 'O':
            if(strlen(optarg)!=1) {
                usage(argv[0],stderr);
                ERROR("Bad format '%s'.",optarg);
                return EXIT_FAILURE;                
                }
            format[0]=optarg[0];
            break;
      case 'o': fileout=strdup(optarg);break;
      case 'h':
            usage(argv[0],stdout);
            return EXIT_SUCCESS;
      case 'e':
            user_expr_str = strdup(optarg);
            break;
      default:
          usage(argv[0],stderr);
          ERROR("Argument error.");
          return EXIT_FAILURE;
      }
     
if( user_expr_str ==NULL) {
    ERROR("expression is missing");
    return EXIT_FAILURE;    
	}
	
if(!(optind==argc || optind+1==argc)) {
    ERROR("Illegal number of arguments");
    return EXIT_FAILURE;    
    }
htsFile *in = hts_open(optind==argc ?"-":argv[optind],"r");
if(in==NULL) {
    ERROR("Cannot open input vcf %s. (%s)",(optind==argc ?"<stdin>":argv[optind]),strerror(errno));
    return EXIT_FAILURE;    
    }
bcf_hdr_t *header = bcf_hdr_read(in);
if(header==NULL) {
    ERROR("Cannot read header for input vcf %s.",(optind==argc ?"<stdin>":argv[optind]));
    return EXIT_FAILURE;    
    }

int nsmpl = bcf_hdr_nsamples(header);
if( nsmpl ==0) {
	ERROR("No Genotypes in input.");
	return EXIT_FAILURE;
	}

g_header = header; 
YY_BUFFER_STATE buffer_state = yy_scan_string(user_expr_str);
yyparse();
yy_delete_buffer(buffer_state);
if( g_node == NULL) {
 	ERROR("Illegal state.");
    return EXIT_FAILURE;   
	}


htsFile *out = hts_open((fileout==NULL?"-":fileout),format);
if(out==NULL) {
    ERROR("Cannot open output vcf %s. (%s)",(fileout==NULL?"<STDOUT>":fileout),strerror(errno));
    return EXIT_FAILURE;    
    }
kstring_t xheader = {0,0,0};
ksprintf(&xheader, "##gtselect.command=%s\n",user_expr_str);
bcf_hdr_append(header, xheader.s);
free(xheader.s);

if ( bcf_hdr_write(out, header)!=0 ) {
    ERROR("Cannot write header.");
    return EXIT_FAILURE;      
    }

bcf1_t* bcf = bcf_init();
if(bcf==NULL) {
    ERROR("Out of memory.");
    return EXIT_FAILURE;    
    }



IntArrayPtr genotype_types  = IntArrayNew();
for(i=0;i< nsmpl ;i++) {
	IntArrayAdd(genotype_types,-1);
	}
assert(genotype_types->size == nsmpl);
	    
while((ret=bcf_read(in, header, bcf))==0) {
	bcf_fmt_t *gt_fmt;
	if(bcf->errcode!=0) {
		WARNING("Skipping Error in VCF record at tid %d:%"PRIhts_pos,bcf->rid, bcf->pos+1);
		continue;
		}
        
   	bcf_unpack(bcf,BCF_UN_IND);
	
    if ( (gt_fmt=bcf_get_fmt(header,bcf,"GT")) ==NULL ) continue;
    

    for(i=0;i< nsmpl ;i++) {
		int type = bcf_gt_type(gt_fmt,i,NULL,NULL);
		genotype_types->data[i]=type;
		}
	
    if(eval_variant(genotype_types,g_node)==0) continue;
    if(bcf_write1(out, header, bcf)!=0) {
        ERROR("IO error. Cannot write record.");
        return EXIT_FAILURE;
        }
  	}

IntArrayFree(genotype_types);
if(fileout) free(fileout);
bcf_destroy(bcf);
bcf_hdr_destroy(header);
hts_close(in);
hts_close(out);
free(user_expr_str);
  return EXIT_SUCCESS;
}
