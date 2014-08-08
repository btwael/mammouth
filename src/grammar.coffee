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
		o 'INDENT Lines OUTDENT', '$$ = new yy.Block($2)'
		o 'LineTerminator INDENT Lines OUTDENT', '$$ = new yy.Block($3)'
	]

	Lines: [
		o 'Line', '$$ = [$1]'
		o 'Lines OptLineTerminator Line', '$$ = $1.concat($3);'
		o 'Lines LineTerminator'
	]

	OptLineTerminator: [
		o '', false
		o 'LineTerminator', 'false'
	]

	Line: [
		o 'Expression', '$$ = new yy.Expression($1)'
		o 'Statement'
	]

	Statement: [
		o 'Function'
		o 'If'
		o 'While'
		o 'Try'
		o 'Switch'
	]

	Expression: [
		o 'Value'
		o 'Invocation'
		o 'Code'
		o 'Operation'
		o 'Assign'
	]

	Value: [
		o 'Assignable'
		o 'Literal'
		o 'Parenthetical', '$$ = new yy.Value($1)'
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
		o '. Identifier', '$$ = new yy.Access($2)'
		o '.. Identifier', '$$ = new yy.Access($2, "..")'
		o ':: Identifier', '$$ = new yy.Access($2, "::")'
		o '[ Expression ]', '$$ = new yy.Access($2, "[]")'
	]

	Identifier: [
		o 'IDENTIFIER', '$$ = new yy.Identifier(yytext)'
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
		o '[ ArgList OptComma ]', '$$ = new yy.Array($2)'
	]

	ArgList: [
		o 'Arg', '$$ = [$1]'
		o 'ArgList , Arg', '$$ = $1.concat($3);'
		o 'ArgList OptComma LineTerminator Arg', '$$ = $1.concat($4)'
		o 'INDENT ArgList OptComma OUTDENT', 2
		o 'ArgList OptComma LineTerminator INDENT ArgList OptComma OUTDENT', '$$ = $1.concat($5)'
		o 'LineTerminator INDENT ArgList OptComma OUTDENT', 3
	]

	Arg: [
		o 'Expression'
		o 'Expression : Expression', '$$ = new yy.ArrayKey($1, $3)'
	]

	OptComma: [
		o ''
		o ','
	]

	# Invocation
	Invocation: [
		o 'Value Arguments', '$$ = new yy.Call($1, $2)'
	]
	Arguments: [
		o 'CALL_START CALL_END', '$$ = []'
		o 'CALL_START ArgList OptComma CALL_END', 2
	]

	# Function
	Function: [
		o 'FUNC IDENTIFIER ( ParametersList ) FuncGlyph Block', '$$ = new yy.Code($4, $7, true, $2)'
		o 'FUNC IDENTIFIER FuncGlyph Block', '$$ = new yy.Code([], $4, true, $2)'
	]

	Code: [
		o 'FUNC ( ParametersList ) FuncGlyph Block', '$$ = new yy.Code($3, $6)'
		o 'FUNC FuncGlyph Block', '$$ = new yy.Code([], $3)'
	]

	FuncGlyph: [
		o '->', false
	]

	ParametersList: [
		o '', '$$ = []'
		o 'Param', '$$ = [$1]'
		o 'ParametersList , Param', '$$ = $1.concat($3);'
	]

	Param: [
		o 'ParamVar'
		o 'USE ParamVar', '$2.passing = true, $$ = $2'
		o 'ParamVar = Expression', '$$ = new yy.Assign("=", $1, $3)'
	]

	ParamVar: [
		o '& IDENTIFIER', '$$ = new yy.Identifier(yytext, true, true)'
		o 'IDENTIFIER', '$$ = new yy.Identifier(yytext, true)'
	]

	Assign: [
		o 'Assignable = Expression', '$$ = new yy.Assign("=", $1, $3)'
		o 'CTE Identifier = Expression', '$$ = new yy.Constant($2, $4)'
	]

	# If
	If: [
		o 'IfBlock'
		o 'IfBlock ELSE Block', '$1.addElse(new yy.Else($3)); $$ = $1'
	]

	IfBlock: [
		o 'IF Expression Block', '$$ = new yy.If($2, $3)'
		o 'IfBlock ELSE IF Expression Block', '$1.addElse(new yy.ElseIf($4, $5)); $$ = $1'
	]

	# While
	While: [
		o 'WHILE Expression Block', '$$ = new yy.While($2, $3)'
	]

	# Try/catch/finally
	Try: [
		o 'TryBlock'
		o 'TryBlock FINALLY Block', '$1.addFinally($3); $$ = $1'
	]

	TryBlock: [
		o 'TRY Block CatchBlock', '$$ = new yy.Try($2, $3[0], $3[1])'
	]

	CatchBlock: [
		o 'CATCH Identifier Block', '$$ = [$2, $3]'
	]

	# Switch
	Switch: [
		o 'SWITCH Expression LineTerminator INDENT Whens OUTDENT', '$$ = new yy.Switch($2, $5)'
		o 'SWITCH Expression LineTerminator INDENT Whens ELSE Block OUTDENT', '$5.push(new yy.SwitchElse($7)); $$ = new yy.Switch($2, $5)'
	]

	Whens: [
		o 'When', '$$ = [$1]'
		o 'Whens OptLineTerminator When', '$$ = $1.concat($2)'
		o 'Whens LineTerminator'
	]

	When: [
		o 'WhenTok Expression Block', '$$ = new yy.When($2, $3)'
	]

	WhenTok: [
		o 'CASE', false
		o 'WHEN', false
	]

	# Operation
	Operation: [
		o '-- Expression', '$$ = new yy.Update("--", $2)'
		o '++ Expression', '$$ = new yy.Update("++", $2)'
		o 'SimpleAssignable --', '$$ = new yy.Update("--", $1, false)'
		o 'SimpleAssignable ++', '$$ = new yy.Update("++", $1, false)'
		o 'NOT Expression', '$$ = new yy.Unary("!", $2)'
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
		o 'Expression & Expression', '$$ = new yy.Operation("&", $1, $3)'
		o 'Expression COMPARE Expression', '$$ = new yy.Operation($2, $1, $3)'
		o 'SimpleAssignable ASSIGN Expression', '$$ = new yy.Assign($2, $1, $3)'
		o 'Expression IN Expression', '$$ = new yy.In($1, $3)'
	]

operators = [
	['left', '..', '.', '::', '->']
	['left', 'CALL_START', 'CALL_END']
	['nonassoc',  '++', '--']
	['left', '?']
	['right', '**']
	['left', '*', '/', '%']
	['left', 'NOT', '+', '-', '<->']
	['left', 'SHIFT']
	['left', 'IN']
	['left', 'COMPARE']
	['left', 'LOGIC', '&']
	['nonassoc', 'INDENT', 'OUTDENT', 'LineTerminator']
	['right', '=', ':', 'ASSIGN']
	['right', 'func', 'IF', 'ELSE']
]

{Parser} = require 'jison'

module.exports = new Parser
	bnf : grammar
	operators: operators.reverse()