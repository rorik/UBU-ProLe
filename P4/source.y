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
    expression
    newLabel { printf("\tsifalsovea LBL%d\n", $<value>3); }
    primmaryThen
    { struct LabelPayload payload = { $<value>3, -1 }; $<payload>$ = &payload; } primmaryElseIf
    { $<value>$ = $<payload>6->currentLabel; } primmaryElse { $<payload>6->endLabel = $<value>9; }
    END { printf("LBL%d\n", $<payload>6->endLabel); }
;

primmaryElseIf:
    ELSIF
    { if ($<payload>0->endLabel == -1) $<payload>0->endLabel = getNewLabel();
        printf("\tvea LBL%d\n", $<payload>0->endLabel); printf("LBL%d\n", $<payload>0->currentLabel); }
    expression
    newLabel { $<payload>0->currentLabel = $<value>4; printf("\tsifalsovea LBL%d\n", $<value>4); }
    primmaryThen
    { $<payload>$ = $<payload>0; } primmaryElseIf
    |   /* EPSILON */
;

primmaryElse:
    ELSE
    newLabel { printf("\tvea LBL%d\n", $<value>2); printf("LBL%d\n", $<value>0); }
    program { $<value>$ = $<value>2; }
    |   /* EPSILON */ { $<value>$ = $<value>0; }
;

primmaryUnless:
    UNLESS
    expression
    newLabel { printf("\tsiciertovea LBL%d\n", $<value>3); }
    primmaryThen
    { $<value>$ = $<value>3; } primmaryElse
    END { printf("LBL%d\n", $<value>7); }
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