{errorAt} = require './utils'

class Lexer
    setInput: (input) ->
        @yytext = '' # value passed to parser (eg. identifier name)

        @track =
            position: new Position
            into:
                mammouth: off # when it's on/true, it means that lexer is into code block, between '{{' & '}}'
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

    addIndentLevel: () ->
        @track.opened.unshift {
            type: 'IndentLevel'
            indentStack: [] # The stack of all current indentation lengths
            currentIndent: -1 # current indent length
            openedIndent: 0 # number of opened indent
        }
    
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

    currentIndentTracker: ->
        for ele in @track.opened
            if ele.type is 'IndentLevel'
                return ele

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
        @rewrite()
        @lexed = on
        return @tokens

    nextToken: ->
        return undefined if @pos is @input.length

        # Everything out of '{{ }}' is a RAW text (html/xml...)
        if not @track.into.mammouth
            return @readTokenRAW()

        # now let's lex what's into '{{ }}'
        if @isInterpolationStartTag()
            return @readTokenInterpolationStartTag()
        if @isStartTag()
            return @readTokenStartTag()
        if @isEndTag()
            return @readTokenEndTag()

        # Skip empty lines
        if @last().type is 'LINETERMINATOR' and @isEmptyLines()
            return @skipEmptyLines()

        # Indent
        if @last().type is 'LINETERMINATOR' and @isIndent()
            @tokens.pop()
            return @readIndent()

        # check for comments and skip them
        if @isComment()
            return @skipComment()

        # check for Qualifiedstring
        if @isQualifiedString()
            return @readTokenQualifiedString()

        # check for identifier
        if @isIdentifier()
            return @readTokenIdentifier()

        # check for number
        if @isNumber()
            return @readTokenNumber()
        
        # check for string
        if @isString()
            return @readTokenString()

        # check for heredoc
        if @isHereDoc()
            return @readTokenHereDoc()

        return @getTokenFromCode @charCode()

    readTokenRAW: ->
        token = (new Token 'RAW').setStart @getPos()
        startPos = @pos
        while @pos < @input.length and not @isInterpolationStartTag() and not @isStartTag()
            @pos++
        if @isInterpolationStartTag()
            @track.into.mammouth = on
        if @isStartTag()
            @track.into.mammouth = on
        value = @input.slice startPos, @pos
        @posAdvance value, off
        return @addToken token.set('value', value).setEnd(@getPos())

    readTokenInterpolationStartTag: ->
        token = (new Token '{{>').setStart @getPos()
        @colAdvance(3)
        @track.opened.unshift {
            type: '{{'
            closableBy: '}}'
        }
        @addIndentLevel()
        return @addToken token.setEnd @getPos()

    readTokenStartTag: ->
        token = (new Token '{{').setStart @getPos()
        @colAdvance(2)
        @track.opened.unshift {
            type: '{{'
            closableBy: '}}'
        }
        @addIndentLevel()
        return @addToken token.setEnd @getPos()

    readTokenEndTag: ->
        token = (new Token '}}').setStart @getPos()
        @colAdvance(2)
        token.setEnd @getPos()
        @track.into.mammouth = off
        tokens = @closeIndent(@currentIndentTracker(), token.location)
        @closeIndentLevel()
        if @track.opened[0].type is '{{'
            @track.opened.shift()
            tokens = tokens.concat token
        return @addToken tokens

    readIndent: () ->
        token = (new Token).setStart @getPos()
        indent = @input.slice(@pos).match(REGEX.INDENT)[0]
        @colAdvance indent.length
        token.setEnd @getPos()
        indentTracker = @currentIndentTracker()
        if indent.length > indentTracker.currentIndent
            indentTracker.currentIndent = indent.length
            indentTracker.openedIndent++
            indentTracker.indentStack.push {
                length: indent.length
            }
            return @addToken token.set('type', 'INDENT').set('length', indent.length)
        else if indent.length is indentTracker.currentIndent
            if @last().type is 'MINDENT'
                return @nextToken()
            return @addToken token.set('type', 'MINDENT').set('length', indent.length)
        else
            tokens = []
            # reversed @track.indent.indentStack
            reversed = @reversedIndentStack(indentTracker)

            for indentLevel in reversed
                if indent.length is indentLevel.length
                    indentTracker.currentIndent = indent.length
                    tokens.push new Token 'MINDENT', token.location, {
                        length: indent.length
                    }
                else if indent.length < indentLevel.length
                    indentTracker.currentIndent = indentTracker.indentStack.pop().length
                    indentTracker.openedIndent--
                    tokens.push new Token 'OUTDENT', token.location, {
                        length: indentLevel.length
                    }

            return @addToken tokens

    readTokenIdentifier: ->
        startPos = @getPos()
        token = (new Token).setStart startPos
        value = @input.slice(@pos).match(REGEX.IDENTIFIER)[0]
        @colAdvance value.length
        token.setEnd @getPos()

        # check for boolean
        if value.toUpperCase() in KEYWORDS.BOOL
            return @addToken token.set('type', 'BOOL').set('value', value)

        # check for operator
        if value in KEYWORDS.LOGIC
            return @addToken token.set('type', 'LOGIC')
                                  .set('value', if value is 'and' then '&&' else if value is 'or' then '||' else value)
        if value in KEYWORDS.COMPARE
            return @addToken token.set('type', 'COMPARE')
                                  .set('value', if value is 'is' then '===' else if value is 'isnt' then '!=' else value)

        if @last().type is '=>' and value in KEYWORDS.CASTTYPE
            return @addToken token.set('type', 'CASTTYPE').set('value', value)

        if value in KEYWORDS.RESERVED
            if value in ['cte', 'const']
                return @addToken token.set('type', 'CONST')
            if (value in ['if', 'unless']) and not (@last().type in ['INDENT', 'MINDENT', 'OUTDENT', '(', 'CALL_START', ',', 'ELSE', '=', 'ASSIGN'])
                return @addToken token.set('type', 'POST_IF')
                                      .set('value', if value is 'if' then off else on)
            if value in ['if', 'unless']
                return @addToken token.set('type', 'IF')
                                      .set('value', if value is 'if' then off else on)
            if value is 'then'
                indentTracker = @currentIndentTracker()
                length = indentTracker.currentIndent + 1
                indentTracker.currentIndent = length
                indentTracker.openedIndent++
                indentTracker.indentStack.push {
                    length: length
                    sensible: on
                }
                return @addToken token.set('type', 'INDENT').set('length', length)
            if value is 'else'
                res = @closeSensibleIndent(@currentIndentTracker(), token.location)
                return @addToken res.concat(token.set('type', 'ELSE')).concat @lookLinearBlock(token.location, 'ELSE')
            if value is 'try'
                return @addToken [].concat(token.set('type', 'TRY')).concat @lookLinearBlock(token.location)
            if value is 'catch'
                res = @closeSensibleIndent(@currentIndentTracker(), token.location)
                return @addToken res.concat(token.set('type', 'CATCH'))
            if value is 'finally'
                res = @closeSensibleIndent(@currentIndentTracker(), token.location)
                return @addToken res.concat(token.set('type', 'FINALLY')).concat @lookLinearBlock(token.location)
            if value is 'for'
                @track.into.for = on
            if value in ['of', 'in'] and @track.into.for
                @track.into.for = off
                return @addToken token.set('type', 'FOR' + value.toUpperCase())
            if (value is 'when' and @last().type in ['INDENT', 'MINDENT', 'OUTDENT']) or value is 'case'
                return @addToken token.set('type', 'LEADING_WHEN')
            return @addToken token.set('type', value.toUpperCase())

        # other php reserved words can't be identifiers
        if value in KEYWORDS.PHPRESERVED
            throw "Unexpected, PHP reserved words can't be identifier at line #{startPos.row}, col #{startPos.col}:\n" + errorAt(@input, startPos)

        # then it's an identifier
        return @addToken token.set('type', 'IDENTIFIER').set('value', value)

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

    readTokenHereDoc: () ->
        token = (new Token 'HEREDOC').setStart @getPos()
        value = @input.slice(@pos).match(REGEX.HEREDOC)[0]
        @posAdvance value
        return @addToken token.set('value', value[1...value.length - 1]).setEnd @getPos()

    readTokenQualifiedString: () ->
        token = (new Token 'QUALIFIEDQTRING').setStart @getPos()
        value = @input.slice(@pos).match(REGEX.QUALIFIEDQTRING)[0]
        @posAdvance value
        return @addToken token.set('value', eval value[1..]).setEnd @getPos()

    getTokenFromCode: (code) ->
        startPos = @getPos()
        token = (new Token).setStart startPos
        @colAdvance()
        switch code
            when 10, 13, 8232 # 10 is "\n", 13 is "\r", 8232 is "\u2028"
                @colAdvance(-1)
                return @readLineTerminator()
            # Skip whitespaces
            when 32, 160, 5760, 6158, 8192, 8193, 8194, 8195, 8196, 8197, 8198, 8199, 8200, 8201, 8202, 8239, 8287, 12288
                return @nextToken()
            when 33 # 33 is '!'
                # look for '!='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'COMPARE').set('value', '!=').setEnd @getPos()
                return @addToken token.set('type', 'NOT').setEnd @getPos()
            when 37 # 37 is '%'
                # look for '%='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '%=').setEnd @getPos()
                return @addToken token.set('type', '%').setEnd @getPos()
            when 38 # 38 is '&'
                # look for '&='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '&=').setEnd @getPos()
                # look for '&&'
                if @charCode() is 38 # 38 is '&'
                    @colAdvance()
                    return @addToken token.set('type', 'LOGIC').set('value', '&&').setEnd @getPos()
                return @addToken token.set('type', '&').setEnd @getPos()
            when 40 # 40 is '('
                if @last().type in KEYWORDS.CALLABLE and @last(2).type isnt 'FUNC'
                    @track.opened.unshift {
                        type: 'CALL_START'
                        closableBy: 'CALL_END'
                    }
                    @addIndentLevel()
                    return @addToken token.set('type', 'CALL_START').setEnd @getPos()
                @track.opened.unshift {
                    type: '('
                    closableBy: ')'
                }
                @addIndentLevel()
                return @addToken token.set('type', '(').setEnd @getPos()
            when 41 # 41 is ')'
                tokens = @closeIndent(@currentIndentTracker(), token.location)
                @closeIndentLevel()
                switch @track.opened[0].type
                    when 'CALL_START'
                        tokens = tokens.concat token.set('type', 'CALL_END').setEnd @getPos()
                        @track.opened.shift()
                    when '('
                        tokens = tokens.concat token.set('type', ')').setEnd @getPos()
                        @track.opened.shift()
                return @addToken tokens
            when 42 # 43 is '*'
                # look for '**'
                if @charCode() is 42 # 42 is '*'
                    @colAdvance()
                    return @addToken token.set('type', '**').setEnd @getPos()
                # look for '*='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '*=').setEnd @getPos()
                return @addToken token.set('type', '*').setEnd @getPos()
            when 43 # 43 is '+'
                # look for '++'
                if @charCode() is 43 # 43 is '+
                    @colAdvance()
                    return @addToken token.set('type', '++').setEnd @getPos()
                # look for '+='
                if @charCode() is 61 # 61 is '=
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '+=').setEnd @getPos()
                return @addToken token.set('type', '+').setEnd @getPos()
            when 44 # 44 is ','
                return @addToken token.set('type', ',').setEnd @getPos()
            when 45 # 45 is '-'
                # look for '--'
                if @charCode() is 45 # 45 is '-'
                    @colAdvance()
                    return @addToken token.set('type', '--').setEnd @getPos()
                # look for '-='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '-=').setEnd @getPos()
                # look for '->'
                if @charCode() is 62 # 61 is '>'
                    @colAdvance()
                    tokens = [
                        token.set('type', '->').setEnd @getPos()
                    ].concat @lookLinearBlock(token.location)

                    return @addToken tokens
                return @addToken token.set('type', '-').setEnd @getPos()
            when 46 # 46 is '.'
                # look for '..'
                if @charCode() is 46 # 46 is '.'
                    @colAdvance()
                    # look for '...'
                    if @charCode() is 46 # 46 is '.'
                        @colAdvance()
                        # look for '....'
                        if @charCode() is 46 # 46 is '.'
                            @colAdvance()
                            return @addToken token.set('type', '....').setEnd @getPos()
                        return @addToken token.set('type', '...').setEnd @getPos()
                    return @addToken token.set('type', '..').setEnd @getPos()
                return @addToken token.set('type', '.').setEnd @getPos()
            when 47 # 47 is '/'
                # look for '/='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '/=').setEnd @getPos()
                return @addToken token.set('type', '/').setEnd @getPos()
            when 58 # 58 is ':'
                # look for '::'
                if @charCode() is 58 # 58 is ':'
                    @colAdvance()
                    return @addToken token.set('type', '::').setEnd @getPos()
                return @addToken token.set('type', ':').setEnd @getPos()
            when 59 # 59 is ';'
                return @addToken token.set('type', ';').setEnd @getPos()
            when 60 # 60 is '<'
                if @charCode() is 60 # 60 is '<'
                    @colAdvance()
                    # look for '<<='
                    if @charCode() is 61 # 61 is '='
                        @colAdvance()
                        return @addToken token.set('type', 'ASSIGN').set('value', '<<=').setEnd @getPos()
                    # then it's just '<<'
                    return @addToken token.set('type', 'BITWISE').set('value', '<<').setEnd @getPos()
                # look for '<->'
                if @charCode() is 45 and @charCode(@pos + 1) is 62 # 45 is '-' and 62 is '>'
                    @colAdvance(2)
                    return @addToken token.set('type', 'CONCAT').setEnd @getPos()
                # look for '<='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'COMPARE').set('value', '<=').setEnd @getPos()
                return @addToken token.set('type', 'COMPARE').set('value', '<').setEnd @getPos()
            when 61 # 61 is '='
                # look for '=>'
                if @charCode() is 62 # 62 is '>'
                    @colAdvance()
                    return @addToken token.set('type', '=>').setEnd @getPos()
                # look for '==='
                if @charCode() is 61 and @charCode(@pos + 1) is 61 # 61 is '='
                    @colAdvance(2)
                    return @addToken token.set('type', 'COMPARE').set('value', '===').setEnd @getPos()
                # look for '=='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'COMPARE').set('value', '==').setEnd @getPos()
                return @addToken token.set('type', '=').setEnd @getPos()
            when 62 # 62 is '>'
                if @charCode() is 62 # 62 is '>'
                    @colAdvance()
                    # look for '>>='
                    if @charCode() is 61 # 61 is '='
                        @colAdvance()
                        return @addToken token.set('type', 'ASSIGN').set('value', '>>=').setEnd @getPos()
                    return @addToken token.set('type', 'BITWISE').set('value', '>>').setEnd @getPos()
                # look for '>='
                if @charCode() is 61
                    @colAdvance()
                    return @addToken token.set('type', 'COMPARE').set('value', '>=').setEnd @getPos()
                return @addToken token.set('type', 'COMPARE').set('value', '>').setEnd @getPos()
            when 63 # 63 is '?'
                return @addToken token.set('type', '?').setEnd @getPos()
            when 64 # 64 is '@'
                return @addToken token.set('type', '@').setEnd @getPos()
            when 91 # 91 is ']'
                if @last().type in KEYWORDS.INDEXABLE
                    @track.opened.unshift {
                        type: 'INDEX_START'
                        closableBy: 'INDEX_END'
                    }
                    @addIndentLevel()
                    return @addToken token.set('type', 'INDEX_START').setEnd @getPos()
                else
                    @track.opened.unshift {
                        type: '['
                        closableBy: ']'
                    }
                    @addIndentLevel()
                    return @addToken token.set('type', '[').setEnd @getPos()
            when 93 # 93 is ']'
                tokens = @closeIndent(@currentIndentTracker(), token.location)
                @closeIndentLevel()
                if @track.opened[0].type is '['
                    @track.opened.shift()
                    tokens = tokens.concat token.set('type', ']').setEnd @getPos()
                else if @track.opened[0].type is 'INDEX_START'
                    @track.opened.shift()
                    tokens = tokens.concat token.set('type', 'INDEX_END').setEnd @getPos()
                return @addToken tokens
            when 94 # 94 is '^'
                # look for '^='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '^=').setEnd @getPos()
                return @addToken token.set('type', 'BITWISE').set('value', '^').setEnd @getPos()
            when 123 # 123 is '{'
                return @addToken token.set('type', '{').setEnd @getPos()
            when 124 # 124 is '|'
                # look for '||'
                if @charCode() is 124 # 124 is '|'
                    @colAdvance()
                    return @addToken token.set('type', 'BITWISE').set('value', '||').setEnd @getPos()
                # look for '|='
                if @charCode() is 61 # 61 is '='
                    @colAdvance()
                    return @addToken token.set('type', 'ASSIGN').set('value', '|=').setEnd @getPos()
                return @addToken token.set('type', 'BITWISE').set('value', '|').setEnd @getPos()
            when 125 # 125 is '}'
                return @addToken token.set('type', '}').setEnd @getPos()
            when 126 # 126 is '~'
                if @charCode() is 126 # 126 is '~'
                    @colAdvance()
                    # look for '~~='
                    if @charCode() is 61 # 61 is '='
                        @colAdvance()
                        return @addToken token.set('type', 'ASSIGN').set('value', '.=').setEnd @getPos()
                    return @addToken token.set('type', 'CONCAT').setEnd @getPos()
                return @addToken token.set('type', '~').setEnd @getPos()
            else
                throw "Unexpected caharacter at line #{startPos.row}, col #{startPos.col}:\n" + errorAt(@input, startPos)


    readLineTerminator: () ->
        token = (new Token 'LINETERMINATOR').setStart @getPos()
        @rowAdvance()
        if @charCode() in [10, 13, 8232]
            return @readLineTerminator()
        return @addToken token.setEnd @getPos()

    skipEmptyLines: () ->
        value = @input.slice(@pos).match(REGEX.EMPTYLINE)[0]
        @posAdvance value
        return @nextToken()

    skipComment: () ->
        value = @input.slice(@pos).match(REGEX.COMMENT)[0]
        @posAdvance value
        return @nextToken()

    lookLinearBlock: (loc, tok = '') ->
        tokens = []
        if tok is 'ELSE' and @next().type in ['IF', 'POST_IF']
            return tokens
        next = @next(2).type
        if next isnt 'INDENT'
            indentTracker = @currentIndentTracker()
            length = indentTracker.currentIndent + 1
            if next in ['MINDENT', 'OUTDENT']
                tokens.push (new Token 'INDENT', loc).set('length', indentTracker.currentIndent + 1)
                tokens.push (new Token 'OUTDENT', loc).set('length', indentTracker.currentIndent + 1)
            else
                indentTracker.currentIndent = length
                indentTracker.openedIndent++
                indentTracker.indentStack.push {
                    length: length
                    sensible: on
                }
                tokens.push (new Token 'INDENT', loc).set('length', length)
        return tokens

    # Scanning
    isInterpolationStartTag: (pos = @pos) ->
        return off if @pos + 2 > @input.length - 1
        return @charCode(pos) is 123 and @charCode(@pos + 1) is 123 and @charCode(@pos + 2) is 62 # 123 is '{' and 62 is '>'

    isStartTag: (pos = @pos) ->
        return off if @pos + 1 > @input.length - 1
        return @charCode(pos) is 123 and @charCode(@pos + 1) is 123 # 123 is '{'

    isEndTag: (pos = @pos) ->
        return off if @pos + 1 > @input.length - 1
        return @charCode(pos) is 125 and @charCode(@pos + 1) is 125 # 125 is '}'

    isComment: (pos = @pos) -> @input.slice(pos).match(REGEX.COMMENT) isnt null

    isEmptyLines: (pos = @pos) -> @input.slice(pos).match(REGEX.EMPTYLINE) isnt null

    isIdentifier: (pos = @pos) -> @input.slice(pos).match(REGEX.IDENTIFIER) isnt null

    isIndent: (pos = @pos) -> @input.slice(pos).match(REGEX.INDENT) isnt null and @last().type isnt 'INDENT'

    isNumber: (pos = @pos) -> @input.slice(pos).match(REGEX.NUMBER) isnt null

    isString: (pos = @pos) -> @input.slice(pos).match(REGEX.STRING) isnt null

    isHereDoc: (pos = @pos) -> @input.slice(pos).match(REGEX.HEREDOC) isnt null

    isQualifiedString: (pos = @pos) -> @input.slice(pos).match(REGEX.QUALIFIEDQTRING) isnt null

    # Rewrite
    rewrite: () ->
        for token, i in @tokens
            if token
                if token.type is 'MINDENT' and @tokens[i + 1] and @tokens[i + 1].type in ['CATCH', 'ELSE', 'FINALLY']
                    @tokens.splice i, 1
                if token.type is 'MINDENT' and @tokens[i + 1] and @tokens[i + 1].type is 'OUTDENT' and @tokens[i + 1].length is token.length
                    @tokens.splice i, 1

    # helpers
    reversedIndentStack: (indentTracker) ->
        reversed = []
        for i in indentTracker.indentStack
            reversed.unshift i
        return reversed

    closeIndent: (indentTracker, loc) ->
        tokens = []
        reversed = @reversedIndentStack(indentTracker)
        while indentTracker.openedIndent
            if @last().type in ['LINETERMINAROR', 'MINDENT']
                @tokens.pop()
            tokens.unshift (new Token 'OUTDENT', loc).set('length', reversed[indentTracker.openedIndent - 1].length)
            indentTracker.openedIndent--
        if @last().type is 'LINETERMINATOR'
            @tokens.pop()
        return tokens

    closeIndentLevel: () -> @track.opened.shift()

    closeSensibleIndent: (indentTracker, loc) ->
        res = []
        if indentTracker.indentStack[indentTracker.indentStack.length - 1] and indentTracker.indentStack[indentTracker.indentStack.length - 1].sensible is on
            length = indentTracker.indentStack.pop().length - 1
            indentTracker.currentIndent = length
            indentTracker.openedIndent--
            res.push (new Token 'OUTDENT', loc).set('length', length)
        return res


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
    COMMENT: /^###([^#][\s\S]*?)(?:###[^\n\S]*|###$)|^(?:\s*#(?!##[^#]).*)+/
    EMPTYLINE: /(^[\u0020\u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000]*[\n\r\u2028\u2029])/
    IDENTIFIER: /((^[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/
    INDENT: /(^[ \t]*)/
    HEREDOC: /^`(((?!(\`|{{|}}))([\n\r\u2028\u2029]|.))*)`/
    LINETERMINATOR: /[\n\r\u2028]/
    NUMBER: /^(0b[01]+|0o[0-7]+|0(x|X)[\da-fA-F]+|\d*\.?\d+(?:(e|E)[+-]?\d+)?)/
    STRING: /^('[^\\']*(?:\\[\s\S][^\\']*)*'|"[^\\"]*(?:\\[\s\S][^\\"]*)*")/
    QUALIFIEDQTRING: /^q('[^\\']*(?:\\[\s\S][^\\']*)*'|"[^\\"]*(?:\\[\s\S][^\\"]*)*")/

KEYWORDS =
    BOOL: ['TRUE', 'FALSE']
    CALLABLE: ['CALL_END', 'IDENTIFIER', ')', ']', 'INDEX_END', '?', '@', 'QUALIFIEDQTRING']
    CASTTYPE: ['array', 'binary', 'bool', 'boolean', 'double', 'int', 'integer', 'float', 'object', 'real', 'string', 'unset']
    COMPARE: ['is', 'isnt']
    INDEXABLE: ['CALL_END', 'IDENTIFIER', ')', ']', '?', '@', 'QUALIFIEDQTRING', 'NUMBER', 'STRING', 'BOOL', 'NULL']
    LOGIC: ['and', 'or', 'xor']
    RESERVED: [
        'abstract', 'as'
        'break', 'by'
        'catch', 'case', 'class', 'clone', 'const', 'continue', 'cte'
        'declare', 'delete'
        'echo', 'else', 'extends'
        'final', 'finally', 'for', 'func'
        'global', 'goto'
        'if', 'implements', 'in', 'instanceof', 'interface', 'include'
        'loop'
        'namespace', 'new', 'not', 'null'
        'of', 'once'
        'private', 'protected', 'public'
        'require', 'return'
        'static', 'switch'
        'then', 'throw', 'try'
        'unless', 'until', 'use'
        'when', 'while'
    ]
    PHPRESERVED: [
        'abstract', 'and', 'as' # array
        'break'
        'callable', 'case', 'catch', 'class', 'clone', 'const', 'continue'
        'declare', 'default', 'do' # die
        'echo', 'else', 'elseif', 'enddeclare', 'endfor', 'endforeach', 'endif', 'endswitch', 'endwhile', 'extends' # eval, exit, empty
        'final', 'finally', 'for', 'foreach', 'function'
        'global', 'goto'
        'if', 'implements', 'include', 'include_once', 'instanceof', 'insteadof', 'interface' # isset
        # list
        'namespace', 'new'
        'or'
        'print', 'private', 'protected', 'public'
        'require', 'require_once', 'return'
        'static', 'switch'
        'throw', 'trait', 'try'
        'unset', 'use' # unset
        #'var'
        'while'
    ]

module.exports = new Lexer