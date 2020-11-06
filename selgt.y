%{
#include <assert.h>
#include <errno.h>
#include "selgt.h"
#include "lex.yy.h"
#include <regex.h> 


extern bcf_hdr_t *g_header;
extern NodePtr g_node;



void yyerror (char const *s) {
   ERROR("[scanner]%s.\n", s);
 }


%}

%locations


%union {
    char* str;
    int sample_idx;
    IntArrayPtr sample_indexes;
    IntArrayPtr gt_types;
    CheckGtPtr checkGt;
    NodePtr node;
	int d;
	};

%token<d> LEX_GT_TYPE LEX_COLUMN_INDEX
%token<str> LEX_FILENAME
%token LEX_EQ
%token LEX_NE
%token LEX_NO_CALL
%token LEX_IS
%token LEX_AND
%token LEX_OR
%token LEX_NOT
%token LEX_CARET
%token<str> LEX_STRING LEX_REGEX
%type<sample_idx> sample_index
%type<sample_indexes>  sample_items sample_set
%type<gt_types>  gt_type_set
%type<checkGt> sample_check
%type<node> boolean_expr and_expr or_expr
%type<d> opt_caret not_flag gt_type

%left LEX_AND
%left LEX_NOT
%%

input: and_expr {
	g_node =  $1;
	};



and_expr: or_expr {$$=$1;} | and_expr  LEX_AND  or_expr {
	assert($1!=NULL);
	assert($3!=NULL);
	$$ = NodeNew();
	$$->type = 1;
	$$->left = $1;
	$$->right = $3;
	} | '(' and_expr ')' {
	$$ = $2;
	}  | LEX_NOT and_expr {
	$$ = NodeNew();
	$$->type = 3;
	$$->left = $2;
	};


or_expr: boolean_expr {$$=$1;} | or_expr  LEX_OR boolean_expr {
	assert($1!=NULL);
	assert($3!=NULL);
	$$ = NodeNew();
	$$->type = 2;
	$$->left = $1;
	$$->right = $3;
	};

boolean_expr: sample_check {
	$$ = NodeNew();
	$$->type = 0;
	$$->check = $1;
	};



sample_check : sample_set LEX_IS not_flag gt_type_set {
	$$ =(CheckGtPtr)malloc(sizeof(CheckGt));
	if($$==NULL) ERROR("out of memory");
	$$->negate = $3;
	$$->samples = $1;
	$$->gtypes = $4;
	} | sample_set LEX_EQ gt_type_set {
	$$ =(CheckGtPtr)malloc(sizeof(CheckGt));
	if($$==NULL) ERROR("out of memory");
	$$->negate = 0;
	$$->samples = $1;
	$$->gtypes = $3;
	} | sample_set LEX_NE gt_type_set {
	$$ =(CheckGtPtr)malloc(sizeof(CheckGt));
	if($$==NULL) ERROR("out of memory");
	$$->negate = 1;
	$$->samples = $1;
	$$->gtypes = $3;
	};



not_flag:  {$$=0;} | LEX_NOT {$$=1;};

gt_type_set:gt_type {
    $$ = IntArrayInsert(IntArrayNew(),$1);
	}| gt_type_set '|' gt_type {
	$$ = IntArrayInsert($1,$3);
	};

gt_type: LEX_GT_TYPE {$$=$1;};

sample_set: sample_index {
	$$ = IntArrayInsert(IntArrayNew(),$1);
	} | '[' opt_caret sample_items ']' {
	if($2==0)
		{
		$$ = $3;
		}
	else
		{
		int i,j;
		$$ = IntArrayNew();
		for(i=0;i< (int)bcf_hdr_nsamples(g_header);i++) {
			for(j=0;j< $3->size;++j) {
				if ($3->data[j] == i) break;
				}
			if(j == $3->size) {
				IntArrayInsert($$,i);
				}
			}
		IntArrayFree($3);
		}
	} | opt_caret LEX_FILENAME {
	int negate=$1;
	char line[1024];
	FILE* f=fopen($2,"r");
	if(f==NULL) {
		ERROR("Cannot open \"%s\" (%s)",$2,strerror(errno));
		}
	$$ =IntArrayNew();
	while(fgets(line,1024,f)!=NULL) {
		size_t l = strlen(line);
		if(l==0) continue;
		if(line[l-1]=='\n') line[l-1]=0;
		int idx = bcf_hdr_id2int(g_header,BCF_DT_SAMPLE,line);
		if ( idx < 0 ) {
			WARNING("file \"%s\" : undefined  sample \"%s\" in vcf. SKIPPING.\n",$2,line);
			continue;
			}
		IntArrayInsert($$,idx);
		}
	fclose(f);
	if(negate==1) {
		int i;
		IntArrayPtr array = IntArrayNew();
		for(i=0;i< (int)bcf_hdr_nsamples(g_header);i++) {
			if( IntArrayContains($$,i) ) continue;
                        IntArrayInsert(array,i);        
                        }
		IntArrayFree($$);
		$$=array;
		}

	if($$->size==0) {
		ERROR("file \"%s\" : no valid  sample found in vcf (negate flag=%d).",line,negate);
		}
	free($2);
	} | opt_caret LEX_REGEX {
	regex_t regex;
	int negate=$1;
	int i;
	if(regcomp(&regex,$2,REG_EXTENDED|REG_NOSUB)!=0) {
		ERROR("cannot compile regular expression \"%s\".",$2);
		}
	IntArrayPtr array = IntArrayNew();
	for(i=0;i< (int)bcf_hdr_nsamples(g_header);i++) {
		int found = (regexec(&regex,g_header->samples[i],0,NULL,0)==0);
		if(negate) found=!found;
		if(found) IntArrayInsert(array,i); 
		}
	regfree(&regex);
	
	if(array->size==0) {
		ERROR("regex \"%s\" : no valid  sample found in vcf (negate flag=%d).",$2,negate);
		}
	free($2);
	$$=array;
	};

sample_items: sample_index {
	$$ = IntArrayInsert(IntArrayNew(),$1);
	} | sample_items  sample_index {
	$$ = IntArrayInsert($1,$2);
	};



sample_index : LEX_STRING {
	assert(g_header!=NULL);
	assert($1!=NULL);

	int idx = bcf_hdr_id2int(g_header,BCF_DT_SAMPLE,$1);
	if ( idx < 0 ) {
		ERROR("undefined  sample \"%s\" in vcf.\n",$1);
		}
	free($1);
	$$ = idx;
	} | LEX_COLUMN_INDEX {
	if($1 < 1 || $1>(int)bcf_hdr_nsamples(g_header)) {
		ERROR("Bad sample index 1<=$%d<=%d",$1,(int)bcf_hdr_nsamples(g_header));
		}
	$$= ($1 -1 );
	} ;

opt_caret: {$$ = 0;} |  LEX_CARET { $$ = 1;};
%%


