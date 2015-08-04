REGEX =
    EMPTYLINE: /(^[\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000]*[\n\r\u2028\u2029])/
    IDENTIFIER: /((^[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/
    INDENT: /(^[ \t]*)/
    LINETERMINATOR: /[\n\r\u2028]/
    NUMBER: /^(0b[01]+|0o[0-7]+|0(x|X)[\da-fA-F]+|\d*\.?\d+(?:(e|E)[+-]?\d+)?)/
    STRING: /^('[^\\']*(?:\\[\s\S][^\\']*)*'|"[^\\"]*(?:\\[\s\S][^\\"]*)*")/

KEYWORDS =
    CALLABLE: ['IDENTIFIER', ')', ']', '?', '@']
    CASTTYPE: ['array', 'binary', 'bool', 'boolean', 'double', 'int', 'integer', 'float', 'object', 'real', 'string', 'unset']
    RESERVED: ['clone', 'const', 'cte', 'func', 'in', 'instanceof', 'new', 'not', 'null']

class Lexer
    constructor: () ->
        @initialize()

    initialize: () ->
        @input = ''
        @inputLength = 0
        @Tokens = []
        @_Tokens = []
        @yytext = ''
        @pos = 0
        @Track =
            position:
                col: 1
                row: 1
            into:
                mammouth: off
                call: off
            indent:
                indentStack: []
                currentIndent: -1
                openedIndent: 0
        @lexed = off

    setInput: (code) ->
        @initialize()
        @input = code
        @inputLength = code.length

    lex: () ->
        if not @lexed
            @tokenize()
        token = @_Tokens.shift()
        if token
            @yytext = if token.value then token.value else ''
            return token.type

    tokenize: () ->
        m = 0;
        while m isnt undefined
            m = @nextToken();
        for token, i in @Tokens
            if token
                if token.type is 'MINDENT'
                    if @Tokens[i + 1] and @Tokens[i - 1]
                        if @Tokens[i + 1].type is ']' and @Tokens[i - 1].type is 'OUTDENT'
                            @Tokens.splice i, 1
                        if @Tokens[i + 1].type is 'CALL_END' and @Tokens[i - 1].type is 'OUTDENT'
                            @Tokens.splice i, 1
        @_Tokens = @Tokens
        @lexed = on
        return @Tokens

    posAdvance: (string) ->
        lines = string.split REGEX.LINETERMINATOR
        for line, i in lines
            if i is 0
                @Track.position.col += string.length
            else
                @Track.position.row++
                @Track.position.col = string.length

    colAdvance: (num = 1) ->
        @pos += num
        @Track.position.col += num

    addToken: (token) ->
        if token instanceof Array
            for tok in token
                @Tokens.push tok
            return token
        else
            @Tokens.push token
            return token

    lastToken: () ->
        if @Tokens[@Tokens.length - 1]
            @Tokens[@Tokens.length - 1].type

    nextToken: () ->
        return undefined if @pos is @inputLength
        # Everything out of '{{ }}' is a RAW text (html/xml...)
        if not @Track.into.mammouth
            return @readTokenRAW()
        # now let's lex what's into '{{ }}'
        if @isStartTag @pos
            return @readTokenStartTag()
        if @isEndTag @pos
            return @readTokenEndTag()
        # Skip empty lines
        if @lastToken() is 'LINETERMINAROR' and @isEmptyLines(@pos)
            return @skipEmptyLines()
        # Indent
        if @lastToken() is 'LINETERMINAROR' and @isIndent(@pos)
            @Tokens.pop()
            return @readIndent()
        if @isIdentifier @pos
            return @readTokenIdentifier()
        if @isNumber @pos
            return @readTokenNumber()
        if @isString @pos
            return @readTokenString()   
        return @getTokenFromCode @input.charCodeAt @pos

    # Tokenizing
    getTokenFromCode: (code) ->
        switch code
            when 10, 13, 8232 # 10 is "\n", 13 is "\r", 8232 is "\u2028"
                return @readLineTerminator()
            # Skip whitespaces
            when 32, 160, 5760, 6158, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288
                @colAdvance()
                @nextToken()
            when 33 # 33 is '!'
                @colAdvance()
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'COMPARE'
                        value: '!='
                    }
                return @addToken {
                    type: 'NOT'
                }
            when 37 # 37 is '%'
                @colAdvance()
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'ASSIGN'
                        value: '%='
                    }
                return @addToken {
                    type: '%'
                }
            when 38 # 38 is '&'
                @colAdvance()
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'ASSIGN'
                        value: '&='
                    }
                if @input.charCodeAt(@pos) is 38
                    @colAdvance()
                    return @addToken {
                        type: 'LOGIC'
                        value: '&&'
                    }
                return @addToken {
                    type: '&'
                }
            when 40 # 40 is '('
                @colAdvance()
                if @lastToken() in KEYWORDS.CALLABLE
                    @Track.into.call = on
                    return @addToken {
                        type: 'CALL_START'
                    }
                return @addToken {
                    type: '('
                }
            when 41 # 41 is ')'
                @colAdvance()
                if @Track.into.call is on
                    @Track.into.call = off
                    return @addToken {
                        type: 'CALL_END'
                    }
                return @addToken {
                    type: ')'
                }
            when 42 # 43 is '*'
                @colAdvance()
                if @input.charCodeAt(@pos) is 42
                    @colAdvance()
                    return @addToken {
                        type: '**'
                    }
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'ASSIGN'
                        value: '*='
                    }
                return @addToken {
                    type: '*'
                }
            when 43 # 43 is '+'
                @colAdvance()
                if @input.charCodeAt(@pos) is 43
                    @colAdvance()
                    return @addToken {
                        type: '++'
                    }
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'ASSIGN'
                        value: '+='
                    }
                return @addToken {
                    type: '+'
                }
            when 44 # 44 is ','
                @colAdvance()
                return @addToken {
                    type: ','
                }
            when 45 # 45 is '-'
                @colAdvance()
                switch @input.charCodeAt(@pos)
                    when 45
                        @colAdvance()
                        return @addToken {
                            type: '--'
                        }
                    when 61
                        @colAdvance()
                        return @addToken {
                            type: 'ASSIGN'
                            value: '-='
                        }
                    when 62
                        @colAdvance()
                        return @addToken {
                            type: '->'
                        }
                return @addToken {
                    type: '-'
                }
            when 46 # 46 is '.'
                @colAdvance()
                if @input.charCodeAt(@pos) is 46
                    @colAdvance()
                    return @addToken {
                        type: '..'
                    }
                return @addToken {
                    type: '.'
                }
            when 47 # 47 is '/'
                @colAdvance()
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'ASSIGN'
                        value: '/='
                    }
                return @addToken {
                    type: '/'
                }
            when 58 # 58 is ':'
                @colAdvance()
                if @input.charCodeAt(@pos) is 58
                    @colAdvance()
                    return @addToken {
                        type: '::'
                    }
                return @addToken {
                    type: ':'
                }
            when 60 # 60 is '<'
                @colAdvance()
                if @input.charCodeAt(@pos) is 60
                    @colAdvance()
                    if @input.charCodeAt(@pos) is 61
                        @colAdvance()
                        return @addToken {
                            type: 'ASSIGN'
                            value: '<<='
                        }
                    return @addToken {
                        type: 'BITWISE'
                        value: '<<'
                    }
                if @input.charCodeAt(@pos) is 45 and @input.charCodeAt(@pos + 1) is 62
                    # looking for '<->' 
                    @colAdvance(2)
                    return @addToken {
                        type: 'CONCAT'
                    }
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'COMPARE'
                        value: '<='
                    }
                return @addToken {
                    type: 'COMPARE'
                    value: '<'
                }
            when 61 # 61 is '='
                @colAdvance()
                if @input.charCodeAt(@pos) is 62
                    @colAdvance()
                    return @addToken {
                        type: '=>'
                    }
                if @input.charCodeAt(@pos) is 61 and @input.charCodeAt(@pos + 1) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'COMPARE'
                        value: '==='
                    }
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'COMPARE'
                        value: '=='
                    }
                return @addToken {
                    type: '='
                }
            when 62 # 62 is '>'
                @colAdvance()
                if @input.charCodeAt(@pos) is 62
                    @colAdvance()
                    if @input.charCodeAt(@pos) is 61
                        @colAdvance()
                        return @addToken {
                            type: 'ASSIGN'
                            value: '>>='
                        }
                    return @addToken {
                        type: 'BITWISE'
                        value: '>>'
                    }
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'COMPARE'
                        value: '>='
                    }
                return @addToken {
                    type: 'COMPARE'
                    value: '>'
                }
            when 63 # 63 is '?'
                @colAdvance()
                return @addToken {
                    type: '?'
                }
            when 64 # 61 is '@'
                @colAdvance()
                return @addToken {
                    type: '@'
                }  
            when 91 # 58 is ']'
                @colAdvance()
                @Track.into.array = on
                return @addToken {
                    type: '['
                }
            when 93 # 58 is ']'
                @colAdvance()
                @Track.into.array = off
                return @addToken {
                    type: ']'
                }
            when 94 # 94 is '^'
                @colAdvance()
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'ASSIGN'
                        value: '^='
                    }
                return @addToken {
                    type: 'BITWISE'
                    value: '^'
                }
            when 96 # 96 is '`'
                @colAdvance()
                return @addToken {
                    type: '`'
                }
            when 124 # 124 is '|'
                @colAdvance()
                if @input.charCodeAt(@pos) is 124
                    @colAdvance()
                    return @addToken {
                        type: 'BITWISE'
                        value: '||'
                    }
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'ASSIGN'
                        value: '|='
                    }
                return @addToken {
                    type: 'BITWISE'
                    value: '|'
                }
            when 126 # 126 is '~'
                @colAdvance()
                if @input.charCodeAt(@pos) is 126
                    @colAdvance()
                    if @input.charCodeAt(@pos) is 61
                        @colAdvance()
                        return @addToken {
                            type: 'ASSIGN'
                            value: '.='
                        }
                    return @addToken {
                        type: 'CONCAT'
                    }
                if @input.charCodeAt(@pos) is 61
                    @colAdvance()
                    return @addToken {
                        type: 'ASSIGN'
                        value: '.='
                    }
                return @addToken {
                    type: 'CONCAT'
                }

    readTokenRAW: () ->
        startPos = @pos
        while @pos < @inputLength and not @isStartTag @pos
            @pos++
        if @isStartTag @pos
            @Track.into.mammouth = on
        value = @input.slice startPos, @pos
        @posAdvance value
        return @addToken {
            type: 'RAW'
            value: value
        }

    readTokenStartTag: () ->
        @colAdvance 2
        return @addToken {type: '{{'}

    readTokenEndTag: () ->
        @colAdvance 2
        tokens = [{
            type: '}}'
        }]
        @Track.into.mammouth = off
        reversed = @reversedIndentStack()
        while @Track.indent.openedIndent
            if @lastToken() is 'LINETERMINAROR'
                @Tokens.pop()
            tokens.unshift {
                type: 'OUTDENT'
                length: reversed[@Track.indent.openedIndent - 1]
            }
            @Track.indent.openedIndent--
        if @lastToken() is 'LINETERMINAROR'
                @Tokens.pop()
        return @addToken tokens

    skipEmptyLines: () ->
        value = @input.slice(@pos).match(REGEX.EMPTYLINE)[0]
        @pos += value.length
        @posAdvance value
        return @nextToken()

    readLineTerminator: () ->
        @colAdvance()
        if @input.charCodeAt(@pos) in [10, 13, 8232]
            return @readLineTerminator()
        return @addToken {
            type: 'LINETERMINAROR'
        }

    readTokenIdentifier: () ->
        value = @input.slice(@pos).match(REGEX.IDENTIFIER)[0]
        @colAdvance value.length
        # it can be also a reserved words
        if value in ['true', 'false']
            return  @addToken {
                type: 'BOOL'
                value: value
            }
        if value in ['and', 'or', 'xor']
            return  @addToken {
                type: 'LOGIC'
                value: if value is 'and' then '&&' else if value is 'or' then '||' else value
            }
        if value is 'is'
            return  @addToken {
                type: 'COMPARE'
                value: "==="
            }
        if value is 'isnt'
            return  @addToken {
                type: 'COMPARE'
                value: '!='
            }
        # it can be a casting type
        if @lastToken() is '=>' and value in KEYWORDS.CASTTYPE
            return @addToken {
                type: 'CASTTYPE'
                value: value
            }
        if value in KEYWORDS.RESERVED
            if value is 'cte' then value = 'const'
            return  @addToken {
                type: value.toUpperCase()
            }
        return @addToken {
            type: 'IDENTIFIER'
            value: value
        }

    readIndent: () ->
        indent = @input.slice(@pos).match(REGEX.INDENT)[0]
        @colAdvance indent.length
        if indent.length > @Track.indent.currentIndent
            @Track.indent.currentIndent = indent.length
            @Track.indent.openedIndent++
            @Track.indent.indentStack.push indent.length
            return @addToken {
                type: 'INDENT'
                length: indent.length
            }
        else if indent.length is @Track.indent.currentIndent
            return @addToken {
                type: 'MINDENT'
                length: indent.length
            }
        else
            tokens = []
            # reversed @Track.indent.indentStack
            reversed = @reversedIndentStack()

            for indentLevel in reversed
                if indent.length is indentLevel
                    @Track.indent.currentIndent = indent.length
                    tokens.push {
                        type: 'MINDENT'
                        length: indent.length
                    }
                else if indent.length < indentLevel
                    @Track.indent.currentIndent = @Track.indent.indentStack.pop()
                    @Track.indent.openedIndent--
                    tokens.push {
                        type: 'OUTDENT'
                        value: indentLevel
                    }

            return @addToken tokens

    readTokenNumber: () ->
        value = @input.slice(@pos).match(REGEX.NUMBER)[0]
        @colAdvance value.length
        return @addToken {
            type: 'NUMBER'
            value: value
        }

    readTokenString: () ->
        value = @input.slice(@pos).match(REGEX.STRING)[0]
        @pos += value.length
        @posAdvance value
        return @addToken {
            type: 'STRING'
            value: value
        }

    # Scanning
    isStartTag: (pos) -> # 123 is '{'
        if @pos + 1 > @inputLength - 1
            return false
        return @input.charCodeAt(pos) is 123 and @input.charCodeAt(@pos + 1) is 123

    isEndTag: (pos) -> # 125 is '}'
        if @pos + 1 > @inputLength - 1
            return false
        return @input.charCodeAt(pos) is 125 and @input.charCodeAt(@pos + 1) is 125

    isEmptyLines: (pos) ->
        return @input.slice(pos).match(REGEX.EMPTYLINE) isnt null

    isIdentifier: (pos) ->
        return @input.slice(pos).match(REGEX.IDENTIFIER) isnt null

    isIndent: (pos) ->
        return @input.slice(pos).match(REGEX.INDENT) isnt null and @lastToken() isnt 'INDENT'

    isNumber: (pos) ->
        return @input.slice(pos).match(REGEX.NUMBER) isnt null

    isString: (pos) ->
        return @input.slice(pos).match(REGEX.STRING) isnt null

    # helpers
    reversedIndentStack: () ->
        reversed = []
        for i in @Track.indent.indentStack
            reversed.unshift i
        return reversed

module.exports = new Lexer