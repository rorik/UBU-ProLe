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

%union {
    int value;
    char *string;
}

%token EOL EQUALS ADDITION SUBSTRACTION MULTIPLICATION DIVISION ADDITION_EQUALS SUBSTRACTION_EQUALS MULTIPLICATION_EQUALS DIVISION_EQUALS PARENTHESIS_START PARENTHESIS_END END THEN DO ELSE IF ELSIF UNLESS UNTIL WHILE PRINT RESERVED
%token <value> NUMBER
%token <string> VARIABLE

%%

program: statement
    |   statement EOL program
;

statement: primmary
    |   statementAssignment
;

statementAssignment:
    VARIABLE { printf("\tvalori %s\n", $1); }
    assignment { if ($<string>3[0] != '\0') printf("\tvalord %s\n", $1); }
    expression { if ($<string>3[0] != '\0') printf("\t%s\n", $<string>3); printf("\tasigna\n"); }
;

assignment: EQUALS { $<string>$ = ""; }
    |   ADDITION_EQUALS { $<string>$ = "sum"; }
    |   SUBSTRACTION_EQUALS { $<string>$ = "sub"; }
    |   MULTIPLICATION_EQUALS { $<string>$ = "mul"; }
    |   DIVISION_EQUALS { $<string>$ = "div"; }
;

newLabel:
    { $<value>$ = getNewLabel(); }
;

primmary: primmaryIf
    |   primmaryUnless
    |   primmaryUntilWhile
    |   primmaryPrint
;

primmaryThen:
    THEN
    program
;

primmaryIf:
    IF
    expression { printf("\tsifalsovea LBLx\n"); }
    primmaryThen
    primmaryElseIf
    primmaryElse
    END { printf("LBLx\n"); }
;

primmaryElse:
    ELSE { printf("\tvea LBLx\n"); printf("LBLx\n"); }
    program
    |   /* EPSILON */ { printf("LBLx\n"); }
;

primmaryElseIf:
    ELSIF { printf("\tvea LBLx\n"); printf("LBLx\n"); }
    expression { printf("\tsifalsovea LBLx\n"); }
    primmaryThen
    primmaryElseIf
    |   /* EPSILON */
;

primmaryUnless:
    UNLESS
    expression{ printf("\tsiciertovea LBLx\n"); }
    primmaryThen
    primmaryUnlessElse
    END { printf("LBLx\n"); }
;

primmaryUnlessElse:
    ELSE { printf("\tvea LBLx\n"); printf("LBLx\n"); }
    program
    |   /* EPSILON */
;

primmaryUntilWhile:
    UNTIL { $<value>$ = 1; } primmaryUntilWhileDo
    |   WHILE { $<value>$ = 0; } primmaryUntilWhileDo
;

primmaryUntilWhileDo:
    newLabel { printf("LBL%d\n", $<value>1); }
    expression
    DO
    newLabel { printf("\tsi%svea LBL%d\n", $<value>0 ? "cierto" : "falso", $<value>5 ); }
    program
    END { printf("\tvea LBL%d\n", $<value>1); printf("LBL%d\n", $<value>5); }
;

primmaryPrint:
    PRINT expression { printf("\tprint\n"); }
;

expression:
    mexpression expression2
;

expression2: ADDITION expression { printf("\tsum\n"); }
    |   SUBSTRACTION expression { printf("\tsub\n"); }
    |   /* EPSILON */
;

mexpression: value  mexpression2
;

mexpression2: MULTIPLICATION mexpression { printf("\tmul\n"); }
    |   DIVISION mexpression { printf("\tdiv\n"); }
    |   /* EPSILON */
;

value: NUMBER { printf("\tmete %d\n", $1); }
    |   VARIABLE { printf("\tvalord %s\n", $1); }
    |   PARENTHESIS_START expression PARENTHESIS_END
;

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