yy = require './nodes'
parser = require('./parser').parser
lexer = require './lexer'

# Connect parser with lexer...
parser.lexer = lexer
parser.yy = yy

module.exports =
    VERSION: '3.0.0'

    parser: parser

    parse: (code) ->
        return @parser.parse code