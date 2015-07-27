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
        console.log token, @pos, @inputLength - 1
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
        return undefined if @pos is @inputLength
        # Everything out of '{{ }}' is a RAW text (html/xml...)
        if not @Track.into.mammouth
            return @readRAW()
        # now let's lex what's into '{{ }}'
        if @isStartTag @pos
            return @readTokenStartTag()
        if @isEndTag @pos
            return @readTokenEndTag()
        if @isIdentifier @pos
            return @readTokenIdentifier()
        return @getTokenFromCode @input.charCodeAt @pos

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
        return @addToken {
            type: 'RAW'
            value: value
        }

    readTokenStartTag: () ->
        @Track.position.col += 2
        @pos += 2
        return @addToken {type: '{{'}

    readTokenEndTag: () ->
        @Track.position.col += 2
        @pos += 2
        @Track.into.mammouth = off
        return @addToken {type: '}}'}

    readLineTerminator: () ->
        @pos++
        @Track.position.row++
        return @addToken {
            type: 'LINETERMINAROR'
        }

    readTokenIdentifier: () ->
        value = @input.slice(@pos).match(REGEX.IDENTIFIER)[0]
        @pos += value.length
        @Track.position.col += value.length
        return @addToken {
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
lexer.setInput('sdfsdfsdf{{fs\ndf}}sdfsd')
Tokens = []
m = 0;
while m isnt undefined
    m = lexer.nextToken();
    Tokens.push m
console.log(Tokens)