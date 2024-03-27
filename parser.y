//
//  parser.y
//  A basic parser for uci config files
//
//  https://openwrt.org/docs/guide-user/base-system/uci#file_syntax
//  Will catch all errors, but not necessarily report them very user-friendly
//
//  (C) 2024 Thibaut VARENE
//  License: GPLv2 - http://www.gnu.org/licenses/gpl-2.0.html
//

%{
	#include <stdio.h>
	#include <stdlib.h>

	extern int yylineno;
	extern int yylex();
	extern FILE *yyin;
	void yyerror(const char *);
	const char *filename;
	static int retval = 0;
%}

%define parse.error verbose
%verbose

%token PACKAGE CONFIG OPTION NEWLINE
%token IDENTIFIER STRING

%%

start: stmtlist ;

stmtlist: /* empty */
	| stmtlist NEWLINE
	| stmtlist stmt NEWLINE
	| stmtlist error NEWLINE	{ retval = 1; }
;

stmt:	PACKAGE IDENTIFIER
	| CONFIG IDENTIFIER
	| CONFIG IDENTIFIER value
	| OPTION IDENTIFIER		{ yyerror("missing value"); YYERROR; }
	| OPTION IDENTIFIER value
;

value: IDENTIFIER | STRING ;

%%


int main(int argc, char **argv)
{
	if (argc < 2) {
		fprintf(stderr, "Missing filename!\n");
		exit(-1);
	}

	filename = argv[1];
	if (!(yyin = fopen(filename, "r"))) {
		perror(filename);
		exit(-1);
	}

	yyparse();
	fclose(yyin);
	return retval;
}

void yyerror(const char *msg)
{
	fprintf(stderr, "%s: error line %d: %s\n", filename, yylineno, msg);
}

