nodes = require './nodes'

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
            next = @indexGen.get()
            while @has next
                next = @indexGen.get()
            @push new Name next
            return next
        else
            i = 0
            loop
                unless @has name + (if i is 0 then '' else i)
                    @push new Name name + (if i is 0 then '' else i)
                    return name + (if i is 0 then '' else i)
                i++

exports.IndexGenerator = class IndexGenerator
    letter: ['i', 'j', 'k', 'c', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'a', 'b', 'c', 'd', 'e', 'f', 'j', 'h']
    _level: 0
    letterLevel: 0

    generateAtLevel: ->
        r = ''
        i = 0
        while i < @_level
            r += '_'
            i++
        return r
        
    next: ->
        if (@letterLevel + 1) is @letter.length
            @_level++
            @letterLevel = 0
        else
            @letterLevel++

    get: ->
        r = @generateAtLevel() + @letter[@letterLevel]
        @next()
        return r