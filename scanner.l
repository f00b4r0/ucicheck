/*
//  scanner.l
//  A basic scanner for uci config files
//
//  (C) 2024 Thibaut VARENE
//  License: GPLv2 - http://www.gnu.org/licenses/gpl-2.0.html
*/

/*
 package $name
 config $type[ $identifier]
 {option|list} $identifier $value
 - $identifier contains [A-Za-z0-9_], can be quoted (' or ")
 - $name adds '-' to $identifier set
 - $type contains ASCII chars 33-126, can be quoted (' or ")
 - $value contains bytes 33-255, + sp \t \n \r when quoted
 - implicit concatenation of string literals is valid (currently only supported here for values)
 further references in https://github.com/openwrt/uci/blob/master/util.c

 the scanner is walking a fine line dealing with whitespace, since tokens are wsp-separated
 and thus it is an implicit part of the grammar. In order not to make the parser more complex,
 whitespace token separation is internally handled in the scanner.
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

%x PNAM IDENT TYP DATA DATAN ERROR UNKWN

IDENTPART		[A-Za-z0-9_]+
NAMEPART		[-A-Za-z0-9_]+
TYPECHAR		[\x21-\x7e]
SPOREOL			[ \t\n]

%{
	#include "parser.tab.h"
	extern void yyerror(const char *, ...);
	extern int no_nl;
	static const char *obj;
	static int seen;
%}

%%
	/* new lines */
<*>\n			{ seen = 0; BEGIN(INITIAL); return NEWLINE; }

	/* comments */
<*>#.*			/* ignore comments */

	/* keywords */
package/{SPOREOL}	{ BEGIN(PNAM); return PACKAGE; }
config/{SPOREOL}	{ BEGIN(TYP); return CONFIG; }
(option|list)/{SPOREOL}	{ BEGIN(IDENT); return OPTION; }

	/* package names */
<PNAM>{NAMEPART}		|
<PNAM>'{NAMEPART}'		|
<PNAM>\"{NAMEPART}\"		{ seen = 1; return NAME; }

	/* types */
<TYP>(\\{TYPECHAR}|[\x21-\x7e]{-}['\"\\])+	|
<TYP>'(\\{TYPECHAR}|[\x21-\x7e]{-}['\\])+'	|
<TYP>\"(\\{TYPECHAR}|[\x21-\x7e]{-}[\"\\])+\"	{ seen = 1; return TYPE; }

	/* identifiers */
<IDENT>{IDENTPART}		|
<IDENT>'{IDENTPART}'		|
<IDENT>\"{IDENTPART}\"		{ seen = 1; return IDENTIFIER; }

	/* values */
<DATA,DATAN>(\\.|[\x21-\xff]{-}['\"\\])+	|	/* unquoted, without whitespace, possibly escaped */
<DATAN>'(\\.|[\t \x21-\xff]{-}['\\])*'		|	/* single quoted, no newline, possibly escaped */
<DATAN>\"(\\.|[\t \x21-\xff]{-}[\"\\])*\"	|	/* double quoted, no newline, possibly escaped */
<DATA>'(\\.|[\t\n\r \x21-\xff]{-}['\\])*'	|	/* single quoted, possibly escaped */
<DATA>\"(\\.|[\t\n\r \x21-\xff]{-}[\"\\])*\"	{	/* double quoted, possibly escaped */
							seen = 1; return VALUE;
						}

			/* error reporting: one error per line */
<ERROR>.+		{ yyerror("invalid %s input starting at: %s", obj, yytext); } /* ignore rest of line */

<*>[ \t]+		{
				/* use whitespace after seen input to switch to next start state */
				if (seen) {
					switch (YY_START) {
					case TYP:	/* identifier after type */
						BEGIN(IDENT);
						break;
					case IDENT:	/* value after identifier */
						BEGIN(no_nl ? DATAN : DATA);
						break;
					/* all other cases are unknown input (unless comments):
					   no "seen" in INITIAL, nothing else after NAME or VALUE */
					default:
						BEGIN(UNKWN);
						break;
					}
					seen = 0;
				}
				/* else ignore */
			}

	/* catch-all for unmatched input */
<*>.			{
				switch (YY_START) {
				case INITIAL:
					obj = "keyword";
					break;
				case PNAM:
					obj = "name";
					break;
				case TYP:
					obj = "type";
					break;
				case IDENT:
					obj = "indentifier";
					break;
				case DATA:
				case DATAN:
					obj = "value";
					break;
				default:
					obj = "unknown";
					break;
				}
				BEGIN(ERROR); yyless(0);
				return YYerror;
}

<<EOF>>			{ yyterminate(); }
%%
