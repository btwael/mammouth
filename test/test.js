var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
wael
boutglay{{
    wael until true when false
}}
*/
})

console.log(mammouth.parse(code).sections[1].body.body[0].test)

var lexer = require('../lib/lexer');
lexer.setInput(code);

//console.log(lexer.tokenize())