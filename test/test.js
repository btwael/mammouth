var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
{{
str = 'tex1' ~~ 'text2' # in all modes

str = 'tex1' + 123

'strict mode'
str = 'tex1' + 123 
}}
*/
})


//console.log(mammouth.parse(code).sections)

console.log(mammouth.compile(code))

var lexer = require('../lib/lexer');
lexer.setInput(code);

//console.log(lexer.tokenize())