var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
{{
  abstract class wael extends sdf implements q'fdsf\dsfsdf', q'sqd'
    public static const wael = 12
    protected func cube() -> x*x
}}fsdf
*/
})

console.log(mammouth.parse(code).sections[1].body.body[0])

var lexer = require('../lib/lexer');
lexer.setInput(code);

//onsole.log(lexer.tokenize())