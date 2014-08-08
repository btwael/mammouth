Lexer = require("lex")

col = 1
row = 1

IntoArray = false
IntoMammouth = false

Levels = [
	{
		IndentStack: []
		CurrentIndent: -1
		OpenedIndent: 0
	}
]

lastIsIdentifier = false
ShouldCloseCall = false

setToken = (token) ->
	if token is 'IDENTIFIER'
		lastIsIdentifier = true
	else
		lastIsIdentifier = false

CloseIndents = (tokens) ->
	while Levels[0].OpenedIndent > 0
		tokens.unshift 'OUTDENT'
		Levels[0].OpenedIndent--
	return tokens

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
		setToken('PlainText')
		return 'PlainText'
	else
		@reject = true

# Skip Empty line 
lexer.addRule RegularExpression.EmptyLine, (lexeme) ->

# Python like-indentation
lexer.addRule RegularExpression.Python_indent, (lexeme) ->
	if IntoMammouth
		col += lexeme.length
		current_line_indent = lexeme.replace(/\t/g,'    ').length
		if current_line_indent > Levels[0].CurrentIndent
			Levels[0].CurrentIndent = current_line_indent
			Levels[0].OpenedIndent++
			Levels[0].IndentStack.push Levels[0].CurrentIndent
			setToken('INDENT')
			return 'INDENT'
		else if current_line_indent < Levels[0].CurrentIndent
			tokens = []
			a = []
			for i in Levels[0].IndentStack
				a.unshift i
			for i in a
				if current_line_indent is i
					Levels[0].CurrentIndent = i
				else if current_line_indent < i
					Levels[0].CurrentIndent = Levels[0].IndentStack.pop()
					setToken('OUTDENT')
					tokens.push 'OUTDENT'
					Levels[0].OpenedIndent -= 1
			return tokens
		else
			#

# Skip Whitespace
lexer.addRule RegularExpression.Zs, (lexeme) ->

# Mammouth block start and end
lexer.addRule RegularExpression.MammouthStart, ->
	col += 2
	IntoMammouth = true
	setToken('{{')
	return '{{'

lexer.addRule RegularExpression.MammouthEnd, ->
	col += 2
	IntoMammouth = false
	tokens = CloseIndents(['}}'])
	for token in tokens
		setToken(token)
	return tokens

# Symbols
lexer.addRule /\(/, (lexeme) ->
	col += lexeme.length
	if lastIsIdentifier
		lastIsIdentifier = false
		ShouldCloseCall = true
		setToken('CALL_START')
		return 'CALL_START'
	else
		setToken('(')
		return '('

lexer.addRule /\)/, (lexeme) ->
	col += lexeme.length
	if ShouldCloseCall
		ShouldCloseCall = false
		setToken('CALL_END')
		return 'CALL_END'
	else
		setToken(')')
		return ')'

lexer.addRule /\[/, (lexeme) ->
	col += lexeme.length
	setToken('[')
	return '['

lexer.addRule /\]/, (lexeme) ->
	col += lexeme.length
	setToken(']')
	return ']'

lexer.addRule /,/, (lexeme) ->
	col += lexeme.length
	setToken(',')
	return ','

lexer.addRule /\./, (lexeme) ->
	col += lexeme.length
	setToken('.')
	return '.'

lexer.addRule /\.\./, (lexeme) ->
	col += lexeme.length
	setToken('..')
	return '..'

lexer.addRule /<->/, (lexeme) ->
	col += lexeme.length
	setToken('<->')
	return '<->'

lexer.addRule /->/, (lexeme) ->
	col += lexeme.length
	setToken('->')
	return '->'

lexer.addRule /:/, (lexeme) ->
	col += lexeme.length
	setToken(':')
	return ':'

lexer.addRule /::/, (lexeme) ->
	col += lexeme.length
	setToken('::')
	return '::'

lexer.addRule /\+/, (lexeme) ->
	col += lexeme.length
	setToken('+')
	return '+'

lexer.addRule /\+\+/, (lexeme) ->
	col += lexeme.length
	setToken('++')
	return '++'

lexer.addRule /-/, (lexeme) ->
	col += lexeme.length
	setToken('-')
	return '-'

lexer.addRule /--/, (lexeme) ->
	col += lexeme.length
	setToken('--')
	return '--'

lexer.addRule /\?/, (lexeme) ->
	col += lexeme.length
	setToken('?')
	return '?'

lexer.addRule /\*/, (lexeme) ->
	col += lexeme.length
	setToken('*')
	return '*'

lexer.addRule /\*\*/, (lexeme) ->
	col += lexeme.length
	setToken('**')
	return '**'

lexer.addRule /\//, (lexeme) ->
	col += lexeme.length
	setToken('/')
	return '/'

lexer.addRule /%/, (lexeme) ->
	col += lexeme.length
	setToken('%')
	return '%'

lexer.addRule /\+\=/, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('ASSIGN')
	return "ASSIGN"

lexer.addRule /-\=/, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('ASSIGN')
	return "ASSIGN"

lexer.addRule /\*\=/, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('ASSIGN')
	return "ASSIGN"

lexer.addRule /\/\=/, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('ASSIGN')
	return "ASSIGN"

lexer.addRule /\%\=/, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('ASSIGN')
	return "ASSIGN"

lexer.addRule /&/, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('&')
	return "&"

lexer.addRule />>/, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('>>')
	return "SHIFT"

lexer.addRule /<</, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('<<')
	return 'SHIFT'

lexer.addRule /\|\|/, (lexeme) ->
	col += lexeme.length;
	@yytext = '||'
	setToken('LOGIC')
	return 'LOGIC';

lexer.addRule /&&/, (lexeme) ->
	col += lexeme.length;
	@yytext = 'and'
	setToken('LOGIC')
	return 'LOGIC';

lexer.addRule /\|/, (lexeme) ->
	col += lexeme.length;
	@yytext = 'or'
	setToken('LOGIC')
	return 'LOGIC'

lexer.addRule /</, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	setToken('COMPARE')
	return "COMPARE";

lexer.addRule />/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	setToken('COMPARE')
	return "COMPARE";

lexer.addRule /<=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	setToken('COMPARE')
	return "COMPARE";

lexer.addRule />=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	setToken('COMPARE')
	return "COMPARE";

lexer.addRule /!\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	setToken('COMPARE')
	return "COMPARE";

lexer.addRule /\=\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	setToken('COMPARE')
	return "COMPARE";

lexer.addRule /\=\=\=/, (lexeme) ->
	col += lexeme.length;
	@yytext = lexeme
	setToken('COMPARE')
	return "COMPARE";

lexer.addRule /\=/, (lexeme) ->
	col += lexeme.length
	setToken('=')
	return "="

# Identifier and reserved words
lexer.addRule RegularExpression.IDENTIFIER, (lexeme) ->
	col += lexeme.length
	if lexeme in ['true', 'false']
		@yytext = eval lexeme
		setToken('BOOL')
		return 'BOOL'
	else if lexeme is 'and'
		@yytext = lexeme
		setToken('LOGIC')
		return 'LOGIC'
	else if lexeme is 'catch'
		@yytext = lexeme
		setToken('CATCH')
		return 'CATCH'
	else if lexeme is 'case'
		setToken('CASE')
		return 'CASE'
	else if lexeme is 'cte'
		@yytext = lexeme
		setToken('CTE')
		return 'CTE'
	else if lexeme is 'else'
		@yytext = lexeme
		setToken('ELSE')
		return 'ELSE'
	else if lexeme is 'finally'
		@yytext = lexeme
		setToken('FINALLY')
		return 'FINALLY'
	else if lexeme is 'func'
		setToken('FUNC')
		return 'FUNC'
	else if lexeme is 'if'
		@yytext = lexeme
		setToken('IF')
		return 'IF'
	else if lexeme is "is"
		@yytext = "==="
		setToken('COMPARE')
		return "COMPARE"
	else if lexeme is "isnt"
		@yytext = "!="
		setToken('COMPARE')
		return "COMPARE"
	else if lexeme is "in"
		setToken('IN')
		return "IN"
	else if lexeme is 'not'
		setToken('NOT')
		return 'NOT'
	else if lexeme is 'or'
		@yytext = lexeme
		setToken('LOGIC')
		return 'LOGIC'
	else if lexeme is 'switch'
		setToken('SWITCH')
		return 'SWITCH'
	else if lexeme is 'try'
		@yytext = lexeme
		setToken('TRY')
		return 'TRY'
	else if lexeme is 'use'
		setToken('USE')
		return 'USE'
	else if lexeme is 'when'
		setToken('WHEN')
		return 'WHEN'
	else if lexeme is 'while'
		setToken('WHILE')
		return 'WHILE'
	else
		@yytext = lexeme
		setToken('IDENTIFIER')
		return "IDENTIFIER"

# Number
lexer.addRule RegularExpression.NUMBER, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('NUMBER')
	return "NUMBER"

# String
lexer.addRule RegularExpression.STRING, (lexeme) ->
	col += lexeme.length
	@yytext = lexeme
	setToken('STRING')
	return "STRING"

# Line Terminator
lexer.addRule RegularExpression.LineTerminator, (lexeme) ->
	col = 1
	row++
	setToken('LineTerminator')
	return "LineTerminator"