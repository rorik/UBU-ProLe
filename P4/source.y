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
    VARIABLE { printf("\tvalori %s", $1); }
    assignment { if ($<variable>2[0] != '\0') printf("\tvalord %s", $1); }
    expression { if ($<variable>2[0] != '\0') printf("\t%s", $<variable>2); printf("\tasigna"); }
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

primmaryThen: THEN program
;

primmaryIf: IF expression primmaryThen primmaryElseIf primmaryElse END
;

primmaryElse: ELSE program
    |   /* EPSILON */
;

primmaryElseIf: ELSIF expression primmaryThen primmaryElseIf
    |   /* EPSILON */
;

primmaryUnless: UNLESS expression primmaryThen primmaryUnlessElse END
;

primmaryUnlessElse: ELSE program
    |   /* EPSILON */
;

primmaryDo: DO program
;

primmaryUntil: UNTIL expression primmaryDo END
;

primmaryWhile: WHILE expression primmaryDo END
;

primmaryPrint: PRINT expression
;

expression: mexpression expression2
;

expression2: ADDITION
    |   SUBSTRACTION
    |   /* EPSILON */
;

mexpression: value mexpression2
;

mexpression2: MULTIPLICATION
    |   DIVISION
    |   /* EPSILON */
;

value: NUMBER
    |   VARIABLE
    | PARENTHESIS_START expression PARENTHESIS_END
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