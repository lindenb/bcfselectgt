
%{
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
