%{
#define DEBUG_MODE 0
#define ERROR(message) fprintf(stderr, "Unexpected character string (%s) at line %d (%s)\n", yytext, currentLine, message); exit(1);
#if DEBUG_MODE != 0
	#define BEGIND(state) printf("{%s| BEGIN %d }", yytext, state); BEGIN state; 
#else
	#define BEGIND(state) BEGIN state;
#endif
#if DEBUG_MODE > 1
	#define IGNORE printf("{~%s~}", yytext);
	#define NEWLINE currentLine++; printf("\n[%d]> ", currentLine);
#else
	#define IGNORE ;
	#define NEWLINE currentLine++;
#endif
#define MAX_GROUP_DEPTH 64
unsigned currentLine = 0, messageCount = 0, groupCount = 0;
char *longestName = "\0", *longestMessage = "\0", *currentMessage = "\0";
char *groupStackName[MAX_GROUP_DEPTH], *longestGroup = "\0";
int groupStackSize[MAX_GROUP_DEPTH], currentGroupLevel = -1, longestGroupSize = -1;
void participant(), messageAppend(), messageEnd(), groupStart(), groupName(), groupEnd();
%}
EOL	\n
ANY .|{EOL}
ALPHA [a-zA-Z]
NUM [0-9]
ALPHANUM {ALPHA}|{NUM}
HEX {NUM}|[a-fA-F]
WHTSPACE [\ \t\r]
FORMATTING \*\*|\/\/|\"\"|--|__|~~
TEXT {ALPHANUM}|{FORMATTING}
IDWORD {FORMATTING}*{ALPHANUM}{TEXT}*{ALPHANUM}{FORMATTING}*
ID  (\"[^\"\n\r]+\")|{IDWORD}
COMMENT '.*
ARROWHEADLEFT (o|x)?<{1,2}|\/{1,2}|\\{1,2}
ARROWHEADRIGHT (>{1,2}|\/{1,2}|\\{1,2})(o|x)?
ARROW {ARROWHEADLEFT}?-(\[#{ALPHANUM}+\])?-?{ARROWHEADRIGHT}?
GROUPSTRT alt|opt|loop|par|break|critical|group
GROUPRSET else
GROUPFNSH end
IGNORABLE database({WHTSPACE}+.*)?$
DECLARATION (participant|actor|boundary|control|entity|database){WHTSPACE}+
DECLARATION_OPT (actor|boundary){WHTSPACE}+

/* 1    2     3    4        5      6       7        8    */
%x DIAG GROUP DECL DECL_OPT ORIGIN DESTINY MESS_OPT MESSAGE
%%
<INITIAL>@startuml					BEGIND(DIAG);
<INITIAL>{WHTSPACE}*|{COMMENT}		IGNORE;
<INITIAL>{EOL}						NEWLINE;
<INITIAL>{ANY}						ERROR("Esperado @startuml");
<DIAG>{WHTSPACE}*|{COMMENT}			IGNORE;
<DIAG>{IGNORABLE}					IGNORE;
<DIAG>@enduml						BEGIND(INITIAL);
<DIAG>{GROUPSTRT} 					groupStart();
<DIAG>{GROUPRSET} 					groupEnd(); groupStart();
<DIAG>{GROUPFNSH} 					groupEnd();
<DIAG>{DECLARATION}					BEGIND(DECL);
<DIAG>{ID}							participant(); BEGIND(ORIGIN);
<DIAG>{EOL}							NEWLINE
<DIAG>.								ERROR("Expected declaration, group, message origin, or @enduml");
<GROUP>{EOL}						BEGIND(DIAG); NEWLINE;
<GROUP>{WHTSPACE}*					IGNORE;
<GROUP>[^\ \t\n\r].*				groupName();
<ORIGIN>{ARROW}						BEGIND(DESTINY);
<ORIGIN>{WHTSPACE}*					IGNORE;
<ORIGIN>{ANY}						ERROR("Expected arrow");
<DESTINY>{ID}						BEGIND(MESS_OPT);
<MESS_OPT>{WHTSPACE}*				IGNORE;
<MESS_OPT>:{WHTSPACE}*				BEGIND(MESSAGE);
<MESS_OPT>{EOL}						messageEnd();
<MESSAGE>{WHTSPACE}*|{COMMENT}		IGNORE;
<MESSAGE>[^'\n\r]*					messageAppend();
<MESSAGE>{EOL}						messageEnd(); NEWLINE;
<DECL>{ID}							participant(); BEGIND(DECL_OPT);
<DECL>{ANY}							ERROR("Expected ID");
<DECL_OPT>.*						IGNORE;
<DECL_OPT>{EOL}						BEGIND(DIAG); NEWLINE;

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
	NEWLINE;
	yylex();
	#if DEBUG_MODE != 0
		printf("\n");
	#endif
	printf("-----------------------------------------------\n");
	printf("- El participante con el nombre mas largo es: \"%s\"\n", longestName);
	printf("- El diagrama tiene %d mensajes.\n", messageCount);
	printf("- El diagrama tiene %d agrupaciones.\n- ", groupCount);
	if (groupCount == 0) {
		printf("No tiene agrupaciones.");
	} else {
		printf("La agrupación \"%s\" tiene %d mensajes.", longestGroup, longestGroupSize);
	}
	printf("\n- El mensaje de mayor longitud es: \"%s\"\n", longestMessage);
	printf("- Se han procesado %d lineas.\n", currentLine);
	printf("-----------------------------------------------\n");
    return 0;
}
char* concat(const char *s1, const char *s2) {
    const size_t len1 = strlen(s1);
    const size_t len2 = strlen(s2);
    char *result = malloc(len1 + len2 + 1);
    memcpy(result, s1, len1);
    memcpy(result + len1, s2, len2 + 1);
    return result;
}
void participant() {
	const _Bool isEscaped = yytext[0]=='"';
	const size_t idLength = strlen(yytext) - (isEscaped ? 2 : 0);
	if (idLength > strlen(longestName)) {
		longestName = malloc(idLength);
		memcpy(longestName, yytext + (isEscaped ? 1 : 0), idLength);
	}
}
void messageAppend() {
	currentMessage = concat(currentMessage, yytext);
}
void messageEnd() {
	if (strlen(currentMessage) > strlen(longestMessage)) {
		longestMessage = malloc(strlen(currentMessage));
		memcpy(longestMessage, currentMessage, strlen(currentMessage));
	}
	messageCount++;
	currentMessage = "\0";
	if (currentGroupLevel  >= 0) {
		groupStackSize[currentGroupLevel]++;
	}
	BEGIND(DIAG);
}
void groupStart() {
	currentGroupLevel++;
	groupCount++;
	if (currentGroupLevel >= MAX_GROUP_DEPTH) {
		ERROR("Excedeed maximum group depth");
	}
	groupStackSize[currentGroupLevel] = 0;
	BEGIND(GROUP);
}
void groupName() {
	groupStackName[currentGroupLevel] = malloc(strlen(yytext));
	memcpy(groupStackName[currentGroupLevel], yytext, strlen(yytext));
}
void groupEnd() {
	if (groupStackSize[currentGroupLevel] > longestGroupSize) {
		longestGroup = groupStackName[currentGroupLevel];
		longestGroupSize = groupStackSize[currentGroupLevel];
	}
	currentGroupLevel--;
	if (currentGroupLevel < 0) {
		currentGroupLevel = -1;
		BEGIND(DIAG);
	}
}