%{
#include <stdio.h>
#include <stdlib.h>

int getNewLabel() {
    static int labelCount = 0;
    return labelCount++;
}
%}


%token ALPHA NUMBER EOL EQUALS ADDITION SUBSTRACTION MULTIPLICATION DIVISION ADDITION_EQUALS SUBSTRACTION_EQUALS MULTIPLICATION_EQUALS DIVISION_EQUALS PARENTHESIS_START PARENTHESIS_END END THEN DO ELSE IF ELSIF UNLESS UNTIL WHILE PRINT RESERVED VARIABLE

%%

%%

yyerror(char *s) {
    printf("%s\n", s);
    exit(1);
}


int main() {
    yyparse();
    return 0;
}