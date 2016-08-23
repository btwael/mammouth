var Lexer = require('./src/lexer');
var Parser = require('./src/parser');
var ErrorM = require('./src/error');
var code = "{{\n i = 12 \n ###\nsdfsdf\n### \n}}";

var l = new Lexer();
l.setInput(code, new ErrorM(code, '/file.js'));
var p = new Parser();
p.setInput(l.lexAll());
console.log(p.input.map(function(tok) {return tok.type;}))
//console.log(p.parseDocument());
//console.log(p.input)
var mammouth = require('./src/mammouth');

var m = new mammouth();
console.log(m.parse(code).sections[1].body);