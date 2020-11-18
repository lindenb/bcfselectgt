HTSLIB?=../htslib
$(warning INFO: compiling using $$HTSLIB=$(HTSLIB) . Otherwise compile using 'make HTSLIB=/path/to/compiled/htslib')
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

RUNIT=LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$(HTSLIB) ./bcfselectgt
test: bcfselectgt rotavirus_rf.vcf
	$(RUNIT) -e '"S1" == HET' $(word 2,$^)
	$(RUNIT) -F FILTERME -e '"S1" == HET' $(word 2,$^)
	$(RUNIT) -e '"S1" != HET' $(word 2,$^)
	$(RUNIT) -e '[ "S1" "S2"] != HET' $(word 2,$^)
	$(RUNIT) -e '[ "S1" "S2"] != HET|HOM_VAR' $(word 2,$^)
	echo  "S1,S2,S3" | tr "," "\n" > test.samples
	$(RUNIT) -e '@test.samples == HOM_REF' $(word 2,$^)
	$(RUNIT) -e '^ @test.samples == HOM_REF' $(word 2,$^)
	rm test.samples
	$(RUNIT) -e '"S3" == HET && "S4" == HET' $(word 2,$^)
	$(RUNIT) -e '"S3" == HET || "S4" == HET' $(word 2,$^)
	$(RUNIT) -e '!("S3" == HET || "S4" == HET)' $(word 2,$^)
	$(RUNIT) -e '/^S[12]$$/ == HOM_REF' $(word 2,$^)
	$(RUNIT) -e '^ /^S[12]$$/ == HOM_REF' $(word 2,$^)
	$(RUNIT) -e '* == HOM_REF' $(word 2,$^)
	$(RUNIT) -e '* == HOM_VAR > 25%' $(word 2,$^)
	echo '[ "S1" "S2"] != HET' > test.script
	$(RUNIT) -f test.script $(word 2,$^)
	rm test.script
	cat $(word 2,$^) | $(RUNIT) -e '"S1" == HOM_VAR'
	cat $(word 2,$^) | $(RUNIT) -O z -e '"S1" == HOM_VAR' | gunzip -c
	
clean:
	rm selgt.tab.h selgt.tab.c lex.yy.h lex.yy.c *.o bcfselectgt test.samples bison.xml bison.report.txt  test.script

