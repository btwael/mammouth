REGEX =
    IDENTIFIER: /((^[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/
    LINETERMINATOR: /[\n\r\u2028]/

class Lexer
    constructor: () ->
        @initialize()

    initialize: () ->
        @input = ''
        @inputLength = 0
        @Tokens = [] 
        @pos = 0
        @Track =
            position:
                col: 1
                row: 1
            into:
                mammouth: off

    setInput: (code) ->
        @initialize()
        @input = code
        @inputLength = code.length

    addToken: (token) ->
        @Tokens.push token
        return token

    posAdvance: (string) ->
        lines = string.split REGEX.LINETERMINATOR
        for line, i in lines
            if i is 0
                @Track.position.col += string.length
            else
                @Track.position.row++
                @Track.position.col = string.length

    nextToken: () ->
        # Everything out of '{{ }}' is a RAW text (html/xml...)
        if not @Track.into.mammouth
            return @addToken @readRAW()
        # now let's lex what's into '{{ }}'
        if @isStartTag @pos
            @Track.position.col += 2
            @pos += 2
            return @addToken {type: '{{'}
        if @isEndTag @pos
            @Track.position.col += 2
            @pos += 2
            return @addToken {type: '}}'}
        if @isIdentifier @pos
            return @addToken @readTokenIdentifier()
        return @addToken @getTokenFromCode @input.charCodeAt @pos

    # reading
    getTokenFromCode: (code) ->
        switch code
            when 10, 13, 8232 # 10 is "\n", 13 is "\r", 8232 is "\u2028"
                return @readLineTerminator()

    readRAW: () ->
        startPos = @pos
        while @pos < @inputLength and not @isStartTag @pos
            @pos++
        if @isStartTag @pos
            @Track.into.mammouth = on
        value = @input.slice startPos, @pos
        @posAdvance value
        return {
            type: 'RAW'
            value: value
        }

    readLineTerminator: () ->
        @pos++
        @Track.position.row++
        return {
            type: 'LINETERMINAROR'
        }

    readTokenIdentifier: () ->
        value = @input.slice(@pos).match(REGEX.IDENTIFIER)[0]
        @pos += value.length
        @Track.position.col += value.length
        return {
            type: 'IDENTIFIER'
            value: value
        }

    # checking
    isStartTag: (pos) -> # 123 is '{'
        if @pos + 1 > @inputLength - 1
            return false
        return @input.charCodeAt(pos) is 123 and @input.charCodeAt(@pos + 1) is 123

    isEndTag: (pos) -> # 125 is '}'
        if @pos + 1 > @inputLength - 1
            return false
        return @input.charCodeAt(pos) is 125 and @input.charCodeAt(@pos + 1) is 125

    isIdentifier: (pos) ->
        return @input.slice(pos).match(REGEX.IDENTIFIER) isnt null


lexer = new Lexer
lexer.setInput('sdfsdfsdf{{fsdf}}')
Tokens = []
m = 0;
while m isnt undefined
    m = lexer.nextToken();
    Tokens.push m
console.log(Tokens)