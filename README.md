# bcfselectgt

VCF/BCF genotypes filtering using htslib

[![Build Status](https://travis-ci.org/lindenb/bcfselectgt.svg)](https://travis-ci.org/lindenb/bcfselectgt)

![Last commit](https://img.shields.io/github/last-commit/lindenb/bcfselectgt.png)


## Usage: 

```
./bcfselectgt [ -O (o|v|z) ] [ -F <FILTER> ] [-o fileout] (-e <expression>|-f <file>)  (stdin|bcf|vcf)
```

## Options:

```
  -h print help
  -F (string) soft FILTER name (default: filter out variants).
  -e (string) expression. See manual. Required or use '-f'.
  -f (file) script file. See manual. Required or use '-e'
  -o (file) output file (default stdout)
  -O (char) output format z:gzip v:vcf b:bcf (default v)
```

## Installation

Requirements:

  * gcc
  * GNU Make
  * Flex https://github.com/westes/flex
  * Bison https://www.gnu.org/software/bison/
  * htslib https://github.com/samtools/htslib/

Compilation:


```
git clone "https://github.com/lindenb/bcfselectgt.git"
cd bcfselectgt
make HTSLIB=/path/to/compiled-htslib-directory
```	

## Expression

syntax:
```

expr: expr1 | ! <expr1> | <expr1> && <expr1> | <expr1> || <expr1>

expr1:= <sample-set> (==|!=) <genotype-choice> ( (==|!=|<|>|<=|>=) <number> )?

genotype-choice:= <genotype-type> ('|' <genotype-type> )*


genotype-types:= are evaluated from the htslib function `bcf_gt_type`. Valid identifiers are:

  - UNKN or GT_UNKN or NO_CALL or NOCALL
  - GT_HOM_AA or HOM_AA or AA or HOM_VAR
  - GT_HET_AA or HET_AA
  - GT_HOM_RR or HOM_RR or RR or HOM_REF
  - GT_HET_RA or HET_RA or HET
  - GT_HAPL_R or HAPL_R
  - GT_HAPL_A or HAPL_A

sample-set:=

  - "sample-name" :quoted sample name
  - $3 : Third sample in VCF
  - [ $1 $3 ] : First and Third samples in VCF
  - @filename file : containing one sample per line
  - ^ @filename file : all the samples in the vcf but the samples in the file.
  - [ "sample1" "sample2" ] : sample1 AND sample2
  - [ ^ "sample1" "sample2" ] : all the samples in the vcf but sample1 AND sample2
  - * : all the samples in the vcf
  - /regex/ : all the samples in the VCF matching the regular expression 'regex'
  -  ^ /regex/ : all the samples in the VCF but those matching the regular expression 'regex'


number:
  - 25: the integer number 25
  - 0.25 : the floating number 0.25
  - 25% : the floating number 0.25

```

## Examples

if needed , update the variable **LD_LIBRARY_PATH**

```
export LD_LIBRARY_PATH=/path/to/htslib
```

sample in column 1 is HOM_REF
```
$ bcfselectgt -e ' $1  == HOM_REF' rotavirus_rf.vcf  | grep -v "##" | cut -f 10- | head
S1	S2	S3	S4	S5
0/0	0/0	0/0	0/0	1/1
0/0	0/1	0/1	0/0	0/0
0/0	0/0	0/0	1/1	0/0
0/0	0/1	0/1	0/0	0/0
0/0	1/1	1/1	0/0	0/0
0/0	0/0	0/0	1/1	0/0
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	0/0	1/1
0/0	0/1	0/1	0/0	0/0
```


all samples are HOM_REF

```
bcfselectgt -e '* == HOM_REF' rotavirus_rf.vcf | grep -v "##" | cut -f 10-
S1	S2	S3	S4	S5
0/0	0/0	0|0	0|0	0/0
```

S1 is HOM_VAR

```
$ bcfselectgt -e ' "S1" == HOM_VAR ' rotavirus_rf.vcf | grep -v "##" | cut -f 10- | head 
S1	S2	S3	S4	S5
1/1	0/0	0/0	0/0	0/0
1/1	0/0	0/0	0/0	0/0
1/1	1/1	1|1	1|1	1/1
```

S1 must be HOM_VAR or HET
```
$ bcfselectgt -e '"S1" == HOM_VAR|HET' rotavirus_rf.vcf | grep -v "##" | cut -f 10-
S1	S2	S3	S4	S5
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
(...)
```
or
```
$ bcfselectgt -e '"S1" == HOM_VAR || "S1" == HET ' rotavirus_rf.vcf | grep -v "##" | cut -f 10- 
S1	S2	S3	S4	S5
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
(...)
```

S1 and S2 must be HET:
```
$ bcfselectgt -e ' [ "S1" "S2" ]  == HET ' rotavirus_rf.vcf | grep -v "##" | cut -f 10-
S1	S2	S3	S4	S5
1/0	1/0	0/1	0/1	1/0
```

or 

```
$ bcfselectgt -e ' "S1" == HET &&  "S2"   == HET ' rotavirus_rf.vcf | grep -v "##" | cut -f 10- S1	S2	S3	S4	S5
1/0	1/0	0/1	0/1	1/0
```

S1 and S2 must not be HET:
```
$ bcfselectgt -e ' [ "S1" "S2" ] != HET ' rotavirus_rf.vcf | grep -v "##" | cut -f 10- | head S1	S2	S3	S4	S5
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	1/1	0/0
0/0	1/1	1/1	0/0	0/0
0/0	0/0	0/0	1/1	0/0
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	0/0	1/1
0/0	1/1	1/1	0/0	0/0
0/0	0/0	0/0	0/1	0/0
0/0	0/0	0/0	1/1	0/0
```

lines where S1 and S2 are not both HET

```
$ bcfselectgt -e '!( [ "S1" "S2" ] == HET )' rotavirus_rf.vcf | grep -v "##" | cut -f 10- | head 
S1	S2	S3	S4	S5
0/0	0/0	0/0	0/0	1/1
0/0	0/1	0/1	0/0	0/0
0/0	0/0	0/0	1/1	0/0
0/1	0/0	0/0	0/0	0/0
0/0	0/1	0/1	0/0	0/0
0/1	0/0	0/0	0/0	0/0
0/0	1/1	1/1	0/0	0/0
0/0	0/0	0/0	1/1	0/0
0/0	0/0	0/0	0/0	1/1
```



all samples but S1 and S2 must be HET:
```
bcfselectgt -e ' [  ^ "S1" "S2" ]  == HET ' rotavirus_rf.vcf | grep -v "##" | cut -f 10- | head
S1	S2	S3	S4	S5
1/0	1/0	0/1	0/1	1/0
```

all samples in file 'samples.txt' must be HET.
```
$ echo -e 'S1\nS2' > samples.txt
bcfselectgt -e ' @samples.txt  == HET ' rotavirus_rf.vcf | grep -v "##" | cut -f 10-
S1	S2	S3	S4	S5
1/0	1/0	0/1	0/1	1/0
```

all samples in the vcf excluding those in the file 'samples.txt' must be HOM_REF.
```
$ echo -e 'S1\nS2' > samples.txt
bcfselectgt -e ' ^ @samples.txt  == HOM_REF ' rotavirus_rf.vcf | grep -v "##" | cut -f 10- | head
S1	S2	S3	S4	S5
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
1/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
1/1	0/0	0/0	0/0	0/0

```

samples matching the regular expression `/S[35]/` must be HOM_REF:
```
$ bcfselectgt -e ' /S[35]/ == HOM_REF ' rotavirus_rf.vcf | grep -v "##" | cut -f 10- | head 
S1	S2	S3	S4	S5
0/0	0/0	0/0	1/1	0/0
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
0/0	0/0	0/0	1/1	0/0
0/1	0/0	0/0	0/0	0/0
0/1	0/0	0/0	0/0	0/0
0/0	0/0	0/0	0/1	0/0
0/0	0/0	0/0	1/1	0/0
0/0	0/0	0/0	0/1	0/0
```

samples that don't match the regular expression `/S[35]/` must be HOM_REF:
```
$ bcfselectgt -e ' ^ /S[35]/ == HOM_REF ' rotavirus_rf.vcf | grep -v "##" | cut -f 10- | head 
S1	S2	S3	S4	S5
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0/0	0/0	1/1
0/0	0/0	0|0	0|0	0/0
```

all samples matching `/^NA.*/` must be HET.

```
bcfselectgt -e ' /NA.*/ == HOM_REF ' ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.bcf
```

more than 10 samples matching  `/^NA.*/` must be HOM_VAR.
```
$ bcfselectgt -e ' /^NA.*/ == HOM_VAR  > 10  ' ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.bcf
```


only one sample is HOM_VAR

```
bcfselectgt -e ' *  == HOM_VAR  == 1   ' ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.bcf 
```

more than 10% of the  samples matching  `/^NA.*/` are  HET.
```
$ bcfselectgt -e ' /^NA.*/ == HET  > 10%  ' ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.bcf 
```


more than 75% (0.75) of the  samples matching  `/^NA.*/` are HET.
```
bcfselectgt -e ' /^NA.*/ == HET  > 0.75  ' ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.bcf
```

four samples samples matching  `/^NA.*/` are HET.
```
bcfselectgt -e ' /^NA.*/ == HET  == 4  ' ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.bcf 
```

