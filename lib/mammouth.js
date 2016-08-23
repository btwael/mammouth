var mammouth = (function(root) {
  var require = function(path) {return require[path]};
  require["./position"] = (function() {
    var exports = {}, module = {exports: exports};
    
    // Position object describe a specific point in a text code (lsemiliar to cursor in text editor)
    // a Position is defined with a file name, offset (the number of characters from code start, from 0),
    // line (start from 1), and column (start from 0);
    function Position(filename, offset, line, column) {
        this.filename = filename === undefined ? null : filename;
        this.offset = offset === undefined ? 0 : offset;
        this.line = line === undefined ? 1 : line;
        this.column = column === undefined ? 0 : column;
    }
    
    // Get a clone of this object
    Position.prototype.clone = function() {
        return new Position(this.filename, this.offset, this.line, this.column);
    };
    
    /*-- For dynamic and tracking position --*/
    // Increment a position with number of columns
    Position.prototype.colAdvance = function(num) {
        num = num === undefined ? 1 : num;
        this.offset += num;
        this.column += num;
    };
    
    // Increment a position with number of line breaks
    Position.prototype.rowAdvance = function(num) {
        num = num === undefined ? 1 : num;
        this.offset += num;
        this.line += num;
        this.column = 0;
    };
    
    // exports
    module.exports = Position;
    
    return module.exports;
    
  })();
  
  require["./location"] = (function() {
    var exports = {}, module = {exports: exports};
    
    // imports
    var Position = require("./position");
    
    // A location describe the start and the end of a code sequence (ex. Token)
    function Location(start, end) {
        this.start = start === undefined ? new Position() : start;
        this.end = end === undefined ? new Position() : end;
    }
    
    // Get a clone of this object
    Location.prototype.clone = function() {
        return new Location(this.start.clone(), this.end.clone());
    };
    
    // Set filename
    Location.prototype.setFilename = function(filename) {
        this.start.filename = this.end.filename = filename;
    };
    
    // exports
    module.exports = Location;
    
    return module.exports;
    
  })();
  
  require["./token"] = (function() {
    var exports = {}, module = {exports: exports};
    
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
    
    return module.exports;
    
  })();
  
  require["./utils"] = (function() {
    var exports = {}, module = {exports: exports};
    
    exports.reverseArray = function(array) {
        var reversed = [];
        for(var i = 0; i < array.length; i++) {
            reversed.unshift(array[i]);
        }
        return reversed;
    };
    
    exports.extends = function(base, extension) {
        var constructed = function() {
            extension.apply(this, arguments);
            delete this.location;
            base.apply(this, arguments);
        };
        for(var key in extension.prototype) {
            base.prototype[key] = extension.prototype[key];
        }
        return constructed;
    };
    
    return exports;
    
  })();
  
  require["./error"] = (function() {
    var exports = {}, module = {exports: exports};
    
    var ErrorList = {
        100: function() {
            return "unexpected " + this.what;
        },
        101: function() {
            return "Expected " + this.expected + ' but found ' + this.found;
        }
    };
    
    function error(source, filename, option) {
        this.source = source;
        this.filename = filename === undefined ? null : filename;
        this.option = option === undefined ? {} : option;
        if(this.option.showWhere === undefined) this.option.showWhere = true;
        if(this.option.showInSource === undefined) this.option.showInSource = true;
    }
    
    error.prototype.process = function(message, option) {
        var premessage;
        if(this.option.showWhere == true && option.pos != undefined) {
            premessage = 'Error';
            if(this.filename != null) {
                premessage += ' on ' + this.filename;
            }
            premessage += ' on line ' + option.pos.line + (option.pos.column == 0 ? '' : ' on column ' + (option.pos.column + 1));
            premessage += ': ';
            message = premessage + message;
        }
        if(this.option.showInSource == true && option.pos != undefined) {
            postmessage = '\n' + this.source.split("\n")[option.pos.line - 1]
            postmessage += '\n'
            for(var i = 0; i < option.pos.column + 1; i++) {
                postmessage += '^'
            }
            message = message + postmessage;
        }
        throw message;
    };
    
    error.prototype.let = function(errorid, option) {
        this.process(ErrorList[errorid].call(option), option);
    };
    
    module.exports = error;
    
    return module.exports;
    
  })();
  
  require["./consts"] = (function() {
    var exports = {}, module = {exports: exports};
    
    var RegularExpressions = {
        'IDENTIFIER': /((^[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/,
        'HEREDOC': /^`(((?!(\`|{{|}}))([\n\r\u2028\u2029]|.))*)`/,
        'NUMBER': /^(0b[01]+|0o[0-7]+|0(x|X)[\da-fA-F]+|\d*\.?\d+(?:(e|E)[+-]?\d+)?)/,
        'STRING': /^('[^\\']*(?:\\[\s\S][^\\']*)*'|\u0022[^\\\u0022]*(?:\\[\s\S][^\\\u0022]*)*\u0022)/,
        'QUALIFIEDSTRING': /^q('[^\\']*(?:\\[\s\S][^\\']*)*'|\u0022[^\\\u0022]*(?:\\[\s\S][^\\\u0022]*)*\u0022)/,
    
        'INDENTATION': /(^[ \t]*)/,
    
        'COMMENT': /^###([^#][\s\S]*?)###|^(?:\s*#(?!##[^#]).*)+/,
    
        'START_TAG': /^{{/,
        'END_TAG': /^}}/,
        'INTERPOLATION_START_TAG': /^{{>/
    };
    
    var Precedence = {
        expression: 0,
        logicalOR: 2,
        logicalAND: 3,
        bitwiseOR: 4,
        bitwiseXOR: 5,
        bitwiseAND: 6,
        equality: 7,
        relationel: 8,
        shift: 9,
        additive: 10,
        multiplicative: 11,
    };
    
    var Keywords = {
        bool: ['true', 'false'],
        compare: ['is', 'isnt'],
        logic: ['and', 'or', 'xor'],
        castType: ['array', 'binary', 'bool', 'boolean', 'double', 'int', 'integer', 'float', 'object', 'real', 'string', 'unset'],
        reserved: [
            'abstract', 'as',
            'break', 'by',
            'case', 'catch', 'class', 'clone', 'const', 'continue',
            'delete',
            'echo', 'else', 'extends',
            'final', 'finally', 'for', 'func',
            'global', 'goto',
            'if', 'implements', 'in', 'include', 'instanceof', 'interface',
            'loop',
            'namespace', 'new', 'null',
            'of', 'once',
            'private', 'protected', 'public',
            'require', 'return',
            'static', 'switch',
            'throw', 'try',
            'until', 'use',
            'while', 'when'
        ]
    };
    
    // TODO: fill indexable and callable
    var CALLABLE = ['CALL_END', 'IDENTIFIER', 'INDEX_END', 'QUALIFIEDSTRING', ')', ']', '?'];
    
    var INDEXABLE = ['SLICE_END', 'RANGE_END'].concat(CALLABLE);
    
    var tokenInterpretation = {
        importantComment: ['INDENT', 'MINDENT', 'OUTDENT'],
        callable: CALLABLE,
        indexable: INDEXABLE,
        notExpression: ['INDENT', 'MINDENT', 'OUTDENT'].concat(Keywords.compare).concat(Keywords.logic).concat(Keywords.reserved),
        prefixOperator: ['CLONE', 'NEW', 'UNARY', 'UPDATE', '+', '-']
    }
    
    // exports
    exports.RegularExpressions = RegularExpressions;
    exports.Precedence = Precedence;
    exports.Keywords = Keywords;
    exports.tokenInterpretation = tokenInterpretation;
    
    return exports;
    
  })();
  
  require["./rewriter"] = (function() {
    var exports = {}, module = {exports: exports};
    
    // Rewriter takes from lexer a token stream, and improve the ouput for better parsing and error handling
    function Rewriter() {
        // Nothing go here
    }
    
    Rewriter.prototype.setInput = function(tokens) {
        this.input = tokens;
    };
    
    Rewriter.prototype.rewrite = function() {
        // Remove meaning-less token
        this.removeUnnecessary();
        // Token that meaning changes when they are in a special sequence (ex. between '[' & ']')
        this.landlockedToken();
        // Replace tokens reference with their indexes (avoiding circular references)
        this.referencesIndex();
        //return final tokens list
        return this.input;
    };
    
    Rewriter.prototype.removeUnnecessary = function() {
        for (var i = 0; i < this.input.length - 1; i++) {
            var firstToken = this.input[i];
            var secondToken = this.input[i + 1];
            // LINETERMINATOR + OUTDENT => delete LINETERMINATOR
            if(firstToken.type == 'LINETERMINATOR' && secondToken.type == 'OUTDENT') {
                this.input.splice(i, 1);
                i--; continue;
            }
            // CASE => SWITCH_WHEN
            if(firstToken.type == 'CASE') {
                firstToken.type == 'SWITCH_WHEN';
                i--; continue;
            }
            // INDENT or MINDENT or OUTDENT + WHEN => rename WHEN to SWITCH_WHEN
            if(['INDENT', 'MINDENT', 'OUTDENT'].indexOf(firstToken.type) > -1 && secondToken.type == 'WHEN') {
                secondToken.type = 'SWITCH_WHEN';
                i--; continue;
            }
            // MINDENT + CATCH => delete MINDENT
            if(firstToken.type == 'MINDENT' && secondToken.type == 'CATCH') {
                this.input.splice(i, 1);
                i--; continue;
            }
            // MINDENT + ELSE => delete MINDENT
            if(firstToken.type == 'MINDENT' && secondToken.type == 'ELSE') {
                this.input.splice(i, 1);
                i--; continue;
            }
            // MINDENT + FINALLY => delete MINDENT
            if(firstToken.type == 'MINDENT' && secondToken.type == 'FINALLY') {
                this.input.splice(i, 1);
                i--; continue;
            }
            // FINAL or ABSTARCT + CLASS => rename first to CLASSMODIFIER
            if(['FINAL', 'ABSTRACT'].indexOf(firstToken.type) > -1 && secondToken.type == 'CLASS') {
                firstToken.type = 'CLASSMODIFIER';
                i--; continue;
            }
            // FUNC + IDENTIFIER + CALL_START => FUNC + IDENTIFIER + (
            if(firstToken.type == 'FUNC' && secondToken.type == 'IDENTIFIER'
                                         && i + 2 < this.input.length
                                         && this.input[i + 2].type == 'CALL_START') {
                var thirdToken = this.input[i + 2];
                thirdToken.type = '(';
                thirdToken._.closedIn.type = ')';
            }
        }
    };
    
    Rewriter.prototype.landlockedToken = function() {
        for(var i = 0; i < this.input.length; i++) {
            var startToken = this.input[i];
            if(startToken.type == 'INDEX_START' && this.checkLandlocked(i, startToken, 'RANGE')) {
                startToken.type = 'SLICE_START';
                startToken._.closedIn.type = 'SLICE_END';
            }
            if(startToken.type == '[' && this.checkLandlocked(i, startToken, 'RANGE')) {
                startToken.type = 'RANGE_START';
                startToken._.closedIn.type = 'RANGE_END';
            }
        }
    };
    
    Rewriter.prototype.referencesIndex = function() {
        for(var i = 0; i < this.input.length; i++) {
            var startToken = this.input[i];
            for(var j = 0; j < this.input.length; j++) {
                if(j == i) continue;
                var endToken = this.input[j];
                switch(startToken.type) {
                    case 'MINDENT':
                        if(startToken._.startedIn == endToken) {
                            startToken._.startedIn = j;
                        }
                        break;
                    case 'OUTDENT':
                        if(startToken._.openedIn == endToken) {
                            startToken._.openedIn = j;
                            endToken._.closedIn = i;
                        }
                        break;
                    case 'INDEX_START':
                    case 'START_TAG':
                    case '{':
                    case 'CALL_START':
                    case 'RANGE_START':
                        if(startToken._.closedIn == endToken) {
                            startToken._.closedIn = j;
                            endToken._.openedIn = i;
                        }
                        break;
                }
            }
        }
    };
    
    Rewriter.prototype.checkLandlocked = function(startIndex, startToken, landlockedType) {
        var found = false;
        for(var i = startIndex + 1; i < this.input.length; i++) {
            var endToken = this.input[i];
            if(endToken.type == landlockedType) {
                found = true;
                break;
            }
            if(endToken == startToken._.closedIn) {
                break;
            }
        }
        return found;
    };
    
    // exports
    module.exports = Rewriter;
    
    return module.exports;
    
  })();
  
  require["./lexer"] = (function() {
    var exports = {}, module = {exports: exports};
    
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
    
    return module.exports;
    
  })();
  
  require["./nodes"] = (function() {
    var exports = {}, module = {exports: exports};
    
    // imports
    var Location = require("./location");
    var utils = require("./utils");
    
    // Base node
    var Base = function() {};
    
    // Document Node
    var Document = function(sections) {
        this.type = 'Document';
        this.sections = sections === undefined ? [] : sections; // List of DocumentSection
        this.location = new Location();
    };
    
    Document = utils.extends(Document, Base);
    
    // DocumentSection node
    var DocumentSection = function() {
        this.type = 'DocumentSection';
        this.location = new Location();
    };
    
    DocumentSection = utils.extends(DocumentSection, Base);
    
    // RAW node
    var RAW = function(text) {
        this.type = 'RAW';
        this.text = text === undefined ? '' : text;
        this.location = new Location();
    };
    
    RAW = utils.extends(RAW, DocumentSection);
    
    // Script node
    var Script = function(body) {
        this.type = 'Script';
        this.body = body === undefined ? new Block() : body;
        this.location = new Location();
    };
    
    Script = utils.extends(Script, DocumentSection);
    
    // Block node
    var Block = function(statements) {
        this.type = 'Block';
        this.statements = statements === undefined ? [] : statements; // List of Statement
        this.location = new Location();
    };
    
    Block = utils.extends(Block, Base);
    
    // Statement node
    var Statement = function() {
        this.type = 'Statement';
        this.location = new Location();
    };
    
    Statement = utils.extends(Statement, Base);
    
    // Include node
    var Include = function(path, isOnce) {
        this.type = 'Include';
        this.path = path === undefined ? null : path;
        this.isOnce = isOnce === undefined ? false : isOnce;
        this.location = new Location();
    }
    
    Include = utils.extends(Include, Statement);
    
    // Require node
    var Require = function(path, isOnce) {
        this.type = 'Require';
        this.path = path === undefined ? null : path;
        this.isOnce = isOnce === undefined ? false : isOnce;
        this.location = new Location();
    }
    
    Require = utils.extends(Require, Statement);
    
    // Section node
    var Section = function(name) {
        this.type = 'Section';
        this.name = name === undefined ? null : name;
        this.location = new Location();
    };
    
    Section = utils.extends(Section, Statement);
    
    // Delete node
    var Delete = function(argument) {
        this.type = 'Delete';
        this.argument = argument;
        this.location = new Location();
    };
    
    Delete = utils.extends(Delete, Statement);
    
    // Global node
    var Global = function(args) {
        this.type = 'Global';
        this.arguments = args;
        this.location = new Location();
    };
    
    Global = utils.extends(Global, Statement);
    
    // Break node
    var Break = function(argument) {
        this.type = 'Break';
        this.argument = argument === undefined ? null : argument;
        this.location = new Location();
    };
    
    Break = utils.extends(Break, Statement);
    
    // Continue node
    var Continue = function(argument) {
        this.type = 'Continue';
        this.argument = argument === undefined ? null : argument;
        this.location = new Location();
    };
    
    Continue = utils.extends(Continue, Statement);
    
    // Return node
    var Return = function(argument) {
        this.type = 'Return';
        this.argument = argument === undefined ? null : argument;
        this.location = new Location();
    };
    
    Return = utils.extends(Return, Statement);
    
    // Throw node
    var Throw = function(argument) {
        this.type = 'Throw';
        this.argument = argument === undefined ? null : argument;
        this.location = new Location();
    };
    
    Throw = utils.extends(Throw, Statement);
    
    // Goto node
    var Goto = function(section) {
        this.type = 'Goto';
        this.section = section === undefined ? null : section;
        this.location = new Location();
    };
    
    Goto = utils.extends(Goto, Statement);
    
    // Constant node
    var Constant = function(name, value) {
        this.type = 'Constant';
        this.name = name;
        this.value = value;
        this.location = new Location();
    };
    
    Constant = utils.extends(Constant, Statement);
    
    // ExpressionStatement node
    var ExpressionStatement = function(expression) {
        this.type = 'ExpressionStatement';
        this.expression = expression;
        this.location = new Location();
    };
    
    ExpressionStatement = utils.extends(ExpressionStatement, Statement);
    
    // Expression node
    var Expression = function() {
        this.type = 'Expression';
        this.location = new Location();
    };
    
    Expression = utils.extends(Expression, Base);
    
    // For node
    var If = function(condition, body) {
        this.type = 'If';
        this.condition = condition;
        this.body = body === undefined ? null : body;
        this.elses = [];  
        this.location = new Location();
    };
    
    If = utils.extends(If, Expression);
    
    var ElseIf = function(condition, body) {
        this.type = 'ElseIf';
        this.condition = condition;
        this.body = body === undefined ? null : body;    
        this.location = new Location();
    };
    
    ElseIf = utils.extends(ElseIf, Expression);
    
    var Else = function(body) {
        this.type = 'Else';
        this.body = body === undefined ? null : body;    
        this.location = new Location();
    };
    
    Else = utils.extends(Else, Expression);
    
    // For node
    var For = function(source, body) {
        this.type = 'For';
        this.source = source;
        this.body = body === undefined ? null : body;    
        this.location = new Location();
    };
    
    For = utils.extends(For, Expression);
    
    // While node
    var While = function(test, invert, guard, body) {
        this.type = 'While';
        this.test = test;
        this.invert = invert === undefined ? false : invert;
        this.guard = guard === undefined ? null : guard;
        this.body = body === undefined ? null : body;    
        this.location = new Location();
    };
    
    While = utils.extends(While, Expression);
    
    // Try node
    var Try = function() {
        this.type = 'Try';
        this.tryBody = null;
        this.catchIdentifier = null;
        this.catchBody = null;
        this.finallyBody = null;
        this.location = new Location();
    };
    
    Try = utils.extends(Try, Expression);
    
    // Switch node
    var Switch = function() {
        this.type = 'Switch';
        this.subject = null;
        this.whens = [];
        this.otherwise = null;
        this.location = new Location();
    };
    
    Switch = utils.extends(Switch, Expression);
    
    // Assignement node
    var Assignement = function(operator, left, right) {
        this.type = 'Assignement';
        this.operator = operator;
        this.left = left;
        this.right = right;
        this.location = new Location();
    };
    
    Assignement = utils.extends(Assignement, Expression);
    
    // Keys Assignement node
    var KeysAssignement = function(keys, right) {
        this.type = 'KeysAssignement';
        this.keys = keys === undefined ? [] : keys;
        this.right = right === undefined ? null : right;
        this.location = new Location();
    };
    
    KeysAssignement = utils.extends(KeysAssignement, Expression);
    
    // Operation node
    var Operation = function(operator, left, right) {
        this.type = 'Operation';
        this.operator = operator;
        this.left = left;
        this.right = right;
        this.location = new Location();
    };
    
    Operation = utils.extends(Operation, Expression);
    
    // Operation node
    var CastTyping = function(argument, castType) {
        this.type = 'CastTyping';
        this.argument = argument;
        this.castType = castType;
        this.location = new Location();
    };
    
    CastTyping = utils.extends(CastTyping, Expression);
    
    // Unary node
    var Unary = function(operator, argument) {
        this.type = 'Unary';
        this.operator = operator;
        this.argument = argument;
        this.location = new Location();
    };
    
    Unary = utils.extends(Unary, Expression);
    
    // Update node
    var Update = function(operator, argument, prefix) {
        this.type = 'Update';
        this.operator = operator;
        this.argument = argument;
        this.prefix = prefix;
        this.location = new Location();
    };
    
    Update = utils.extends(Update, Expression);
    
    // Clone node
    var Clone = function(operator, argument) {
        this.type = 'Clone';
        this.operator = operator;
        this.argument = argument;
        this.location = new Location();
    };
    
    Clone = utils.extends(Clone, Expression);
    
    // Echo node
    var Echo = function(argument) {
        this.type = 'Echo';
        this.argument = argument;
        this.location = new Location();
    };
    
    Echo = utils.extends(Echo, Expression);
    
    // Value node
    var Value = function() {
        this.type = 'Value';
        this.location = new Location();
    };
    
    Value = utils.extends(Value, Base);
    
    // New node
    var New = function(operator, argument) {
        this.type = 'New';
        this.operator = operator;
        this.argument = argument;
        this.location = new Location();
    };
    
    New = utils.extends(New, Base);
    
    // Member node
    var Member = function(operator, base, property) {
        this.type = 'Member';
        this.base = base;
        this.property = property;
        this.operator = operator === undefined ? '.' : operator;
        this.location = new Location();
    };
    
    Member = utils.extends(Member, Value);
    
    // Call node
    var Call = function(callee, args) {
        this.type = 'Call';
        this.callee = callee;
        this.args = args;
        this.location = new Location();
    };
    
    Call = utils.extends(Call, Value);
    
    // Index node
    var Index = function(base, property) {
        this.type = 'Index';
        this.base = base;
        this.property = property;
        this.location = new Location();
    };
    
    Index = utils.extends(Index, Value);
    
    // Slice node
    var Slice = function(base, range) {
        this.type = 'Slice';
        this.base = base;
        this.range = range;
        this.location = new Location();
    };
    
    Slice = utils.extends(Slice, Value);
    
    // Existance node
    var Existance = function(value) {
        this.type = 'Existance';
        this.value = value;
        this.location = new Location();
    };
    
    Existance = utils.extends(Existance, Value);
    
    // Array node
    var ArrayNode = function(elements) {
        this.type = 'Array';
        this.elements = elements === undefined ? [] : elements;
        this.location = new Location();
    };
    
    ArrayNode = utils.extends(ArrayNode, Value);
    
    // Array key node
    var ArrayKey = function(key, value) {
        this.type = 'ArrayKey';
        this.key = key;
        this.value = value;
        this.location = new Location();
    };
    
    ArrayKey = utils.extends(ArrayKey, Base);
    
    // Range node
    var Range = function(from, to, rangeOperator) {
        this.type = 'Range';
        this.from = from;
        this.to = to;
        this.rangeOperator = rangeOperator;
        this.location = new Location();
    };
    
    Range = utils.extends(Range, Value);
    
    // Parenthetical node
    var Parenthetical = function(expression) {
        this.type = 'Parenthetical';
        this.expression = expression;
        this.location = new Location();
    };
    
    Parenthetical = utils.extends(Parenthetical, Value);
    
    // Identifier node
    var Identifier = function(name) {
        this.type = 'Identifier';
        this.name = name;
        this.isThis = false;
        if(this.name == 'this') {
            this.isThis = true;
            this.isAt = false;
        }
        this.location = new Location();
    };
    
    Identifier = utils.extends(Identifier, Value);
    
    // Literal node
    var Literal = function(value, subtype) {
        this.type = 'Literal';
        this.subtype = subtype;
        this.value = value;
        this.location = new Location();
    };
    
    Literal = utils.extends(Literal, Value);
    
    // Code (functions) node
    var Code = function() {
        this.type = 'Code';
        this.parameters = [];
        this.isAnonymous = true;
        this.name = null;
        this.hasBody = false;
        this.body = null;
        this.withUses = false;
        this.uses = [];
        this.location = new Location();
    };
    
    Code = utils.extends(Code, Value);
    
    // Parameter node
    var Parameter = function(name, isPassing) {
        this.type = 'Parameter';
        this.name = name === undefined ? null : name;
        this.isPassing = isPassing === undefined ? false : isPassing;
        this.hasDefault = false;
        this.default = null;
        this.location = new Location();
    };
    
    Parameter = utils.extends(Parameter, Base);
    
    // Casting type node
    var CastType = function(name) {
        this.type = 'CastType';
        this.name = name;
        this.location = new Location();
    };
    
    CastType = utils.extends(CastType, Value);
    
    // Operator node
    var Operator = function(symbol, subtype) {
        this.type = 'Operator';
        this.subtype = subtype === undefined ? null : subtype;
        this.symbol = symbol;
        this.precedence = 1;
        this.location = new Location();
    };
    
    Operator = utils.extends(Operator, Base);
    
    // Namespace node
    var Namespace = function(name, body) {
        this.type = 'Namespace';
        this.name = name === undefined ? null : name;
        this.body = body === undefined ? null : body;
        this.location = new Location();
    };
    
    Namespace = utils.extends(Namespace, Statement);
    
    // Namespace name node
    var NamespaceName = function() {
        this.type = 'NamespaceName';
        this.nameSequence = [];
        this.startWithBackSlash = false;
        this.location = new Location();
    };
    
    NamespaceName = utils.extends(NamespaceName, Value);
    
    // Class node
    var Class = function() {
        this.type = 'Class';
        this.modifier = null;
        this.name = null;
        this.extends = null;
        this.implements = null;
        this.members = null;
        this.location = new Location();
    };
    
    Class = utils.extends(Class, Statement);
    
    // Class member node
    var ClassMember = function() {
        this.type = 'ClassMember';
        this.isAbstract = false;
        this.isFinal = false;
        this.visibility = null;
        this.isStatic = false;
        this.member = null;
        this.location = new Location();
    };
    
    ClassMember = utils.extends(ClassMember, Base);
    
    // Interface node
    var Interface = function() {
        this.type = 'Interface';
        this.name = null;
        this.extends = null;
        this.members = null;
        this.location = new Location();
    };
    
    Interface = utils.extends(Interface, Statement);
    
    // Use statement node
    var Use = function() {
        this.type = 'Use';
        this.isConstFunc = null;
        this.clauses = [];
        this.location = new Location();
    };
    
    Use = utils.extends(Use, Statement);
    
    // Comment statement node
    var Comment = function() {
        this.type = 'Comment';
        this.value = "";
        this.location = new Location();
    };
    
    Comment = utils.extends(Comment, Statement);
    
    // exports
    exports.Base = Base;
    
    exports.Document = Document;
    exports.DocumentSection = DocumentSection;
    exports.RAW = RAW;
    exports.Script = Script;
    
    exports.Block = Block;
    exports.Statement = Statement;
    exports.Include = Include;
    exports.Require = Require;
    exports.Section = Section;
    exports.Delete = Delete;
    exports.Global = Global;
    exports.Break = Break;
    exports.Continue = Continue;
    exports.Return = Return;
    exports.Throw = Throw;
    exports.Goto = Goto;
    exports.Constant = Constant;
    exports.ExpressionStatement = ExpressionStatement;
    
    exports.Expression = Expression;
    exports.If = If;
    exports.ElseIf = ElseIf;
    exports.Else = Else;
    exports.For = For;
    exports.While = While;
    exports.Try = Try;
    exports.Switch = Switch;
    exports.Assignement = Assignement;
    exports.KeysAssignement = KeysAssignement;
    exports.Operation = Operation;
    exports.CastTyping = CastTyping;
    exports.Unary = Unary;
    exports.Update = Update;
    exports.Clone = Clone;
    exports.Echo = Echo;
    
    exports.Value = Value;
    exports.New = New;
    exports.Member = Member;
    exports.Call = Call;
    exports.Index = Index;
    exports.Slice = Slice;
    exports.Existance = Existance;
    exports.Array = ArrayNode;
    exports.ArrayKey = ArrayKey;
    exports.Range = Range;
    exports.Parenthetical = Parenthetical;
    exports.Identifier = Identifier;
    exports.Literal = Literal;
    exports.Code = Code;
    exports.Parameter = Parameter;
    
    exports.CastType = CastType;
    exports.Operator = Operator;
    
    exports.Namespace = Namespace;
    exports.NamespaceName = NamespaceName;
    exports.Class = Class;
    exports.ClassMember = ClassMember;
    exports.Interface = Interface;
    exports.Use = Use;
    
    exports.Comment = Comment
    
    return exports;
    
  })();
  
  require["./parser"] = (function() {
    var exports = {}, module = {exports: exports};
    
    // imports
    var Position = require("./position");
    var Nodes = require("./nodes");
    var consts = require("./consts");
    
    // Parser takes an input tokens stream/list, and generates an AST
    function Parser() {
        // nothing go here
    }
    
    Parser.prototype.setInput = function(tokens, errorM, filename) {
        this.input = tokens;
        this._i = 0;
        this.errorM = errorM;
        this.filename = filename === undefined ? null : filename;
        this.endPosition = new Position(filename);
    };
    
    // Tokens
    // Check if we have anymore token
    Parser.prototype.hasNextToken = function() {
        return this._i < this.input.length;
    };
    
    // Get the current token
    Parser.prototype.currentToken = function() {
        return this.input[this._i];
    };
    
    // Go to the next token
    Parser.prototype.next = function() {
        var token = this.currentToken();
        this._i++;
        this.endPosition = token.location.end === null ? token.location.start.clone() : token.location.start.clone();
        return token;
    };
    
    // Consume a token of type or throw error
    Parser.prototype.consume = function(type) {
        if(this.currentToken().type != type) {
            this.fail({expected: type});
        }
        return this.next();
    };
    
    // Error handling
    Parser.prototype.fail = function(arg) {
        var token = null, expected = null, message = null;
        if(arg === undefined) arg = {};
        if(arg.hasOwnProperty('token')) token = arg.token;
        if(arg.hasOwnProperty('expected')) expected = arg.expected;
        if(arg.hasOwnProperty('message')) message = arg.message;
        if(token === null) {
            token = this.currentToken();
        }
        if(message === null){
            if(expected === null) {
                var what;
                if(token.type == 'IDENTIFIER') {
                    what = 'identifier ' + token.value;
                } else {
                    what = token.value;
                }
                this.errorM.let(100, {
                    what: what,
                    pos: token.location.start
                });
                return;
            } else {
                message = 'Expected ' + expected  + ' but found ' + token;
                this.errorM.let(101, {
                    expected: expected,
                    found: token.type,
                    pos: token.location.start
                });
            }
        } else {
    
        }
        // TODO: error : throw better error
        throw message;
    };
    
    // Parsing
    
    // Parse Document (root)
    //      Document := DocumentSections
    //      DocumentSections := DocumentSection
    //                        | DocumentSections DocumentSection
    //      DocumentSection := RAWSection
    //                       | Script
    Parser.prototype.parseDocument = function() {
        var node = new Nodes.Document();
        if(this.hasNextToken()) {
            node.location.start = this.currentToken().location.start.clone();
            while(this.hasNextToken()) {
                switch(this.currentToken().type) {
                    case 'RAW':
                        node.sections.push(this.parseRAW());
                        break;
                    case 'START_TAG':
                        node.sections.push(this.parseScript());
                        break;
                    case 'INTERPOLATION_START_TAG':
                        node.sections.push(this.parseInterpolation())
                    default:
                        // TODO: error
                }
            }
            node.location.end = this.endPosition.clone();
        }
        return node;
    };
    
    // Parse RAW text setion
    //      RAWSection := RAW
    Parser.prototype.parseRAW = function() {
        var token = this.consume('RAW');
        var node = new Nodes.RAW(token.value);
        node.location = token.location.clone();
        return node;
    };
    
    // Parse mammouth script
    //      Script := START_TAG Block END_TAG
    Parser.prototype.parseScript = function() {
        var startPos = this.consume('START_TAG').location.start.clone();
        var node = new Nodes.Script(this.parseBlock(true));
        var endPos = this.consume('END_TAG').location.end.clone();
        node.location.start = startPos;
        node.location.end = endPos;
        return node;
    };
    
    // Parse mammouth interpolation
    //      Script := INTERPOLATION_START_TAG Expression INTERPOLATION_END_TAG
    Parser.prototype.parseInterpolation = function() {
        var startPos = this.consume('INTERPOLATION_START_TAG').location.start.clone();
        var node = new Nodes.Script(new Nodes.Block([new Nodes.Echo(this.parseExpression())]));
        node.body.statements[0].location = node.body.statements[0].argument.location.clone();
        node.body.location = node.body.statements[0].location.clone();
        var endPos = this.consume('INTERPOLATION_END_TAG').location.end.clone();
        node.location.start = startPos;
        node.location.end = endPos;
        return node;
    };
    
    // Parse block of code
    //      Block := INDENT Statements OUTDENT
    //             | Statement
    //      Statements := Statement
    //                  | Statements MINDENT Statement                 
    
    Parser.prototype.parseBlock = function(allowInline) {
        var node, startPos;
        allowInline = allowInline === undefined ? false : allowInline;
        // look for inline block
        if(allowInline && this.currentToken().type != 'INDENT') {
            node = this.parseStatement();
            node = new Nodes.Block([node]);
            node.location = node.statements[0].location.clone();
            return node;
        }
        // parse a no-inline block
        startPos = this.consume('INDENT').location.start.clone();
        node = new Nodes.Block();
        while(this.currentToken().type != 'OUTDENT') {
            node.statements.push(this.parseStatement());
            if(this.currentToken().type != 'OUTDENT') {
                this.consume('MINDENT');
            }
        }
        node.location.start = startPos;
        node.location.end = this.consume('OUTDENT').location.start.clone();
        return node;
    };
    
    // Parse statement
    //      Statement := SimpleStatement IfHeader IfElses
    //                 | SimpleStatement IfHeader
    //                 | SimpleStatement ForSource
    //                 | SimpleStatement WhileSource
    //                 | Namespace
    //                 | Class
    //                 | Interface
    //                 | Use
    //                 | Comment
    //      SimpleStatement := ExpressionStatement
    //                       | Include
    //                       | Require
    //                       | Section
    //                       | Break
    //                       | Constant
    //                       | Continue
    //                       | Delete
    //                       | Global
    //                       | Goto
    //                       | Return
    //                       | Throw
    Parser.prototype.parseStatement = function() {
        var statement, block;
        if(this.currentToken().type == 'IDENTIFIER' && this.input[this._i + 1] !== undefined && this.input[this._i + 1].type == ':') {
            statement = this.parseSection();
        }
        else switch(this.currentToken().type) {
            case 'INCLUDE':
                statement = this.parseInclude();
                break;
            case 'REQUIRE':
                statement = this.parseRequire();
                break;
            case 'BREAK':
                statement = this.parseBreak();
                break;
            case 'CONST':
                statement = this.parseConstant();
                break;
            case 'CONTINUE':
                statement = this.parseContinue();
                break;
            case 'DELETE':
                statement = this.parseDelete();
                break;
            case 'GLOBAL':
                statement = this.parseGlobal();
                break;
            case 'GOTO':
                statement = this.parseGoto();
                break;
            case 'RETURN':
                statement = this.parseReturn();
                break;
            case 'THROW':
                statement = this.parseThrow();
                break;
            case 'NAMESPACE':
                return this.parseNamespace();
            case 'CLASS':
                return this.parseClass();
            case 'INTERFACE':
                return this.parseInterface();
            case 'USE':
                return this.parseUse();
            case 'COMMENT':
                return this.parseComment();
            default:
                statement = this.parseExpressionStatement();
        }
        switch(this.currentToken().type) {
            case 'IF':
                var ifHeader = this.parseIfHeader();
                block = new Nodes.Block([statement]);
                block.location = statement.location.clone();
                ifHeader.body = block;
                ifHeader.location.start = statement.location.start.clone();
                ifHeader.location.end = ifHeader.condition.location.end.clone();
                if(this.currentToken().type == 'ELSE') {
                    ifHeader.elses = this.parseIfElses();
                    ifHeader.location.end = ifHeader.elses[ifHeader.elses.length - 1].location.end.clone();
                }
                statement = ifHeader;
                break;
            case 'FOR':
                var forSource = this.parseForSource();
                block = new Nodes.Block([statement]);
                block.location = statement.location.clone();
                statement = new Nodes.For(forSource, block);
                statement.location.start = block.location.start.clone();
                statement.location.end = forSource.endPos.clone();
                break;
            case 'UNTIL':
            case 'WHILE':
                var whileSource = this.parseWhileSource();
                whileSource.body = new Nodes.Block([statement]);
                whileSource.body.location = statement.location.end.clone();
                statement = whileSource;
                break;
        }
        return statement;
    };
    
    // Parse comment
    //      Comment := COMMENT
    Parser.prototype.parseComment = function() {
        var node = new Nodes.Comment();
        var token = this.consume('COMMENT');
        node.value = token.value;
        node.location = token.location.clone();
        return node;
    };
    
    // Parse include statement
    //      Include := INCLUDE ONCE Expression
    //               | INCLUDE Expression
    Parser.prototype.parseInclude = function() {
        var node = new Nodes.Include();
        node.location.start = this.consume('INCLUDE').location.start.clone();
        if(this.currentToken().type == 'ONCE') {
            this.consume('ONCE');
            node.isOnce = true;
        }
        node.path = this.parseExpression(false);
        node.location.end = node.path.location.end.clone();
        return node;
    };
    
    // Parse require statement
    //      Require := REQUIRE ONCE Expression
    //               | REQUIRE Expression
    Parser.prototype.parseRequire = function() {
        var node = new Nodes.Require();
        node.location.start = this.consume('REQUIRE').location.start.clone();
        if(this.currentToken().type == 'ONCE') {
            this.consume('ONCE');
            node.isOnce = true;
        }
        node.path = this.parseExpression(false);
        node.location.end = node.path.location.end.clone();
        return node;
    };
    
    // Parse section statament
    //      Section := IDENTIFIER :
    Parser.prototype.parseSection = function() {
        var node = new Nodes.Section();
        var token = this.consume('IDENTIFIER');
        node.name = token.value;
        node.location.start = token.location.start.clone();
        node.location.end = this.consume(':').location.end.clone();
        return node;
    };
    
    // Parse break statement
    //      Break := BREAK Number
    //             | BREAK
    Parser.prototype.parseBreak = function() {
        var node = new Nodes.Break();
        node.location = this.consume('BREAK').location.clone();
        if(this.currentToken().type == 'NUMBER') {
            node.argument = this.parseNumber();
            node.location.end = node.argument.location.end.clone();
        }
        return node;
    };
    
    // Parse constant statement
    //      Constant := CONST IDENTIFIER = INDENT Expression OUTDENT
    //                | CONST IDENTIFIER = Expression
    Parser.prototype.parseConstant = function() {
        var node = new Nodes.Constant();
        node.location.start = this.consume('CONST').location.start.clone();
        node.name = this.consume('IDENTIFIER').value;
        var needOutdent = false;
        var operator = this.parseAssignOperator();
        if(this.currentToken().type == 'INDENT') {
            needOutdent = true;
            this.consume('INDENT');
        }
        var right = this.parseExpression();
        node.value = right;
        node.location.end = right.location.end.clone();
        if(needOutdent === true) {
            this.consume('OUTDENT');
        }
        return node;
    };
    
    // Parse continue statement
    //      Continue := CONTINUE Number
    //                | CONTINUE
    Parser.prototype.parseContinue = function() {
        var node = new Nodes.Continue();
        node.location = this.consume('CONTINUE').location.clone();
        if(this.currentToken().type == 'NUMBER') {
            node.argument = this.parseNumber();
            node.location.end = node.argument.location.end.clone();
        }
        return node;
    };
    
    // Parse delete statement
    //      Delete := DELETE Expression
    Parser.prototype.parseDelete = function() {
        var node = new Nodes.Delete();
        node.location.start = this.consume('DELETE').location.start.clone();
        node.argument = this.parseExpression(false);
        node.location.end = node.argument.location.end.clone();
        return node;
    };
    
    // Parse global statement
    //      Global := GLOBAL Arguments
    Parser.prototype.parseGlobal = function() {
        var node = new Nodes.Global();
        node.location.start = this.consume('GLOBAL').location.start.clone();
        node.arguments = this.parseArguments(['INDENT', 'MINDENT', 'OUTDENT'], false);
        if(node.arguments.length === 0) {
            // TODO: error
            throw 'error';
        } else {
            node.location.end = node.arguments[node.arguments.length - 1].location.end.clone();
        }
        return node;
    };
    
    // Parse goto statement
    //      Goto := GOTO IDENTIFIER
    Parser.prototype.parseGoto = function() {
        var token;
        var node = new Nodes.Goto();
        node.location.start = this.consume('GOTO').location.start.clone();
        token = this.consume('IDENTIFIER');
        node.section = token.value;
        node.location.end = token.location.end.clone();
        return node;
    };
    
    // Parse return statement
    //      Return := RETURN Expression
    //              | RETURN
    Parser.prototype.parseReturn = function() {
        var node = new Nodes.Return();
        node.location = this.consume('RETURN').location.clone();
        if(consts.tokenInterpretation.notExpression.indexOf(this.currentToken().type) == - 1) {
            node.argument = this.parseExpression(false);
            node.location.end = node.argument.location.end.clone();
        }
        return node;
    };
    
    // Parse throw statement
    //      Throw := THROW Expression
    Parser.prototype.parseThrow = function() {
        var node = new Nodes.Throw();
        node.location.start = this.consume('THROW').location.start.clone();
        node.argument = this.parseExpression(false);
        node.location.end = node.argument.location.end.clone();
        return node;
    };
    
    // Parse expression statement
    //      ExpressionStatement := Expression
    Parser.prototype.parseExpressionStatement = function() {
        var expression = this.parseExpression();
        var node = new Nodes.ExpressionStatement(expression);
        node.location = expression.location.clone();
        return node;
    };
    
    // Parse expression
    //      Expression := SimpleExpression IFHeader IfElses
    //                  | SimpleExpression IFHeader
    //                  | SimpleExpression ForSource
    //                  | SimpleExpression WhileSource
    //                  | SimpleExpression
    //      SimpleExpression := Assignement
    //                        | Echo
    //                        | If
    //                        | For
    //                        | While
    //                        | Try
    //                        | Switch
    Parser.prototype.parseExpression = function(allowControl) {
        var expression, block;
        allowControl = allowControl === undefined ? true : allowControl;
        switch(this.currentToken().type) {
            case 'ECHO':
                expression = this.parseEcho();
                break;
            case 'IF':
                expression = this.parseIf();
                break;
            case 'FOR':
                expression = this.parseFor();
                break;
            case 'LOOP':
            case 'UNTIL':
            case 'WHILE':
                expression = this.parseWhile();
                break;
            case 'TRY':
                expression = this.parseTry();
                break;
            case 'SWITCH':
                expression = this.parseSwitch();
                break;
            default:
                expression = this.parseAssignement();
        }
        if(allowControl) {
            switch(this.currentToken().type) {
                case 'IF':
                    var ifHeader = this.parseIfHeader();
                    block = new Nodes.Block([expression]);
                    block.location = expression.location.clone();
                    ifHeader.body = block;
                    ifHeader.location.start = expression.location.start.clone();
                    ifHeader.location.end = ifHeader.condition.location.end.clone();
                    if(this.currentToken().type == 'ELSE') {
                        ifHeader.elses = this.parseIfElses();
                        ifHeader.location.end = ifHeader.elses[ifHeader.elses.length - 1].location.end.clone();
                    }
                    expression = ifHeader;
                    break;
                case 'FOR':
                    var forSource = this.parseForSource();
                    block = new Nodes.Block([expression]);
                    block.location = expression.location.clone();
                    expression = new Nodes.For(forSource, block);
                    expression.location.start = block.location.start.clone();
                    expression.location.end = forSource.endPos.clone();
                    break;
                case 'UNTIL':
                case 'WHILE':
                    var whileSource = this.parseWhileSource();
                    whileSource.body = new Nodes.Block([expression]);
                    whileSource.body.location = expression.location.end.clone();
                    expression = whileSource;
                    break;
            }
        }
        return expression;
    };
    
    // Parse echo expression
    Parser.prototype.parseEcho = function() {
        var node = new Nodes.Echo();
        node.location.start = this.consume('ECHO').location.start.clone();
        node.argument = this.parseExpression();
        node.location.end = node.argument.location.end.clone();
        return node;
    };
    
    // Parse if expression
    //      If := IfHeader Block IfElses
    //  (Other if expression, see Statement and Expression sections)
    Parser.prototype.parseIf = function() {
        var node = this.parseIfHeader();
        node.body = this.parseBlock(true);
        node.location.end = node.body.location.end.clone();
        if(this.currentToken().type == 'ELSE') {
            node.elses = this.parseIfElses();
            node.location.end = node.elses[node.elses.length - 1].location.end.clone();
        }
        return node;
    };
    
    // Parse if condition/header
    //      IfHeader := IF Expression
    Parser.prototype.parseIfHeader = function() {
        var node = new Nodes.If();
        node.location.start = this.consume('IF').location.start.clone();
        node.condition = this.parseExpression();
        return node;
    };
    
    // Parse if elses
    //      IfElses := ElseIfs ELSE Block
    //               | ElseIfs
    //               | ELSE Block
    //               |
    //      ElseIfs := ElseIfs ELSE IF Expression Block
    //               | ELSE IF Expression Block
    Parser.prototype.parseIfElses = function() {
        var elses = [];
        while(this.currentToken().type == 'ELSE') {
            var node;
            var startPos = this.consume('ELSE').location.start.clone();
            if(this.currentToken().type == 'IF') {
                this.consume('IF');
                node = new Nodes.ElseIf();
                node.condition = this.parseExpression();
                node.body = this.parseBlock(true);
                node.location.start = startPos;
                node.location.end = node.body.location.end.clone();
                elses.push(node);
                continue;
            } else {
                node = new Nodes.Else();
                node.body = this.parseBlock(true);
                node.location.start = startPos;
                node.location.end = node.body.location.end.clone();
                elses.push(node);
                break;
            }
        }
        return elses;
    };
    
    // Parse for expression
    //      For := ForSource Block      
    //  (Other for expression, see Statement and Expression sections)
    Parser.prototype.parseFor = function() {
        var node = new Nodes.For();
        node.source = this.parseForSource();
        node.body = this.parseBlock(true);
        node.location.start = node.source.startPos.clone();
        node.location.end = node.body.location.end.clone();
        return node;
    };
    
    // Parse for source/header
    //      ForSource := 
    //                 | FOR Range BY Expression AS Identifier WHEN Expression
    //                 | FOR Range AS Identifier BY Expression WHEN Expression
    //                 | FOR Range AS Identifier BY Expression
    //                 | FOR Range BY Expression AS Identifier
    //                 | FOR Range BY Expression WHEN Expression
    //                 | FOR Range AS Identifier WHEN Expression
    //                 | FOR Range BY Expression
    //                 | FOR Range AS Identifier
    //                 | FOR Range
    //                 | FOR ForVariables FORIN Expression BY Expression WHEN Expression
    //                 | FOR ForVariables FOROF Expression BY Expression WHEN Expressio 
    //                 | FOR ForVariables FORIN Expression WHEN Expression
    //                 | FOR ForVariables FOROF Expression WHEN Expressio 
    //                 | FOR ForVariables FORIN Expression BY Expression
    //                 | FOR ForVariables FOROF Expression BY Expression
    //                 | FOR ForVariables FORIN Expression
    //                 | FOR ForVariables FOROF Expression
    //      ForVariables := ForValue , ForValue
    //                    | ForValue
    Parser.prototype.parseForSource = function() {
        var token;
        var source = {source: null, name: null, index: null, step: null, guard: null, isRange: false, isForIn: false, isForOf: false, startPos: null, endPos: null};
        token = this.consume('FOR');
        source.startPos = token.location.start.clone();
        source.endPos = token.location.end.clone();
        if(this.currentToken().type == 'RANGE_START') {
            var range = this.parseRange();
            source.isRange = true;
            source.source = range;
            source.endPos = range.location.end.clone();
            var asParsed = false, byParsed = false, whenParsed = false;
            var i = 0;
            while(i < 3) {
                if(asParsed === false && this.currentToken().type == 'AS') {
                    asParsed = true;
                    this.consume('AS');
                    source.index = this.parseIdentifier();
                    source.endPos = source.index.location.end.clone(); 
                } else if(byParsed === false && this.currentToken().type == 'BY') {
                    byParsed = true;
                    this.consume('BY');
                    source.step = this.parseExpression();
                    source.endPos = source.step.location.end.clone(); 
                } else if(whenParsed === false && this.currentToken().type == 'WHEN') {
                    whenParsed = true;
                    this.consume('WHEN');
                    source.guard = this.parseExpression();
                    source.endPos = source.guard.location.end.clone(); 
                }
                i++;
            }
        } else {
            source.name = this.parseForValue();
            if(this.currentToken().type == ',') {
                this.consume(',');
                source.index = this.parseForValue();
            }
            if(this.currentToken().type == 'FORIN') {
                this.consume('FORIN');
                source.isForIn = true;
            } else if(this.currentToken().type == 'FOROF') {
                this.consume('FOROF');
                source.isForOf = true;
            } else {
                // TODO : error
                throw 'error';
            }
            var expression = this.parseExpression();
            source.source = expression;
            source.endPos = expression.location.end.clone();
            var byParsed = false, whenParsed = false;
            var i = 0;
            while(i < 2) {
                if(byParsed === false && this.currentToken().type == 'BY') {
                    byParsed = true;
                    this.consume('BY');
                    source.step = this.parseExpression();
                    source.endPos = source.step.location.end.clone(); 
                } else if(whenParsed === false && this.currentToken().type == 'WHEN') {
                    whenParsed = true;
                    this.consume('WHEN');
                    source.guard = this.parseExpression();
                    source.endPos = source.guard.location.end.clone(); 
                }
                i++;
            }
        }
        return source;
    };
    
    // Parse a for valable value
    //      ForValue := Identifier
    //                | Array
    Parser.prototype.parseForValue = function() {
        if(this.currentToken().type == 'IDENTIFIER') {
            return this.parseIdentifier();
        } else if(this.currentToken().type == '[') {
            return this.parseArray();
        }
        // TODO : error
        throw 'error';
    };
    
    // Parse while expression
    //      While := WhileSource Block
    //             | Loop
    //  (Other while expression, see Statement and Expression sections)
    Parser.prototype.parseWhile = function() {
        var node;
        if(this.currentToken().type == 'WHILE' || this.currentToken().type == 'UNTIL') {
            node = this.parseWhileSource();
            var block = this.parseBlock(true);
            node.body = block;
            node.location.end = block.location.end.clone();
        } else if(this.currentToken().type == 'LOOP') {
            return this.parseLoop();
        }
        return node;
    };
    
    // Parse a while source/header
    //      WhileSource := WHILE Expression
    //                   | WHILE Expression WHEN Expression
    //                   | UNTIL Expression
    //                   | UNTIL Expression WHEN Expression
    Parser.prototype.parseWhileSource = function() {
        var token, expression;
        var node = new Nodes.While();
        switch(this.currentToken().type) {
            case 'UNTIL':
            case 'WHILE':
                token = this.consume(this.currentToken().type);
                if(token.type == 'WHILE') {
                    node.invert = false;
                } else if(token.type == 'UNTIL') {
                    node.invert = true;
                }
                node.location.start = token.location.start.clone();
                break;
            default:
                // TODO: error
        }
        expression = this.parseExpression();
        node.test = expression;
        if(this.currentToken().type == 'WHEN') {
            this.consume('WHEN');
            expression = this.parseExpression();
            node.guard = expression;
            node.location.end = expression.location.end.clone();
        } else {
            node.location.end = expression.location.end.clone();
        }
        return node;
    };
    
    // Parse loop
    //      Loop := LOOP Block
    //            | LOOP Expression
    Parser.prototype.parseLoop = function() {
        var node = new Nodes.While();
        var token = this.consume('LOOP');
        node.location.start = token.location.start.clone();
        node.test = new Nodes.Literal('true', 'bool');
        node.test.location = token.location.clone();
        if(this.currentToken().type == 'INDENT') {
            var block = this.parseBlock();
            node.body = block;
            node.location.end = block.location.end.clone();
        } else {
            var expression = this.parseExpression();
            node.body = new Nodes.Block([expression]);
            node.body.location = expression.location.clone();
        }
        return node;
    };
    
    // Parse try expression
    //      Try := TRY Block CATCH Identifier Block FINALLY Block
    //           | TRY Block CATCH Block FINALLY Block
    //           | TRY Block FINALLY Block
    //           | TRY Block CATCH Identifier Block
    //           | TRY Block CATCH Block
    //           | TRY BLOCK
    Parser.prototype.parseTry = function() {
        var node = new Nodes.Try();
        node.location.start = this.consume('TRY').location.start.clone();
        node.tryBody = this.parseBlock(true);
        node.location.end = node.tryBody.location.end.clone();
        if(this.currentToken().type == 'CATCH') {
            this.consume('CATCH');
            if(this.currentToken().type == 'IDENTIFIER') {
                node.catchIdentifier = this.parseIdentifier();
            }
            node.catchBody = this.parseBlock();
            node.location.end = node.catchBody.location.end.clone();
        }
        if(this.currentToken().type == 'FINALLY') {
            this.consume('FINALLY');
            node.finallyBody = this.parseBlock(true);
            node.location.end = node.finallyBody.location.end.clone();
        }
        return node;
    };
    
    // Parse switch expression
    //      Switch := SWITCH Expression INDENT Whens OUTDENT
    //              | SWITCH Expression INDENT Whens ELSE Block OUTDENT
    //              | SWITCH INDENT Whens OUTDENT
    //              | SWITCH INDENT Whens ELSE Block OUTDENT
    //      Whens := Whens MINDENT When
    //             | When
    //      When := SWITCH_WHEN SimpleArgs Block
    Parser.prototype.parseSwitch = function() {
        var node = new Nodes.Switch();
        node.location.start = this.consume('SWITCH').location.start.clone();
        if(this.currentToken().type != 'INDENT') {
            node.subject = this.parseExpression();
        }
        this.consume('INDENT');
        isFirstCase = true;
        while(isFirstCase || this.currentToken().type == 'SWITCH_WHEN') {
            isFirstCase = false;
            this.consume('SWITCH_WHEN');
            node.whens.push([this.parseSimpleArgs(), this.parseBlock(true)]);
        }
        if(this.currentToken().type == 'ELSE') {
            this.consume('ELSE');
            node.otherwise = this.parseBlock(true);
        }
        node.location.end = this.consume('OUTDENT').location.start.clone();
        return node;
    };
    
    // Parse SimpleArgs
    //      SimpleArgs := SimpleArgs , Expression
    //                  | Expression
    Parser.prototype.parseSimpleArgs = function() {
        var args = [this.parseExpression()];
        while(this.currentToken().type == ',') {
            args.push(this.parseExpression());
        }
        return args;
    };
    
    // Parse assignement expression
    //      Assignement := Operation AssignOperator Expression
    //                   | Operation AssignOperator INDENT Expression OUTDENT
    //                   | Operation
    //                   | KeyAssignement
    Parser.prototype.parseAssignement = function() {
        if(this.currentToken().type == '{') {
            return this.parseKeysAssignement();
        }
        var node = this.parseOperation(consts.Precedence.expression);
        if(this.currentToken().type == 'ASSIGN') {
            var needOutdent = false;
            var startPos = node.location.start.clone();
            var operator = this.parseAssignOperator();
            if(this.currentToken().type == 'INDENT') {
                needOutdent = true;
                this.consume('INDENT');
            }
            var right = this.parseExpression();
            node = new Nodes.Assignement(operator, node, right);
            node.location.start = startPos;
            node.location.end = right.location.end.clone();
            if(needOutdent === true) {
                this.consume('OUTDENT');
            }
        }
        return node;
    };
    
    // Parse keys assignement expression
    //      KeyAssignement := { KeysList } = INDENT Expression OUTDENT
    //                      | { KeysList } = Expression
    Parser.prototype.parseKeysAssignement = function() {
        var startPos = this.consume('{').location.start.clone();
        var node = new Nodes.KeysAssignement(this.parseKeysList());
        this.consume('}');
        var needOutdent = false;
        var operator = this.parseAssignOperator();
        if(this.currentToken().type == 'INDENT') {
            needOutdent = true;
            this.consume('INDENT');
        }
        var right = this.parseExpression();
        node.right = right;
        node.location.end = right.location.end.clone();
        if(needOutdent === true) {
            this.consume('OUTDENT');
        }
        return node;
    };
    
    // Parse a keys list
    //      KeysList := INDENT KeysList , Identifier OUTDENT
    //                | INDENT KeysList MINDENT Identifier OUTDENT
    //                | INDENT OUTDENT
    //                | Identifier
    //                |                        (possibly empty)
    Parser.prototype.parseKeysList = function() {
        var args = [];
        if(this.currentToken().type == 'INDENT') {
            this.consume('INDENT');
            var loopInside = function() {
                args.push(this.parseIdentifier());
                if(this.currentToken().type == ',') {
                    this.consume(',');
                }
                if(this.currentToken().type != 'OUTDENT') {
                    if(this.currentToken().type != 'MINDENT') {
                        loopInside.call(this);
                    } else {
                        this.consume('MINDENT');
                    }
                }
            };
            while(this.currentToken().type != 'OUTDENT') {
                loopInside.call(this);
            }
            this.consume('OUTDENT');
        } else {
            while(this.currentToken().type != '}') {
                if(args.length > 0) {
                    var commaConsumed = false;
                    if(this.currentToken().type == ',') {
                        this.consume(',');
                        commaConsumed = true;
                    }
                    if(this.currentToken().type == 'INDENT') {
                        args = args.concat(this.parseKeysList());
                        continue;
                    } else {
                        if(commaConsumed === false) {
                            this.consume(',');
                        }
                    }
                }
                args.push(this.parseIdentifier());
            }
        }
        return args;
    };
    
    // Parse binary operation
    //      Operation := CastExpression BinaryOperator operation (BinaryOperator with precedence rule)
    //                 | CastExpression
    Parser.prototype.parseOperation = function(minPrecedence) {
        var node = this.parseCastExpression();
        while(this.currentToken().precedence >= minPrecedence) {
            var precedence = this.currentToken().precedence;
            var operator = this.parseBinaryOperator();
            var startPos = node.location.start.clone();
            var right = this.parseOperation(precedence + 1);
            node = new Nodes.Operation(operator, node, right);
            node.location.start = startPos;
            node.location.end = right.location.end.clone();
        }
        return node;
    };
    
    // Parse cast expression
    //      CastExpression := Unary => CASTTYPE
    //                      | Unary
    Parser.prototype.parseCastExpression = function() {
        var node = this.parsePrefix();
        if(this.currentToken().type == '=>') {
            var startPos = node.location.start.clone();
            // Cast operator
            var operator = new Nodes.Operator('=>', 'cast');
            operator.location = this.consume('=>').location.clone();
            // Cast type
            var token = this.consume('CASTTYPE');
            var castType = new Nodes.CastType();
            castType.location = token.location.clone();
            // final node
            node = new Nodes.CastTyping(node, castType);
            node.location.start = startPos;
            node.location.end = castType.location.end.clone();
        }
        return node;
    };
    
    // Parse expression with prefix
    //      Posfix := CLONE Expression
    //              | UNARY Expression
    //              | Update Expression
    //              | + Expression
    //              | - Expression
    //              | Posfix
    Parser.prototype.parsePrefix = function() {
        if(consts.tokenInterpretation.prefixOperator.indexOf(this.currentToken().type) > -1) {
            var operator, node, argument;
            switch(this.currentToken().type) {
                case 'CLONE':
                    operator = new Nodes.Operator('clone', 'clone');
                    operator.location = this.consume('CLONE').location.clone();
                    argument = this.parseExpression();
                    node = new Nodes.Clone(operator, argument);
                    node.location.start = operator.location.start.clone();
                    node.location.end = argument.location.end.clone();
                    return node;
                case 'UNARY':
                case '+':
                case '-':
                    operator = this.parseUnaryOperator();
                    argument = this.parseExpression();
                    node = new Nodes.Unary(operator, argument);
                    node.location.start = operator.location.start.clone();
                    node.location.end = argument.location.end.clone();
                    return node;
                case 'UPDATE':
                    operator = this.parseUpdateOperator();
                    argument = this.parseExpression();
                    node = new Nodes.Update(operator, argument, true);
                    node.location.start = operator.location.start.clone();
                    node.location.end = argument.location.end.clone();
                    return node;
            }
        }
        return this.parsePostfix();
    };
    
    // Parse postfix expression
    //      Postfix := UPDATE LeftHand
    //               | LeftHand
    Parser.prototype.parsePostfix = function() {
        var expression = this.parseLeftHand();
        if(this.currentToken().type == 'UPDATE') {
            var startPos = expression.location.start.clone();
            var operator = this.parseUpdateOperator();
            expression = new Nodes.Update(operator, expression, false);
            expression.location.start = startPos;
            expression.location.end = operator.location.end.clone();
        }
        return expression;
    };
    
    // Parse left hand side
    //      LeftHand := NEW Expression
    //                | Member
    Parser.prototype.parseLeftHand = function() {
        if(this.currentToken().type == 'NEW') {
            var operator = new Nodes.Operator('new', 'new');
            operator.location = this.consume('NEW').location.clone();
            var argument = this.parseExpression();
            var node = new Nodes.New(operator, argument);
            node.location.start = operator.location.start.clone();
            node.location.end = argument.location.end.clone();
            return node;
        } else {
            return this.parseMember();
        }
    };
    
    // Parse member/index/invocation
    //      Member := Member MemberOperator Identifier
    //              | Member INDEX_START Expression INDEX_END
    //              | Member SLICE_START Slice SLICE_END
    //              | Member CALL_START ArgumentsList CALL_END
    //              | Member ?
    //              | Primary
    Parser.prototype.parseMember = function() {
        var node = this.parsePrimary();
        loop: while(true) {
            var startPos = node.location.start.clone();
            switch(this.currentToken().type) {
                case 'MEMBER':
                    var operator = this.parseMemberOperator();
                    var member = this.parseIdentifier();
                    node = new Nodes.Member(operator, node, member);
                    node.location.start = startPos;
                    node.location.end = member.location.end.clone();
                    break;
                case 'CALL_START':
                    this.consume('CALL_START');
                    args = this.parseArguments('CALL_END', false);
                    node = new Nodes.Call(node, args);
                    node.location.start = startPos;
                    node.location.end = this.consume('CALL_END').location.end.clone();
                    break;
                case 'INDEX_START':
                    this.consume('INDEX_START');
                    var index = this.parseExpression();
                    node = new Nodes.Index(node, index);
                    node.location.start = startPos;
                    node.location.end = this.consume('INDEX_END').location.end.clone();
                    break;
                case 'SLICE_START':
                    this.consume('SLICE_START');
                    var slicingRange = this.parseSlice();
                    node = new Nodes.Slice(node, slicingRange);
                    node.location.start = startPos;
                    node.location.end = this.consume('SLICE_END').location.end.clone();
                    break;
                case '?':
                    node = new Nodes.Existance(node);
                    node.location.start = startPos;
                    node.location.end = this.consume('?').location.end.clone();
                    break;
                default:
                    break loop;
            }
        }
        return node;
    };
    
    // Parse slice range
    //      Slice := Expression RANGE Expression
    //             | Expression RANGE
    //             | RANGE Expression
    //             | RANGE
    Parser.prototype.parseSlice = function() {
        var node;
        if(this.currentToken().type == 'RANGE') {
            var token = this.consume('RANGE');
            var operator = new Nodes.Operator(token.value, 'range');
            operator.location = token.location.clone();
            if(this.currentToken().type == 'SLICE_END') {
                node = new Nodes.Range(null, null, operator);
            } else {
                node = new Nodes.Range(null, this.parseExpression(), operator);
            }
        } else {
            var from = this.parseExpression();
            var token = this.consume('RANGE');
            var operator = new Nodes.Operator(token.value, 'range');
            operator.location = token.location.clone();
            if(this.currentToken().type == 'SLICE_END') {
                node = new Nodes.Range(from, null, operator);
            } else {
                node = new Nodes.Range(from, this.parseExpression(), operator);
            }
        }
        return node;
    };
    
    // Parse primary value
    //      Primary := Boolean
    //               | Identifier
    //               | Number
    //               | Null
    //               | String
    //               | QualifiedString
    //               | HereDoc
    //               | Array
    //               | Range
    //               | Parenthetical
    //               | Code
    //               | At
    //               | QualifiedNamespaceName
    Parser.prototype.parsePrimary = function() {
        switch(this.currentToken().type) {
            case 'BOOL':
                return this.parseBoolean();
            case 'IDENTIFIER':
                if(this.input[this._i + 1] !== undefined && this.input[this._i + 1].type == '\\') {
                    return this.parseQualifiedNamespaceName();
                }
                return this.parseIdentifier();
            case 'NUMBER':
                return this.parseNumber();
            case 'NULL':
                return this.parseNull();
            case 'STRING':
                return this.parseString();
            case 'QUALIFIEDSTRING':
                return this.parseQualifiedString();
            case 'HEREDOC':
                return this.parseHereDoc();
            case '[':
                return this.parseArray();
            case 'RANGE_START':
                return this.parseRange();
            case '(':
                return this.parseParenthetical();
            case 'FUNC':
                return this.parseCode();
            case '@':
                return this.parseAtOperator();
            case '\\':
                return this.parseQualifiedNamespaceName();
            default:
                this.fail();
        }
    };
    
    // Parse array
    //      Array := [ ArgumentsList ]
    Parser.prototype.parseArray = function() {
        var startPos = this.consume('[').location.start.clone();
        var node = new Nodes.Array(this.parseArguments(']', true));
        node.location.start = startPos;
        node.location.end = this.consume(']').location.end.clone();
        return node;
    };
    
    // Parse arguments list for invocation/call or array declaration
    //      ArgumentsList := INDENT ArgumentsList , Argument OUTDENT
    //                     | INDENT ArgumentsList MINDENT Argument OUTDENT
    //                     | INDENT OUTDENT
    //                     | Argument
    //                     |                        (possibly empty)
    Parser.prototype.parseArguments = function(endTokenType, allowKey) {
        var args = [];
        var checkisEnd = function(tokenType) {
            if(endTokenType instanceof Array) {
                return endTokenType.indexOf(tokenType) > -1;
            } else {
                return endTokenType == tokenType;
            }
        };
        if(this.currentToken().type == 'INDENT') {
            this.consume('INDENT');
            var loopInside = function() {
                args.push(this.parseArgument(allowKey));
                if(this.currentToken().type == ',') {
                    this.consume(',');
                }
                if(this.currentToken().type != 'OUTDENT') {
                    if(this.currentToken().type != 'MINDENT') {
                        loopInside.call(this);
                    } else {
                        this.consume('MINDENT');
                    }
                }
            };
            while(this.currentToken().type != 'OUTDENT') {
                loopInside.call(this);
            }
            this.consume('OUTDENT');
        } else {
            while(!checkisEnd(this.currentToken().type)) {
                if(args.length > 0) {
                    var commaConsumed = false;
                    if(this.currentToken().type == ',') {
                        this.consume(',');
                        commaConsumed = true;
                    }
                    if(this.currentToken().type == 'INDENT') {
                        args = args.concat(this.parseArguments());
                        continue;
                    } else {
                        if(commaConsumed === false) {
                            this.consume(',');
                        }
                    }
                }
                args.push(this.parseArgument(allowKey));
            }
        }
        return args;
    };
    
    // Parse signle argument for invocation/call or array keyed arg
    //      Argument := Expression
    //                | Expression : Expression     (if array declaration)
    Parser.prototype.parseArgument = function(allowKey) {
        var node  = this.parseExpression();
        if(allowKey && this.currentToken().type == ':') {
            this.consume(':');
            var startPos = node.location.start.clone();
            var value = this.parseExpression();
            node = new Nodes.ArrayKey(node, value);
            node.location.start = startPos;
            node.location.end = value.location.end.clone();
        }
        return node;
    };
    
    // Parse range
    //      Range := RANGE_START Expression RANGE Expression RANGE_END
    Parser.prototype.parseRange = function() {
        var startPos = this.consume('RANGE_START').location.start.clone();
        var from = this.parseExpression();
        var token = this.consume('RANGE');
        var operator = new Nodes.Operator(token.type, 'range');
        operator.location = token.location.clone();
        var to = this.parseExpression();
        var node = new Nodes.Range(from, to, operator);
        node.location.start = startPos;
        node.location.end = this.consume('RANGE_END').location.end.clone();
        return node;
    };
    
    // Parse parenthetical
    //      Parenthetical := ( Expression )
    //                     | ( INDENT Expression OUTDENT )
    Parser.prototype.parseParenthetical = function() {
        var expression;
        var startPos = this.consume('(').location.start.clone();
        if(this.currentToken().type == 'INDENT') {
            this.consume('INDENT');
            expression = this.parseExpression();
            this.consume('OUTDENT');
        } else {
            expression = this.parseExpression();
        }
        var node = new Nodes.Parenthetical(expression);
        node.location.start = startPos;
        node.location.end = this.consume(')').location.end.clone();
        return node;
    };
    
    // Parse identifier
    //      Identifier := IDENTIFIER
    Parser.prototype.parseIdentifier = function() {
        var token = this.consume('IDENTIFIER');
        var node = new Nodes.Identifier(token.value);
        node.location = token.location.clone();
        return node;
    };
    
    // Parse number
    //      Number := NUMBER
    Parser.prototype.parseNumber = function() {
        var token = this.consume('NUMBER');
        var node = new Nodes.Literal(token.value, 'number');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse string
    //      String := STRING
    Parser.prototype.parseString = function() {
        var token = this.consume('STRING');
        var node = new Nodes.Literal(token.value, 'string');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse qualified string
    //      QualifiedString := QUALIFIEDSTRING
    Parser.prototype.parseQualifiedString = function() {
        var token = this.consume('QUALIFIEDSTRING');
        var node = new Nodes.Literal(token.value, 'qualifiedString');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse Heredoc
    //      HereDoc := HEREDOC
    Parser.prototype.parseHereDoc = function() {
        var token = this.consume('HEREDOC');
        var node = new Nodes.Literal(token.value, 'herDoc');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse boolean
    //      Boolean := BOOL
    Parser.prototype.parseBoolean = function() {
        var token = this.consume('BOOL');
        var node = new Nodes.Literal(token.value, 'bool');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse null
    //      Null := NULL
    Parser.prototype.parseNull = function() {
        var token = this.consume('NULL');
        var node = new Nodes.Literal(token.value, 'null');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse anonymous function
    //      Code := FUNC ( ParametersList ) CALL_START ParametersList CALL_END  -> Block
    //            | FUNC ( ParametersList ) -> Block
    //            | FUNC ( ParametersList ) CALL_START ParametersList CALL_END
    //            | FUNC ( ParametersList )
    //            | FUNC -> Block
    //            | FUNC IDENTIFIER ( ParametersList ) CALL_START ParametersList CALL_END -> Block
    //            | FUNC IDENTIFIER ( ParametersList ) -> Block
    //            | FUNC IDENTIFIER ( ParametersList ) CALL_START ParametersList CALL_END
    //            | FUNC IDENTIFIER ( ParametersList )
    //            | FUNC IDENTIFIER -> Block
    Parser.prototype.parseCode = function() {
        var node = new Nodes.Code();
        node.location.start = this.consume('FUNC').location.start.clone();
        if(this.currentToken().type == 'IDENTIFIER') {
            node.isAnonymous = false;
            node.name = this.parseIdentifier();
        } else {
            node.isAnonymous = true;
            node.hasBody = true;
            node.body = new Nodes.Block();
            node.location.start = node.location.start.clone();
            node.location.end = node.location.start.clone();
        }
        if(this.currentToken().type == '(') {
            this.consume('(');
            node.parameters = this.parseParametersList(')');
            this.consume(')');
        }
        if(this.currentToken().type == 'CALL_START') {
            this.consume('CALL_START');
            node.withUses = true;
            node.uses = this.parseParametersList('CALL_END');
            this.consume('CALL_END');
        }
        if(this.currentToken().type == '->') {
            this.consume('->');
            node.hasBody = true;
            node.body = this.parseBlock(true);
        }
        node.location.end = this.endPosition.clone();
        return node;
    };
    
    // Parse parameters list
    //      ParametersList := ParametersList , Param
    //                      | Param
    Parser.prototype.parseParametersList = function(tokenCloseType) {
        var list = [];
        while(this.currentToken().type != tokenCloseType) {
            list.push(this.parseParam());
        }
        return list;
    };
    
    // Parse parameter
    //      Param := USE ParamIdentifier
    //             | ParamIdentifier = Expression
    //             | ParamIdentifier
    Parser.prototype.parseParam = function() {
        var param;
        if(this.currentToken().type == 'USE') {
            this.consume('USE');
            param = this.parseParamIdentifier();
            param.isPassing = true;
        } else {
            param = this.parseParamIdentifier();
            if(this.currentToken().type == '=') {
                this.consume('=');
                param.hasDefault = true;
                param.default = this.parseExpression();
            }
        }
        return param;
    };
    
    // Parse ParamIdentifier
    //      ParamIdentifier := & IDENTIFIER
    //                       | IDENTIFIER
    Parser.prototype.parseParamIdentifier = function() {
        var node = new Nodes.Parameter();
        node.location.start = this.currentToken().location.start.clone();
        if(this.currentToken().type == '&') {
            this.consume('&');
            node.isPassing = true;
        }
        var token = this.consume('IDENTIFIER');
        node.name = token.value;
        node.location.end = token.location.end.clone();
        return node;
    };
    
    // Parse @ operator
    //      At := @ Identifier
    //          | @
    Parser.prototype.parseAtOperator = function() {
        var node;
        var token = this.consume('@');
        if(this.currentToken().type == 'IDENTIFIER') {
            // property
            var identifier = this.parseIdentifier();
            // base
            var base = new Nodes.Identifier('this');
            base.isAt = true;
            base.location = token.location.clone();
            // operator
            var operator = new Nodes.Operator('.', 'member');
            operator.location = null; // cause don't exist in code
            // final member node
            node = new Nodes.Member(operator, base, identifier);
            node.location.start = token.location.start.clone();
            node.location.end = identifier.location.end.clone();
        } else {
            node = new Nodes.Identifier('this');
            node.isAt = true;
            node.location = token.location.clone();
        }
        return node;
    };
    
    // Parse assignement operator
    //      AssignementOperator := ASSIGN
    Parser.prototype.parseAssignOperator = function() {
        var token = this.consume('ASSIGN');
        var node = new Nodes.Operator(token.value, 'assign');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse binary operator
    //      BinaryOperator := BITWISE
    //                      | COMPARE
    //                      | CONCAT
    //                      | LOGIC
    //                      | MATH
    //                      | SHIFT
    //                      | IN
    //                      | INSTANCEOF
    //                      | +
    //                      | -
    Parser.prototype.parseBinaryOperator = function() {
        var token;
        switch(this.currentToken().type) {
            case 'BITWISE':
            case 'COMPARE':
            case 'CONCAT':
            case 'LOGIC':
            case 'MATH':
            case 'SHIFT':
            case 'IN':
            case 'INSTANCEOF':
            case '+':
            case '-':
                token = this.consume(this.currentToken().type);
                break;
            default:
                // TODO: error
                throw 'error';
        }
        var node = new Nodes.Operator(token.value, 'binary');
        node.precedence = token.precedence;
        node.location = token.location.clone();
        return node;
    };
    
    // Parse update operator
    //      UpdateOperator := UPDATE
    Parser.prototype.parseUpdateOperator = function() {
        var token = this.consume('UPDATE');
        var node = new Nodes.Operator(token.value, 'update');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse unary operator
    //      UnaryOperator := UNARY
    //                     | +
    //                     | -
    Parser.prototype.parseUnaryOperator = function() {
        var token;
        switch(this.currentToken().type) {
            case 'UNARY':
            case '+':
            case '-':
                token = this.consume(this.currentToken().type);
                break;
            default:
                // TODO: erreor
                throw 'error';
        }
        var node = new Nodes.Operator(token.value, 'unary');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse member operator
    //      MemberOperator := MEMBER
    Parser.prototype.parseMemberOperator = function() {
        var token = this.consume('MEMBER');
        var node = new Nodes.Operator(token.value, 'member');
        node.location = token.location.clone();
        return node;
    };
    
    // Parse a namespace definition
    //      Namespace := NAMESPACE Block
    //                 | NAMESPACE NamespaceName Block
    //                 | NAMESPACE NamespaceName
    Parser.prototype.parseNamespace = function() {
        var node = new Nodes.Namespace();
        node.location.start = this.consume('NAMESPACE').location.start.clone();
        if(this.currentToken().type != 'INDENT') {
            node.name = this.parseNamespaceName();
            node.location.end = node.name.location.end.clone();
        }
        if(this.currentToken().type == 'INDENT') {
            node.body = this.parseBlock();
            node.location.end = node.location.end.clone();
            return node;
        }
        return node;
    };
    
    // Parse namespace name
    //      NamespaceName := NamespaceName \ IDENTIFIER
    //                     | IDENTIFIER
    Parser.prototype.parseNamespaceName = function() {
        var node = new Nodes.NamespaceName();
        var token = this.consume('IDENTIFIER');
        node.location = token.location.clone();
        node.nameSequence.push(token.value);
        while(this.currentToken().type == '\\') {
            this.consume('\\');
            token = this.consume('IDENTIFIER');
            node.location.end = token.location.end.clone();
            node.nameSequence.push(token.value);
        }
        return node;
    };
    
    // Parse qualified namespace name
    //      QualifiedNamespaceName := \ NamespaceName
    //                              | NamespaceName
    Parser.prototype.parseQualifiedNamespaceName = function() {
        var node;
        if(this.currentToken().type == '\\') {
            var startPos = this.consume('\\').location.start.clone();
            node = this.parseNamespaceName();
            node.startWithBackSlash = true;
            node.location.start = startPos;
        } else if(this.currentToken().type == 'QUALIFIEDSTRING') {
            node = this.parseQualifiedString();
        } else {
            node = this.parseNamespaceName();
        }
        return node;
    };
    
    
    // Parse class declatarion statement
    //      Class := ClassModifier CLASS IDENTIFIER Extends ImplementsOpt INDENT ClassMembers OUTDENT
    //      ClassModifier := CLASSMODIFIER
    //                     | 
    //      Extends := EXTENDS QualifiedNamespaceName
    //               |
    //      ImplementsOpt := Implements
    //                     | 
    //      Implements := Implements , QualifiedNamespaceName
    //                  | IMPLEMENTS QualifiedNamespaceName
    //      ClassMembers := ClassMembers MINDENT ClassMember
    //                    | ClassMember
    //      ClassMember := Abstractity FINAL Visiblility Statically Code
    //                   | Abstractity Visiblility Statically Assignement
    //      Abstractity := ABSTRACT
    //                   | 
    //      Visiblility := PUBLIC
    //                   | PROTECTED
    //                   | PUBLIC
    //                   |
    //      Statically := STATIC
    //                  |
    Parser.prototype.parseClass = function() {
        var node = new Nodes.Class(), token;
        if(this.currentToken().type == 'CLASSMODIFIER') {
            token = this.consume('CLASSMODIFIER');
            node.modifier = token.value;
            node.location.start = token.location.start.clone();
            this.consume('CLASS');
        } else {
            node.location.start = this.consume('CLASS').location.start.clone();
        }
        token = this.consume('IDENTIFIER');
        node.name = token.value;
        if(this.currentToken().type == 'EXTENDS') {
            this.consume('EXTENDS');
            node.extends = this.parseQualifiedNamespaceName();
        }
        if(this.currentToken().type == 'IMPLEMENTS') {
            node.implements = [];
            this.consume('IMPLEMENTS');
            node.implements.push(this.parseQualifiedNamespaceName());
            while(this.currentToken().type == ',') {
                node.implements.push(this.parseQualifiedNamespaceName());
            }
        }
        if(this.currentToken().type == 'INDENT') {
            node.members = [];
            this.consume('INDENT');
            while(this.currentToken().type != 'OUTDENT') {
                var startPos = null;
                var member = new Nodes.ClassMember();
                if(this.currentToken().type == 'ABSTRACT') {
                    token = this.consume('ABSTRACT');
                    member.isAbstract = true;
                    if(startPos == null) {
                        startPos = token.location.start.clone();
                    }
                }
                if(this.currentToken().type == 'FINAL') {
                    token = this.consume('FINAL');
                    member.isFinal = true;
                    if(startPos == null) {
                        startPos = token.location.start.clone();
                    }
                }
                if(['PUBLIC', 'PROTECTED', 'PUBLIC'].indexOf(this.currentToken().type) > -1) {
                    token = this.consume(this.currentToken().type);
                    member.visibility = token.value;
                    if(startPos == null) {
                        startPos = token.location.start.clone();
                    }
                }
                if(this.currentToken().type == 'STATIC') {
                    token = this.consume('STATIC');
                    member.isStatic = true;
                    if(startPos == null) {
                        startPos = token.location.start.clone();
                    }
                }
                if(member.isFinal) {
                    member.member = this.parseCode();
                } else {
                    member.member = this.parseAssignement();
                }
                member.location.start = startPos;
                member.location.end = member.location.end.clone();
                node.location.end = member.location.end.clone();
                node.members.push(member);
                if(this.currentToken().type == 'MINDENT') {
                    this.consume('MINDENT');
                }
            }
            this.consume('OUTDENT');
        }
        return node;
    };
    
    // Parse interface declaration statement
    //      Interface := INTERFACE IDENTIFIER Extends INDENT InterfaceMembers OUTDENT
    //      Extends := EXTENDS QualifiedNamespaceName
    //               |
    //      InterfaceMembers := InterfaceMembers MINDENT InterfaceMember
    //                    | InterfaceMember
    //      InterfaceMember := FINAL Visiblility Statically Code
    //                   | Visiblility Statically Assignement
    //      Visiblility := PUBLIC
    //                   | PROTECTED
    //                   | PUBLIC
    //                   |
    //      Statically := STATIC
    //                  |
    Parser.prototype.parseInterface = function() {
        var node = new Nodes.Interface(), token;
        node.location.start = this.consume('INTERFACE').location.start.clone();
        token = this.consume('IDENTIFIER');
        node.name = token.value;
        if(this.currentToken().type == 'EXTENDS') {
            this.consume('EXTENDS');
            node.extends = this.parseQualifiedNamespaceName();
        }
        if(this.currentToken().type == 'INDENT') {
            node.members = [];
            this.consume('INDENT');
            while(this.currentToken().type != 'OUTDENT') {
                var startPos = null;
                var member = new Nodes.ClassMember();
                if(this.currentToken().type == 'FINAL') {
                    token = this.consume('FINAL');
                    member.isFinal = true;
                    if(startPos == null) {
                        startPos = token.location.start.clone();
                    }
                }
                if(['PUBLIC', 'PROTECTED', 'PUBLIC'].indexOf(this.currentToken().type) > -1) {
                    token = this.consume(this.currentToken().type);
                    member.visibility = token.value;
                    if(startPos == null) {
                        startPos = token.location.start.clone();
                    }
                }
                if(this.currentToken().type == 'STATIC') {
                    token = this.consume('STATIC');
                    member.isStatic = true;
                    if(startPos == null) {
                        startPos = token.location.start.clone();
                    }
                }
                if(member.isFinal) {
                    member.member = this.parseCode();
                } else {
                    member.member = this.parseAssignement();
                }
                member.location.start = startPos;
                member.location.end = member.location.end.clone();
                node.location.end = member.location.end.clone();
                node.members.push(member);
                if(this.currentToken().type == 'MINDENT') {
                    this.consume('MINDENT');
                }
            }
            this.consume('OUTDENT');
        }
        return node;
    };
    
    // Parse a use statement
    //      Use := USE UseType UseClauses
    //      UseType := CONST
    //               | FUNC
    //               |
    //      UseClauses := UseClauses , UseClause
    Parser.prototype.parseUse = function() {
        var node = new Nodes.Use();
        node.location.start = this.consume('USE').location.start.clone();
        if(this.currentToken().type == 'CONST') {
            this.consume('CONST');
            node.isConstFunc = 'const';
        } else if(this.currentToken().type == 'FUNC') {
            this.consume('FUNC');
            node.isConstFunc = 'function';
        }
        node.clauses.push(this.parseUseClause());
        while(this.currentToken().type == ',') {
            node.clauses.push(this.parseUseClause());
        }
        node.location.end = node.clauses[node.clauses.length - 1][node.clauses[node.clauses.length - 1].length - 1].location.end.clone();
        return node;
    };
    
    // Parse use clause
    //      UseClause := QualifiedNamespaceName AS IDENTIFIER
    //                 | QualifiedNamespaceName
    Parser.prototype.parseUseClause = function() {
        var clause = [this.parseQualifiedNamespaceName()];
        if(this.currentToken().type == 'AS') {
            this.consume('AS');
            clause.push(this.parseIdentifier());
        }
        return clause;
    };
    
    // exports
    module.exports = Parser;
    
    return module.exports;
    
  })();
  
  require["./mammouth"] = (function() {
    var exports = {}, module = {exports: exports};
    
    var Lexer = require('./lexer');
    var Parser = require('./parser');
    var ErrorM = require('./error');
    
    function Mammouth() {
    
    }
    
    Mammouth.VERSION = '4.0.0';
    
    Mammouth.prototype.parse = function(source, filename) {
        var lexer = new Lexer();
        var parser = new Parser();
        var errorM = new ErrorM(source, filename);
        lexer.setInput(source, errorM, filename);
        parser.setInput(lexer.lexAll(), errorM, filename);
        return parser.parseDocument();
    };
    
    module.exports = Mammouth;
    
    return module.exports;
    
  })();
  
  
  return require("./mammouth");
})(this);