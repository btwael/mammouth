var Precedence = require("./precedence");

//*-- TokenKind
/**
 * TokenKind allows to classify tokens into kinds.
 */
function TokenKind(/*String*/ name,
                   /*TokenKind?*/ parentKind,
                   /*String?*/ lexeme,
                   /*Precedence?*/ precedence) {
    this._name = name;
    this._parentKind = parentKind === undefined ? null : parentKind; 
    this._lexeme = lexeme === undefined ? null : lexeme;
    this._precedence = precedence === undefined ? Precedence.Expression : precedence;
}

/**
 * Returns the representative name of this TokenKind. 
 */
TokenKind.prototype.getName = /*String*/ function() {
    return this._name
};

/**
 * Returns the representative name of this TokenKind. 
 */
TokenKind.prototype.getParentKind = /*TokenKind?*/ function() {
    return this._parentKind;
};

/**
 * Returns the representative name of this TokenKind. 
 */
TokenKind.prototype.getLexeme = /*String?*/ function() {
    return this._lexeme;
};

/**
 * Returns the representative name of this TokenKind. 
 */
TokenKind.prototype.getPrecedence = /*Precedence*/ function() {
    return this._precedence;
};

/**
 * Checks if this TokenKind is equal or subkind of given TokenKind.
 */
TokenKind.prototype.is = /*boolean*/ function(/*TokenKind*/ givenKind) {
    var /*TokenKind*/ kind = this;
    while(kind != null) {
        if(kind == givenKind) {
            return true;
        }
        kind = kind.getParentKind();
    }
    return false;
};

TokenKind.Raw = new TokenKind("raw");
TokenKind.DoubleOpeningBrace = new TokenKind("doubleopeningbrace");

//*-- Token
/**
 * Entity produced by scanner describing the lexicon used in source code.
 */
function Token(/*int*/ offset) {
    this._kind = null;
    this._lexeme = null;
    this._offset = offset === undefined ? null : offset;
} 

Token.prototype.setKind = /*Token*/ function(/*TokenKind*/ kind) {
    this._kind = kind;
    return this;
};

Token.prototype.setLexeme = /*Token*/ function(/*String*/ lexeme) {
    this._lexeme = lexeme;
    return this;
};

Token.prototype.setOffset = /*Token*/ function(/*int*/ offset) {
    this._offset = offset;
    return this;
};

/**
 * Returns the kind of this token.
 */
Token.prototype.getKind = /*TokenKind?*/ function() {
    return this._kind;
};

/**
 * Returns the lexeme that represents this token.
 */
Token.prototype.getLexeme = /*String?*/ function() {
    return this._lexeme;
};

/**
 * Returns the offset from the beginning of the file to the first character in
 * the token.
 */
Token.prototype.getOffset = /*int?*/ function() {
    return this._offset;
};

Token.prototype.getLength = /*int*/ function() {
    if(this._lexeme != null) {
        return this._lexeme.length;
    }
    if(this._kind.getLexeme() != null) {
        return this._kind.getLexeme().length;
    }
    return 0;
};

Token.prototype.getOffset = /*int?*/ function() {
    if(this._offset == null) {
        return null
    }
    return this.getOffset() + this.getLength();
};


// exports
exports.Token = Token;
exports.TokenKind = TokenKind;
