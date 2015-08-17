class Lexer
    setInput: (input) ->
        # Initialing the lexer
        @yytext = '' # value passed to parser (eg. identifier name)

        @Track = # important tracking data for lexer
            position:
                row: 1
                col: 0
            into:
                array: off
                call: off # when it's on, it means that between '(' & ')' of an invocation 
                mammouth: off # when it's on/true, it means that lexer is into code block, between '{{' & '}}'
            indent: [ # We can have many ident stacks,
                      # cause by example between '(' & ')', indent leveling can be independent of global one
                {
                    indentStack: [] # The stack of all current indentation lengths
                    currentIndent: -1 # current indent length
                    openedIndent: 0 # number of opend indent
                }
            ]

        @Tokens = [] # Stream of parsed tokens

        @pos = 0 # position of lexer
        @input = input = input.replace(/\r\n/g, '\n')
        @inputLength = input.length
        @lexed = off

    # Other lexer methods can be categorized to
        # Tracking: helpful functions to simplify error detection and position tracking
        # scanning: those functions only check type/form of code at certain position
        # tokenizing: those functions are responsible to generate tokens, also determine indents
        # rewriting: this one add additional tokens to the result to avoid confusion while parsing 

    # Tracking
    addToken: (tokens) -> # add tokens to the tokens stream list
        if tokens instanceof Array
            for token in tokens
                @Tokens.push token
        else
            @Tokens.push tokens
        return tokens

    posAdvance: (string, incPos = on) -> # increase position by given string
        @pos += string.length if incPos
        lines = string.split REGEX.LINETERMINATOR
        for line, i in lines
            if i is 0
                @Track.position.col += string.length
            else
                @Track.position.row++
                @Track.position.col = line.length

    colAdvance: (num = 1) -> # increase position by number of column
        @pos += num
        @Track.position.col += num

    rowAdvance: (num = 1) -> # increase position by number of column
        @pos += num
        @Track.position.row += num
        @Track.position.col = 0

    getPos: () ->
        JSON.parse JSON.stringify @Track.position

    last: (num = 1) -> # get the previous token
        if @Tokens[@Tokens.length - num]
            return @Tokens[@Tokens.length - num]
        return undefined

    next: (num = 1) -> # get the supposed next token
        lexer = new Lexer
        lexer.yyloc = @yyloc
        lexer.Track = JSON.parse JSON.stringify @Track
        lexer.Tokens = JSON.parse JSON.stringify @Tokens
        lexer.pos = @pos
        lexer.input = @input
        lexer.inputLength = @inputLength
        lexer.name = 2
        while num > 0
            lexer.nextToken()
            num--
        return lexer.Tokens[lexer.Tokens.length - 1]

    charCode: (pos = @pos) ->
        return @input.charCodeAt pos

    # Tokenizing
    lex: () ->
        if not @lexed
            @tokenize()
        token = @Tokens.shift()
        if token
            @yytext = if token.value then token.value else ''
            @yylloc =
                first_column: token.loc.start.col
                first_line: token.loc.start.row
                last_line: token.loc.end.row
                last_column: token.loc.end.col
            return token.type

    tokenize: () -> # get list of all tokens
        m = 0;
        while m isnt undefined
            m = @nextToken();
        @rewrite()
        @lexed = on
        return @Tokens

    nextToken: () ->
        return undefined if @pos is @inputLength

        # Everything out of '{{ }}' is a RAW text (html/xml...)
        if not @Track.into.mammouth
            return @readTokenRAW()

        # now let's lex what's into '{{ }}'
        if @isStartTag()
            return @readTokenStartTag()
        if @isEndTag()
            return @readTokenEndTag()

        # Skip empty lines
        if @last().type is 'LINETERMINATOR' and @isEmptyLines()
            return @skipEmptyLines()

        # Indent
        if @last().type is 'LINETERMINATOR' and @isIndent()
            @Tokens.pop()
            return @readIndent()

        # check for identifier
        if @isIdentifier()
            return @readTokenIdentifier()

        # check for number
        if @isNumber()
            return @readTokenNumber()
        
        # check for string
        if @isString()
            return @readTokenString() 

        return @getTokenFromCode @charCode()

    readTokenRAW: () ->
        token = @newToken()
        startPos = @pos
        while @pos < @inputLength and not @isStartTag()
            @pos++
        if @isStartTag()
            @Track.into.mammouth = on
        value = @input.slice startPos, @pos
        @posAdvance value, off
        token.loc.end = @getPos()
        return @addToken collect {
            type: 'RAW'
            value: value
        }, token

    readTokenStartTag: () ->
        token = @newToken()
        @colAdvance(2)
        token.loc.end = @getPos()
        return @addToken collect {
            type: '{{'
        }, token

    readTokenEndTag: () ->
        token = @newToken()
        @colAdvance(2)
        token.loc.end = @getPos()
        tokens = [
            collect {
                type: '}}'
            }, token
        ]
        tokens = @closeIndent(0, token).concat tokens
        @Track.into.mammouth = off
        return @addToken tokens

    readIndent: () ->
        token = @newToken()
        indent = @input.slice(@pos).match(REGEX.INDENT)[0]
        @colAdvance indent.length
        token.loc.end = @getPos()
        if indent.length > @Track.indent[0].currentIndent
            @Track.indent[0].currentIndent = indent.length
            @Track.indent[0].openedIndent++
            @Track.indent[0].indentStack.push {
                length: indent.length
            }
            return @addToken collect {
                type: 'INDENT'
                length: indent.length
            }, token
        else if indent.length is @Track.indent[0].currentIndent
            return @addToken collect {
                type: 'MINDENT'
                length: indent.length
            }, token
        else
            tokens = []
            # reversed @Track.indent.indentStack
            reversed = @reversedIndentStack()

            for indentLevel in reversed
                if indent.length is indentLevel.length
                    @Track.indent[0].currentIndent = indent.length
                    tokens.push collect {
                        type: 'MINDENT'
                        length: indent.length
                    }, token
                else if indent.length < indentLevel.length
                    @Track.indent[0].currentIndent = @Track.indent[0].indentStack.pop().length
                    @Track.indent[0].openedIndent--
                    tokens.push collect {
                        type: 'OUTDENT'
                        value: indentLevel.length
                    }, token

            return @addToken tokens

    readTokenIdentifier: () ->
        token = @newToken()
        value = @input.slice(@pos).match(REGEX.IDENTIFIER)[0]
        @colAdvance value.length
        token.loc.end = @getPos()
        # check for boolean
        if value.toUpperCase() in KEYWORDS.BOOL
            return @addToken collect {
                type: 'BOOL'
                value: value
            }, token

        # check for operator
        if value in KEYWORDS.LOGIC
            return @addToken collect {
                type: 'LOGIC'
                value: if value is 'and' then '&&' else if value is 'or' then '||' else value
            }, token
        if value in KEYWORDS.COMPARE
            return @addToken collect {
                type: 'COMPARE'
                value: if value is 'is' then '===' else if value is 'isnt' then '!=' else value
            }, token

        # check for casting type
        if @last().type is '=>' and value in KEYWORDS.CASTTYPE
            return @addToken collect {
                type: 'CASTTYPE'
                value: value
            }, token

        # check for other reserved words
        if value in KEYWORDS.RESERVED
            if (value in ['if', 'unless']) and not (@last().type in ['INDENT', 'MINDENT', 'OUTDENT', '(', 'CALL_START', ','])
                return @addToken collect {
                    type: 'POST_IF'
                    value: if value is 'if' then off else on
                }, token
            if value in ['if', 'unless']
                return @addToken collect {
                    type: 'IF'
                    value: if value is 'if' then off else on
                }, token
            if value is 'then'
                length = @Track.indent[0].currentIndent + 1
                @Track.indent[0].currentIndent = length
                @Track.indent[0].openedIndent++
                @Track.indent[0].indentStack.push {
                    length: length
                    sensible: on
                }
                return @addToken collect {
                        type: 'INDENT'
                        length: length
                }, token
            if value is 'else'
                res = @closeSensibleIndent(0, token)
                if res[0] is on
                    return @addToken res[1].concat collect {
                        type: value.toUpperCase()
                    }, token
            return @addToken collect {
                type: value.toUpperCase()
            }, token

        # other php reserved words can't be identifiers
        if value in KEYWORDS.PHPRESERVED
            # throw error
            return @addToken collect {
                type: 'UNEXPECTED'
                value: value
            }, token

        # if it's not a reserved word then it's an identifier
        return @addToken collect {
            type: 'IDENTIFIER'
            value: value
        }, token

    readTokenNumber: () ->
        token = @newToken()
        value = @input.slice(@pos).match(REGEX.NUMBER)[0]
        @colAdvance value.length
        token.loc.end = @getPos()
        return @addToken collect {
            type: 'NUMBER'
            value: value
        }, token

    readTokenString: () ->
        token = @newToken()
        value = @input.slice(@pos).match(REGEX.STRING)[0]
        @posAdvance value
        token.loc.end = @getPos()
        return @addToken collect {
            type: 'STRING'
            value: value
        }, token

    getTokenFromCode: (code) ->
        token = @newToken()
        switch code
            when 10, 13, 8232 # 10 is "\n", 13 is "\r", 8232 is "\u2028"
                return @readLineTerminator()
            # Skip whitespaces
            when 32, 160, 5760, 6158, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288
                @colAdvance()
                return @nextToken()
            when 33 # 33 is '!'
                @colAdvance()
                # look for '!='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'COMPARE'
                        value: '!='
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: 'NOT'
                }, token
            when 37 # 37 is '%'
                @colAdvance()
                # look for '%='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'ASSIGN'
                        value: '%='
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: '%'
                }, token
            when 38 # 38 is '&'
                @colAdvance()
                switch @charCode()
                    # look for '&='
                    when 61 # 61 is '='
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: 'ASSIGN'
                            value: '&='
                        }, token
                    # look for '&&'
                    when 38 # 38 is '&'
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: 'LOGIC'
                            value: '&&'
                        }, token
                    else
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: '&'
                        }, token
            when 40 # 40 is '('
                @colAdvance()
                token.loc.end = @getPos()
                @addIndentLevel()
                if @last().type in KEYWORDS.CALLABLE and @last(2).type isnt 'FUNC'
                    @Track.into.call = on
                    return @addToken collect {
                        type: 'CALL_START'
                    }, token
                return @addToken collect {
                    type: '('
                }, token
            when 41 # 41 is ')'
                @colAdvance()
                token.loc.end = @getPos()
                if @Track.into.call is on
                    @Track.into.call = off
                    tokens = [
                        collect {
                            type: 'CALL_END'
                        }, token
                    ]
                    tokens = @closeIndent(0, token).concat tokens
                    @closeIndentLevel()
                    return @addToken tokens
                tokens = [
                    collect {
                        type: ')'
                    }, token
                ]
                tokens = @closeIndent(0, token).concat tokens
                @closeIndentLevel()
                return @addToken tokens
            when 42 # 43 is '*'
                @colAdvance()
                switch @charCode()
                    # look for '**'
                    when 42 # 42 is '*'
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: '**'
                        }, token
                    # look for '*='
                    when 61 # 61 is '='
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: 'ASSIGN'
                            value: '*='
                        }, token
                    else
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: '*'
                        }, token
            when 43 # 43 is '+'
                @colAdvance()
                switch @charCode()
                    # look for '++'
                    when 43 # 43 is '+
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: '++'
                        }, token
                    # look for '*+='
                    when 61 # 61 is '=
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: 'ASSIGN'
                            value: '+='
                        }, token
                    else
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: '+'
                        }, token
            when 44 # 44 is ','
                @colAdvance()
                token.loc.end = @getPos()
                return @addToken collect {
                    type: ','
                }, token
            when 45 # 45 is '-'
                @colAdvance()
                switch @charCode()
                    # look for '--'
                    when 45 # 45 is '-'
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: '--'
                        }, token
                    # look for '-='
                    when 61 # 61 is '='
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: 'ASSIGN'
                            value: '-='
                        }, token
                    # look for '->'
                    when 62 # 61 is '>'
                        @colAdvance()
                        token.loc.end = @getPos()
                        tokens = [
                            collect {
                                type: '->'
                            }, token
                        ]
                        next = @next(2).type
                        if next isnt 'INDENT'
                            if next in ['MINDENT', 'OUTDENT', 'LINETERMINATOR']
                                tokens.push collect {
                                    type: 'INDENT'
                                    length: @Track.indent[0].currentIndent + 1
                                }, token
                                tokens.push collect {
                                    type: 'OUTDENT'
                                    length: @Track.indent[0].currentIndent + 1
                                }, token
                            else
                                length = @Track.indent[0].currentIndent + 1
                                @Track.indent[0].currentIndent = length
                                @Track.indent[0].openedIndent++
                                @Track.indent[0].indentStack.push {
                                    length: length
                                }
                                tokens.push collect {
                                    type: 'INDENT'
                                    length: length
                                }, token
                        return @addToken tokens
                    else
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: '-'
                        }, token
            when 46 # 46 is '.'
                @colAdvance()
                # look for '..'
                if @charCode() is 46 # 46 is '.'
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: '..'
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: '.'
                }, token
            when 47 # 47 is '/'
                @colAdvance()
                # look for '/='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'ASSIGN'
                        value: '/='
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: '/'
                }, token
            when 58 # 58 is ':'
                @colAdvance()
                # look for '::'
                if @charCode() is 58 # 58 is ':'
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: '::'
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: ':'
                }, token
            when 60 # 60 is '<'
                @colAdvance()
                if @charCode() is 60 # 60 is '<'
                    @colAdvance()
                    # look for '<<='
                    if @charCode() is 61 # 61 is '='
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: 'ASSIGN'
                            value: '<<='
                        }, token
                    # then it's just '<<'
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'BITWISE'
                        value: '<<'
                    }, token
                # look for '<->'
                if @charCode() is 45 and @charCode(@pos + 1) is 62 # 45 is '-' and 62 is '>'
                    @colAdvance(2)
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'CONCAT'
                    }, token
                # look for '<='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'COMPARE'
                        value: '<='
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: 'COMPARE'
                    value: '<'
                }, token
            when 61 # 61 is '='
                @colAdvance()
                # look for '=>'
                if @charCode() is 62 # 62 is '>'
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: '=>'
                    }, token
                # look for '==='
                if @charCode() is 61 and @charCode(@pos + 1) is 61 # 61 is '='
                    @colAdvance(2)
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'COMPARE'
                        value: '==='
                    }, token
                # look for '=='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'COMPARE'
                        value: '=='
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: '='
                }, token
            when 62 # 62 is '>'
                @colAdvance()
                if @charCode() is 62 # 62 is '>'
                    @colAdvance()
                    # look for '>>='
                    if @charCode() is 61 # 61 is '='
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: 'ASSIGN'
                            value: '>>='
                        }, token
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'BITWISE'
                        value: '>>'
                    }, token
                # look for '>='
                if @charCode() is 61
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'COMPARE'
                        value: '>='
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: 'COMPARE'
                    value: '>'
                }, token
            when 63 # 63 is '?'
                @colAdvance()
                token.loc.end = @getPos()
                return @addToken collect {
                    type: '?'
                }, token
            when 64 # 61 is '@'
                @colAdvance()
                token.loc.end = @getPos()
                return @addToken collect {
                    type: '@'
                }, token
            when 91 # 58 is ']'
                @colAdvance()
                @addIndentLevel()
                @Track.into.array = on
                token.loc.end = @getPos()
                return @addToken collect {
                    type: '['
                }, token
            when 93 # 58 is ']'
                @colAdvance()
                token.loc.end = @getPos()
                @Track.into.array = off
                tokens = [
                    collect {
                        type: ']'
                    }, token
                ]
                tokens = @closeIndent(0, token).concat tokens
                @closeIndentLevel()
                return @addToken tokens
            when 94 # 94 is '^'
                @colAdvance()
                # look for '^='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'ASSIGN'
                        value: '^='
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: 'BITWISE'
                    value: '^'
                }, token
            when 96 # 96 is '`'
                @colAdvance()
                token.loc.end = @getPos()
                return @addToken collect {
                    type: '`'
                }, token
            when 124 # 124 is '|'
                @colAdvance()
                # look for '||'
                if @charCode() is 124 # 124 is '|'
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'BITWISE'
                        value: '||'
                    }, token
                # look for '|='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'ASSIGN'
                        value: '|='
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: 'BITWISE'
                    value: '|'
                }, token
            when 126 # 126 is '~'
                @colAdvance()
                if @charCode() is 126 # 126 is '~'
                    @colAdvance()
                    # look for '~~='
                    if @charCode() is 61 # 61 is '='
                        @colAdvance()
                        token.loc.end = @getPos()
                        return @addToken collect {
                            type: 'ASSIGN'
                            value: '.='
                        }, token
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'CONCAT'
                    }, token
                # look for '~='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    token.loc.end = @getPos()
                    return @addToken collect {
                        type: 'ASSIGN'
                        value: '.='
                    }, token
                token.loc.end = @getPos()
                return @addToken collect {
                    type: 'CONCAT'
                }, token
            else
                # throw error

    readLineTerminator: () ->
        token = @newToken()
        @rowAdvance()
        if @charCode() in [10, 13, 8232]
            return @readLineTerminator()
        token.loc.end = @getPos()
        return @addToken collect {
            type: 'LINETERMINATOR'
        }, token

    skipEmptyLines: () ->
        value = @input.slice(@pos).match(REGEX.EMPTYLINE)[0]
        @posAdvance value
        return @nextToken()

    # Scanning
    isStartTag: (pos = @pos) ->
        return false if @pos + 1 > @inputLength - 1
        return @charCode(pos) is 123 and @charCode(@pos + 1) is 123 # 123 is '{'

    isEndTag: (pos = @pos) ->
        return false if @pos + 1 > @inputLength - 1
        return @charCode(pos) is 125 and @charCode(@pos + 1) is 125 # 125 is '}'

    isEmptyLines: (pos = @pos) ->
        return @input.slice(pos).match(REGEX.EMPTYLINE) isnt null

    isIdentifier: (pos = @pos) ->
        return @input.slice(pos).match(REGEX.IDENTIFIER) isnt null

    isIndent: (pos = @pos) ->
        return @input.slice(pos).match(REGEX.INDENT) isnt null and @last().type isnt 'INDENT'

    isNumber: (pos = @pos) ->
        return @input.slice(pos).match(REGEX.NUMBER) isnt null

    isString: (pos = @pos) ->
        return @input.slice(pos).match(REGEX.STRING) isnt null

    # Rewriting
    rewrite: () ->  
        for token, i in @Tokens
            if token
                if token.type is 'MINDENT' and @Tokens[i + 1] and @Tokens[i + 1].type in ['CATCH', 'ELSE', 'FINALLY']
                    @Tokens.splice i, 1
        
    # helpers
    newToken: () ->
        return {
            loc:
                start: @getPos()
        }

    addIndentLevel: () ->
        @Track.indent.unshift {
            indentStack: []
            currentIndent: -1
            openedIndent: 0
        }

    closeIndentLevel: () -> @Track.indent.shift()

    reversedIndentStack: (level = 0) ->
        reversed = []
        for i in @Track.indent[level].indentStack
            reversed.unshift i
        return reversed

    closeIndent: (level = 0, posTok = {}) ->
        tokens = []
        reversed = @reversedIndentStack()
        while @Track.indent[level].openedIndent
            if @last().type in ['LINETERMINAROR', 'MINDENT']
                @Tokens.pop()
            tokens.unshift collect {
                type: 'OUTDENT'
                length: reversed[@Track.indent[0].openedIndent - 1].length
            }, posTok
            @Track.indent[0].openedIndent--
        if @last().type is 'LINETERMINATOR'
            @Tokens.pop()
        return tokens

    closeSensibleIndent: (level = 0, posTok = 0) ->
        res = [off]
        if @Track.indent[level].indentStack[@Track.indent[level].indentStack.length - 1] and @Track.indent[level].indentStack[@Track.indent[level].indentStack.length - 1].sensible is on
            (res[0] = on) and (res.push [])
            length = @Track.indent[0].indentStack.pop().length - 1
            @Track.indent[0].currentIndent = length
            @Track.indent[0].openedIndent--
            res[1].push collect {
                type: 'OUTDENT'
                length: length
            }, posTok
        return res


collect = -> # {n:1} + {l:2} = {n:1, l:2}
    ret = {}
    for object in arguments
        for key, value of object
            ret[key] = value
    return ret

REGEX = # some useful regular expression
    EMPTYLINE: /(^[\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000]*[\n\r\u2028\u2029])/
    IDENTIFIER: /((^[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/
    INDENT: /(^[ \t]*)/
    LINETERMINATOR: /[\n\r\u2028]/
    NUMBER: /^(0b[01]+|0o[0-7]+|0(x|X)[\da-fA-F]+|\d*\.?\d+(?:(e|E)[+-]?\d+)?)/
    STRING: /^('[^\\']*(?:\\[\s\S][^\\']*)*'|"[^\\"]*(?:\\[\s\S][^\\"]*)*")/

KEYWORDS =
    CALLABLE: ['CALL_END', 'IDENTIFIER', ')', ']', '?', '@']
    BOOL: ['TRUE', 'FALSE']
    CASTTYPE: ['array', 'binary', 'bool', 'boolean', 'double', 'int', 'integer', 'float', 'object', 'real', 'string', 'unset']
    COMPARE: ['is', 'isnt']
    LOGIC: ['and', 'or', 'xor']
    RESERVED: ['catch', 'clone', 'const', 'cte', 'else', 'finally', 'func', 'if', 'in', 'instanceof', 'loop', 'new', 'not', 'null', 'then', 'try', 'unless', 'until', 'use', 'when', 'while']
    PHPRESERVED: [
        'abstract', 'and', 'array', 'as'
        'break'
        'callable', 'case', 'catch', 'class', 'clone', 'const', 'continue'
        'declare', 'default', 'die', 'do'
        'echo', 'else', 'elseif', 'empty', 'enddeclare', 'endfor', 'endforeach', 'endif', 'endswitch', 'endwhile', 'eval', 'exit', 'extends'
        'final', 'finally', 'for', 'foreach', 'function'
        'global', 'goto'
        'if', 'implements', 'include', 'include_once', 'instanceof', 'insteadof', 'interface', 'isset'
        'list'
        'namespace', 'new'
        'or'
        'print', 'private', 'protected', 'public'
        'require', 'require_once', 'return'
        'static', 'switch'
        'throw', 'trait', 'try'
        'unset', 'use'
        'var'
        'while'
    ]

module.exports = new Lexer