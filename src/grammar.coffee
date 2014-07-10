o = (patternString, action) ->
	if action?
		if action is false 
			return [patternString, '']
		if typeof action is 'number'
			return [patternString, '$$ = $' + action + ';']
		else
			return [patternString, action]
	else
		return [patternString, '$$ = $1;']

grammar =
	# Starting from here
	Root: [
		o 'Contents', 'return $1'
	]

	Contents: [
		o 'Content', '$$ = [$1]'
		o 'Contents Content', '$$ = $1.concat($2)'
	]

	Content: [
		o 'PlainBlock'
		o 'MammouthBlock'
	]

	PlainBlock: [
		o 'PlainText', '$$ = new yy.PlainBlock(yytext)'
	]

	MammouthBlock: [
		o '{{ Block }}', '$$ = new yy.MammouthBlock($2)'
	]

	Block: [
		o 'LineTerminator INDENT Lines DEDENT', '$$ = new yy.Block($3)'
	]

	Lines: [
		o 'Line', '$$ = [$1]'
		o 'Lines Line', '$$ = $1.concat($2);'
	]
	
	Line: [
		o 'BLANKLINE', '$$ = new yy.BlankLine()'
		o 'SAMEDENT OptionalLineTerminator', '$$ = new yy.BlankLine()'
		o 'SAMEDENT SimpleStatement OptionalLineTerminator', 2
		o 'SAMEDENT Expression OptionalLineTerminator', '$$ = new yy.Expression($2)'
		o 'SAMEDENT FunctionCode OptionalLineTerminator', 2
		o 'If'
		o 'SAMEDENT While OptionalLineTerminator', '$$ = new yy.Expression($2)'
	]

	Expression: [
		o 'Value'
		o 'Invocation'
		o 'Code'
		o 'Operation'
		o 'Assign'
		o 'IfExpression'
	]

	######## Values
	Value: [
		o 'Assignable'
		o 'Literal'
		o 'Parenthetical'
	]

	Parenthetical: [
		o '( Expression )', '$$ = new yy.Parens($2)'
	]

	Assignable: [
		o 'SimpleAssignable'
		o 'Array', '$$ = new yy.Value($1)'
	]

	SimpleAssignable: [
		o 'Identifier', '$$ = new yy.Value($1)'
		o 'Value Accessor', '$1.add($2); $$ = $1'
	]

	Accessor: [
		o '.. Identifier', '$$ = new yy.Access($2, "..")'
		o '. Identifier', '$$ = new yy.Access($2)'
		o '-> Identifier', '$$ = new yy.Access($2, "->")'
		o ':: Identifier', '$$ = new yy.Access($2, "::")'
		o '[ Expression ]', '$$ = new yy.Access($2, "[]")'
	]

	Identifier: [
		o 'IDENTIFIER', '$$ = new yy.Identifier(yytext)'
		o '& IDENTIFIER', '$$ = new yy.PassingIdentifier(yytext)'
	]

	Literal: [
		o 'AlphaNumeric'
		o 'BOOL', '$$ = new yy.Bool(yytext)'
	]

	AlphaNumeric: [
		o 'NUMBER', '$$ = new yy.Literal(yytext)'
		o 'STRING', '$$ = new yy.Literal(yytext)'
	]

	# Array
	Array: [
		o '[ ]', '$$ = new yy.Array()'
		o '[ ArgList OptionalComma ]', '$$ = new yy.Array($2)'
	]

	ArgList: [
		o 'Arg', '$$ = [$1]'
		o 'ArgList , Arg', '$$ = $1.concat($3)'
		o 'ArgList OptionalComma LineTerminator Arg', '$$ = $1.concat($4)'
	]

	Arg: [
		o 'Expression : Expression', '$$ = new yy.ArrayKey($1, $3)'
		o 'Expression'
	]

	# Invocation
	Invocation: [
		o 'Value Arguments', '$$ = new yy.Call($1, $2)'
	]

	Arguments: [
		o '( )', '$$ = []'
		o '( ArgList OptionalComma )', 2
	]

	# Variable Function
	Code: [
		o '( ParametersList ) FuncGlyph Block', '$$ = new yy.Code($2, $5)'
		o 'FuncGlyph Block', '$$ = new yy.Code([], $2)'
	]

	FuncGlyph: [
		o '->', '$$ = "->"'
	]

	ParametersList: [
		o '', '$$ = []'
		o 'Param', '$$ = [$1]'
		o 'ParametersList , Param', '$$ = $1.concat($3);'
	]

	Param: [
		o 'ParamVar'
		o 'use ParamVar', '$2.and = true, $$ = $2'
		o 'ParamVar = Expression', '$$ = new yy.Assign("=", $1, $3)'
	]

	ParamVar: [
		o 'Identifier'
	]

	# Assign
	Assign: [
		o 'Assignable = Expression', '$$ = new yy.Assign("=", $1, $3)'
		o 'cte Identifier = Expression', '$$ = new yy.Constant($2, $4)'
	]

	# Operation
	Operation: [
		o '-- Expression', '$$ = new yy.Update("--", $2)'
		o '++ Expression', '$$ = new yy.Update("++", $2)'
		o 'SimpleAssignable --', '$$ = new yy.Update("--", $1, false)'
		o 'SimpleAssignable ++', '$$ = new yy.Update("++", $1, false)'

		o 'NOT Expression', '$$ = new yy.Unary($1, $2)'

		o '- Expression', '$$ = new yy.Unary("-", $2)'
		o '+ Expression', '$$ = new yy.Unary("+", $2)'

		o 'Expression ?', '$$ = new yy.Existence($1)'

		o 'Expression + Expression', '$$ = new yy.Operation("+", $1, $3)'
		o 'Expression <-> Expression', '$$ = new yy.Operation("<->", $1, $3)'
		o 'Expression - Expression', '$$ = new yy.Operation("-", $1, $3)'
		o 'Expression * Expression', '$$ = new yy.Operation("*", $1, $3)'
		o 'Expression ** Expression', '$$ = new yy.Operation("**", $1, $3)'
		o 'Expression / Expression', '$$ = new yy.Operation("/", $1, $3)'
		o 'Expression % Expression', '$$ = new yy.Operation("%", $1, $3)'

		o 'Expression SHIFT Expression', '$$ = new yy.Operation($2, $1, $3)'
		o 'Expression LOGIC Expression', '$$ = new yy.Operation($2, $1, $3)'
		o 'Expression LOGIC Expression', '$$ = new yy.Operation("&", $1, $3)'
		o 'Expression COMPARE Expression', '$$ = new yy.Operation($2, $1, $3)'

		o 'SimpleAssignable ASSIGN Expression', '$$ = new yy.Assign($2, $1, $3)'

		o 'Expression RELATION Expression', '$$ = new yy.Operation($2, $1, $3)'
	]

	######## Statement
	Statement: [
		o 'SimpleStatement'
	]

	SimpleStatement: [
		o 'EchoStatement'
		o 'ReturnStatement'
		o 'BreakStatement'
		o 'ContinueStatement'
		o 'IncludeStatement'
		o 'RequireStatement'
	]

	EchoStatement: [
		o 'ECHO ( Expression )', '$$ = new yy.EchoStatement($3)'
		o 'ECHO Expression', '$$ = new yy.EchoStatement($2)'
	]

	ReturnStatement: [
		o 'RETURN', '$$ = new yy.ReturnStatement()'
		o 'RETURN Expression', '$$ = new yy.ReturnStatement($2)'
	]

	BreakStatement: [
		o 'BREAK', '$$ = new yy.BreakStatement()'
		o 'BREAK Expression', '$$ = new yy.BreakStatement($2)'
	]

	ContinueStatement: [
		o 'CONTINUE', '$$ = new yy.ContinueStatement()'
		o 'CONTINUE Expression', '$$ = new yy.ContinueStatement($2)'
	]

	IncludeStatement: [
		o 'INCLUDE isOnce Expression', '$$ = new yy.IncludeStatement($3, $2)'
	]

	RequireStatement: [
		o 'REQUIRE isOnce Expression', '$$ = new yy.RequireStatement($3, $2)'
	]

	isOnce: [
		o '', '$$ = false'
		o 'ONCE', '$$ = true'
	]

	# IF
	If: [
		o 'IfBlock'
		o 'IfBlock SAMEDENT ELSE Block OptionalLineTerminator', '$1.addElse($4); $$ = $1'
	]

	IfBlock: [
		o 'SAMEDENT IF Expression Block OptionalLineTerminator', '$$ = new yy.If($3, $4)'
		o 'IfBlock SAMEDENT ELSE IF Expression Block OptionalLineTerminator', '$1.addElseIf($5, $6); $$ = $1' 
	]

	IfExpression: [
		o 'IfBlockExpression'
		o 'IfBlockExpression ELSE Expression', '$1.Elses = $3; $$ = $1'
	]

	IfBlockExpression: [
		o 'IF Expression THEN Expression', '$$ = new yy.If($2, $4, true)'
		o 'Expression IF Expression', '$$ = new yy.If($3, $1, true)'
	]

	# While
	While: [
		o 'WHILE Expression Block', '$$ = new yy.While($2, $3)'
	]

	# Function Code
	FunctionCode: [
		o 'DEF IDENTIFIER ( ParametersList ) FuncGlyph Block', '$$ = new yy.Code($4, $7, true, $2)'
		o 'DEF IDENTIFIER FuncGlyph Block', '$$ = new yy.Code([], $3, true, $2)'
	]

	# Comma
	OptionalComma: [
		o '', false
		o ',', false
	]
	# Optional Line Terminator
	OptionalLineTerminator: [
		o '', false
		o 'LineTerminator', false
	]

operators = [
	['left', '+', '-', '<->']
	['left', '*', '/', '%', '**']
	['left', 'SHIFT', 'LOGIC', '&', 'COMPARE', 'RELATION']
	['left', '.']
	['nonassoc', '++', '--', 'NOT', 'cte']
	['left', '?']
	['right', '=', 'ASSIGN']
	['right', 'IF', 'THEN', 'ELSE', 'WHILE']
]
{Parser} = require 'jison'

module.exports = new Parser
	bnf : grammar
	operators: operators