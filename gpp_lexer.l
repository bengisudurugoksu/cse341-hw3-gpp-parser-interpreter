/*extern int yylex(void);*/
%{
#include <stdio.h>
#include <stdlib.h>
#include "gpp_interpreter.tab.h"  // Include the Bison-generated token definitions
%}

%option noyywrap

/* Regular expressions for tokens */
%%
"if"           { return KW_IF; }
"defun"         { return KW_DEFFUN; }
"+"             { return OP_PLUS; }
"-"             { return OP_MINUS; }
"*"             { return OP_MULT; }
"/"             { return OP_DIV; }
"("             { return OP_OP; }
")"             { return OP_CP; }
","             { return OP_COMMA; }
"equal"        { return KW_EQUAL; }
"less"         { return KW_LESS; }
"while"          { return KW_WHILE; }
"for"          { return KW_FOR; }
"defvar"       { return KW_DEFVAR; }
"set"           { return KW_SET; }
"load"           { return KW_LOAD; }
"exit"            { return KW_EXIT; }
"print"          { return KW_PRINT; }

[0-9]+\.[0-9]+  { yylval.valuef = atof(yytext); return VALUEF; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return IDENTIFIER; }


[ \t\n]+        { /* Ignore whitespace */ }

.               { printf("Unexpected character: %s\n", yytext); exit(EXIT_FAILURE); }

%%
