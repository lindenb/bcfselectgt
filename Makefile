HTSLIB?=../htslib
CC?=gcc
CFLAGS= -O2 -Wall -c -I$(HTSLIB) -Wall
LDFLAGS= -L$(HTSLIB) 
.PHONY=test

	
bcfselectgt: selgt_main.o selgt.tab.o lex.yy.o 
	$(CC) -o $@ $(LDFLAGS) $^  -lhts

selgt_main.o: selgt_main.c selgt.tab.h selgt.h lex.yy.h
	$(CC) $(CFLAGS) -o $@ $<

selgt.tab.o: selgt.tab.c selgt.tab.h selgt.h lex.yy.h
	$(CC) $(CFLAGS) -o $@ $<

lex.yy.o: lex.yy.c selgt.h
	$(CC) $(CFLAGS) -o $@ $<

lex.yy.h: lex.yy.c

lex.yy.c: selgt.l selgt.h selgt.tab.h
	flex --header-file=lex.yy.h $<

selgt.tab.h: selgt.tab.c

selgt.tab.c :selgt.y selgt.h
	bison --xml=bison.xml --verbose --report-file=bison.report.txt --output=$@ -d $<


test: bcfselectgt rotavirus_rf.vcf
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '"S1" == HET' $(word 2,$^)
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '"S1" != HET' $(word 2,$^)
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '[ "S1" "S2"] != HET' $(word 2,$^)
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '[ "S1" "S2"] != HET|HOM_VAR' $(word 2,$^)
	echo  "S1,S2,S3" | tr "," "\n" > test.samples
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '@test.samples == HOM_REF' $(word 2,$^)
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '^ @test.samples == HOM_REF' $(word 2,$^)
	rm test.samples
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '"S3" == HET && "S4" == HET' $(word 2,$^)
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '"S3" == HET || "S4" == HET' $(word 2,$^)
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '!("S3" == HET || "S4" == HET)' $(word 2,$^)
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '/^S[12]$$/ == HOM_REF' $(word 2,$^)
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '^ /^S[12]$$/ == HOM_REF' $(word 2,$^)
	LD_LIBRARY_PATH=${ LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt -e '* == HOM_REF' $(word 2,$^)

clean:
	rm selgt.tab.h selgt.tab.c lex.yy.h lex.yy.c *.o bcfselectgt test.samples bison.xml bison.report.txt 

