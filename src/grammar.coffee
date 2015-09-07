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
        o 'Sections', 'return new yy.Document($1);'
    ]

    Sections: [
        o 'Section', '$$ = [$1];'
        o 'Sections Section', '$$ = $1.concat($2);'
    ]

    Section: [
        o 'RAW', '$$ = new yy.RawText($1);'
        o 'Script'
    ]

    Script: [
        o '{{ }}', '$$ = new yy.Script(new yy.Block([]));'
        o '{{ Block }}', '$$ = new yy.Script($2);'
    ]

    Block: [
        o 'INDENT OUTDENT', '$$ = new yy.Block([]);'
        o 'INDENT Instructions OUTDENT', '$$ = new yy.Block($2);'
    ]

    Instructions: [
        o 'Instruction', '$$ = [$1];'
        o 'Instructions MINDENT Instruction', '$$ = $1.concat($3);'
    ]

    Instruction: [
        o 'Expression'
        o 'BigStatement'
    ]

    BigStatement: [
        o 'Statement'
        o 'Function'
        o 'Class'
        o 'Interface'
        o 'Namespace'
    ]

    Statement: [
        o 'JumpStatement'
        o 'Declare'
        o 'SectionStatement'
    ]

    JumpStatement: [
        o 'Goto'
        o 'Break'
        o 'Continue'
        o 'Return'
        o 'Throw'
    ]

    Expression: [
        o 'Value'
        o 'Invocation', '$$ = new yy.Value($1);';
        o 'Code'
        o 'Operation', '$$ = new yy.Value($1);';
        o 'Assign'
        o 'Casting'
        o 'Clone'
        o 'If'
        o 'While'
        # dowhile
        o 'Try'
        o 'For'
        o 'Switch'
        o 'Intrinsic'
    ]

    # A world of values
    Value: [
        o 'Assignable'
        o 'Literal', '$$ = new yy.Value($1);'
        o 'Parenthetical', '$$ = new yy.Value($1);'
        o 'Existence', '$$ = new yy.Value($1);'
        o 'Range', '$$ = new yy.Value($1);'
        o 'QualifiedName', '$$ = new yy.Value($1);'
        o 'Heredoc', '$$ = new yy.Value($1);'
    ]

    Heredoc: [
        o 'HEREDOC', '$$ = new yy.HereDoc($1);';
    ]

    Parenthetical: [
        o '( Expression )', '$$ = new yy.Parens($2);'
    ]

    Existence: [
        o 'Value ?', '$$ = new yy.Existence($1);'
    ]

    RangeDots: [
        o '...', '$$ = "inclusive";'
        o '....', '$$ = "exclusive";'
    ]

    Range: [
        o '[ Expression RangeDots Expression ]', '$$ = new yy.Range($2, $4, $3);'
    ]

    Assignable: [
        o 'SimpleAssignable'
        o 'Array'
    ]

    SimpleAssignable: [
        o 'Identifier', '$$ = new yy.Value($1);'
        o 'Value Accessor', 'if($2.type == "Slice") {
                                $2.value = $1;
                                $$ = new yy.Value($2);
                            } else {
                                $$ = $1.add($2);
                            }'
        o 'Invocation Accessor', '$1 = new yy.Value($1);
                            if($2.type == "Slice") {
                                $2.value = $1;
                                $$ = new yy.Value($2);
                            } else {
                                $$ = $1.add($2);
                            }'
        o '@ Identifier', 'var value = new yy.Value(new yy.Identifier("this"));
                            value.add(new yy.Access($2));
                            $$ = value;'

    ]

    Identifier: [
        o 'IDENTIFIER', '$$ = new yy.Identifier($1);'
    ]

    Accessor: [
        o '. Identifier', '$$ = new yy.Access($2);'
        o '.. Identifier', '$$ = new yy.Access($2, "..");'
        o ':: Identifier', '$$ = new yy.Access($2, "::");'
        o 'Index'
    ]

    Index: [
        o 'INDEX_START Expression INDEX_END', '$$ = new yy.Access($2, "[]");'
        o 'INDEX_START Slice INDEX_END', '$$ = new yy.Slice($2);'
    ]

    Slice: [
        o 'Expression RangeDots Expression', '$$ = new yy.Range($1, $3, $2);'
        o 'Expression RangeDots','$$ = new yy.Range($1, null, $2);'
        o 'RangeDots Expression', '$$ = new yy.Range(null, $2, $1);'
        o 'RangeDots', '$$ = new yy.Range(null, null, $1);'
    ]

    Literal: [
        o 'AlphaNumeric'
        o 'BOOL', '$$ = new yy.Literal($1);'
        o 'NULL', '$$ = new yy.Literal("null");'
    ]

    AlphaNumeric: [
        o 'NUMBER', '$$ = new yy.Literal($1);'
        o 'STRING', '$$ = new yy.Literal($1);'
    ]

    Array: [
        o '[ ]', '$$ = new yy.Array();'
        o '[ ArgList OptComma ]', '$$ = new yy.Array($2);'
    ]

    ArgList: [
        o 'Arg', '$$ = [$1];'
        o 'ArgList , Arg', '$$ = $1.concat($3);'
        o 'ArgList OptComma MINDENT Arg', '$$ = $1.concat($4);'
        o 'INDENT OUTDENT', '$$ = [];'
        o 'INDENT ArgList OptComma OUTDENT', 2
        o 'ArgList OptComma INDENT ArgList OptComma OUTDENT', '$$ = $1.concat($4);'
    ]

    Arg: [
        o 'Expression'
        o 'Expression : Expression', '$$ = new yy.ArrayKey($1, $3);'
    ]

    OptComma: [
        o ''
        o ','
    ]

    Assign: [
        o 'Assignable = Expression', '$$ = new yy.Assign("=", $1, $3);'
        o 'Assignable = INDENT Expression OUTDENT', '$$ = new yy.Assign("=", $1, $4);'
        o '{ KeysList } = Expression', '$$ = new yy.GetKeyAssign($2, $5);'
        o '{ KeysList } = INDENT Expression OUTDENT', '$$ = new yy.GetKeyAssign($2, $6);'
        o 'CONST IDENTIFIER = Expression', '$$ = new yy.Constant($2, $4);'
        o 'CONST IDENTIFIER = INDENT Expression OUTDENT', '$$ = new yy.Constant($2, $5);'
    ]

    KeysList: [
        o 'Identifier', '$$ = [$1];'
        o 'KeysList , Identifier', '$$ = $1.concat($3);'
        o 'KeysList OptComma MINDENT Identifier', '$$ = $1.concat($4);'
        o 'INDENT OUTDENT', '$$ = [];'
        o 'INDENT KeysList OptComma OUTDENT', 2
        o 'KeysList OptComma INDENT KeysList OptComma OUTDENT', '$$ = $1.concat($4);'
    ]

    Casting: [
        o 'Value => CASTTYPE','$$ = new yy.typeCasting($1, $3);'
    ]

    Clone: [
        o 'CLONE Value', '$$ = new yy.Clone($2);'
    ]

    # Invocation
    Invocation: [
        o 'Value Arguments', '$$ = new yy.Call($1, $2);'
        o 'NEW Value', '$$ = new yy.NewExpression($2);'
        o 'NEW Value Arguments', '$$ = new yy.NewExpression($2, $3);'
    ]

    Arguments: [
        o 'CALL_START CALL_END', '$$ = [];'
        o 'CALL_START ArgList OptComma CALL_END', 2
    ]

    # Intrinsic
    Intrinsic: [
        o 'Echo'
        o 'Delete'
    ]

    Echo: [
        o 'ECHO Expression', '$$ = new yy.Echo($2)'
    ]

    Delete: [
        o 'DELETE Expression', '$$ = new yy.Delete($2)'
    ]

    # Functions
    Function: [
        o 'FUNC IDENTIFIER', '$$ = new yy.Code([], false, true, $2);'
        o 'FUNC IDENTIFIER FuncGlyph Block', '$$ = new yy.Code([], $4, true, $2);'
        o 'FUNC IDENTIFIER ( ParametersList )', '$$ = new yy.Code($4, false, true, $2);'
        o 'FUNC IDENTIFIER ( ParametersList ) FuncGlyph Block', '$$ = new yy.Code($4, $7, true, $2);'
    ]

    Code: [
        o 'FUNC ( ParametersList ) FuncGlyph Block', '$$ = new yy.Code($3, $6);'
        o 'FUNC FuncGlyph Block', '$$ = new yy.Code([], $3);'
    ]

    FuncGlyph: [
        o '->', false
    ]

    ParametersList: [
        o '', '$$ = [];'
        o 'Param', '$$ = [$1];'
        o 'ParametersList , Param', '$$ = $1.concat($3);'
    ]

    Param: [
        o 'ParamVar'
        o 'USE ParamVar', '$2.passing = true; $$ = $2;'
        o 'ParamVar = Expression', '$1.hasDefault = true; $1.default = $3; $$ = $1;'
    ]

    ParamVar: [
        o '& IDENTIFIER', '$$ = new yy.Param(yytext, true);'
        o 'IDENTIFIER', '$$ = new yy.Param(yytext);'
    ]

    # If
    If: [
        o 'IfBlock'
        o 'IfBlock ELSE Block', '$$ = $1.addElse(new yy.Else($3));'
        o 'Statement POST_IF Expression', '$$ = new yy.If($3, new yy.Block([$1]), $2)'
        o 'Expression POST_IF Expression', '$$ = new yy.If($3, new yy.Block([$1]), $2)'
    ]

    IfBlock: [
        o 'IF Expression Block', '$$ = new yy.If($2, $3, $1);'
        o 'IfBlock ELSE IF Expression Block', '$$ = $1.addElse(new yy.ElseIf($4, $5));'
    ]

    # While
    While: [
        o 'WhileSource Block', '$$ = $1.addBody($2);'
        o 'Statement WhileSource', '$$ = $2.addBody(new yy.Block([$1]));'
        o 'Expression WhileSource', '$$ = $2.addBody(new yy.Block([$1]));'
        o 'Loop'
    ]

    WhileSource: [
        o 'WHILE Expression', '$$ = new yy.While($2, false);'
        o 'WHILE Expression WHEN Expression', '$$ = new yy.While($2, false, $4);'
        o 'UNTIL Expression', '$$ = new yy.While($2, true);'
        o 'UNTIL Expression WHEN Expression', '$$ = new yy.While($2, true, $4);'
    ]

    Loop: [
        o 'LOOP Block', '$$ = new yy.While(new yy.Value(new yy.Literal("true")), false, null, $2);'
        o 'LOOP Expression', '$$ = new yy.While(new yy.Value(new yy.Literal("true")), false, null, new yy.Block([$2]));'
    ]

    # Try
    Try: [
        o 'TRY Block', '$$ = new yy.Try($2);'
        o 'TRY Block Catch', '$$ = new yy.Try($2, $3[0], $3[1]);'
        o 'TRY Block FINALLY Block', '$$ = new yy.Try($2, new yy.Block, false, $4);'
        o 'TRY Block Catch FINALLY Block', '$$ = new yy.Try($2, $3[0], $3[1], $5);'
    ]

    Catch: [
        o 'CATCH Identifier Block', '$$ = [$3, $2];'
        o 'CATCH Block', '$$ = [$2, false];'
    ]

    # For
    For: [
        o 'Statement ForBody', '$$ = new yy.For($2, new yy.Block([$1]));'
        o 'Expression ForBody', '$$ = new yy.For($2, new yy.Block([$1]));'
        o 'ForBody Block', '$$ = new yy.For($1, $2);'
    ]

    ForBody: [
        o 'FOR Range', '$$ = {source: $2, range: true};'
        o 'FOR Range AS Identifier', '$$ = {source: $2, index: $4, range: true};'
        o 'FOR Range BY Expression', '$$ = {source: $2, step: $4, range:true};'
        o 'FOR Range BY Expression AS Identifier', '$$ = {source: $2, index:$6, step: $4, range:true};'
        o 'FOR Range AS Identifier BY Expression', '$$ = {source: $2, index:$4, step: $6, range:true};'
        o 'ForStart ForSource', '$2.name = $1[0]; $2.index = $1[1]; $$ = $2;'
    ]

    ForStart: [
        o 'FOR ForVariables', '$$ = $2;'
    ]

    ForValue: [
        o 'Identifier'
        o 'Array', '$$ = new yy.Value($1);'
    ]

    ForVariables: [
        o 'ForValue', '$$ = [$1];'
        o 'ForValue , ForValue', '$$ = [$1, $3];'
    ]

    ForSource: [
        o 'FORIN Expression', '$$ = {source: $2};'
        o 'FOROF Expression', '$$ = {source: $2, object: true};'
        o 'FORIN Expression WHEN Expression', '$$ = {source: $2, guard: $4};'
        o 'FOROF Expression WHEN Expression', '$$ = {source: $2, guard: $4, object: true};'
        o 'FORIN Expression BY Expression', '$$ = {source: $2, step: $4};'
        o 'FORIN Expression WHEN Expression BY Expression', '$$ = {source: $2, guard: $4, step: $6};'
        o 'FORIN Expression BY Expression WHEN Expression', '$$ = {source: $2, guard: $6, step: $4};'
    ]

    # Switch
    Switch: [
        o 'SWITCH Expression INDENT Whens OUTDENT', '$$ = new yy.Switch($2, $4);'
        o 'SWITCH Expression INDENT Whens ELSE Block OUTDENT', '$$ = new yy.Switch($2, $4, $6);'
        o 'SWITCH INDENT Whens OUTDENT', '$$ = new yy.Switch(null, $3);'
        o 'SWITCH INDENT Whens ELSE Block OUTDENT', '$$ = new yy.Switch(null, $3, $5);'
    ]

    Whens: [
        o 'When', '$$ = [$1];'
        o 'Whens MINDENT When', '$1.push($3); $$ = $1;'
    ]

    When: [
        o 'LEADING_WHEN SimpleArgs Block', '$$ = [$2, $3];'
    ]

    SimpleArgs: [
        o 'Expression', '$$ = [$1];'
        o 'SimpleArgs , Expression', '$$ = $1.concat($3);'
    ]

    # Declare
    Declare: [
        o 'DECLARE SimpleArg', '$$ = new yy.Declare($2);'
        o 'DECLARE SimpleArg -> Block', '$$ = new yy.Declare($2, $4);'
    ]

    SimpleArg: [
        o 'Expression'
        o '( Expression )', 2
    ]

    # Sections
    SectionStatement: [
        o 'IDENTIFIER :', '$$ = new yy.Section($1);'
    ]

    # Jump statement
    Goto: [
        o 'GOTO IDENTIFIER', '$$ = new yy.Goto($2);'
    ]

    Break: [
        o 'BREAK', '$$ = new yy.Break();'
        o 'BREAK NUMBER', '$$ = new yy.Break(new yy.Literal($2));'
    ]

    Continue: [
        o 'CONTINUE', '$$ = new yy.Continue();'
        o 'CONTINUE NUMBER', '$$ = new yy.Continue(new yy.Literal($2));'
    ]

    Return: [
        o 'RETURN SimpleArg', '$$ = new yy.Return($2);'
        o 'RETURN', '$$ = new yy.Return();'
    ]

    Throw: [
        o 'THROW Expression', '$$ = new yy.Throw($2);'
    ]

    # Classes
    Class: [
        o 'ClassModifier CLASS IDENTIFIER Extends OptImplements INDENT ClassMembers OUTDENT', '$$ = new yy.Class($3, $7, $4, $5, $1);'
    ]

    ClassModifier: [
        o '', '$$ = false;'
        o 'ABSTRACT', '$$ = "abstract";'
        o 'FINAL', '$$ = "final";'
    ]

    Extends: [
        o '', '$$ = false;'
        o 'EXTENDS Qualified', 2
    ]

    OptImplements: [
        o 'Implements'
    ]

    Implements: [
        o 'IMPLEMENTS Qualified', '$$ = [$2];'
        o 'Implements , Qualified', '$$ = $1.concat($3);'
    ]

    ClassMembers: [
        o 'ClassMember', '$$ = [$1];'
        o 'ClassMembers MINDENT ClassMember', '$$ = $1.concat($3);'
    ]

    ClassMember: [
        o 'Visibility Statically Identifier', '$$ = new yy.ClassLine($1, $2, $$ = new yy.Expression($3));'
        o 'Visibility Statically Assign', '$$ = new yy.ClassLine($1, $2, $$ = new yy.Expression($3));'
        o 'Visibility Statically Function', '$$ = new yy.ClassLine($1, $2, $3);'
        o 'FINAL Visibility Statically Function', 'n = new yy.ClassLine($2, $3, $4); n.finaly = true; $$ = n;'
        o 'ABSTRACT ClassMember', '$2.abstract = true; $$ = $2;'
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
        o 'INTERFACE IDENTIFIER Extends INDENT InterfaceBody OUTDENT', '$$ = new yy.Interface($2, $5, $3);'
    ]

    InterfaceBody: [
        o 'InterfaceLine', '$$ = [$1];'
        o 'InterfaceBody MINDENT InterfaceLine', '$$ = $1.concat($3);'
    ]

    InterfaceLine: [
        o 'Visibility Statically Assign', '$$ = new yy.ClassLine($1, $2, $$ = new yy.Expression($3));'
        o 'Visibility Statically Function', '$$ = new yy.ClassLine($1, $2, $3);'
        o 'FINAL Visibility Statically Function', 'n = new yy.ClassLine($2, $3, $4); n.finaly = true; $$ = n;'
    ]

    # Qualified
    Qualified: [
        o 'IDENTIFIER', '$$ = new yy.QualifiedName($1);'
        o 'QualifiedName'
    ]

    QualifiedName: [
        o 'QUALIFIEDQTRING', '$$ = new yy.QualifiedName($1);'
    ]

    # Namespaces
    Namespace: [
        o 'NAMESPACE Qualified', '$$ = new yy.Expression(new yy.Namespace($2));'
        o 'NAMESPACE Qualified Block', '$$ = new yy.Namespace($2, $3);'
    ]

    # Operation
    Operation: [
        o '-- Expression', '$$ = new yy.Update("--", $2);'
        o '++ Expression', '$$ = new yy.Update("++", $2);'
        o 'SimpleAssignable --', '$$ = new yy.Update("--", $1, false);'
        o 'SimpleAssignable ++', '$$ = new yy.Update("++", $1, false);'
        o 'NOT Expression', '$$ = new yy.Unary("!", $2);'
        o '- Expression', '$$ = new yy.Unary("-", $2);'
        o '+ Expression', '$$ = new yy.Unary("+", $2);'
        o 'Expression + Expression', '$$ = new yy.Operation("+", $1, $3);'
        o 'Expression CONCAT Expression', '$$ = new yy.Operation("~", $1, $3);'
        o 'Expression - Expression', '$$ = new yy.Operation("-", $1, $3);'
        o 'Expression * Expression', '$$ = new yy.Operation("*", $1, $3);'
        o 'Expression ** Expression', '$$ = new yy.Operation("**", $1, $3);'
        o 'Expression / Expression', '$$ = new yy.Operation("/", $1, $3);'
        o 'Expression % Expression', '$$ = new yy.Operation("%", $1, $3);'
        o 'Expression BITWISE Expression', '$$ = new yy.Operation($2, $1, $3);'
        o 'Expression & Expression', '$$ = new yy.Operation("&", $1, $3);'
        o 'Expression LOGIC Expression', '$$ = new yy.Operation($2, $1, $3);'
        o 'Expression COMPARE Expression', '$$ = new yy.Operation($2, $1, $3);'
        o 'SimpleAssignable ASSIGN Expression', '$$ = new yy.Assign($2, $1, $3);'
        o 'Expression INSTANCEOF Expression', '$$ = new yy.Operation("instanceof", $1, $3);'
        o 'Expression IN Expression', '$$ = new yy.Operation("in", $1, $3);'
    ]


operators = [
    ['left', '.', '..', '::']
    ['nonassoc', '++', '--']
    ['left', 'CALL_START', 'CALL_END']
    ['right', 'NOT']
    ['left', '*', '**', '/', '%']
    ['left', '+', '-', 'CONCAT']
    ['left', 'BITWISE']
    ['left', 'INSTANCEOF', 'IN']
    ['left', 'COMPARE']
    ['left', 'LOGIC'; '&']
    ['left', '=>']
    ['nonassoc',  'INDENT', 'MINDENT', 'OUTDENT']
    ['right', '=', ':', 'ASSIGN', 'RETURN', 'THROW', 'GOTO', 'BREAK', 'CONTINUE', 'CLONE', 'ECHO', 'DELETE', 'EXTENDS', 'IMPLEMENTS']
    ['right', 'FORIN', 'FOROF', 'BY', 'WHEN']
    ['right', 'IF', 'ELSE', 'FOR', 'WHILE', 'UNTIL', 'LOOP', 'FUNC', 'NAMESPACE', 'ABSTRACT', 'FINAL', 'CLASS', 'INTERFACE', 'NAMESPACE']
    ['left', 'POST_IF']
]

{Parser} = require 'jison'

module.exports = new Parser
    bnf : grammar
    operators: operators.reverse()