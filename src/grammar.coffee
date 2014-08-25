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
		o 'Expression', '$$ = new yy.Block([new yy.Expression($1)])'
		o 'SimpleStatement', '$$ = new yy.Block([new yy.Expression($1)])'
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
		o 'SimpleStatement', '$$ = new yy.Expression($1)' # Is not expressions but only for add ;
		o 'Function'
		o 'If'
		o 'While'
		o 'DoWhile'
		o 'For'
		o 'Try'
		o 'Switch'
		o 'Declare'
		o 'Section'
		o 'Class'
		o 'Interface'
		o 'Namespace'
	]

	Expression: [
		o 'Value'
		o 'Invocation'
		o 'Code'
		o 'Operation'
		o 'Assign'
		o 'IfExpression'
		o 'HereDoc'
	]

	Value: [
		o 'Assignable'
		o 'Literal'
		o 'Parenthetical', '$$ = new yy.Value($1)'
		o 'Casting'
		o 'Execution'
		o 'NamespaceRef', '$$ = new yy.Value($1)'
		o 'Clone'
	]

	HereDoc: [
		o '` HEREDOCTEXT `', '$$ = new yy.HereDoc($2)'
	]

	Parenthetical: [
		o '( Expression )', '$$ = new yy.Parens($2)'
	]

	Casting: [
		o 'SimpleAssignable => cType', '$$ = new yy.Casting($1, $3)'
	]

	Execution: [
		o 'EXEC STRING', '$$ = new yy.Exec($2)'
		o 'EXEC ( STRING )', '$$ = new yy.Exec($3)'
	]

	Clone: [
		o 'CLONE Value', '$$ = new yy.Clone($2)'
	]

	Assignable: [
		o 'SimpleAssignable'
		o 'Array', '$$ = new yy.Value($1)'
	]

	SimpleAssignable: [
		o 'Identifier', '$$ = new yy.Value($1)'
		o '& IDENTIFIER', '$$ = new yy.Identifier(yytext, true, true)'
		o 'Value Accessor', '$1.add($2); $$ = $1'
		o '@ Identifier', 'th = new yy.Value(new yy.Identifier("this")); th.add(new yy.Access($2)); $$ = th'
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
		o 'NULL', '$$ = new yy.Null()'
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
		o 'NEW Value', '$$ = new yy.NewCall($2)'
		o 'NEW Value Arguments', '$$ = new yy.NewCall($2, $3)'
	]
	Arguments: [
		o 'CALL_START CALL_END', '$$ = []'
		o 'CALL_START ArgList OptComma CALL_END', 2
	]

	# Function
	Function: [
		o 'FUNC IDENTIFIER', '$$ = new yy.Code([], false, true, $2)'
		o 'FUNC IDENTIFIER FuncGlyph Block', '$$ = new yy.Code([], $4, true, $2)'
		o 'FUNC IDENTIFIER ( ParametersList )', '$$ = new yy.Code($4, false, true, $2)'
		o 'FUNC IDENTIFIER ( ParametersList ) FuncGlyph Block', '$$ = new yy.Code($4, $7, true, $2)'
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
		o '{ KeysList } = Expression', '$$ = new yy.GetKeyAssign($2, $5)'
		o 'CTE Identifier = Expression', '$$ = new yy.Constant($2, $4)'
	]

	KeysList: [
		o 'Identifier', '$$ = [$1]'
		o 'KeysList , Identifier', '$$ = $1.concat($3)'
	]

	# Simple Statement
	SimpleStatement: [
		o 'Echo' 
		o 'Break'
		o 'Continue'
		o 'Delete'
		o 'Include'
		o 'Require'
		o 'Return'
		o 'Goto'
	]

	Echo: [
		o 'ECHO SimpleArg', '$$ = new yy.Echo($2)'
	]

	Break: [
		o 'BREAK', '$$ = new yy.Break()'
		o 'BREAK NUMBER', '$$ = new yy.Break(new yy.Literal($2))'
	]

	Continue: [
		o 'CONTINUE', '$$ = new yy.Continue()'
		o 'CONTINUE NUMBER', '$$ = new yy.Continue(new yy.Literal($2))'
	]

	Delete: [
		o 'DELETE SimpleArg', '$$ = new yy.Delete($2)'
	]

	Include: [
		o 'INCLUDE isOnce SimpleArg', '$$ = new yy.Include($3, $2)'
	]

	Require: [
		o 'REQUIRE isOnce SimpleArg', '$$ = new yy.Require($3, $2)'
	]

	isOnce: [
		o '', '$$ = false'
		o 'ONCE', '$$ = true'
	]

	Return: [
		o 'RETURN SimpleArg', '$$ = new yy.Return($2)'
	]

	SimpleArg: [
		o 'Expression'
		o '( Expression )', 2
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

	DoWhile: [
		o 'DO WHILE Expression Block', '$$ = new yy.DoWhile($3, $4)'
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
		o 'Whens OptLineTerminator When', '$$ = $1.concat($3)'
		o 'Whens LineTerminator'
	]

	When: [
		o 'WhenTok Expression Block', '$$ = new yy.When($2, $3)'
	]

	WhenTok: [
		o 'CASE', false
		o 'WHEN', false
	]

	# For
	For: [
		o 'FOR ForExpressions Block', '$$ = new yy.For("normal", $2, $3)'
		o 'FOR EACH Expression AS Expression Block', '$5.foreach = true; $$ = new yy.For("foreach", $3, $5, $6)'
	]

	ForExpressions: [
		o 'Expression', '$$ = [$1]'
		o 'ForExpressions ; Expression', '$$ = $1.concat($3)'
	]

	# Declare
	Declare: [
		o 'DECLARE SimpleArg', '$$ = new yy.Expression(new yy.Declare($2))'
		o 'DECLARE SimpleArg -> Block', '$$ = new yy.Declare($2, $4)'
	]

	# Section
	Section: [
		o 'IDENTIFIER :', '$$ = new yy.Section($1)'
	]

	Goto: [
		o '==> IDENTIFIER', '$$ = new yy.Goto($2)'
		o 'GOTO IDENTIFIER', '$$ = new yy.Goto($2)'
	]

	# Class
	Class: [
		o 'CLASS IDENTIFIER LineTerminator INDENT ClassBody OUTDENT', '$$ = new yy.Class($2, $5)'
		o 'CLASS IDENTIFIER EXTENDS IDENTIFIER LineTerminator INDENT ClassBody OUTDENT', '$$ = new yy.Class($2, $7, $4)'
		o 'CLASS IDENTIFIER IMPLEMENTS IDENTIFIER LineTerminator INDENT ClassBody OUTDENT', '$$ = new yy.Class($2, $7, false, $4)'
		o 'ABSTRACT CLASS IDENTIFIER LineTerminator INDENT ClassBody OUTDENT', '$$ = new yy.Class($3, $6, false, false, true)'
	]

	ClassBody: [
		o 'ClassLine', '$$ = [$1]'
		o 'ClassBody OptLineTerminator ClassLine', '$$ = $1.concat($3)'
		o 'ClassBody LineTerminator'
	]

	ClassLine: [
		o 'Visibility Statically Identifier', '$$ = new yy.ClassLine($1, $2, $$ = new yy.Expression($3))'
		o 'Visibility Statically Assign', '$$ = new yy.ClassLine($1, $2, $$ = new yy.Expression($3))'
		o 'Visibility Statically Function', '$$ = new yy.ClassLine($1, $2, $3);'
		o 'FINAL Visibility Statically Function', 'n = new yy.ClassLine($2, $3, $4); n.finaly = true; $$ = n'
		o 'ABSTRACT ClassLine', '$2.abstract = true; $$ = $2'
	]

	Finaly: [
		o '', '$$ = false'
		o 'FINAL', '$$ = true'
	]

	Visibility: [
		o '', '$$ = false'
		o 'PUBLIC', '$$ = "public"'
		o 'PRIVATE', '$$ = "private"'
		o 'PROTECTED', '$$ = "protected"'
	]

	Statically: [
		o '', '$$ = false'
		o 'STATIC', '$$ = "static"'
	]

	# Interface
	Interface: [
		o 'INTERFACE IDENTIFIER LineTerminator INDENT InterfaceBody OUTDENT', '$$ = new yy.Interface($2, $5)'
		o 'INTERFACE IDENTIFIER EXTENDS ExtendedList LineTerminator INDENT InterfaceBody OUTDENT', '$$ = new yy.Interface($2, $7, $4)'
	]

	InterfaceBody: [
		o 'InterfaceLine', '$$ = [$1]'
		o 'InterfaceBody OptLineTerminator InterfaceLine', '$$ = $1.concat($3)'
		o 'InterfaceBody LineTerminator'
	]

	InterfaceLine: [
		o 'PUBLIC Function', 2
		o 'Assign', '$$ = new yy.Expression($1)'
	]

	ExtendedList: [
		o 'IDENTIFIER', '$$ = [$1]'
		o 'ExtendedList , IDENTIFIER', '$$ = $1.concat($3)'
	]

	# Namespace
	Namespace: [
		o 'NAMESPACE NamespaceName', '$$ = new yy.Expression(new yy.Namespace($2))'
		o 'NAMESPACE NamespaceName -> Block', '$$ = new yy.Namespace($2, $4)'
	]

	NamespaceName: [
		o 'IDENTIFIER'
		o 'NamespaceName \\ IDENTIFIER', ' $$ = $1 + "\\\\" + $3'
	]

	NamespaceRef: [
		o 'NamespaceRefname', '$$ = new yy.NamespaceRef($1)'
	]

	NamespaceRefname: [
		o 'IDENTIFIER \\ IDENTIFIER', '$$ = $1 + "\\\\" + $3'
		o 'NamespaceRefname \\ IDENTIFIER', '$$ = $1 + "\\\\" + $3'
		o '\\ NamespaceRefname', '$$ = "\\\\" + $2'
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
		o 'Expression INSTANCEOF Expression', '$$ = new yy.Operation("instanceof", $1, $3)'
		o 'Expression IN Expression', '$$ = new yy.In($1, $3)'
	]

operators = [
	['left', '..', '.', '::', '->', '=>']
	['left', 'CALL_START', 'CALL_END']
	['nonassoc',  '++', '--']
	['left', '?']
	['right', '**']
	['left', '*', '/', '%']
	['left', 'NOT', '+', '-', '<->', 'EXEC', 'CLONE']
	['left', 'SHIFT']
	['left', 'INSTANCEOF']
	['left', 'IN']
	['left', 'AS']
	['left', 'COMPARE']
	['left', 'LOGIC', '&']
	['nonassoc', 'INDENT', 'OUTDENT', 'LineTerminator']
	['left', 'DELETE', 'ECHO', 'REQUIRE', 'INCLUDE', 'ONCE', 'BREAK', 'CONTINUE', 'RETURN', 'DECLARE']
	['right', 'PUBLIC', 'PRIVATE', 'PROTECTED', 'FINAL', 'STATIC']
	['right', 'func', 'IF', 'THEN', 'ELSE', 'FOR', 'EACH', 'DO', 'WHILE', 'ABSTRACT', 'CLASS', 'EXTENDS', 'IMPLEMENTS']
	['right', '=', ':', 'ASSIGN']
]

{Parser} = require 'jison'

module.exports = new Parser
	bnf : grammar
	operators: operators.reverse()