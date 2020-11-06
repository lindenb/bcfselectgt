HTSLIB=${HOME}/src/htslib
CC?=gcc
CFLAGS= -Wall -c -I$(HTSLIB) -Wall
LDFLAGS= -L$(HTSLIB) 

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
	bison --verbose --report-file=bison.report.txt --output=$@ -d $<

clean:
	rm selgt.tab.h selgt.tab.c lex.yy.h lex.yy.c *.o bcfselectgt

