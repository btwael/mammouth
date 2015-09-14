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