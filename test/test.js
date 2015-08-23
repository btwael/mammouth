var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
wael
boutglay{{
    try dsfsdf
    catch sdf
      dsfsdf
    finally dfsdf
    var
}}fsdf
*/
})

console.log(mammouth.parse(code).sections[1].body.body)

var lexer = require('../lib/lexer');
lexer.setInput(code);

//console.log(lexer.tokenize())