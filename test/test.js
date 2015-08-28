var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
{{
  namespace moha
   sdfsdf
}}fsdf
*/
})

console.log(mammouth.parse(code).sections[1].body.body[0])

var lexer = require('../lib/lexer');
lexer.setInput(code);

//onsole.log(lexer.tokenize())