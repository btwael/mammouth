###
    This is just aaditmshah/lexer (https://github.com/aaditmshah/lexer) lexer rewrited
    in coffeescript with some addtion:
        * the `look` function that allow to detect next token into addRule
###
Lexer = (defunct) ->
    if typeof defunct isnt 'function'
        defunct = (char) ->
            throw new Error 'Unexpected character at index ' + (@index - 1) + ': ' + char

    tokens = []
    @rules = []
    remove = 0
    @state = 0
    @index = 0
    @input = ''

    @addRule = (pattern, action, start) ->
        global = pattern.global

        if not global
            flags = "g"
            flags += "m" if pattern.multiline
            flags += "i" if pattern.ignoreCase
            pattern = new RegExp pattern.source, flags

        if Object.prototype.toString.call(start) isnt "[object Array]"
            start = [0]

        @rules.push {
            pattern: pattern
            global: global
            action: action
            start: start
        }

        return @

    @setInput = (input) ->
        remove = 0
        @state = 0
        @index = 0
        @input = input
        return @

    @lex = ->
        if tokens.length
            return tokens.shift()

        @reject = true

        while @index <= @input.length
            matches = scan.call(@).splice remove
            index = @index

            while matches.length
                if @reject
                    match = matches.shift();
                    result = match.result
                    length = match.length
                    @index += length
                    @reject = false
                    remove++

                    token = match.action.apply @, result
                    if @reject
                        @index = result.index
                    else if typeof token isnt 'undefined'
                        switch Object.prototype.toString.call token
                            when '[object Array]'
                                tokens = token.slice(1)
                                token = token[0]
                            else
                                if length
                                    remove = 0
                                return token
                else
                    break

            input = @input

            if index < input.length
                if @reject
                    remove = 0
                    token = defunct.call @, input.charAt @index++
                    if typeof token isnt 'undefined'
                        if Object.prototype.toString.call(token) is '[object Array]'
                            tokens = token.slice 1
                            return token[0]
                        else
                            return token
                else
                    if @index isnt index
                        remove = 0
                    @reject = true
            else if matches.length
                @reject = true
            else
                break

    scan = ->
        matches = []
        index = 0

        state = @state
        lastIndex = @index
        input = @input

        for rule in @rules
            start = rule.start
            states = start.length

            if (not states or start.indexOf(state) >= 0) or (state % 2 and states is 1 and not start[0])
                pattern = rule.pattern
                pattern.lastIndex = lastIndex
                result = pattern.exec input

                if result and result.index is lastIndex
                    j = matches.push {
                        result: result
                        action: rule.action
                        length: result[0].length
                    }

                    if rule.global
                        index = j

                    while --j > index
                        k = j - 1

                        if matches[j].length > matches[k].length
                            temple = matches[j]
                            matches[j] = matches[k]
                            matches[k] = temple;

        return matches

    @look = (num = 1) ->
        lexer = new Lexer
        lexer.state = @state
        lexer.index = @index
        lexer.input = @input
        lexer.rules = @rules
        res = null
        i = 0
        while i < num 
            res = lexer.lex()
            i++
        return res

    return @

module.exports = Lexer