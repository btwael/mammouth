var CodePoint = require("./codepoint");
var Token = require("./token").Token;
var TokenKind = require("./token").TokenKind;

//*-- Scanner
/**
 * The scanner transforms the input source code into a list
 * or a stream of tokens.
 */
function Scanner() {
    this._offset = 0;
    this._input = null;
    this._output = null;
}

/**
 * Initializes the scanner with a source
 */
Scanner.prototype.setInput = /*void*/ function(/*Source*/ input) {
    this._offset = 0;
    this._input = input;
    this._output = new Array/*<Token>*/();
    this._state = new ScannerState();
};

/**
 * Add a token to the output stream.
 */
Scanner.prototype.addToken = /*void*/ function(/*Token*/ token) {
    if(this._output != null) {
        this._output.push(token);
    }
};

/**
 * Checks if we acheived the end of the source, or not yet.
 */
Scanner.prototype.hasNextChar = /*boolean*/ function() {
    if(this._input != null && this._offset < this._input.getContent().length) {
        return true;
    }
    return false;
};

/**
 * Gets the code point at given offset.
 */
Scanner.prototype.codePointAt = /*int?*/ function(/*int*/ offset) {
    if(this._input != null && offset < this._input.getContent().length) {
        return this._input.getContent().codePointAt(offset);
    }
    return null;
};

/**
 * Gets the code point at current offset.
 */
Scanner.prototype.currentCodePoint = /*int?*/ function() {
    return this.codePointAt(this._offset);
};

/**
 * Advances the current position (offset) and return the character at 
 * the new current position.
 */
Scanner.prototype.nextChar = /*int?*/ function() {
    this._offset++;
    return this.currentCodePoint();
};

/**
 * Retreats the current position (offset) and return the character at 
 * the new current position.
 */
Scanner.prototype.prevChar = /*int?*/ function() {
    this._offset--;
    return this.currentCodePoint();
};

/**
 * Scans the source code and returns the corresponding token stream.
 */
Scanner.prototype.scanAll = /*[Token]*/ function() {
    while(this.scanNext());
    return this._output;
};

/**
 * Scans at the current offset and optionally add token to the output stream.
 * Returns true if everything goes well, false if error reported.
 */
Scanner.prototype.scanNext = /*boolean*/ function() {
    if(this.hasNextChar()) {
        if(!this._stat.into.mammouth) {
            return this.scanRaw();
        }
        // "{{"
        if(
            this.currentCodePoint() == CodePoint.LBRACE
            && this.codePointAt(this._offset + 1) == CodePoint.LBRACE
        ) {
            return this.scanDoubleLeftBrace();
        }
        // "}}"
        if(
            this.currentCodePoint() == CodePoint.RBRACE
            && this.codePointAt(this._offset + 1) == CodePoint.RBRACE
        ) {
            return this.scanDoubleRightBrace();
        }
    }
    return false;
};

/**
 * Scans the html or raw text that surrounds the mammouth blocks.
 */
Scanner.prototype.scanRaw = /*boolean*/ function() {
    var /*int*/ offset,
        /*int*/ endOffset,
        /*String*/ value,
        /*Token*/ token;

    offset = this._offset;
    c = this.currentCodePoint();
    while(
        this.hasNextChar()
        && (c != CodePoint.LBRACE
        || this.codePointAt(this._offset + 1) != CodePoint.LBRACE)
    ) {
        c = this.nextChar();
    }
    endOffset = this._offset;
    value = this._input.getContent().substring(offset, endOffset);

    this._state.into.mammouth = true;

    // MARK(MAKE TOKEN)
    token = (new Token()).setKind(TokenKind.Raw)
                         .setLexeme(value)
                         .setOffset(offset);
    this.addToken(token);
    return true; 
};

/**
 * Scans the opening double left brace.
 */
Scanner.prototype.scanDoubleLeftBrace = /*boolean*/ function() {
    var /*int*/ offset = this._offset,
        /*Token*/ token;
    this.nextChar();
    this.nextChar();
            // MARK(MAKE TOKEN)
    token = (new Token()).setKind(TokenKind.DoubleLeftBrace)
                         .setLexeme("{{")
                         .setOffset(offset);
    this.addToken(token);
    this._state.openIndentLevel()
    return true; 
};

/**
 * Scans the closing double right brace.
 */
Scanner.prototype.scanDoubleRightBrace = /*boolean*/ function() {
    var /*int*/ offset = this._offset,
        /*Token*/ token;

    this.closeIndent(this.tracker.closeIndentLevel());
    if(this.tracker.opened[0].type == 'START_TAG') {
        token.setType('END_TAG')
        var openation = this.tracker.opened.shift();
        openation.openedIn.set('closedIn', token);
        token.set('openedIn', openation.openedIn);
    } else if(this.tracker.opened[0].type == 'INTERPOLATION_START_TAG') {
        token.setType('INTERPOLATION_END_TAG');
        var openation = this.tracker.opened.shift();
        openation.openedIn.set('closedIn', token);
        token.set('openedIn', openation.openedIn);
    }
    this.nextChar();
    this.nextChar();
    this._state.into.mammouth = false;
    token = (new Token()).setKind(TokenKind.DoubleLeftBrace)
                         .setLexeme("{{")
                         .setOffset(offset);
    this.addToken(token);
};

/**
 * TODO: comment
 */
Scanner.prototype.closeIndent = /*void*/ function(/*IndentLevel*/ indentLevel) {
    while(indentLevel.indentStack.length > 0) {
        var indentation = indentLevel.indentStack.shift();
        var openedIn = indentLevel.tokenStack.shift();
        this.addToken(
            (new Token())
                .setKind(TokenKind.Outdent)
                .setOffset(this._offset)
        );
    }
};

//*-- ScannerState (internal)
function ScannerState() {
    this.into =  {
        mammouth: false
    };
    this.indentLevels = new Array/*<IndentLevel>*/();
}

ScannerState.prototype.openIndentLevel = /*IndentLevel*/ function() {
    var /*IndentLevel*/ level = new IndentLevel();
    this.indentLevels.unshift(level);
    return level;
};

ScannerState.prototype.closeIndentLevel = /*IndentLevel*/ function() {
    return this.indentLevels.shift();
};

ScannerState.prototype.currentIndentLevel =/*IndentLevel?*/ function() {
    if(this.indentLevels.length > 0) {
        return this.indentLevels[0];
    }
    return null;
};

//*-- IndentLevel (internal)
function IndentLevel() {
    this.currentIndent = -1;
    this.indentStack = [];
    this.tokenStack = [];
}

// exports
module.exports = Scanner;
