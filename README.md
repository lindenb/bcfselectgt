# bcfselectgt

Bcf genotypes filtering using htslib

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

genotype-type:=
  - NKN or GT_UNKN or NO_CALL or NOCALL
  - GT_HOM_AA or HOM_AA or AA or HOM_VAR
  - GT_HET_AA or HET_AA
  - GT_HOM_RR or HOM_RR or RR or HOM_REF
  - GT_HET_RA or HET_RA or HET
  - GT_HAPL_R or HAPL_R
  - GT_HAPL_A or HAPL_A

sample-set:=
  - "sample-name" :quoted sample name
  - @filename file : containing one sample per line
  - [ "sample1" "sample2" ] : sample1 AND sample2
  - [ ^ "sample1" "sample2" ] : all the sample in the vcf but sample1 AND sample2



```



## Example

```
# if needed
export LD_LIBRARY_PATH=/path/to/htslib/lib

./bcfselectgt -e '' input test.bcf
```





