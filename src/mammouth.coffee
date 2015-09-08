yy = require './nodes'
parser = require('./parser').parser
lexer = require './lexer'
Context = require './context'
{IndentGenerator} = require './utils'
parser.lexer = lexer
parser.yy = yy

module.exports =
    VERSION: '3.0.0'

    parser: parser

    parse: (code) ->
        return @parser.parse code

    compile: (code, context) ->
        tree = @parse code
        result = tree.prepare().compile(new System)

class System
    constructor: ->
        @indent = new IndentGenerator
        @context = new Context.Context new Context.Scope
        @config = {}
        @setDefaultConfig()

    setDefaultConfig: ->
        @config['+'] = on

    setStrictMode: ->
        @config['+'] = off