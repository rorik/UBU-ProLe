%{
#include <stdio.h>
#include <stdlib.h>

/**
 * Used when a label hasn't been initialized.
 */
#define UNDEFINED -1

/**
 * Language parser class.
 *
 * @author <a href="mailto:rdg1003@alu.ubu.es">Rodrigo Díaz García</a>
 * @author <a href="mailto:sbm0020@alu.ubu.es">Sergio Bueno Medina</a>
 */
int yylex();

/**
 * The file which to be parsed.
 */
extern FILE *yyin;

/**
 * The error handler for the syntactic parser.
 */
void yyerror(const char *s);

/**
 * Get the next label.
 *
 * @return the latest label.
 */
int getNewLabel() {
    static int labelCount = 0;
    return labelCount++;
}

/**
 * Struct used to store labels in if/unless blocks
 */
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

/**
 * The program, each statement separated by semicolons.
 */
program: statement
    |   statement EOL program
;

/**
 * Either a built-in function (`if`/`while`/`print`/...) or an assignment.
 */
statement: primmary
    |   statementAssignment
;

/**
 * An assigment to a variable, in the following syntax:
 * VARIABLE (`=`|`+=`|`-=`|`*=`|`/=`) expression()
 */
statementAssignment:
    VARIABLE { printf("\tvalori %s\n", $1); }
    assignment { if ($<string>3[0] != '\0') printf("\tvalord %s\n", $1); }
    expression { if ($<string>3[0] != '\0') printf("\t%s\n", $<string>3); printf("\tasigna\n"); }
;

/**
 * An assigment operator (`=`|`+=`|`-=`|`*=`|`/=`).
 *
 * @return a String with the corresponding operation (sum, sub, mul, or div).
 */
assignment: EQUALS { $<string>$ = ""; }
    |   ADDITION_EQUALS { $<string>$ = "sum"; }
    |   SUBSTRACTION_EQUALS { $<string>$ = "sub"; }
    |   MULTIPLICATION_EQUALS { $<string>$ = "mul"; }
    |   DIVISION_EQUALS { $<string>$ = "div"; }
;

/**
 * Creates a new label.
 *
 * @return a <value> with the new label.
 */
newLabel:
    { $<value>$ = getNewLabel(); }
;

/**
 * One of the built-in functions (`if`, `unless`, `until`, `while`, or `print`).
 */
primmary: IF { $<value>$ = 0; } primmaryIfUnless
    |   UNLESS { $<value>$ = 1; } primmaryIfUnless
    |   UNTIL { $<value>$ = 1; } primmaryUntilWhile
    |   WHILE { $<value>$ = 0; } primmaryUntilWhile
    |   PRINT expression { printf("\tprint\n"); }
;

/**
 * The (`if`|`unless`)/`elsif`/`else` block, with the following syntax:
 * expression THEN program primmaryElseIf primmaryElse END
 *
 * @param <value>0, a boolean statement indicating the condition of the `then` jumps.
 */
primmaryIfUnless:
    expression
    newLabel { printf("\tsi%svea LBL%d\n", $<value>0 ? "cierto" : "falso", $<value>2); }
    THEN program
    { struct LabelPayload payload = { $<value>2, UNDEFINED }; $<payload>$ = &payload; } primmaryElseIf
    primmaryElse
    { if (!$<value>8 && $<payload>6->endLabel != UNDEFINED) printf("LBL%d\n", $<payload>6->currentLabel); }
    END { printf("LBL%d\n", $<payload>6->endLabel == UNDEFINED ? $<payload>6->currentLabel : $<payload>6->endLabel); }
;

/**
 * The `elseif` statement inside an (`if`|`unless`)/`elsif`/`else` block.
 * Syntax: (ELSIF expression THEN program)*
 *
 * @param <payload>0, the LabelPayload of the `if`/`unless` block.
 */
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

/**
 * The `else` statement inside an (`if`|`unless`)/`elsif`/`else` block.
 * Syntax: (ELSE program)?
 *
 * @param <payload>-1, the LabelPayload of the `if`/`unless` block.
 *
 * @return a boolean <value> indicating wether there was an `else` or not.
 */
primmaryElse:
    ELSE
    { if ($<payload>-1->endLabel == UNDEFINED) $<payload>-1->endLabel = getNewLabel();
        printf("\tvea LBL%d\n", $<payload>-1->endLabel); printf("LBL%d\n", $<payload>-1->currentLabel); }
    program { $<value>$ = 1; }
    |   /* EPSILON */ { $<value>$ = 0; }
;

/**
 * The `until`/`while` block.
 * Syntax: expression DO program END
 *
 * @param <value>0, a boolean statement indicating the condition of the `do` jump.
 */
primmaryUntilWhile:
    newLabel { printf("LBL%d\n", $<value>1); }
    expression
    DO
    newLabel { printf("\tsi%svea LBL%d\n", $<value>0 ? "cierto" : "falso", $<value>5 ); }
    program
    END { printf("\tvea LBL%d\n", $<value>1); printf("LBL%d\n", $<value>5); }
;

/**
 * An arithmetic expression.
 * Syntax: (expression (ADDITION | SUBSTRACTION))? mexpression
 */
expression: expression ADDITION mexpression { printf("\tsum\n"); }
    |   expression SUBSTRACTION mexpression { printf("\tsub\n"); }
    |   mexpression
;

/**
 * A final or high priority arithmetic expression.
 * Syntax: (mexpression (MULTIPLICATION | DIVISION))? value
 */
mexpression: mexpression MULTIPLICATION value { printf("\tmul\n"); }
    |   mexpression DIVISION value { printf("\tdiv\n"); }
    |   value
;

/**
 * The final data of an expression.
 * Either a number, a variable or the result of an expression inside parentheses.
 * Syntax: NUMBER | VARIABLE | PARENTHESIS_START expression PARENTHESIS_END
 */
value: NUMBER { printf("\tmete %d\n", $1); }
    |   VARIABLE { printf("\tvalord %s\n", $1); }
    |   PARENTHESIS_START expression PARENTHESIS_END
;

%%

/**
 * The error handler for the syntactic parser.
 */
void yyerror(const char *s) {
    printf("%s\n", s);
    exit(1);
}

/**
 * Main function
 * If given the uri in the first arg, opens the file and uses it as parsing input, otherwise uses stdin.
 * Then begins the parsing.
 */
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