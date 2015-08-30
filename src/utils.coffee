exports.errorAt = (input, pos) ->
    res = input.split("\n")[pos.row - 1]
    res += '\n'
    for i in [0..pos.col]
        res += '^'
    return res