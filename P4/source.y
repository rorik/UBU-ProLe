%{
#include <stdio.h>
#include <stdlib.h>
#define UNDEFINED -1

int yylex();
extern FILE *yyin;
void yyerror(const char *s);

int getNewLabel() {
    static int labelCount = 0;
    return labelCount++;
}

struct LabelPayload {
    int currentLabel;
    int endLabel;
};

%}

%union {
    int value;
    char *string;
    struct LabelPayload *payload;
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

primmary: primmaryIfUnless
    |   primmaryUntilWhile
    |   primmaryPrint
;

primmaryIfUnless:
    IF { $<value>$ = 0; } primmaryIfUnless2
    |   UNLESS { $<value>$ = 1; } primmaryIfUnless2
;

primmaryIfUnless2:
    expression
    newLabel { printf("\tsi%svea LBL%d\n", $<value>0 ? "cierto" : "falso", $<value>2); }
    THEN program
    { struct LabelPayload payload = { $<value>2, UNDEFINED }; $<payload>$ = &payload; } primmaryElseIf
    primmaryElse
    { if (!$<value>8 && $<payload>6->endLabel != UNDEFINED) printf("LBL%d\n", $<payload>6->currentLabel); }
    END { printf("LBL%d\n", $<payload>6->endLabel == UNDEFINED ? $<payload>6->currentLabel : $<payload>6->endLabel); }
;

primmaryElseIf:
    ELSIF
    { if ($<payload>0->endLabel == UNDEFINED) $<payload>0->endLabel = getNewLabel();
        printf("\tvea LBL%d\n", $<payload>0->endLabel); printf("LBL%d\n", $<payload>0->currentLabel); }
    expression
    newLabel { $<payload>0->currentLabel = $<value>4; printf("\tsifalsovea LBL%d\n", $<value>4); }
    THEN program
    { $<payload>$ = $<payload>0; } primmaryElseIf
    |   /* EPSILON */
;

primmaryElse:
    ELSE
    { if ($<payload>-1->endLabel == UNDEFINED) $<payload>-1->endLabel = getNewLabel();
        printf("\tvea LBL%d\n", $<payload>-1->endLabel); printf("LBL%d\n", $<payload>-1->currentLabel); }
    program { $<value>$ = 1; }
    |   /* EPSILON */ { $<value>$ = 0; }
;

primmaryUntilWhile:
    UNTIL { $<value>$ = 1; } primmaryUntilWhile2
    |   WHILE { $<value>$ = 0; } primmaryUntilWhile2
;

primmaryUntilWhile2:
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

expression: expression ADDITION mexpression { printf("\tsum\n"); }
    |   expression SUBSTRACTION mexpression { printf("\tsub\n"); }
    |   mexpression
;

mexpression: mexpression MULTIPLICATION value { printf("\tmul\n"); }
    |   mexpression DIVISION value { printf("\tdiv\n"); }
    |   value
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
		FILE *file = fopen(argv[1], "r");
		if(!file) {
			fprintf(stderr, "no se puede abrir %s\n", argv[1]);
			exit(1);
		}
		yyin = file;
	}
    yyparse();
    return 0;
}