yy = require './nodes'
parser = require('./parser').parser
lexer = require './lexer'
rewriter = require './rewriter'
{PreContext} = require './context'
parser.lexer = lexer
parser.yy = yy

module.exports =
	VERSION: '2.0.0'

	parser: parser

	parse: (code) ->
		return @parser.parse code

	compile: (code, context) ->
		tree = @parse code
		result = rewriter.rewrite tree, if context then context else PreContext