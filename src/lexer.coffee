REGEX =
    IDENTIFIER: /((^[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/
    INDENT: /(^[ \t]*)/
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
            indent:
                indentStack: []
                currentIndent: -1
                openedIndent: 0

    setInput: (code) ->
        @initialize()
        @input = code
        @inputLength = code.length

    posAdvance: (string) ->
        lines = string.split REGEX.LINETERMINATOR
        for line, i in lines
            if i is 0
                @Track.position.col += string.length
            else
                @Track.position.row++
                @Track.position.col = string.length

    addToken: (token) ->
        if token instanceof Array
            for tok in token
                @Tokens.push tok
            return token
        else
            @Tokens.push token
            return token

    lastToken: () ->
        @Tokens[@Tokens.length - 1].type

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
        # Indent
        if @lastToken() is 'LINETERMINAROR' and @isIndent(@pos)
            @Tokens.pop()
            return @readIndent()
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
        tokens = [{
            type: '}}'
        }]
        @Track.into.mammouth = off
        while @Track.indent.openedIndent
            tokens.unshift {
                type: 'OUTDENT'
            }
            @Track.indent.openedIndent--
        return @addToken tokens

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

    readIndent: () ->
        indent = @input.slice(@pos).match(REGEX.INDENT)[0]
        @pos += indent.length
        @Track.position.col += indent.length
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
            }
        else
            tokens = []
            # reversed @Track.indent.indentStack
            reversed = []
            for i in @Track.indent.indentStack
                reversed.unshift i

            for indentLevel in reversed
                if indent.length is indentLevel
                    @Track.indent.currentIndent = indent.length
                    tokens.push {
                        type: 'MINDENT'
                    }
                else if indent.length < indentLevel
                    @Track.indent.currentIndent = @Track.indent.indentStack.pop()
                    @Track.indent.openedIndent--
                    tokens.push {
                        type: 'OUTDENT'
                    }

            return @addToken tokens

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

    isIndent: (pos) ->
        return @input.slice(pos).match(REGEX.INDENT) isnt null


lexer = new Lexer
lexer.setInput('sdfsdfsdf{{\nv1\n v2\n v2\n   v3\n   v3\n  v2}}sdfsd')
Tokens = []
m = 0;
while m isnt undefined
    m = lexer.nextToken();
console.log(lexer.Tokens)