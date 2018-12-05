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
    char *variable;
}

%token EOL EQUALS ADDITION SUBSTRACTION MULTIPLICATION DIVISION ADDITION_EQUALS SUBSTRACTION_EQUALS MULTIPLICATION_EQUALS DIVISION_EQUALS PARENTHESIS_START PARENTHESIS_END END THEN DO ELSE IF ELSIF UNLESS UNTIL WHILE PRINT RESERVED
%token <value> NUMBER
%token <variable> VARIABLE

%%

program: statement
    |   statement EOL program
;

statement: primmary
    |   statementAssignment
;

statementAssignment:
    VARIABLE { printf("\tvalori %s\n", $1); }
    assignment { if ($<variable>3[0] != '\0') printf("\tvalord %s\n", $1); }
    expression { if ($<variable>3[0] != '\0') printf("\t%s\n", $<variable>3); printf("\tasigna\n"); }
;

assignment: EQUALS { $<variable>$ = ""; }
    |   ADDITION_EQUALS { $<variable>$ = "sum"; }
    |   SUBSTRACTION_EQUALS { $<variable>$ = "sub"; }
    |   MULTIPLICATION_EQUALS { $<variable>$ = "mul"; }
    |   DIVISION_EQUALS { $<variable>$ = "div"; }
;

primmary: primmaryIf
    |   primmaryUnless
    |   primmaryUntil
    |   primmaryWhile
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

primmaryDo:
    DO { printf("\tsiXvea LBLx\n"); }
    program
;

primmaryUntil:
    UNTIL { printf("LBLx\n"); }
    expression
    primmaryDo
    END { printf("\tvea LBLx\n"); printf("LBLx\n"); }
;

primmaryWhile:
    WHILE { printf("LBLx\n"); }
    expression
    primmaryDo
    END { printf("\tvea LBLx\n"); printf("LBLx\n"); }
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