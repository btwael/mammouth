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
	# Everything starts here 
	Root: [
		o 'Sections', 'return new yy.Document($1);'
	]

	Sections: [
		o 'Section', '$$ = [$1];'
		o 'Sections Section', '$$ = $1.concat($2);'
	]

	Section: [
		o 'Raw'
		o 'Script'
	]

	Raw: [
		o 'RAWTEXT', '$$ = new yy.Raw(yytext);'
	]

	Script: [
		o '{{ Block }}', '$$ = new yy.Script($1);'
	]

	# The script grammar description is here
	Block: [ # a block is a list of instructions with the some indent level
        o 'INDENT Instructions OUTDENT', 2
	]

    Instructions: [
        o 'Instruction', '$$ = [$1];'
        o 'Instructions MINDENT Instruction', '$$ = $1.concat($3);'
    ]

operators = []

{Parser} = require 'jison'

module.exports = new Parser
    bnf : grammar
    operators: operators.reverse()