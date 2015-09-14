yy = require './nodes'
parser = require('./parser').parser
lexer = require './lexer'
Context = require './context'
Predefined = require './predefined'
{IndentGenerator} = require './utils'
PHP = require './php'

parser.lexer = lexer
parser.yy = yy

class System
    constructor: ->
        @indent = new IndentGenerator
        @context = new Context.Context new Context.Scope
        Predefined.Initialize @context
        @config = {}
        @setDefaultConfig()

    setDefaultConfig: ->
        @config['+'] = on
        @config['import'] = off
        @config['addMammouth'] = off

    setStrictMode: ->
        @config['+'] = off
        @config['import'] = off

class Mammouth
    @VERSION: '3.0.0'

    constructor: ->
        @_fs = require 'fs'
        @_path = require 'path'

    compile: (file) ->
        code = @_fs.readFileSync file, 'utf8'
        @path = @_path.dirname file
        @system = new System
        @system.config['import'] = on
        @system.Mammouth = @
        result = Mammouth.compile(code, @system)
        return result

    contextify: (file) ->
        path = @_path.join @path, file
        type = 'php'
        switch @_path.extname path
            when '.php'
                type = 'php'
            when '.mammouth'
                type = 'mammouth'
            else
                return
        if @_fs.existsSync path
            code = @_fs.readFileSync path, 'utf8'
            if type is 'mammouth'
                Mammouth.compile code, @system
            else if type is 'php'
                PHP.compile code, @system
            return
        if type is 'php'
            path2 = @_path.join(@_path.dirname(path), path.basename(path, '.php'), '.mammouth')
            if @_fs.existsSync path2
                code = @_fs.readFileSync path2, 'utf8'
                Mammouth.compile path2, @system
                return

    @parser: parser

    @parse: (code) ->
        return Mammouth.parser.parse code

    @compile: (code, sys = off) ->
        if sys is off
            system = new System 
        else
            system = sys
        tree = Mammouth.parse code
        result = tree.prepare().compile(system)

    @contextify: (code, sys = off) ->
        if sys is off
            system = new System 
        else
            system = sys
        result = Mammouth.compile(system, system)
        return system.context

module.exports = Mammouth