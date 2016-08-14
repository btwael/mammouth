var Location = require("./location");

// A lexer returns a tokens stream, a token is an atomic result explicitly indicates
// its categorization for the purpose of parsing
function Token(type, value) {
    this.type = type === undefined ? null : type;
    this.value = value === undefined ? null : value;
    this.precedence = -100;
    this._ = {};
    this.location = new Location();
}

Token.prototype.set = function(key, value) {
    this._[key] = value;
    return this;
};

Token.prototype.setType = function(type) {
    this.type = type;
    return this;
};

Token.prototype.setValue = function(value) {
    this.value = value;
    return this;
};

Token.prototype.setPrecedence = function(precedence) {
    this.precedence = precedence;
    return this;
};

Token.prototype.setStart = function(start) {
    this.location.start = start;
    return this;
};

Token.prototype.setEnd = function(end) {
    this.location.end = end;
    return this;
};

// exports
module.exports = Token;