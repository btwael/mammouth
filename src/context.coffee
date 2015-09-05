nodes = require './nodes'
{IndexGenerator} = require './utils'

exports.Name = class Name
    constructor: (@name, @type = 'variable') ->

exports.Scope = class Scope
    constructor: ->
        @names = {}

    has: (name) -> @names[name]?

    add: (name) ->
        @names[name.name] = name

    get: (name) -> @names[name]

    delete: () ->
        delete @names[name.name]

exports.Context = class Context
    constructor: (scope) ->
        @indexGen = new IndexGenerator
        @scopes = []
        @scopes.unshift(scope)

    push: (name) ->
        @scopes[0].add(name)

    has: (name) ->
        for scope in @scopes
            return on if scope.has(name)
        return off

    scopeStarts: () ->
        @scopes.unshift(new Scope);

    scopeEnds: () ->
        @scopes.shift()

    Identify: (name) ->
        for scope in @scopes
            if scope.has(name)
                if scope.get(name).type in ['function', 'const', 'class', 'interface']
                    return name
                else
                    return '$' + name
        return '$' + name

    free: (name) ->
        if name is 'i'
            next = @indexGen.next
            until @has new Name next.name
                next = @indexGen.next
            return next
        else
            i = 0
            loop
                unless @has name + (if i is 0 then '' else i)
                    return new nodes.Identifier name + (if i is 0 then '' else i)
                i++