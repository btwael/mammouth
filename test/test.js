var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
fsdfsdfsdf{{
#require once "dsfsdf"
abstract class iTemplat extends dfs implements sdfsd, q'sdfsdf'
    public dfg ###
    dfsdf

dsfsdf
###
    abstract final public static func wael()
    const fdg=123
sdfsdf().dfsdf
[][sdfsd]
}}
*/
})


//console.log(mammouth.parse(code).sections)

console.log(mammouth.compile(code))

var lexer = require('../lib/lexer');
lexer.setInput(code);

//console.log(lexer.tokenize())