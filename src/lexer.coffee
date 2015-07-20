Lexer = require './util/lex'
{REGEX} = require './constants'

# We should track some informations while lexing like positions & indents...
Track = {}

# So we should have an initialize function for Track called for each file lexing
initializeTrack = ->
    return {
        # Positions
        row: 1
        col: 1
        into:
            mammouth: off # to check if we're in a code block or not
        # Tokens list
        tokens: []
        # Indent level
        indent:
            currentIndent: -1
            openedIndent: 0
            indentStack: []
    }

# We also need to track previous tokens
addToken = (tok, value = undefined, prop = {}) ->
    if tok instanceof Array
        # A rule in our lexer can return many tokens
        for el, i in tok
            token =
                type: el
            token['value'] = value[i] if value && value[i]
            if prop && prop[i]
                for key, val of prop[i]
                    token[key] = val 
            Track.tokens.push token
        return tok
    else
        token =
            type: tok
        token['value'] = value if value
        for key, val of prop
            token[key] = val
        Track.tokens.push token
        return tok

# and a helper function to increase lexing positon
posAdvance = (string, yy) ->
    yy.yylloc = {
        first_line: Track.row,
        first_column: Track.col,
    }
    lines = string.split REGEX.LINETERMINATOR
    for line, i in lines
        if i is 0
            Track.col += string.length
        else
            Track.row++
            Track.col = string.length
    yy.yylloc.last_line = Track.row
    yy.yylloc.last_column = Track.col

# Initialising...
Track = initializeTrack()

# Create a new lexer instance
lexer = module.exports = new Lexer (char) ->
    throw new Error 'Unexpected character at row ' + Track.row + ', col ' + Track.col + ': ' + char

# Mammouth files are very similiar to PHP files, each file can contain what I
# call RAW text (html/xml...) and code block, in mammouth between `{{` & `}}`.
# So if we're not into a code block everything is a RAW
lexer.addRule REGEX.RAWTEXT, (lexeme) ->
    if not Track.into.mammouth
        posAdvance lexeme, @
        @yytext = lexeme
        return addToken 'RAWTEXT', lexeme
    else
        @reject = true

# The rest of lexng rules are only executed if we're into code block.
lexer.addRule REGEX.startTag, (lexeme) ->
    posAdvance lexeme, @
    Track.into.mammouth = on
    return addToken '{{'

lexer.addRule REGEX.endTag, (lexeme) ->
    posAdvance lexeme, @
    Track.into.mammouth = off
    tokens = ['}}']
    # Some indent can still unclosed, so we should close them
    while Track.indent.openedIndent > 0
        tokens.unshift 'OUTDENT'
        Track.indent.openedIndent--
    console.log(tokens)
    return addToken tokens

# Skip empty lines
lexer.addRule REGEX.EMPTYLINE, (lexeme) ->
    posAdvance lexeme, @

# Indent are used to determine block start and end instead of { & } in php
lexer.addRule REGEX.INDENT, (lexeme) ->
    posAdvance lexeme, @
    # For reasons, we don't support TAB as indent, so we treat as 4 spaces
    multiIndent = lexeme.split REGEX.LINETERMINATOR
    indentLength = multiIndent[multiIndent.length - 1].replace(/\t/g,'    ').length
    if indentLength > Track.indent.currentIndent
        # if indent lenght is superior than current indent, thhen it's a new block
        Track.indent.currentIndent = indentLength
        Track.indent.openedIndent++
        Track.indent.indentStack.push indentLength
        return addToken 'INDENT', undefined, {
            length: indentLength
        }
    else if indentLength is Track.indent.currentIndent
        # This is optional just to decrease parser errors.
        return addToken 'MINDENT'
    else
        tokens = []
        prop = []
        # reverse indent stack to reversedStack
        reversedStack = []
        for i in Track.indent.indentStack
            reversedStack.unshift i

        for indentLevel in reversedStack
            if indentLength is indentLevel
                Track.indent.currentIndent = indentLevel
            else if indentLength < indentLevel
                Track.indent.currentIndent = Track.indent.indentStack.pop()
                tokens.push 'OUTDENT'
                prop.push undefined
                Track.indent.openedIndent--
            else if indentLength > indentLevel
                Track.indent.currentIndent = indentLength
                Track.indent.openedIndent++
                Track.indent.indentStack.push indentLength
                tokens.push 'INDENT'
                prop.push {
                    length: indentLength
                }
        return addToken tokens, undefined, prop

# Detect identifier
lexer.addRule REGEX.IDENTIFIER, (lexeme) ->
    posAdvance lexeme, @
    return addToken 'IDENTIFIER', lexeme

# Line terminator
lexer.addRule REGEX.LINETERMINATOR, (lexeme) ->
    posAdvance lexeme, @
    if @look() in ['INDENT', 'MINDENT', 'OUTDENT']
        return addToken 'LINETERMINATOR'

# End of string
lexer.addRule /$/, (lexeme) ->
    @tokens = Track.tokens
    @reject = true