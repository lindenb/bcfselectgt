%{
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
    FloatOrInt float_or_int;
	int d;
	float f;
	};

%token<d> LEX_GT_TYPE LEX_COLUMN_INDEX
%token<str> LEX_FILENAME
%token LEX_EQ
%token LEX_NE
%token LEX_GT LEX_GE LEX_LT LEX_LE
%token LEX_NO_CALL
%token LEX_AND
%token LEX_OR
%token LEX_NOT
%token LEX_CARET
%token LEX_STAR
%token<d> LEX_INT
%token<f> LEX_FLOAT
%token<str> LEX_STRING LEX_REGEX

%type<sample_idx> sample_index
%type<sample_indexes>  sample_items sample_set
%type<gt_types>  gt_type_set
%type<checkGt> sample_check0 sample_check
%type<node> boolean_expr and_expr or_expr
%type<d> opt_caret gt_type eqorne cmpop 
%type<float_or_int> samplecount

%%

input: or_expr {
	g_node =  $1;
	};


or_expr: and_expr {$$=$1;} | or_expr  LEX_OR and_expr {
	assert($1!=NULL);
	assert($3!=NULL);
	$$ = NodeNew();
	$$->type = NODE_TYPE_OR;
	$$->left = $1;
	$$->right = $3;
	};


and_expr: boolean_expr {$$=$1;} | and_expr  LEX_AND  boolean_expr {
	assert($1!=NULL);
	assert($3!=NULL);
	$$ = NodeNew();
	$$->type = NODE_TYPE_AND;
	$$->left = $1;
	$$->right = $3;
	};


boolean_expr: sample_check {
	$$ = NodeNew();
	$$->type = NODE_TYPE_COMPARE;
	$$->check = $1;
	} | '(' or_expr ')' {
	$$ = $2;
	}  | LEX_NOT or_expr {
	$$ = NodeNew();
	$$->type = NODE_TYPE_NOT;
	$$->left = $2;
	};
;

sample_check: sample_check0 {
	$$ = $1;
	$$->cmp_operator = LEX_EQ;
	$$->expect_n_samples = IntArraySize($$->samples);
	} | sample_check0 cmpop samplecount {
	int expect_n_samples;
	$$ = $1;
	$1->cmp_operator = $2;
	if( $3.type == TYPE_IS_INT ) {
		expect_n_samples = $3.data.d;
		}
	else
		{
		expect_n_samples = (int)($3.data.f * IntArraySize($1->samples) );
		}
	if(expect_n_samples<0) {
		ERROR("Sample count cannot be lower than 0 (%d)",expect_n_samples);
		}
	if(expect_n_samples> IntArraySize($1->samples)) {
		ERROR("Sample count (%d)cannot be greater than the number of samples in the group (%d) ",
			expect_n_samples,IntArraySize($1->samples));
		}
	$$->expect_n_samples = expect_n_samples;
	};

sample_check0 : sample_set eqorne gt_type_set {
	$$ = CheckGtNew();
	$$->negate = ($2==LEX_EQ?0:1);
	$$->samples = $1;
	$$->gtypes = $3;
	};

samplecount: LEX_INT {
	$$.type=TYPE_IS_INT;
	$$.data.d = $1;
	}|
	LEX_FLOAT {
	if($1<0.0 || $1>1.0) ERROR("Bad fraction of samples value 0<=%f<=1.0.",$1);
	$$.type=TYPE_IS_FLOAT;
	$$.data.f = $1;
	}
	;

cmpop: eqorne {$$=$1;} | 
	LEX_LT {$$=LEX_LT;}|
	LEX_GT {$$=LEX_GT;}|
	LEX_GE {$$=LEX_GE;}|
	LEX_LE {$$=LEX_LE;};


eqorne:LEX_EQ {$$=LEX_EQ;} | LEX_NE {$$=LEX_NE;};



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
	
	if(IntArraySize(array)==0) {
		ERROR("regex \"%s\" : no valid  sample found in vcf (negate flag=%d).",$2,negate);
		}
	free($2);
	$$=array;
	} | LEX_STAR {
	int i;
	$$ = IntArrayNew();
	for(i=0;i< (int)bcf_hdr_nsamples(g_header);i++) {
		IntArrayInsert($$,i); 
		}
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


