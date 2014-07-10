yy = require './nodes'
parser = require('./parser').parser
parser.lexer = require './lexer'
rewriter = require './rewriter'
{PreContext} = require './context'
parser.yy = yy
exports.VERSION = '1.0.0'

module.exports =
	parse: (code) ->
		return parser.parse code

	compile: (code, context) ->
		tree = @parse code
		result = rewriter.rewrite tree, if context then context else PreContext