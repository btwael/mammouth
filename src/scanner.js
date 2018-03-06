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
    this._stat = {
        into: {
            mammouth: false
        }
    };
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
        if(
            this.currentCodePoint() == CodePoint.LBRACE
            && this.codePointAt(this._offset + 1) == CodePoint.LBRACE
        ) {
            var /*int*/ offset = this._offset,
                /*Token*/ token;
            this.nextChar();
            this.nextChar();
            // MARK(MAKE TOKEN)
            token = (new Token()).setKind(TokenKind.DoubleOpeningBrace)
                                 .setLexeme("{{")
                                 .setOffset(offset);
            this.addToken(token);
            return true;
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

    this._stat.into.mammouth = true;

    // MARK(MAKE TOKEN)
    token = (new Token()).setKind(TokenKind.Raw)
                         .setLexeme(value)
                         .setOffset(offset);
    this.addToken(token);
    return true; 
};

// exports
module.exports = Scanner;
