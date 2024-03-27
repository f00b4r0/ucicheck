/*
//  scanner.l
//  A basic scanner for uci config files
//
//  (C) 2024 Thibaut VARENE
//  License: GPLv2 - http://www.gnu.org/licenses/gpl-2.0.html
*/

%option noyywrap
%option nounput
%option noinput
%option nodefault
%option nounistd
%option batch
%option 8bit
%option nodebug
%option yylineno

IDENTPART		[A-Za-z0-9_]

%{
	#include "parser.tab.h"
	extern void yyerror(const char *, ...);
%}

%%
	/* consecutive new lines */
\n+		{ return NEWLINE; }

	/* keywords */
package		{ return PACKAGE; }
config		{ return CONFIG; }
option		|
list		{ return OPTION; }

	/* comments */
#.*			/* ignore comments */

	/* identifiers */
{IDENTPART}+		|
'{IDENTPART}+'		|
\"{IDENTPART}+\"	{ return IDENTIFIER; }


	/* user strings */
[^ '\t\"\n]+		|			/* unquoted, without whitespace */
'[^'\n]*'		|			/* single quoted */
\"[^\"\n]*\"		{ return STRING; }	/* double quoted */

[ \t]+			/* ignore whitespace */

.			{ yyerror("spurious character '%c'", *yytext); return YYerror; }

<<EOF>>			{ yyterminate(); }
%%
