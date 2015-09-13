{errorAt} = require './utils'

class Lexer
    setInput: (input) ->
        @yytext = '' # value passed to parser (eg. identifier name)

        @track =
            position: new Position
            into:
                php: off # when it's on/true, it means that lexer is into code block, between '<?php' & '?>'
            opened: []

        @tokens = [] # stream of tokens

        @pos = 0 # lexer position
        @input = input.replace(/\r\n/g, '\n')

    # Other lexer methods can be categorized to
        # Tracking: helpful functions to simplify error detection and position tracking
        # scanning: those functions only check type/form of code at certain position
        # tokenizing: those functions are responsible to generate tokens, also determine indents
        # rewriting: this one add additional tokens to the result to avoid confusion while parsing 

    # Tracking
    addToken: (tokens) -> # add tokens to the tokens stream list
        if tokens instanceof Array
            for token in tokens
                if token.type in ['INDENT', 'MINDENT', 'LINETERMINATOR']
                    @track.into.for = off
                @tokens.push token
        else
            @tokens.push tokens
        return tokens

    getPos: () -> @track.position.clone()

    posAdvance: (string, incPos = on) -> # increase position by given string
        @pos += string.length if incPos
        lines = string.split REGEX.LINETERMINATOR
        for line, i in lines
            if i is 0
                @track.position.col += string.length
            else
                @track.position.row++
                @track.position.col = line.length

    colAdvance: (num = 1) -> # increase position by number of column
        @pos += num
        @track.position.col += num

    rowAdvance: (num = 1) -> # increase position by number of column
        @pos += num
        @track.position.row += num
        @track.position.col = 0

    last: (num = 1) -> # get the previous token
        if @tokens[@tokens.length - num]
            return @tokens[@tokens.length - num]
        return undefined

    next: (num = 1) -> # get the supposed next token
        lexer = new Lexer
        lexer.track = JSON.parse JSON.stringify @track
        lexer.track.position = @track.position.clone()
        lexer.tokens = JSON.parse JSON.stringify @tokens
        lexer.pos = @pos
        lexer.input = @input
        while num > 0
            lexer.nextToken()
            num--
        return lexer.tokens[lexer.tokens.length - 1]

    charCode: (pos = @pos) -> @input.charCodeAt pos

    # Tokenizing
    lex: ->
        if not @lexed
            @tokenize()
        token = @tokens.shift()
        if token
            @yytext = if token.value then token.value else ''
            @yylloc =
                first_column: token.location.start.col
                first_line: token.location.start.row
                last_line: token.location.end.row
                last_column: token.location.end.col
            return token.type

    tokenize: -> # get list of all tokens
        m = 0;
        while m isnt undefined
            m = @nextToken();
        @lexed = on
        return @tokens

    nextToken: ->
        return undefined if @pos is @input.length

        # Everything out of '<?php ?>' is a RAW text (html/xml...)
        if not @track.into.php
            return @readTokenRAW()

        # now let's lex the php script
        if @isStartTag()
            return @readTokenStartTag()
        if @isEndTag()
            return @readTokenEndTag()

        # check for comments and skip them
        if @isComment()
            return @skipComment()

        # check for variable
        if @isVariable()
            return @readTokenVariable()

        # check for variable
        if @isName()
            return @readTokenName()

        # check for number
        if @isNumber()
            return @readTokenNumber()

        # check for string
        if @isString()
            return @readTokenString()

        return @getTokenFromCode @charCode()

    readTokenRAW: ->
        token = (new Token 'RAW').setStart @getPos()
        startPos = @pos
        while @pos < @input.length and not @isStartTag()
            @pos++
        if @isStartTag()
            @track.into.php = on
        value = @input.slice startPos, @pos
        @posAdvance value, off
        return @addToken token.set('value', value).setEnd(@getPos())

    readTokenStartTag: ->
        token = (new Token 'STARTTAG').setStart @getPos()
        value = @input.slice(@pos).match(REGEX.STARTTAG)[0]
        @colAdvance(value.length)
        @track.opened.unshift {
            type: 'STARTTAG'
            closableBy: 'ENDTAG'
        }
        return @addToken token.setEnd @getPos()

    readTokenEndTag: ->
        token = (new Token 'ENDTAG').setStart @getPos()
        @colAdvance(2)
        token.setEnd @getPos()
        @track.into.php = off
        tokens = [token]
        # close opened
        if @track.opened[0].type is 'STARTTAG'
            @track.opened.shift()
            # tokens = tokens.concat token
        return @addToken tokens

    readTokenVariable: () ->
        token = (new Token 'VARIABLENAME').setStart @getPos()
        value = @input.slice(@pos).match(REGEX.VARIABLE)[0]
        @posAdvance value
        return @addToken token.set('value', value.slice(1)).setEnd @getPos()

    readTokenName: () ->
        token = (new Token).setStart @getPos()
        value = @input.slice(@pos).match(REGEX.NAME)[0]
        @posAdvance value
        if value.toUpperCase() in ['TRUE', 'FALSE']
            return @addToken token.set('type', 'BOOL').set('value', value).setEnd @getPos()
        if value.toLowerCase() in KEYWORDS.PHPRESERVED
            return @addToken token.set('type', value.toUpperCase()).setEnd @getPos()
        return @addToken token.set('type', 'NAME').set('value', value).setEnd @getPos()

    readTokenNumber: () ->
        token = (new Token 'NUMBER').setStart @getPos()
        value = @input.slice(@pos).match(REGEX.NUMBER)[0]
        @colAdvance value.length
        return @addToken token.set('value', value).setEnd @getPos()

    readTokenString: () ->
        token = (new Token 'STRING').setStart @getPos()
        value = @input.slice(@pos).match(REGEX.STRING)[0]
        @posAdvance value
        return @addToken token.set('value', value).setEnd @getPos()

    getTokenFromCode: (code) ->
        startPos = @getPos()
        token = (new Token).setStart startPos
        @colAdvance()
        switch code
            when 10, 13, 8232 # 10 is "\n", 13 is "\r", 8232 is "\u2028"
                @colAdvance(-1)
                @rowAdvance()
                return @nextToken()
            # Skip whitespaces
            when 32, 160, 5760, 6158, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288
                return @nextToken()
            when 33
                if @charCode() is 61
                    @colAdvance()
                    if @charCode() is 61
                        @colAdvance()
                        return @addToken token.set('type', 'COMPARE').set('value', '!==').setEnd @getPos()
                    return @addToken token.set('type', 'COMPARE').set('value', '!=').setEnd @getPos()
                return @addToken token.set('type', '!').setEnd @getPos()
            when 36
                return @addToken token.set('type', '$').setEnd @getPos()
            when 37
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '%=').setEnd @getPos()
                return @addToken token.set('type', '%').setEnd @getPos()
            when 38
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '&=').setEnd @getPos()
                if @charCode() is 38
                    @colAdvance()
                    return @addToken token.set('type', 'LOGIC').set('value', '&&').setEnd @getPos()
                return @addToken token.set('type', '&').setEnd @getPos()
            when 40
                return @addToken token.set('type', '(').setEnd @getPos()
            when 41
                return @addToken token.set('type', ')').setEnd @getPos()
            when 42
                if @charCode() is 42
                    @colAdvance()
                    if @charCode() is 61
                        @colAdvance()
                        return @addToken token.set('type', 'ASSIGN').set('value', '**=').setEnd @getPos()
                    return @addToken token.set('type', '**').setEnd @getPos()
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '*=').setEnd @getPos()
                return @addToken token.set('type', '*').setEnd @getPos()
            when 43
                if @charCode() is 43
                    @colAdvance()
                    return @addToken token.set('type', '++').setEnd @getPos()
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '+=').setEnd @getPos()
                return @addToken token.set('type', '+').setEnd @getPos()
            when 44
                return @addToken token.set('type', ',').setEnd @getPos()
            when 45
                if @charCode() is 62
                    @colAdvance()
                    return @addToken token.set('type', '->').setEnd @getPos()
                if @charCode() is 45
                    @colAdvance()
                    return @addToken token.set('type', '--').setEnd @getPos()
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '-=').setEnd @getPos()
                return @addToken token.set('type', '-').setEnd @getPos()
            when 46
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '.=').setEnd @getPos()
                return @addToken token.set('type', '.').setEnd @getPos()
            when 47
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '/=').setEnd @getPos()
                return @addToken token.set('type', '/').setEnd @getPos()
            when 58
                if @charCode() is 58
                    @colAdvance()
                    return @addToken token.set('type', '::').setEnd @getPos()
                return @addToken token.set('type', ':').setEnd @getPos()
            when 59
                return @addToken token.set('type', ';').setEnd @getPos()
            when 60
                if @charCode() is 60
                    @colAdvance()
                    if @charCode() is 61
                        @colAdvance()
                        return @addToken token.set('type', 'ASSIGN').set('value', '<<=').setEnd @getPos()
                    return @addToken token.set('type', 'BITWISE').set('value', '<<').setEnd @getPos()
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'COMPARE').set('value', '<=').setEnd @getPos()
                return @addToken token.set('type', 'COMPARE').set('value', '<').setEnd @getPos()
            when 61
                if @charCode() is 61
                    @colAdvance()
                    if @charCode() is 61
                        @colAdvance()
                        return @addToken token.set('type', 'COMPARE').set('value', '===').setEnd @getPos()
                    return @addToken token.set('type', 'COMPARE').set('value', '==').setEnd @getPos()
                if @charCode() is 38
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '=&').setEnd @getPos()
                if @charCode() is 62
                    @colAdvance()
                    return @addToken token.set('type', '=>').setEnd @getPos()
                return @addToken token.set('type', '=').setEnd @getPos()
            when 62
                if @charCode() is 62
                    @colAdvance()
                    if @charCode() is 61
                        @colAdvance()
                        return @addToken token.set('type', 'ASSIGN').set('value', '>>=').setEnd @getPos()
                    return @addToken token.set('type', 'BITWISE').set('value', '>>').setEnd @getPos()
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'COMPARE').set('value', '>=').setEnd @getPos()
                return @addToken token.set('type', 'COMPARE').set('value', '>').setEnd @getPos()
            when 63
                return @addToken token.set('type', '?').setEnd @getPos()
            when 91
                return @addToken token.set('type', '[').setEnd @getPos()
            when 92
                return @addToken token.set('type', 'BS').setEnd @getPos()
            when 93
                return @addToken token.set('type', ']').setEnd @getPos()
            when 94
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '^=').setEnd @getPos()
                return @addToken token.set('type', 'BITWISE').set('value', '^').setEnd @getPos()
            when 123
                return @addToken token.set('type', '{').setEnd @getPos()
            when 124
                if @charCode() is 124
                    @colAdvance()
                    return @addToken token.set('type', 'BITWISE').set('value', '||').setEnd @getPos()
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '|=').setEnd @getPos()
                return @addToken token.set('type', 'BITWISE').set('value', '|').setEnd @getPos()
            when 125
                return @addToken token.set('type', '}').setEnd @getPos()
            when 126
                return @addToken token.set('type', '~').setEnd @getPos()

    skipComment: () ->
        value = @input.slice(@pos).match(REGEX.COMMENT)[0]
        @posAdvance value
        return @nextToken()

    # Scanning
    isStartTag: (pos = @pos) -> @input.slice(pos).match(REGEX.STARTTAG) isnt null

    isEndTag: (pos = @pos) -> @input.slice(pos).match(REGEX.ENDTAG) isnt null

    isComment: (pos = @pos) -> @input.slice(pos).match(REGEX.COMMENT) isnt null

    isVariable: (pos = @pos) -> @input.slice(pos).match(REGEX.VARIABLE) isnt null

    isName: (pos = @pos) -> @input.slice(pos).match(REGEX.NAME) isnt null

    isNumber: (pos = @pos) -> @input.slice(pos).match(REGEX.NUMBER) isnt null

    isString: (pos = @pos) -> @input.slice(pos).match(REGEX.STRING) isnt null

class Token
    constructor: (@type = null, @location = {}, obj = {}) ->
        for key, value of obj
            @[key] = value
        if @location is null then delete @location

    set: (key, value) ->
        @[key] = value
        return @

    get: (key) -> @[key]

    setStart: (value) ->
        @location.start = value
        return @

    setEnd: (value) ->
        @location.end = value
        return @

    clone: ->
        token = new Token
        for k, v of @
            token.set(k, v)
        return token
        

class Position
    constructor: (@row = 1, @col = 0) ->

    clone: -> new Position @row, @col

    @from: (pos) -> new Position pos.row or 1, pos.col or 0

REGEX = # some useful regular expression
    COMMENT: /^\/\*([\s\S]*?)(?:\*\/[^\n\S]*|\*\/$)|^(?:\s*\/\/(.*)+)|^(?:\s*\#(.*)+)/
    LINETERMINATOR: /[\n\r\u2028]/
    STARTTAG: /^<\?php|^<\?=/
    ENDTAG: /^\?>/
    NAME: /((^[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/
    NUMBER: /^(0b[01]+|0o[0-7]+|0(x|X)[\da-fA-F]+|\d*\.?\d+(?:(e|E)[+-]?\d+)?)/
    STRING: /^('[^\\']*(?:\\[\s\S][^\\']*)*'|"[^\\"]*(?:\\[\s\S][^\\"]*)*")/
    VARIABLE: /((^\$[A-Za-z_\x7f-\uffff][\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/

KEYWORDS = 
    PHPRESERVED: [
        'abstract', 'and', 'array', 'as'
        'break'
        'callable', 'case', 'catch', 'class', 'clone', 'const', 'continue'
        'declare', 'default', 'do' # die
        'echo', 'else', 'elseif', 'empty', 'enddeclare', 'endfor', 'endforeach', 'endif', 'endswitch', 'endwhile', 'extends' # eval, exit
        'final', 'finally', 'for', 'foreach', 'function'
        'global', 'goto'
        'if', 'implements', 'include', 'include_once', 'instanceof', 'insteadof', 'interface' # isset
        # list
        'namespace', 'new', 'null'
        'or'
        'print', 'private', 'protected', 'public'
        'require', 'require_once', 'return'
        'static', 'switch'
        'throw', 'trait', 'try'
        'unset', 'use' # unset
        'var'
        'while'
    ]
module.exports = new Lexer