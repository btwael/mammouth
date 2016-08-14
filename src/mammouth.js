var Lexer = require('./lexer');
var Parser = require('./parser');
var ErrorM = require('./error');

function Mammouth() {

}

Mammouth.VERSION = '4.0.0';

Mammouth.prototype.parse = function(source, filename) {
    var lexer = new Lexer();
    var parser = new Parser();
    var errorM = new ErrorM(source, filename);
    lexer.setInput(source, errorM, filename);
    parser.setInput(lexer.lexAll(), errorM, filename);
    return parser.parseDocument();
};

module.exports = Mammouth;