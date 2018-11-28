%{
#include <stdio.h>
#include <stdlib.h>

int yylex();
extern FILE *yyin;
void yyerror(const char *s);

int getNewLabel() {
    static int labelCount = 0;
    return labelCount++;
}
%}

%token ALPHA NUMBER EOL EQUALS ADDITION SUBSTRACTION MULTIPLICATION DIVISION ADDITION_EQUALS SUBSTRACTION_EQUALS MULTIPLICATION_EQUALS DIVISION_EQUALS PARENTHESIS_START PARENTHESIS_END END THEN DO ELSE IF ELSIF UNLESS UNTIL WHILE PRINT RESERVED VARIABLE

%%

%%

void yyerror(const char *s) {
    printf("%s\n", s);
    exit(1);
}


int main(int argc, char **argv) {
    if(argc > 1) {
		FILE *file;
		file=fopen(argv[1], "r");
		if(!file) {
			fprintf(stderr, "no se puede abrir %s\n", argv[1]);
			exit(1);
		}
		yyin = file;
	}
    yyparse();
    return 0;
}