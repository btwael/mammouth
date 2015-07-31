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
        o 'INDENT Instructions OUTDENT', '$$ = new yy.Block($2);'
    ]

    Instructions: [
        o 'Instruction', '$$ = [$1];'
        o 'Instructions MINDENT Instruction', '$$ = $1.concat($3);'
    ]

    Instruction: [
        o 'Expression'
    ]

    Expression: [
        o 'Value'
        o 'Casting'
        # Execution
        o 'Clone'
    ]

    # A world of values
    Value: [
        o 'Assignable'
        o 'Literal', '$$ = new yy.Value($1);'
        o 'Parenthetical', '$$ = new yy.Value($1);'
    ]

    Parenthetical: [
        o '( Expression )', '$$ = new yy.Parens($2);'
    ]

    Casting: [
        o 'Value => CASTTYPE','$$ = new yy.typeCasting($1, $3);'
    ]

    Clone: [
        o 'CLONE Value', '$$ = new yy.Clone($2);'
    ]

    Assignable: [
        o 'SimpleAssignable'
        o 'Array'
    ]

    SimpleAssignable: [
        o 'Identifier', '$$ = new yy.Value($1);'
        o 'Value Accessor', '$1.add($2); $$ = $1;'
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
        o '[ Expression ]', '$$ = new yy.Access($2, "[]");'
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

operators = [
    ['left', '.', '..', '::']
    ['left', '=>']
    ['nonassoc',  'INDENT', 'MINDENT', 'OUTDENT']
    ['right', 'CLONE']
]

{Parser} = require 'jison'

module.exports = new Parser
    bnf : grammar
    operators: operators.reverse()