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

%x PNAM IDENT TYP DATA ERROR

IDENTPART		[A-Za-z0-9_]+
NAMEPART		[-A-Za-z0-9_]+
TYPEPART		[\x21-\x7e]{-}['\"]+

%{
	#include "parser.tab.h"
	extern void yyerror(const char *, ...);
	static const char *obj;
	static int flags;
	enum {
		FL_CHKSP = 0x01,
		FL_SP = 0x02,
	};
%}

%%
	/* new lines */
<*>\n		{ flags = 0; BEGIN(INITIAL); return NEWLINE; }

	/* comments */
<*>#.*			/* ignore comments */

	/* keywords */
package		{ BEGIN(PNAM); return PACKAGE; }
config		{ BEGIN(TYP); return CONFIG; }
option		|
list		{ BEGIN(IDENT); return OPTION; }

	/* package names */
<PNAM>{NAMEPART}		|
<PNAM>'{NAMEPART}'		|
<PNAM>\"{NAMEPART}\"		{ return NAME; }

	/* types */
<TYP>{TYPEPART}			|
<TYP>'{TYPEPART}'		|
<TYP>\"{TYPEPART}\"		{ BEGIN(IDENT); return TYPE; }

	/* identifiers */
<IDENT>{IDENTPART}		|
<IDENT>'{IDENTPART}'		|
<IDENT>\"{IDENTPART}\"		{ BEGIN(DATA); return IDENTIFIER; }

	/* values */
<DATA>(\\.|[\x21-\xff]{-}['\"])+		|	/* unquoted, without whitespace, possibly escaped */
<DATA>'(\\.|[\t\n\r \x21-\xff]{-}['])*'		|	/* single quoted, possibly escaped */
<DATA>\"(\\.|[\t\n\r \x21-\xff]{-}[\"])*\"	{	/* double quoted, possibly escaped */
				flags |= FL_CHKSP;
				if (flags & FL_SP) {
					yyerror("spurious whitespace in value");
					return YYerror;
				}
				return VALUE;
			}

			/* error reporting: one error per line */
<ERROR>.+		{ yyerror("invalid %s input starting at: %s", obj, yytext); } /* ignore rest of line */

<*>[ \t]+		{ if (flags & FL_CHKSP) flags |= FL_SP; } /* ignore whitespace */

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
