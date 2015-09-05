nodes = require './nodes'

exports.errorAt = (input, pos) ->
    res = input.split("\n")[pos.row - 1]
    res += '\n'
    for i in [0..pos.col]
        res += '^'
    return res

exports.IndentGenerator = class IndentGenerator
    constructor:(@indent = '  ') ->
        @level = 0

    get: (num = @level) ->
        res = ''
        for  i in [0...num]
            res += @indent
        return res

    up: -> @level++

    down: -> @level--

exports.IndexGenerator = class IndexGenerator
    letter: ['i', 'j', 'k', 'c', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'a', 'b', 'c', 'd', 'e', 'f', 'j', 'h']
    _level: 1
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
        return new nodes.Identifier(r)