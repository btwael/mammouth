Lexer = require "lex"

col = 1
row = 1

IntoArray = false
IntoMammouth = false
IntoHereDoc = false

Levels = [
	{
		IndentStack: []
		CurrentIndent: -1
		OpenedIndent: 0
	}
]

lastIsIdentifier = false
ShouldCloseCall = false
captureTypeCasting  =false
tokenStack = []

setToken = (token) ->
	if token is 'IDENTIFIER' and tokenStack[0] isnt 'FUNC'
		lastIsIdentifier = true
	else
		lastIsIdentifier = false
		if token is '=>'
			captureTypeCasting = true
		else
			captureTypeCasting = false
	tokenStack.unshift(token)

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
	NUMBER: /(0b[01]+|0o[0-7]+|0(x|X)[\da-fA-F]+|\d*\.?\d+(?:(e|E)[+-]?\d+)?)/
	STRING: /('[^\\']*(?:\\[\s\S][^\\']*)*'|"[^\\"]*(?:\\[\s\S][^\\"]*)*")/

	# HEREDOC
	HEREDOC: /// (
		(
			(
				?!(
					\`
				)
			)
			(.|[\n\r\u2028\u2029]|[\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000])
		)*
	) ///

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

# HEREDOC
lexer.addRule RegularExpression.HEREDOC, (lexeme) ->
	if IntoMammouth and IntoHereDoc
		col += lexeme.length
		@yytext = lexeme
		setToken('HEREDOCTEXT')
		return 'HEREDOCTEXT'
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
lexer.addRule /\`/, (lexeme) ->
	col += lexeme.length
	if IntoHereDoc
		IntoHereDoc = false
	else
		IntoHereDoc = true
	setToken('`')
	return '`'

lexer.addRule /\{/, (lexeme) ->
	col += lexeme.length
	setToken('{')
	return '{'

lexer.addRule /\}/, (lexeme) ->
	col += lexeme.length
	setToken('}')
	return '}'

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

lexer.addRule /\;/, (lexeme) ->
	col += lexeme.length
	setToken(';')
	return ';'

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

lexer.addRule /\=>/, (lexeme) ->
	col += lexeme.length
	setToken('=>')
	return '=>'

lexer.addRule /\=\=>/, (lexeme) ->
	col += lexeme.length
	setToken('==>')
	return '==>'

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

lexer.addRule /\\/, (lexeme) ->
	col += lexeme.length
	setToken('\\')
	return '\\'

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
	if captureTypeCasting
		@yytext = lexeme
		setToken('cType')
		return 'cType'
	if lexeme in ['true', 'false']
		@yytext = eval lexeme
		setToken('BOOL')
		return 'BOOL'
	else if lexeme is 'break'
		setToken('BREAK')
		return 'BREAK' 
	else if lexeme is 'and'
		@yytext = lexeme
		setToken('LOGIC')
		return 'LOGIC'
	else if lexeme is 'abstract'
		setToken('ABSTRACT')
		return 'ABSTRACT'
	else if lexeme is 'as'
		setToken('AS')
		return 'AS'
	else if lexeme is 'catch'
		setToken('CATCH')
		return 'CATCH'
	else if lexeme is 'case'
		setToken('CASE')
		return 'CASE'
	else if lexeme is 'class'
		setToken('CLASS')
		return 'CLASS'
	else if lexeme is 'clone'
		setToken('CLONE')
		return 'CLONE'
	else if lexeme is 'continue'
		setToken('CONTINUE')
		return 'CONTINUE'
	else if lexeme is 'cte'
		setToken('CTE')
		return 'CTE'
	else if lexeme is 'declare'
		setToken('DECLARE')
		return 'DECLARE'
	else if lexeme is 'delete'
		setToken('DELETE')
		return 'DELETE'
	else if lexeme is 'do'
		setToken('DO')
		return 'DO'
	else if lexeme is 'each'
		setToken('EACH')
		return 'EACH'
	else if lexeme is 'echo'
		setToken('ECHO')
		return 'ECHO'
	else if lexeme is 'else'
		setToken('ELSE')
		return 'ELSE'
	else if lexeme is 'exec'
		setToken('EXEC')
		return 'EXEC'
	else if lexeme is 'extends'
		setToken('EXTENDS')
		return 'EXTENDS'
	else if lexeme is 'final'
		setToken('FINAL')
		return 'FINAL'
	else if lexeme is 'finally'
		setToken('FINALLY')
		return 'FINALLY'
	else if lexeme is 'for'
		setToken('FOR')
		return 'FOR'
	else if lexeme is 'func'
		setToken('FUNC')
		return 'FUNC'
	else if lexeme is 'goto'
		setToken('GOTO')
		return 'GOTO'
	else if lexeme is 'if'
		setToken('IF')
		return 'IF'
	else if lexeme is 'implements'
		setToken('IMPLEMENTS')
		return 'IMPLEMENTS'
	else if lexeme is 'include'
		setToken('INCLUDE')
		return 'INCLUDE'
	else if lexeme is 'instanceof'
		setToken('INSTANCEOF')
		return 'INSTANCEOF'
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
	else if lexeme is 'namespace'
		setToken('NAMESPACE')
		return 'NAMESPACE'
	else if lexeme is 'new'
		setToken('NEW')
		return 'NEW'
	else if lexeme is 'null'
		setToken('NULL')
		return 'NULL'
	else if lexeme is 'once'
		setToken('ONCE')
		return 'ONCE'
	else if lexeme is 'or'
		@yytext = lexeme
		setToken('LOGIC')
		return 'LOGIC'
	else if lexeme is 'public'
		setToken('PUBLIC')
		return 'PUBLIC'
	else if lexeme is 'private'
		setToken('PRIVATE')
		return 'PRIVATE'
	else if lexeme is 'protected'
		setToken('PROTECTED')
		return 'PROTECTED'
	else if lexeme is 'static'
		setToken('STATIC')
		return 'STATIC'
	else if lexeme is 'require'
		setToken('REQUIRE')
		return 'REQUIRE'
	else if lexeme is 'return'
		setToken('RETURN')
		return 'RETURN'
	else if lexeme is 'switch'
		setToken('SWITCH')
		return 'SWITCH'
	else if lexeme is 'then'
		setToken('THEN')
		return 'THEN'
	else if lexeme is 'try'
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