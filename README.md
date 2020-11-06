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




## Example

```
# if needed
export LD_LIBRARY_PATH=/path/to/htslib/lib

./bcfselectgt -e '' input test.bcf
```





