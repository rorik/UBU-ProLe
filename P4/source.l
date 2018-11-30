%{
#include "y.tab.h"
#include <string.h>
%}
%option noyywrap

ALPHA [a-zA-Z]
NUM [0-9]
%%
[ \t\r\n]    ;
{NUM}+      {
    yylval.value = atoi(yytext);
    return NUMBER;
}
";"         return EOL;
"="         return EQUALS;
"+"         return ADDITION;
"-"         return SUBSTRACTION;
"*"         return MULTIPLICATION;
"/"         return DIVISION;
"+="        return ADDITION_EQUALS;
"-="        return SUBSTRACTION_EQUALS;
"*="        return MULTIPLICATION_EQUALS;
"/="        return DIVISION_EQUALS;
"("         return PARENTHESIS_START;
")"         return PARENTHESIS_END;
"end"       return END;
"then"      return THEN;
"do"        return DO;
"else"      return ELSE;
"if"        return IF;
"elsif"     return ELSIF;
"unless"    return UNLESS;
"until"     return UNTIL;
"while"     return WHILE;
"print"     return PRINT;
("class"|"ensure"|"nil"|"self"|"alias"|"defined"|"for"|"or"|"begin"|"return"|"next") return RESERVED;
({ALPHA}|"_")({ALPHA}|{NUM}|"_")*   {
    yylval.variable = strdup(yytext);
    return VARIABLE;
}
%%