//
//  parser.y
//  A basic parser for uci config files
//
//  https://openwrt.org/docs/guide-user/base-system/uci#file_syntax
//  Will catch all errors, but not necessarily report them very user-friendly
//  Requires input to have a terminating newline
//
//  (C) 2024 Thibaut VARENE
//  License: GPLv2 - http://www.gnu.org/licenses/gpl-2.0.html
//

%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <stdarg.h>
	#include <unistd.h>

	void yyerror(const char *, ...);

	extern int yylineno;
	extern int yylex();
	extern FILE *yyin;

	static const char *filename;
	static int retval = 0, prevline = 0;

	int no_nl = 0;
%}

%define parse.error verbose
%verbose

%token PACKAGE CONFIG OPTION NEWLINE
%token NAME IDENTIFIER TYPE VALUE

%%

start: stmtlist ;

stmtlist: /* empty */
	| stmtlist NEWLINE
	| stmtlist stmt NEWLINE
	| stmtlist error NEWLINE	{ yyerrok; if (++retval >= 10) { fprintf(stderr, "TOO MANY ERRORS, ABORTING!\n"); YYABORT; } }
;

stmt:	PACKAGE NAME
	| CONFIG TYPE
	| CONFIG TYPE IDENTIFIER
	| OPTION IDENTIFIER values
;

/* handle implicit concatenation */
values: VALUE | values VALUE ;

%%


int main(int argc, char **argv)
{
	int opt;

	while ((opt = getopt(argc, argv, "n")) != -1) {
		if ('n' == opt)		// 'n' does not permit embedded new lines in string litterals
			no_nl = 1;
		else {
			fprintf(stderr, "Usage: %s [-n] file\n", argv[0]);
			exit(-1);
		}
	}

	if (optind >= argc) {
		fprintf(stderr, "Missing filename!\n");
		exit(-1);
	}

	filename = argv[optind];
	if (!(yyin = fopen(filename, "r"))) {
		perror(filename);
		exit(-1);
	}

	retval += yyparse();	// catch unhandled errors
	fclose(yyin);
	return retval;
}

void yyerror(const char *msg, ...)
{
	va_list ap;

	va_start(ap, msg);
	fprintf(stderr, "%s: error line %d: ", filename, yylineno-prevline);
	vfprintf(stderr, msg, ap);
	va_end(ap);
	fprintf(stderr, "\n");
	prevline = 0;
}

