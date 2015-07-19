var code = 'sdfsd{{\n\n   \n  \n  \n       \n}}sdfdfs';

// The lexer
var lexed = [],
    lexer = require('../lib/lexer.js');
lexer.setInput(code);
var m = 0;
while(m != undefined) {
    m = lexer.lex();
}
console.log(lexer.tokens);