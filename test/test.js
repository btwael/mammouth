function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};

var code = heredoc(function() {
/*
{{ds
     dfsdf
       dfsdf
         fgd
}}
*/
});

// The lexer
var lexed = [],
    lexer = require('../lib/lexer.js');
lexer.setInput(code);
var m = 0;
while(m != undefined) {
    m = lexer.lex();
}
console.log(lexer.tokens);

// The parser
mammouth = require('../lib/mammouth');
//console.log(mammouth.parse(code))