
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

#include "selgt.h"
#include "selgt.tab.h"
%}

%option noyywrap
%option caseless
%option nounput
%option noinput
%%

\* return LEX_STAR;
== return LEX_EQ;
"!=" return LEX_NE;
"<=" return LEX_LE;
"<" return LEX_LT;
">=" return LEX_GE;
">" return LEX_GT;
UNKN|GT_UNKN|NO_CALL|NOCALL	 yylval.d=GT_UNKN; return LEX_GT_TYPE;
GT_HOM_AA|HOM_AA|AA|HOM_VAR|HOMVAR	yylval.d=GT_HOM_AA; return LEX_GT_TYPE;
GT_HET_AA|HET_AA	yylval.d=GT_HET_AA; return LEX_GT_TYPE;
GT_HOM_RR|HOM_RR|RR|HOM_REF|HOMREF	yylval.d=GT_HOM_RR; return LEX_GT_TYPE;
GT_HET_RA|HET_RA|HET	yylval.d=GT_HET_RA; return LEX_GT_TYPE;
GT_HAPL_R|HAPL_R yylval.d=GT_HAPL_R; return LEX_GT_TYPE;
GT_HAPL_A|HAPL_A yylval.d=GT_HAPL_A; return LEX_GT_TYPE;


OR|\|\| return LEX_OR;
AND|&& return LEX_AND;
NOT|\! return LEX_NOT;
\^ return LEX_CARET;
[0-9]+\.[0-9]+ yylval.f= atof(yytext); return LEX_FLOAT;
[0-9]+% yylval.f= atoi(yytext)/100.0; return LEX_FLOAT;
[0-9]+ yylval.d= atoi(yytext); return LEX_INT;
\$[0-9]+   yylval.d= atoi(&yytext[1]); return LEX_COLUMN_INDEX;
@[^ \t\n\:]+  yylval.str= strndup(&yytext[1],yyleng-1);return LEX_FILENAME;
\"[^\"]+\" yylval.str= strndup(&yytext[1],yyleng-2); return LEX_STRING;
\/[^\/]+\/ yylval.str= strndup(&yytext[1],yyleng-2); return LEX_REGEX;
\( return '(';
\) return ')';
\] return ']';
\[ return '[';
\| return '|';
[ \t\n] ;
.	{
	ERROR("[lex]Error char \"%s\".\n",yytext);
	exit(EXIT_FAILURE);
	}

%%\y
