// imports
var Position = require("./position");
var Token = require("./token");
var Rewriter = require("./rewriter");
var consts = require("./consts");
var utils = require("./utils");

var keywords = consts.Keywords;

// Lexer takes a text codes as input and return a n output tokens stream
function Lexer() {
    // Nothing going here
}

// Setting input and initialize
Lexer.prototype.setInput = function(code, errorM, filename) {
    this.input = code;
    this.output = []; // output tokens strea;
    this.errorM = errorM;
    this.filename = filename === undefined ? null : filename;
    this.position = new Position(filename);
    this.rewriter = new Rewriter();
    this.tracker = new Tracker();
};

// Tokens related methods
// Add a token/tokens to output tokens stream
Lexer.prototype.addToken = function(tok) {
    if(tok instanceof Array) {
        for(var i = 0; i < tok.length; i++) {
            this.output.push(tok[i]);
        }
    } else {
        this.output.push(tok);
    }
};

// Check if the output stream isn't empty
Lexer.prototype.hasTokens = function() {
    return this.output.length > 0;
};

// Get the last token
Lexer.prototype.lastToken = function() {
    return this.output[this.output.length - 1];
};

// Contents and characters related methods
// Check if we have more code to lex
Lexer.prototype.hasNextChar = function() {
    return this.position.offset < this.input.length;
};

// Get charCode off given offset
Lexer.prototype.charCode = function(offset) {
    return this.input.charCodeAt(offset === undefined ? this.position.offset : offset);
};

// Check if a regex match in a position
Lexer.prototype.isA = function(name, offset) {
    return this.input.slice(offset === undefined ? this.position.offset : offset).match(consts.RegularExpressions[name]) !== null;
};

// Get result from a regex match
Lexer.prototype.matchA = function(name, offset) {
    return this.input.slice(offset === undefined ? this.position.offset : offset).match(consts.RegularExpressions[name])[0];
};

// Lexing process
// Lex all and return the ouput tokens stream
Lexer.prototype.lexAll = function() {
    while(this.nextToken()) {
        // Not an infinite loop
    }
    this.rewriter.setInput(this.output);
    return this.rewriter.rewrite();
};

// Add the next token if possible to output and return true else return false
Lexer.prototype.nextToken = function() {
    if(!this.hasNextChar()) {
        return false;
    }

    // if we're out of {{}}, then it's a RAW
    if(!this.tracker.into.mammouth) {
        return this.lexRAW();
    }

    // look for interpolation start tag '{{>'
    if(this.isA('INTERPOLATION_START_TAG')) {
        return this.lexInterpolationStartTag();
    }

    // look for start tag '{{'
    if(this.isA('START_TAG')) {
        return this.lexStartTag();
    }
    // look for end tag '}}'
    if(this.isA('END_TAG')) {
        return this.lexEndTag();
    }

    // Indent
    if(this.hasTokens() && this.lastToken().type == 'LINETERMINATOR' && this.isA('INDENTATION')) {
        this.output.pop();
        return this.lexIndent();
    }

    // Comment
    if(this.isA('COMMENT')) {
        return this.lexComment();
    }

    // look for qualified string
    if(this.isA('QUALIFIEDSTRING')) {
        return this.lexQualifiedString();
    }

    // look for idetifiers and reserved words
    if(this.isA('IDENTIFIER')) {
        return this.lexIdentifier();
    }

    // look for numbers
    if(this.isA('NUMBER')) {
        return this.lexNumber();
    }

    // look for strings
    if(this.isA('STRING')) {
        return this.lexString();
    }

    // look for HereDoc
    if(this.isA('HEREDOC')) {
        return this.lexHereDoc();
    }

    return this.lexByCharCode();
};

// Lex RAW datan out of {{}}
Lexer.prototype.lexRAW = function() {
    var token = (new Token('RAW')).setStart(this.position.clone());
    while(this.hasNextChar() && !this.isA('START_TAG')) {
        if(this.charCode() == 10 || this.charCode() == 13) {
            this.position.rowAdvance();
        } else {
            this.position.colAdvance();
        }
    }
    if(this.isA('START_TAG')) {
        this.tracker.into.mammouth = true;
    }
    token.setEnd(this.position.clone())
         .setValue(this.input.slice(token.location.start.offset, token.location.end.offset));
    this.addToken(token);
    return true;
};

// lex start tag '{{'
Lexer.prototype.lexStartTag = function() {
    var token = (new Token('START_TAG', '{{')).setStart(this.position.clone());
    this.position.colAdvance(2);
    token.setEnd(this.position.clone());
    this.addToken(token);
    this.tracker.opened.unshift({
        type: 'START_TAG',
        closeable: true,
        closeableWith: 'END_TAG',
        openedIn: token
    });
    this.tracker.addIndentLevel();
    return true;
};

// lex end tag '}}'
Lexer.prototype.lexEndTag = function() {
    var token = (new Token(null, '}}')).setStart(this.position.clone());
    this.position.colAdvance(2);
    token.setEnd(this.position.clone());
    this.tracker.into.mammouth = false;
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
    this.addToken(token);
    return true;
};

// lex interpolation start tag '{{>'
Lexer.prototype.lexInterpolationStartTag = function() {
    var token = (new Token('INTERPOLATION_START_TAG', '{{>')).setStart(this.position.clone());
    this.position.colAdvance(3);
    token.setEnd(this.position.clone());
    this.addToken(token);
    this.tracker.opened.unshift({
        type: 'INTERPOLATION_START_TAG',
        closeable: true,
        closeableWith: 'INTERPOLATION_END_TAG',
        openedIn: token
    });
    this.tracker.addIndentLevel();
    return true;
};

// lex comment
Lexer.prototype.lexComment = function() {
    var token = (new Token('COMMENT')).setStart(this.position.clone());
    var value = this.matchA('COMMENT');
    token.setValue(value);
    for(var i = 0; i < value.length; i++) {
        var charCode = value.charCodeAt(i);
        if(charCode == 10 || charCode == 13) {
            this.position.rowAdvance();
        } else {
            this.position.colAdvance();
        }
    }
    token.setEnd(this.position.clone());
    if(value.startsWith('###') && consts.tokenInterpretation.importantComment.indexOf(this.lastToken().type) > -1) {
        this.addToken(token);
        return true;
    } else {
        return this.nextToken();
    }
};

// lex qualified string
Lexer.prototype.lexQualifiedString = function() {
    var token = (new Token('QUALIFIEDSTRING')).setStart(this.position.clone());
    var value = this.matchA('QUALIFIEDSTRING');
    this.position.colAdvance(value.length);
    this.addToken(
        token.setValue(value)
             .setEnd(this.position.clone())
    );
    return true;
};

// lex Identifers and reserved words
Lexer.prototype.lexIdentifier = function() {
    var token = (new Token()).setStart(this.position.clone());
    var value = this.matchA('IDENTIFIER');
    this.position.colAdvance(value.length);
    token.setEnd(this.position.clone())
         .setValue(value);
    // look for casting types if after '=>'
    if(this.hasTokens() && this.lastToken().type == '=>' && keywords.castType.indexOf(value) > -1) {
        this.addToken(
            token.setType('CASTTYPE')
        );
        return true;
    }
    // look for boolean value
    if(keywords.bool.indexOf(value) > -1) {
        this.addToken(
            token.setType('BOOL')
        );
        return true;
    }
    // look for compare keywords
    if(keywords.compare.indexOf(value) > -1) {
        this.addToken(
            token.setType('COMPARE')
                 .setPrecedence(consts.Precedence.equality)
        );
        return true;
    }
    // look for logic keywords
    if(keywords.logic.indexOf(value) > -1) {
        var precedence = 1;
        if(value == 'and')
            precedence = consts.Precedence.logicalAND;
        else if(value == 'or')
            precedence = consts.Precedence.logicalOR;
        else if(value == 'xor')
            precedence = consts.Precedence.bitwiseXOR;
        this.addToken(
            token.setType(value == 'xor' ? 'BITWISE' : 'LOGIC')
                 .setPrecedence(precedence)
        );
        return true;
    }
    // look for reserved words
    if(keywords.reserved.indexOf(value) > -1) {
        if(value == 'instanceof' || value == 'in') {
            token.setPrecedence(consts.Precedence.relationel);
        }
        if(value == 'for') {
            this.tracker.into.for = true;
        }
        if(value == 'in' && this.tracker.into.for) {
            this.addToken(
                token.setType('FORIN')
            );
            return true;
        }
        if(value == 'of' && this.tracker.into.for) {
            this.addToken(
                token.setType('FOROF')
            );
            return true;
        }
        this.addToken(
            token.setType(value.toUpperCase())
        );
        return true;
    }
    // then it's just an indetifier
    this.addToken(
        token.setType('IDENTIFIER')
    );
    return true;
};

// lex numbers
Lexer.prototype.lexNumber = function() {
    var token = (new Token('NUMBER')).setStart(this.position.clone());
    var value = this.matchA('NUMBER');
    this.position.colAdvance(value.length);
    this.addToken(
        token.setValue(value)
             .setEnd(this.position.clone())
    );
    return true;
};

// lex numbers
Lexer.prototype.lexString = function() {
    var token = (new Token('STRING')).setStart(this.position.clone());
    var value = this.matchA('STRING');
    this.position.colAdvance(value.length);
    this.addToken(
        token.setValue(value)
             .setEnd(this.position.clone())
    );
    return true;
};

// lex Heredoc
Lexer.prototype.lexHereDoc = function() {
    var token = (new Token('HEREDOC')).setStart(this.position.clone());
    var value = this.matchA('HEREDOC');
    this.position.colAdvance(value.length);
    this.addToken(
        token.setValue(value)
             .setEnd(this.position.clone())
    );
    return true;
};

// Lex by charcter charCOde
Lexer.prototype.lexByCharCode = function() {
    var token = (new Token()).setStart(this.position.clone());
    var charCode = this.charCode();
    this.position.colAdvance();
    switch(charCode) {
        case 13: // 13 is '\r'
        case 10: // 10 is '\n'
            this.position.colAdvance(-1);
            this.position.rowAdvance();
            this.tracker.into.for = false;
            this.addToken(
                token.setType('LINETERMINATOR')
                     .setEnd(null) // line termnator is one position
            );
            return true;
        case 32: // 32 is ' '
            return this.nextToken();
        case 33: // 33 is '!'
            // look for '!='
            if(this.hasNextChar() && this.charCode() == 61) { // 61 is '='
                this.position.colAdvance();
                if(this.hasNextChar() && this.charCode() == 61) { // 61 is '='
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('COMPARE')
                             .setValue('!==')
                             .setPrecedence(consts.Precedence.equality)
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // then it's just a '!='
                this.addToken(
                    token.setType('COMPARE')
                         .setValue('!=')
                         .setPrecedence(consts.Precedence.equality)
                         .setEnd(this.position.clone())
                );
                return true;
            }
            // else it's just '!'
            this.addToken(
                token.setType('UNARY')
                     .setValue('!')
                     .setEnd(this.position.clone())
            );
            return true;
        case 37: // 37 is '%'
            // look for '%='
            if(this.hasNextChar() && this.charCode() == 61) { // 61 is '='
                this.position.colAdvance();
                this.addToken(
                    token.setType('ASSIGN')
                         .setValue('%=')
                         .setEnd(this.position.clone())
                );
                return true;
            }
            // else it's just '%'
            this.addToken(
                token.setType('MATH')
                     .setValue('%')
                     .setPrecedence(consts.Precedence.multiplicative)
                     .setEnd(this.position.clone())
            );
            return true;
        case 38: // 38 is '&'
            if(this.hasNextChar()) {
                // look for '&&'
                if(this.charCode() == 38) { // 38 is '&'
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('LOGIC')
                             .setValue('&&')
                             .setPrecedence(consts.Precedence.logicalAND)
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // look for '&='
                if(this.charCode() == 61) { // 61 is '='
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('ASSIGN')
                             .setValue('&=')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
            }
            // else it's '&'
            this.addToken(
                token.setType('BITWISE')
                     .setValue('&')
                     .setPrecedence(consts.Precedence.bitwiseAND)
                     .setEnd(this.position.clone())
            );
            return true;
        case 40: // 40 is '('
            var type = '(';
            var closeableWith = ')';
            if(consts.tokenInterpretation.callable.indexOf(this.lastToken().type) > -1) {
                type = 'CALL_START';
                closeableWith = 'CALL_END';
            }
            this.addToken(
                token.setType(type)
                     .setValue('[')
                     .setEnd(this.position.clone())
            );
            this.tracker.opened.unshift({
                type: type,
                closeable: true,
                closeableWith: closeableWith,
                openedIn: token
            });
            this.tracker.addIndentLevel();
            return true;
        case 41: // 41 is ')'
            this.closeIndent(this.tracker.closeIndentLevel());
            var openation = this.tracker.opened.shift();
            this.addToken(
                token.setType(openation.closeableWith)
                     .setValue(')')
                     .setEnd(this.position.clone())
            );
            token.set('openedIn', openation.openedIn);
            openation.openedIn.set('closedIn', token);
            return true;
        case 42: // 42 is '*'
            if(this.hasNextChar()) {
                // look for '**' or '**='
                if(this.charCode() == 42) { // 42 is '*'
                    this.position.colAdvance();
                    // look for '**='
                    if(this.hasNextChar() && this.charCode() == 61) { // 61 is '='
                        this.position.colAdvance();
                        this.addToken(
                            token.setType('ASSIGN')
                                 .setValue('**=')
                                 .setEnd(this.position.clone())
                        );
                        return true;
                    }
                    this.addToken(
                        token.setType('MATH')
                             .setValue('**')
                             .setPrecedence(consts.Precedence.multiplicative)
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // look for '*='
                if(this.charCode() == 61) { // 61 is '='
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('ASSIGN')
                             .setValue('*=')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
            }
            // else it's '*'
            this.addToken(
                token.setType('MATH')
                     .setValue('*')
                     .setPrecedence(consts.Precedence.multiplicative)
                     .setEnd(this.position.clone())
            );
            return true;
        case 43: // 43 is '+'
            if(this.hasNextChar()) {
                // look for '++'
                if(this.charCode() == 43) { // 43 is '+'
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('UPDATE')
                             .setValue('++')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // look for '+='
                if(this.charCode() == 61) { // 61 is '='
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('ASSIGN')
                             .setValue('+=')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
            }
            // else it's '+'
            this.addToken(
                token.setType('+')
                     .setValue('+')
                     .setPrecedence(consts.Precedence.additive)
                     .setEnd(this.position.clone())
            );
            return true;
        case 44: // 44 is ','
            this.addToken(
                token.setType(',')
                     .setValue(',')
                     .setEnd(this.position.clone())
            );
            return true;
        case 45: // 45 is '-'
            if(this.hasNextChar()) {
                // look for '--'
                if(this.charCode() == 45) { // 45 is '-'
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('UPDATE')
                             .setValue('--')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // look for '-='
                if(this.charCode() == 61) { // 61 is '='
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('ASSIGN')
                             .setValue('-=')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // look for '->'
                if(this.charCode() == 62) { // 62 is '>'
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('->')
                             .setValue('->')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
            }
            // else it's '-'
            this.addToken(
                token.setType('-')
                     .setValue('-')
                     .setPrecedence(consts.Precedence.additive)
                     .setEnd(this.position.clone())
            );
            return true;
        case 46: // 46 is '.'
            // look for '..', '...' or '....'
            if(this.hasNextChar() && this.charCode() == 46) { // 46 is '.'
                this.position.colAdvance();
                // look for '...'
                if(this.hasNextChar() && this.charCode() == 46) { // 46 is '.'
                    this.position.colAdvance();
                    // look for '....'
                    if(this.hasNextChar() && this.charCode() == 46) { // 46 is '.'
                        this.position.colAdvance();
                        this.addToken(
                            token.setType('RANGE')
                                 .setValue('....')
                                 .setEnd(this.position.clone())
                        );
                        return true;
                    }
                    // then it's just '...'
                    this.addToken(
                        token.setType('RANGE')
                             .setValue('...')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // then it's just '..'
                this.addToken(
                    token.setType('MEMBER')
                         .setValue('..')
                         .setEnd(this.position.clone())
                );
                return true;
            }
            // then it's juts '.'
            this.addToken(
                token.setType('MEMBER')
                     .setValue('.')
                     .setEnd(this.position.clone())
            );
            return true;
        case 47: // 37 is '/'
            // look for '/='
            if(this.hasNextChar() && this.charCode() == 61) { // 61 is '='
                this.position.colAdvance();
                this.addToken(
                    token.setType('ASSIGN')
                         .setValue('/=')
                         .setEnd(this.position.clone())
                );
                return true;
            }
            // else it's just '/'
            this.addToken(
                token.setType('MATH')
                     .setValue('/')
                     .setPrecedence(consts.Precedence.multiplicative)
                     .setEnd(this.position.clone())
            );
            return true;
        // TDOO: implement: ':' and ';'
        case 58: // 58 is ':'
            // look for '::'
            if(this.hasNextChar() && this.charCode() == 58) { // 58 is ':'
                this.position.colAdvance();
                this.addToken(
                    token.setType('MEMBER')
                         .setValue('::')
                         .setEnd(this.position.clone())
                );
                return true;
            }
            // then it's juts ':'
            this.addToken(
                token.setType(':')
                     .setValue(':')
                     .setEnd(this.position.clone())
            );
            return true;
        case 60: // 60 is '<'
            if(this.hasNextChar()) {
                // look for '<<' or '<<='
                if(this.charCode() == 60) { // 60 is '<'
                    this.position.colAdvance();
                    // look for '<<='
                    if(this.hasNextChar() && this.charCode() == 61) { // 61 is '='
                        this.position.colAdvance();
                        this.addToken(
                            token.setType('ASSIGN')
                                 .setValue('<<=')
                                 .setEnd(this.position.clone())
                        );
                        return true;
                    }
                    // else it's '<<'
                    this.addToken(
                        token.setType('SHIFT')
                             .setValue('<<')
                             .setPrecedence(consts.Precedence.shift)
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // look for '<='
                if(this.charCode() == 61) { // 61 is '='
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('COMPARE')
                             .setValue('<=')
                             .setPrecedence(consts.Precedence.relationel)
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // TODO: implement: concat '<->'
            }
            // then it's just '<'
            this.addToken(
                token.setType('COMPARE')
                     .setValue('<')
                     .setPrecedence(consts.Precedence.relationel)
                     .setEnd(this.position.clone())
            );
            return true;
        case 61: // 61 is '='
            if(this.hasNextChar()) {
                // look for '==' and '==='
                if(this.charCode() == 61) { // 61 is '='
                    this.position.colAdvance();
                    // look for '==='
                    if(this.hasNextChar() && this.charCode() == '61') { // 61 is '='
                        this.position.colAdvance();
                        this.addToken(
                            token.setType('COMPARE')
                                 .setValue('===')
                                 .setPrecedence(consts.Precedence.equality)
                                 .setEnd(this.position.clone())
                        );
                        return true;
                    }
                    // then it's just a '=='
                    this.addToken(
                        token.setType('COMPARE')
                             .setValue('==')
                             .setPrecedence(consts.Precedence.equality)
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // look for '=>'
                if(this.charCode() == 62) { // 62 is '>'
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('=>')
                             .setValue('=>')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
            }
            // else it's a '='
            this.addToken(
                token.setType('ASSIGN')
                     .setValue('=')
                     .setEnd(this.position.clone())
            );
            return true;
        case 62: // 62 is '>'
            if(this.hasNextChar()) {
                // look for '>>' or '>>='
                if(this.charCode() == 62) { // 62 is '>'
                    this.position.colAdvance();
                    // look for '>>='
                    if(this.hasNextChar() && this.charCode() == 61) { // 61 is '='
                        this.position.colAdvance();
                        this.addToken(
                            token.setType('ASSIGN')
                                 .setValue('>>=')
                                 .setEnd(this.position.clone())
                        );
                        return true;
                    }
                    // else it's '>>'
                    this.addToken(
                        token.setType('SHIFT')
                             .setValue('>>')
                             .setPrecedence(consts.Precedence.shift)
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // look for '>='
                if(this.charCode() == 61) { // 61 is '='
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('COMPARE')
                             .setValue('>=')
                             .setPrecedence(consts.Precedence.relationel)
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
            }
            // then it's just '>'
            this.addToken(
                token.setType('COMPARE')
                     .setValue('>')
                     .setPrecedence(consts.Precedence.relationel)
                     .setEnd(this.position.clone())
            );
            return true;
        case 63: // 63 is '?'
            this.addToken(
                token.setType('?')
                     .setValue('?')
                     .setEnd(this.position.clone())
            );
            return true;
        case 64: // 64 is '@'
            this.addToken(
                token.setType('@')
                     .setValue('@')
                     .setEnd(this.position.clone())
            );
            return true;
        case 91: // 91 is '['
            var type = '[';
            var closeableWith = ']';
            if(consts.tokenInterpretation.indexable.indexOf(this.lastToken().type) > -1) {
                type = 'INDEX_START';
                closeableWith = 'INDEX_END';
            }
            this.addToken(
                token.setType(type)
                     .setValue('[')
                     .setEnd(this.position.clone())
            );
            this.tracker.opened.unshift({
                type: type,
                closeable: true,
                closeableWith: closeableWith,
                openedIn: token
            });
            this.tracker.addIndentLevel();
            return true;
        case 92: // 92 is '\'
            this.addToken(
                token.setType('\\')
                     .setValue('\\')
                     .setEnd(this.position.clone())
            );
            return true;
        case 93: // 93 is ']'
            this.closeIndent(this.tracker.closeIndentLevel());
            var openation = this.tracker.opened.shift();
            this.addToken(
                token.setType(openation.closeableWith)
                     .setValue(']')
                     .setEnd(this.position.clone())
            );
            token.set('openedIn', openation.openedIn);
            openation.openedIn.set('closedIn', token);
            return true;
        case 94: // 94 is '^'
            // look for '^='
            if(this.hasNextChar() && this.charCode() == 61) { // 61 is '='
                this.position.colAdvance();
                this.addToken(
                    token.setType('ASSIGN')
                         .setValue('^=')
                         .setEnd(this.position.clone())
                );
                return true;
            }
            // else it's just '^'
            this.addToken(
                token.setType('BITWISE')
                     .setValue('^')
                     .setPrecedence(consts.Precedence.bitwiseXOR)
                     .setEnd(this.position.clone())
            );
            return true;
        case 123: // 123 is '{'
            this.addToken(
                token.setType('{')
                     .setValue('{')
                     .setEnd(this.position.clone())
            );
            this.tracker.opened.unshift({
                type: '{',
                closeable: true,
                closeableWith: '}',
                openedIn: token
            });
            this.tracker.addIndentLevel();
            return true;
        case 124: // 124 is '|'
            // look for '||' or '|='
            if(this.hasNextChar()) {
                // look for '||'
                if(this.charCode() == 124) { // 124 is '|'
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('LOGIC')
                             .setValue('||')
                             .setPrecedence(consts.Precedence.logicalOR)
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // look for '|='
                if(this.charCode() == 61) { // 61 is '='
                    this.position.colAdvance();
                    this.addToken(
                        token.setType('ASSIGN')
                             .setValue('|=')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
            }
            // then it's just '|'
            this.addToken(
                token.setType('BITWISE')
                     .setValue('|')
                     .setPrecedence(consts.Precedence.bitwiseOR)
                     .setEnd(this.position.clone())
            );
            return true;
        case 125: // 125 is '}'
            this.closeIndent(this.tracker.closeIndentLevel());
            var openation = this.tracker.opened.shift();
            this.addToken(
                token.setType(openation.closeableWith)
                     .setValue('}')
                     .setEnd(this.position.clone())
            );
            token.set('openedIn', openation.openedIn);
            openation.openedIn.set('closedIn', token);
            return true;
        case 126: // 126 is '~'
            if(this.hasNextChar() && this.charCode() == 126) { // 126 is '~'
                this.position.colAdvance();
                // look for '~~='
                if(this.hasNextChar() && this.charCode() == 61) { // 61 is '='
                    this.position.clone();
                    this.addToken(
                        token.setType('ASSIGN')
                             .setValue('~~=')
                             .setEnd(this.position.clone())
                    );
                    return true;
                }
                // then it's just '~~'
                this.addToken(
                    token.setType('CONCAT')
                         .setValue('~~')
                         .setPrecedence(consts.Precedence.additive)
                         .setEnd(this.position.clone())
                );
                return true;
            }
            // then it's a '~'
            this.addToken(
                token.setType('UNARY')
                     .setValue('~')
                     .setEnd(this.position.clone())
            );
            return true;
    }
    this.errorM.let(100, {
        what: String.fromCharCode(charCode),
        pos: token.location.start
    });
    return false;
};

// lex indentation
Lexer.prototype.lexIndent = function() {
    var token;
    var startPos = this.position.clone();
    var indentation = this.matchA('INDENTATION').length;
    var indentTracker = this.tracker.currentIndentTracker();
    // TODO: error : if indent tracker is null
    this.position.colAdvance(indentation);
    if(indentation > indentTracker.currentIndent) {
        indentTracker.currentIndent = indentation;
        indentTracker.indentStack.unshift(indentation);
        this.addToken(
            token = (new Token('INDENT'))
                .set('length', indentation)
                .setStart(startPos)
                .setEnd(null)
        );
        indentTracker.tokenStack.unshift(token);
        return true;
    } else if(indentation == indentTracker.currentIndent) {
        this.addToken(
            token = (new Token('MINDENT'))
                .set('length', indentation)
                .set('startedIn', indentTracker.tokenStack[0])
                .setStart(startPos)
                .setEnd(null)
        );
        return true;
    } else {
        var indent = indentTracker.indentStack[0];
        while(indentation <= indent) {
            if(indentation == indent) {
                this.addToken(
                    token = (new Token('MINDENT'))
                        .set('length', indentation)
                        .set('startedIn', indentTracker.tokenStack[0])
                        .setStart(startPos)
                        .setEnd(null)
                );
                break;
            } else if(indentation < indent) {
                this.addToken(
                    (new Token('OUTDENT'))
                        .set('length', indent)
                        .set('openedIn', indentTracker.tokenStack.shift())
                        .setStart(startPos)
                        .setEnd(null)
                );
                indentTracker.indentStack.shift();
                indent = indentTracker.indentStack[0];
                indentTracker.currentIndent = indent;
            }
        }
        return true;
    }
    return false;
};

Lexer.prototype.closeIndent = function(indentTracker) {
    while(indentTracker.indentStack.length > 0) {
        var indentation = indentTracker.indentStack.shift();
        var openedIn = indentTracker.tokenStack.shift();
        this.addToken(
            (new Token('OUTDENT'))
                .set('length', indentation)
                .set('openedIn', openedIn)
                .setStart(this.position.clone())
                .setEnd(null)
        );
    }
};

// Tracker
function Tracker() {
    this.into = {
        mammouth: false,
        for: false
    };
    this.opened = [];
    this.indentTrackers = [];
}

Tracker.prototype.addIndentLevel = function() {
    var tracker = new IndentTracker();
    this.indentTrackers.unshift(tracker);
    return tracker;
};

Tracker.prototype.closeIndentLevel = function() {
    return this.indentTrackers.shift();
};

Tracker.prototype.currentIndentTracker = function() {
    if(this.indentTrackers.length > 0) {
        return this.indentTrackers[0];
    }
    return null;
};

function IndentTracker() {
    this.currentIndent = -1;
    this.indentStack = [];
    this.tokenStack = [];
}

// exports
module.exports = Lexer;