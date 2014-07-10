Lexer = require("lex")

col = 0
row = 0

IntoMammouth = false
IntoArray = false

IndentStack = []
CurrentIndent = -1
OpenedIndent = 0

# Create a new lexer
lexer = module.exports = new Lexer (char) ->
	throw new Error "Unexpected character at row " + row + ", col " + col + ": " + char

RegularExpression =
	PlainText: /// (
		(
			(
				?!(
					{{
					|}}
				)
			)
			.
		)*
	) ///
	MammouthStart: /// {{ ///
	MammouthEnd: /// }} ///
	Python_indent: /(^[ \t]*)/gm
	EmptyLine: /(^[\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000]*[\n\r\u2028\u2029])/gmi

	# Value
	IDENTIFIER: /(([$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/
	NUMBER: /(0b[01]+|0o[0-7]+|0x[\da-f]+|\d*\.?\d+(?:e[+-]?\d+)?)/
	STRING: /('[^\\']*(?:\\[\s\S][^\\']*)*'|"[^\\"]*(?:\\[\s\S][^\\"]*)*")/
	BOOL: /true|false/

	LineTerminator: /[\n\r\u2028\u2029]/
	Zs: /[\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000]/

# check for plain text
lexer.addRule RegularExpression.PlainText, (lexeme) ->
	if not IntoMammouth
		col += lexeme.length
		@yytext = lexeme
		return "PlainText"
	else
		@reject = true

# Detect Empty line 
lexer.addRule RegularExpression.EmptyLine, (lexeme) ->
	col += lexeme.length
	return 'BLANKLINE'

# Python-like Indent
lexer.addRule RegularExpression.Python_indent, (lexeme) ->
	if IntoArray
		@reject = true
	if IntoMammouth
		col += lexeme.length
		current_line_indent = lexeme.replace(/\t/g,'    ').length
		if current_line_indent > CurrentIndent
			CurrentIndent = current_line_indent
			OpenedIndent++
			IndentStack.push CurrentIndent
			return ['INDENT', 'SAMEDENT']
		else if current_line_indent < CurrentIndent

			tokens = []
			a = []
			for i in IndentStack
				a.unshift i
			for i in a
				if current_line_indent is i
					CurrentIndent = i
					tokens.push 'SAMEDENT'
				else if current_line_indent < i
					CurrentIndent = IndentStack.pop()
					tokens.push 'DEDENT'
					OpenedIndent -= 1
			return tokens
		else
			return 'SAMEDENT'

# Skip Whitespace
lexer.addRule RegularExpression.Zs, (lexeme) ->

# Mammouth block start and end
lexer.addRule RegularExpression.MammouthStart, ->
	col += 2
	IntoMammouth = true
	return "{{"

lexer.addRule RegularExpression.MammouthEnd, ->
	col += 2
	IntoMammouth = false
	tokens = ["}}"]
	while OpenedIndent > 0
		tokens.unshift 'DEDENT'
		OpenedIndent--
	return tokens

############### Symbols
# Parens
lexer.addRule /\(/, (lexeme) ->
	col += lexeme.length
	return "("

lexer.addRule /\)/, (lexeme) ->
	col += lexeme.length
	return ")"

# Array
lexer.addRule /\[/, (lexeme) ->
	col += lexeme.length
	IntoArray = true
	return "["

lexer.addRule /\]/, (lexeme) ->
	col += lexeme.length
	IntoArray = false
	return "]"

# Comma
lexer.addRule /,/, (lexeme) ->
	col += lexeme.length;
	return ",";

# ::
lexer.addRule /::/, (lexeme) ->
	col += lexeme.length;
	return "::";

# :
lexer.addRule /:/, (lexeme) ->
	col += lexeme.length;
	return ":";

# ..
lexer.addRule /\.\./, (lexeme) ->
	col += lexeme.length
	return ".."

# .
lexer.addRule /\./, (lexeme) ->
	col += lexeme.length
	return "."

# <->
lexer.addRule /<->/, (lexeme) ->
	col += lexeme.length;
	return "<->";

# ->
lexer.addRule /->/, (lexeme) ->
	col += lexeme.length;
	return "->";

# --
lexer.addRule /--/, (lexeme) ->
	col += lexeme.length;
	return "--";

# ++
lexer.addRule /\+\+/, (lexeme) ->
	col += lexeme.length;
	return "++";

# ** for Math power
lexer.addRule /\*\*/, (lexeme) ->
	col += lexeme.length;
	return "**";

# ||
lexer.addRule /\|\|/, (lexeme) ->
	col += lexeme.length;
	@yytext = '||'
	return "LOGIC";

# &&
lexer.addRule /&&/, (lexeme) ->
	col += lexeme.length;
	@yytext = 'and'
	return "LOGIC";

# |
lexer.addRule /\|/, (lexeme) ->
	col += lexeme.length;
	@yytext = 'or'
	return "LOGIC";

# &
lexer.addRule /&/, (lexeme) ->
	col += lexeme.length;
	@yytext = 'and'
	return "&";

# ~ or !
lexer.addRule /!|~/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "NOT";

# -
lexer.addRule /-/, (lexeme) ->
	col += lexeme.length;
	return "-";

# +
lexer.addRule /\+/, (lexeme) ->
	col += lexeme.length;
	return "+";

# *
lexer.addRule /\*/, (lexeme) ->
	col += lexeme.length;
	return "*";

# /
lexer.addRule /\//, (lexeme) ->
	col += lexeme.length;
	return "/";

# %
lexer.addRule /%/, (lexeme) ->
	col += lexeme.length;
	return "%";

# ?
lexer.addRule /\?/, (lexeme) ->
	col += lexeme.length;
	return "?";

# >>
lexer.addRule />>/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "SHIFT";

# <<
lexer.addRule /<</, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "SHIFT";

# <
lexer.addRule /</, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "COMPARE";

# >
lexer.addRule />/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "COMPARE";

# <=
lexer.addRule /<=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "COMPARE";

# >=
lexer.addRule />=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "COMPARE";

# !=
lexer.addRule /!\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "COMPARE";

# ==
lexer.addRule /\=\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "COMPARE";

# ===
lexer.addRule /\=\=\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "COMPARE";

# =
lexer.addRule /\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "=";

# +=
lexer.addRule /\+\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "ASSIGN";

# -=
lexer.addRule /-\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "ASSIGN";

# *=
lexer.addRule /\*\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "ASSIGN";

# /=
lexer.addRule /\/\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "ASSIGN";

# %=
lexer.addRule /\%\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	return "ASSIGN";

############### Vlaue
lexer.addRule RegularExpression.BOOL, (lexeme) ->
	col += lexeme.length
	if lexeme is 'true'
		@yytext = true
	else if lexeme is 'false'
		@yytext = false
	return "BOOL"

# Identifier
lexer.addRule RegularExpression.IDENTIFIER, (lexeme) ->
	col += lexeme.length
	if lexeme is "cte"
		return "cte"
	else if lexeme is "use"
		return "use"
	else if lexeme is "and"
		@yytext = "and"
		return "LOGIC"
	else if lexeme is "or"
		@yytext = "or";
		return "LOGIC"
	else if lexeme is "not"
		@yytext = "!";
		return "NOT"
	else if lexeme is "is"
		@yytext = "===";
		return "COMPARE"
	else if lexeme is 'in'
		@yytext = "IN";
		return 'RELATION'
	else if lexeme is 'echo'
		return 'ECHO'
	else if lexeme is 'return'
		return 'RETURN'
	else if lexeme is 'break'
		return 'BREAK'
	else if lexeme is 'continue'
		return 'CONTINUE'
	else if lexeme is 'include'
		return 'INCLUDE'
	else if lexeme is 'require'
		return 'REQUIRE'
	else if lexeme is 'once'
		return 'ONCE'
	else if lexeme is 'if'
		return 'IF'
	else if lexeme is 'else'
		return 'ELSE'
	else if lexeme is 'then'
		return 'THEN'
	else if lexeme is 'while'
		return 'WHILE'
	else if lexeme is 'def'
		return 'DEF'
	else
		@yytext = lexeme;
		return "IDENTIFIER";

# Number
lexer.addRule RegularExpression.NUMBER, (lexeme) ->
	col += lexeme.length;
	@yytext = parseFloat lexeme;
	return "NUMBER";

# String
lexer.addRule RegularExpression.STRING, (lexeme) ->
	col += lexeme.length;
	@yytext = if lexeme[0] is '"' then lexeme.replace /"/g, '' else if lexeme[0] is '"' then lexeme.replace /'/g, '';
	return "STRING";

# Line terminator
lexer.addRule RegularExpression.LineTerminator, (lexeme) ->
	col = 1
	row++
	return "LineTerminator"