%{
#include <stdio.h>
#include <stdlib.h>
#define UNDEFINED -1

/**
 * Language parser class.
 *
 * @author <a href="mailto:rdg1003@alu.ubu.es">Rodrigo Díaz García</a>
 * @author <a href="mailto:sbm0020@alu.ubu.es">Sergio Bueno Medina</a>
 */
int yylex();
extern FILE *yyin;
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
/*
 *Struct used for saving label numbers
 */
struct LabelPayload {
    int currentLabel;
    int endLabel;
};

%}
/*
 *Union needed for define possible data types for semantic values
 */
%union {
    int value;
    char *string;
    struct LabelPayload *payload;
}
/*
 *Tokens taken from our lex token file
 */
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
 * Either a built-in function (`if`/`while`/`print`) or an assignment.
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
/*
*Increases the label value for printing afterwards
*/
newLabel:
    { $<value>$ = getNewLabel(); }
;
/**
 * One of the built-in functions (`if`, `unless`, `until`, `while`, or `print`).
 */
primmary: primmaryIf
    |   primmaryUnless
    |   primmaryUntilWhile
    |   primmaryPrint
;
/**
 * A common syntax used in many functions.
 * Syntax: THEN program()
 */
primmaryThen:
    THEN
    program
;
/**
 * The `if`/`elsif`/`else` block, with the following syntax:
 * IF expression() primmaryThen() (primmaryElseIf)* primmaryElse()? END
 */
primmaryIf:
    IF
    expression
    newLabel { printf("\tsifalsovea LBL%d\n", $<value>3); }
    primmaryThen
    { struct LabelPayload payload = { $<value>3, UNDEFINED }; $<payload>$ = &payload; } primmaryElseIf
    { $<payload>$ = $<payload>6; } primmaryElse
    { if (!$<value>9 && $<payload>6->endLabel != UNDEFINED) printf("LBL%d\n", $<payload>6->currentLabel); }
    END { printf("LBL%d\n", $<payload>6->endLabel == UNDEFINED ? $<payload>6->currentLabel : $<payload>6->endLabel); }
;
/**
 * The `elseif` statement inside an `if`/`elsif`/`else` block.
 * Syntax: <ELSIF> expression() primmaryThen()
 *
 * @param label the label of this `elsif`.
 * @param endLabel the label that ends the `if` block.
 *
 * @return an int with the label with the following jump address,
 *         either an `elsif`, `else` or before `end`.
 */
primmaryElseIf:
    ELSIF
    { if ($<payload>0->endLabel == UNDEFINED) $<payload>0->endLabel = getNewLabel();
        printf("\tvea LBL%d\n", $<payload>0->endLabel); printf("LBL%d\n", $<payload>0->currentLabel); }
    expression
    newLabel { $<payload>0->currentLabel = $<value>4; printf("\tsifalsovea LBL%d\n", $<value>4); }
    primmaryThen
    { $<payload>$ = $<payload>0; } primmaryElseIf
    |   /* EPSILON */
;
/**
 * The else statement inside an `if`/`elsif`/`else` block.
 * Syntax: <ELSE> program()
 *
 * @param label the label of this `else`.
 * @param endLabel the label that ends the `if` block and comes after this `else`.
 */
primmaryElse:
    ELSE
    { if ($<payload>0->endLabel == UNDEFINED) $<payload>0->endLabel = getNewLabel();
        printf("\tvea LBL%d\n", $<payload>0->endLabel); printf("LBL%d\n", $<payload>0->currentLabel); }
    program { $<value>$ = 1; }
    |   /* EPSILON */ { $<value>$ = 0; }
;
/**
 * The `unless` function.
 * Syntax: <UNLESS> expression() primmaryThen() primmaryUnlessElse()? <END>
 */
primmaryUnless:
    UNLESS
    expression
    newLabel { printf("\tsiciertovea LBL%d\n", $<value>3); }
    primmaryThen
    { struct LabelPayload payload = { $<value>3, UNDEFINED }; $<payload>$ = &payload; } primmaryElse
    END { printf("LBL%d\n", $<value>7 ? $<payload>6->endLabel : $<payload>6->currentLabel); }
;
/**
 * The `UntilWhile` function.
 * Syntax: <UNTIL> expression() primmaryDo() <END>
 * or Syntax: <WHILE> expression() primmaryDo() <END>
 */
primmaryUntilWhile:
    UNTIL { $<value>$ = 1; } primmaryUntilWhileDo
    |   WHILE { $<value>$ = 0; } primmaryUntilWhileDo
;
/**
 * The `UntilWhileDo` function.
 * We move into the labels when the conditions are made
 */
primmaryUntilWhileDo:
    newLabel { printf("LBL%d\n", $<value>1); }
    expression
    DO
    newLabel { printf("\tsi%svea LBL%d\n", $<value>0 ? "cierto" : "falso", $<value>5 ); }
    program
    END { printf("\tvea LBL%d\n", $<value>1); printf("LBL%d\n", $<value>5); }
;
/**
 * The `print` function.
 * Syntax: <PRINT> expression()
 */
primmaryPrint:
    PRINT expression { printf("\tprint\n"); }
;
/**
 * An arithmetic expression.
 * Syntax: mexpression() expression2()?
 */
expression:
    mexpression expression2
;
/**
 * Either an addition or substraction followed by another expression.
 * Syntax: (+|-) expression()
 */
expression2: ADDITION expression { printf("\tsum\n"); }
    |   SUBSTRACTION expression { printf("\tsub\n"); }
    |   /* EPSILON */
;
/**
 * A final or high priority arithmetic expression.
 * A value follwed by another optional final expression.
 * Syntax: value() mexpression2()?
 */
mexpression: value  mexpression2
;
/**
 * Either a multiplication or division followed by another final expression.
 * Syntax: (*|/) mexpression()?
 */
mexpression2: MULTIPLICATION mexpression { printf("\tmul\n"); }
    |   DIVISION mexpression { printf("\tdiv\n"); }
    |   /* EPSILON */
;
/**
 * The final data of an expression.
 * Either a number, a variable or the result of an expression inside parentheses.
 * Syntax: NUMBER | VARIABLE | ( "(" expression() ")" ) 
 */
value: NUMBER { printf("\tmete %d\n", $1); }
    |   VARIABLE { printf("\tvalord %s\n", $1); }
    |   PARENTHESIS_START expression PARENTHESIS_END
;

%%
/*
 *yyerror we print an error in case we found some during the parsing
 */

void yyerror(const char *s) {
    printf("%s\n", s);
    exit(1);
}
/*
 *Main fucrtion
 *It opens the file needed for the parsing
 */
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