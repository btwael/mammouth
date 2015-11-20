var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
{{
func wale(x)(use wael) ->
    fdgdfg()
}}
*/
})


//console.log(mammouth.parse(code).sections)

console.log(mammouth.compile(code))

var lexer = require('../lib/lexer');
lexer.setInput(code);

console.log(lexer.tokenize())