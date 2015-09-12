lexer = require './lexer'
Context = require '../context'

module.exports =
    compile: (code, system) ->
        lexer.setInput(code)
        tokens = lexer.tokenize()
        for token, i in tokens
            if token.type is 'VARIABLENAME'
                system.context.push new Context.Name token.value
            if token.type is 'NAME'
                if tokens[i - 1]?
                    token2 = tokens[i - 1]
                    if token2.type is 'FUNCTION'
                        system.context.push new Context.Name token.value, 'function'
                    if token2.type is 'CLASS'
                        system.context.push new Context.Name token.value, 'class'
                    if token2.type is 'INTERFACE'
                        system.context.push new Context.Name token.value, 'interface'
                    if token2.type is 'CONST'
                        system.context.push new Context.Name token.value, 'const'
             if token.type is 'STRING'
                if tokens[i - 1]? and tokens[i - 2]? and tokens[i - 1].type is '('
                    token3 = tokens[i - 2]
                    if token3.type is 'NAME' and token3.value is 'define'
                        system.context.push new Context.Name token.value[1...-1], 'const'

        return