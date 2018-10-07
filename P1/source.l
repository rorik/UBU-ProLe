%{
#define ERROR(message) printf("Unexpected character string at line %d (%s)\n", currentLine, message); exit(1);
#define BEGIND(state) printf("|%s|----Begin %d----|", yytext, state); BEGIN state; 
unsigned currentLine = 1, messageCount = 0, groupCount = 0, longestGroupId;
char* longestName, longestGroup, longestMessage;
%}
EOL	\n
ANY .|{EOL}
ALPHA [a-zA-Z]
NUM [0-9]
ALPHANUM {ALPHA}|{NUM}
HEX {NUM}|[a-fA-F]
FORMATTING \*\*|\/\/|\"\"|--|__|~~
TEXT [" "{ALPHANUM}{FORMATTING}]*
ID {FORMATTING}*{ALPHANUM}{TEXT}*{ALPHANUM}{FORMATTING}*
WHTSPACE [\ \t]
COMMENT '.*$
ARROWHEADLEFT (o|x)?<|<<|\/\/|\\\\
ARROWHEADRIGHT >|>>|\/\/|\\\\(o|x)?
ARROW {ARROWHEADLEFT}?-(\[#{ALPHANUM}+\])?-?{ARROWHEADRIGHT}?

%x DIAG GROUP DECL DECL_OPT ORIGIN DESTINY MESS_OPT MESSAGE
%%
{EOL}  {currentLine++;};
<INITIAL>@startuml BEGIND(DIAG);
<INITIAL>{ANY} ;
<DIAG>@enduml BEGIND(INITIAL);
<DIAG>^{WHTSPACE}*{COMMENT} ;
<DIAG>{ID} BEGIND(ORIGIN);
<DIAG>{ANY} ECHO;
<ORIGIN>{WHTSPACE}*{ARROW}{WHTSPACE}* BEGIND(DESTINY);
<ORIGIN>{ANY} ECHO;
<DESTINY>{ID} BEGIND(MESS_OPT);
<MESS_OPT>':' BEGIND(MESSAGE);
<MESSAGE>{ANY} BEGIND(MESSAGE);
%%
int main(int argc, char **argv)
{
	if(argc > 1) {
		FILE *file;
		file=fopen(argv[1], "r");
		if(!file) {
			fprintf(stderr, "no se puede abrir %s\n", argv[1]);
			exit(1);
		}
		yyin = file;
	}
	yylex();
	printf("-------------------------------------------\n");
	printf("Participante con nombre mas largo: %s\n", longestName);
	printf("Numero total de mensajes: %d\n", messageCount);
	printf("Numero total de agrupaciones: %d\n", groupCount);
	printf("Agrupacion con mayor numero de mensajes: %s (numero %d)\n", longestGroup, longestGroupId);
	printf("Mensaje con texto mas largo: %s\n", longestMessage);
    return 0;
}
