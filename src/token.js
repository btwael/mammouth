var Precedence = require("./precedence");

//*-- TokenKind
/**
 * TokenKind allows to classify tokens into kinds.
 */
function TokenKind(/*String*/ name,
                   /*TokenKind*/ parentKind,
                   /*String*/ lexeme,
                   /*Precedence*/ precedence) {
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
}

/**
 * Returns the representative name of this TokenKind. 
 */
TokenKind.prototype.getParentKind = /*TokenKind?*/ function() {
    return this._parentKind;
}

/**
 * Returns the representative name of this TokenKind. 
 */
TokenKind.prototype.getLexeme = /*String?*/ function() {
    return this._lexeme;
}

/**
 * Returns the representative name of this TokenKind. 
 */
TokenKind.prototype.getPrecedence = /*Precedence*/ function() {
    return this._precedence;
}

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
}

// exports
module.exports = TokenKind;
