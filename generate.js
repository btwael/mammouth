yy = require('./lib/nodes');
parser = require('./lib/grammar');
parser.lexer = require('./lib/lexer');
parser.yy = yy;
require('fs').writeFile('./lib/parser.js', parser.generate(), function(err) {
    if(err) {
        console.log(err);
    } else {
        console.log("The file was saved!");
    }
});