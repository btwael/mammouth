var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
fsdfsdfsdf{{
    result = 1
    alert((sdf while true), sdf while true)
}}
*/
})

//console.log(mammouth.parse(code).sections[1].body.body)

console.log(mammouth.compile(code))

var lexer = require('../lib/lexer');
lexer.setInput(code);

//console.log(lexer.tokenize())