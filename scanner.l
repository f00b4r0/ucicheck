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

%x PACKNAME IDENT DATA ERROR

IDENTPART		[A-Za-z0-9_]
PACKPART		[-A-Za-z0-9_]

%{
	#include "parser.tab.h"
	extern void yyerror(const char *, ...);
%}

%%
	/* consecutive new lines */
<*>\n+		{ BEGIN(INITIAL); return NEWLINE; }

	/* comments */
<*>#.*			/* ignore comments */

	/* keywords */
package		{ BEGIN(PACKNAME); return PACKAGE; }
config		{ BEGIN(IDENT); return CONFIG; }
option		|
list		{ BEGIN(IDENT); return OPTION; }
[^ \t\n]+	{ yyerror("unknown keyword: %s", yytext); BEGIN(ERROR); return YYerror; }

	/* package names */
<PACKNAME>{PACKPART}+		|
<PACKNAME>'{PACKPART}+'		|
<PACKNAME>\"{PACKPART}+\"	{ return IDENTIFIER; }

	/* identifiers */
<IDENT>{IDENTPART}+		|
<IDENT>'{IDENTPART}+'		|
<IDENT>\"{IDENTPART}+\"		{ BEGIN(DATA); return IDENTIFIER; }

<PACKNAME,IDENT>[^ \t\n]+	{ yyerror("invalid identifier: %s", yytext); return YYerror; }

	/* user strings */
<DATA>[^ '\t\"\n]+	|			/* unquoted, without whitespace */
<DATA>'[^'\n]*'		|			/* single quoted */
<DATA>\"[^\"\n]*\"	{ return VALUE; }	/* double quoted */

<*>[ \t]+		/* ignore whitespace */

<*>.			{ yyerror("spurious character '%c'", *yytext); BEGIN(ERROR); return YYerror; }

<ERROR>.*		/* ignore rest of line */

<<EOF>>			{ yyterminate(); }
%%
