import "../diagnostic/diagnosticEngine.dart" show DiagnosticEngine;
import "../diagnostic/error.dart" show AnalysisError;
import "../basic/source.dart" show Source;
import "./codepoint.dart" show CodePoint;
import "./errors.dart" show ScannerErrorCode;
import "./indentation.dart" show Indentation, IndentationToken;
import "./token.dart" show TokenKind, Token, SimpleToken, StringToken;

final Map<String, TokenKind> keywords = {
    "if": TokenKind.IF,
    "while": TokenKind.WHILE
};

class Scanner {
    int _offset;
    String _input;
    List<Token> _output;
    Source _source;

    DiagnosticEngine _diagnosticEngine;

    bool _insideBlock;
    List<IndentationLevel> _indentationLevels;

    Scanner(this._diagnosticEngine);

    void setInput(Source source) {
        this._offset = 0;
        this._source = source;
        this._input = source.content;
        this._output = new List<Token>();

        this._insideBlock = false;
        this._indentationLevels = new List<IndentationLevel>();
    }

    List<Token> scanAll() {
        while(this._scanNext());
        for(int i = 0, length = this._output.length; i < length; i++) {
            if(i != 0) this._output[i].previous = this._output[i - 1];
            if(i != length)this._output[i].next = this._output[i + 1];
        }
        return this._output;
    }

    bool _hasNextChar() {
        if(this._input != null && this._offset < this._input.length) {
            return true;
        }
        return false;
    }

    void _addToken(Token token) {
        this._output.add(token);
    }

    void _reportError(AnalysisError error) {
        this._diagnosticEngine.report(this._source, error);
    }

    int _codeUnitAt(int offset) {
        if(this._input != null && offset < this._input.length) {
            return this._input.codeUnitAt(offset);
        }
        return CodePoint.NUL;
    }

    int _currentCodeUnit() {
        return this._codeUnitAt(this._offset);
    }

    int _nextChar() {
        this._offset++;
        return this._currentCodeUnit();
    }

    int _previousChar() {
        this._offset--;
        return this._currentCodeUnit();
    }

    bool _scanNext() {
        if(this._hasNextChar()) {
            if(!this._insideBlock) {
                return this._scanInline();
            }
            // "{{"
            if(this._isStartTag(this._offset)) {
                return this._scanStartTag();
            }
            // "}}"
            if(this._isEndTag(this._offset)) {
                return this._scanEndTag();
            }
            int c = this._currentCodeUnit();
            // TODO: comment
            // Indentation
            if(this._output.last.kind.kindOf(TokenKind.LINEFEED)) {
                this._output.removeLast();
                return this._scanIndent();
            }
            // Name
            if(CodePoint.isNameStart(c)) {
                return this._scanName();
            }
            // Numeric
            if(CodePoint.isDigit(c)) {
                return this._scanNumeric();
            }
            // String
            if(c == CodePoint.DOUBLEQUOTE) {
                return this._scanString();
            }
            // TODO: Heredoc
            return this._scanByCodeUnit();
        }
        // MARK(MAKE + ADD TOKEN)
        this._addToken(new SimpleToken(TokenKind.EOS, this._offset));
        return false;
    }

    bool _scanInline() {
        String lexeme;
        int offset;

        int c = this._currentCodeUnit();
        offset = this._offset;
        while(c != CodePoint.NUL && !this._isStartTag(this._offset)) {
            c = this._nextChar();
        }
        lexeme = this._input.substring(offset, this._offset);
        this._insideBlock = true;

        // MARK(MAKE + ADD TOKEN)
        this._addToken(new StringToken(TokenKind.INLINE, lexeme, offset));
        return true;
    }

    bool _scanStartTag() {
        int offset;        

        offset = this._offset;
        this._offset += 2;
        this._indentationLevels.insert(0, new IndentationLevel());

        // MARK(MAKE + ADD TOKEN)
        this._addToken(new SimpleToken(TokenKind.STARTTAG, offset));
        return true;
    }

    bool _scanEndTag() {
        int offset;        

        offset = this._offset;
        this._offset += 2;
        this._insideBlock = false;
        this._closeIndentLevel(this._indentationLevels.removeAt(0));

        // MARK(MAKE + ADD TOKEN)
        this._addToken(new SimpleToken(TokenKind.ENDTAG, offset));
        return true;
    }

    bool _scanIndent() {
        int offset;
        Token token;
        Indentation indentation;

        offset = this._offset;
        int c = this._currentCodeUnit();
        while(this._hasNextChar() && CodePoint.isIndent(c)) {
            c = this._nextChar();
        }
        indentation = new Indentation(this._input.substring(offset, this._offset));

        Indentation currentIndentation = this._currentIndent();
        if(currentIndentation == null || indentation > currentIndentation) {
            // MARK(MAKE TOKEN)
            token = new IndentationToken(TokenKind.INDENT, indentation, offset);
            this._indentationLevels.first.shiftIndent(indentation);
            this._indentationLevels.first.shiftOpenedToken(token);
        } else if(currentIndentation != null && indentation == currentIndentation) {
            token = new IndentationToken(TokenKind.MIDENT, indentation, offset);
        } else if(currentIndentation != null) {
            Indentation indent = this._currentIndent();
            while(indentation <= indent) {
                if(indentation == indent) {
                    // MARK(MAKE TOKEN)
                    token = new IndentationToken(TokenKind.MIDENT, indentation, offset);
                    break;
                } else if(indentation < indent) {
                    // MARK(MAKE + ADD TOKEN)
                    this._addToken(new IndentationToken(TokenKind.OUTDENT, indent, offset));
                    this._indentationLevels.first._indenationtStack.removeAt(0);
                    this._indentationLevels.first._openedToken.removeAt(0);
                    indent = this._currentIndent();
                }
            }
        } else {
            return false;
        }

        // MARK(ADD TOKEN)
        this._addToken(token);
        return true;
    }

    Indentation _currentIndent() {
        if(this._indentationLevels.isNotEmpty) {
            return this._indentationLevels.first.currentIndent;
        }
        return null;
    }

    void _closeIndentLevel(IndentationLevel indentationLevel) {
        while(indentationLevel._indenationtStack.isNotEmpty) {
            Indentation indentation = indentationLevel._indenationtStack.removeAt(0);
            Token openedIn = indentationLevel._openedToken.removeAt(0);
            // MARK(MAKE + ADD TOKEN)
            this._addToken(new IndentationToken(TokenKind.OUTDENT, indentation, this._offset));
        }
    }

    bool _scanName() {
        int offset;
        Token token;
        String value;

        offset = this._offset;
        int c = this._currentCodeUnit();
        while(this._hasNextChar() && CodePoint.isNamePart(c)) {
            c = this._nextChar();
        }
        value = this._input.substring(offset, this._offset);

        if(["false", "true"].contains(value)) {
            // MARK(MAKE TOKEN)
            token = new StringToken(TokenKind.BOOLEAN, value, offset);
        } else if(keywords.containsKey(value)) {
            // MARK(MAKE TOKEN)
            token = new SimpleToken(keywords[value], offset);
        } else {
            // MARK(MAKE TOKEN)
            token = new StringToken(TokenKind.NAME, value, offset);
        }

        // MARK(ADD TOKEN)
        this._addToken(token);
        return true;
    }

    bool _scanNumeric() {
        int offset;
        String value;
        TokenKind kind = TokenKind.INTEGER;

        offset = this._offset;
        int dotOffset = null, eOffset = null;
        int c = this._currentCodeUnit();
        Radix radix = Radix.Decimal;
        CheckCodeUnit isInRadix = (int c) {
            switch(radix) {
                case Radix.Binary:
                    return CodePoint.isBinary(c);
                case Radix.Octal:
                    return CodePoint.isOctal(c);
                case Radix.Decimal:
                    return CodePoint.isDigit(c);
                case Radix.Hexadecimal:
                    return CodePoint.isHexadecimal(c);
            }
        };
        CheckCodeUnit isRadixLetter = (int c) {
            return [CodePoint.$b, CodePoint.$B, CodePoint.$o, CodePoint.$O, CodePoint.$x, CodePoint.$X].contains(c);
        };
        CheckCodeUnit checkCodeUnit = (int c) => isInRadix(c);
        while(checkCodeUnit(c)) {
            if(this._offset == offset) {
                checkCodeUnit = (int c) => isRadixLetter(c) || isInRadix(c) || c == CodePoint.DOT || [CodePoint.$e, CodePoint.$E].contains(c);
            } else if(this._offset == offset + 1) {
                checkCodeUnit = (int c) => isInRadix(c) || c == CodePoint.DOT;
                if(isRadixLetter(c)) {
                    if(c == CodePoint.$b || c == CodePoint.$B) {
                        radix = Radix.Binary;
                    } else if(c == CodePoint.$o || c == CodePoint.$O) {
                        radix = Radix.Octal;
                    } else if(c == CodePoint.$x || c == CodePoint.$X) {
                        radix = Radix.Hexadecimal;
                    }
                } else {
                    radix = Radix.Decimal;
                }
            }
            if(dotOffset == null && c == CodePoint.DOT) {
                kind = TokenKind.FLOAT;
                radix = Radix.Decimal;
                dotOffset = this._offset;
                checkCodeUnit = (int c) => isInRadix(c) || [CodePoint.$e, CodePoint.$E].contains(c);
            }
            if(eOffset == null && [CodePoint.$e, CodePoint.$E].contains(c)) {
                kind = TokenKind.FLOAT;
                radix = Radix.Decimal;
                eOffset = this._offset;
                checkCodeUnit = (int c) => isInRadix(c) || [CodePoint.PLUS, CodePoint.MINUS].contains(c);
            }
            if(eOffset != null && eOffset == this._offset + 1) {
                checkCodeUnit = (int c) => isInRadix(c);
            }
            c = this._nextChar();
        }
        if(isRadixLetter(this._codeUnitAt(offset + 1)) && this._offset == offset + 2) {
            ScannerErrorCode errorCode;
            int c = this._codeUnitAt(offset + 1); 
            if(c == CodePoint.$b || c == CodePoint.$B) {
                errorCode = ScannerErrorCode.MISSING_BIN_DIGIT;
            } else if(c == CodePoint.$o || c == CodePoint.$O) {
                errorCode = ScannerErrorCode.MISSING_OCT_DIGIT;
            } else if(c == CodePoint.$x || c == CodePoint.$X) {
                errorCode = ScannerErrorCode.MISSING_HEX_DIGIT;
            }
            // MARK(REPORT ERROR)
            this._reportError(
                new AnalysisError(
                    this._source,
                    offset,
                    1,
                    errorCode,
                    [this._input.substring(offset, this._offset)]
                )
            );
            // MARK(ERROR STOP SCANNING)
            // TODO: continue scanning evenf if error is reported
            return false;
        }
        if(dotOffset != null && this._offset == dotOffset + 1) {
            // MARK(REPORT ERROR)
            this._reportError(
                new AnalysisError(
                    this._source,
                    offset,
                    1,
                    ScannerErrorCode.MISSING_DEC_DIGIT,
                    [this._input.substring(offset, this._offset)]
                )
            );
            // MARK(ERROR STOP SCANNING)
            // TODO: continue scanning evenf if error is reported
            return false;
        }
        if(eOffset != null && (this._offset == eOffset + 1 || this._offset == eOffset + 2)) {
            // TODO: imporove to "missing exponent digits"
            // MARK(REPORT ERROR)
            this._reportError(
                new AnalysisError(
                    this._source,
                    offset,
                    1,
                    ScannerErrorCode.MISSING_DEC_DIGIT,
                    [this._input.substring(offset, this._offset)]
                )
            );
            // MARK(ERROR STOP SCANNING)
            // TODO: continue scanning even if error is reported
            return false;
        }
        value = this._input.substring(offset, this._offset);

        // MARK(MAKE + ADD TOKEN)
        this._addToken(new StringToken(kind, value, offset));
        return true;
    }

    bool _scanString() {
        int offset;
        String value;

        offset = this._offset;
        int c = this._nextChar(); // consumption of '"'
        while(c != CodePoint.DOUBLEQUOTE) {
            if(c == CodePoint.BACKSLASH) {
                bool ok = this._consumeEscapeSequence();
                if(ok == false) {
                    // MARK(ERROR STOP SCANNING)
                    // TODO: continue scanning even if error is reported
                    return false;
                }
                c = this._currentCodeUnit();
            } else if(c == CodePoint.NUL || c == CodePoint.LF) {
                // MARK(REPORT ERROR)
                this._reportError(
                    new AnalysisError(
                        this._source,
                        offset,
                        1,
                        ScannerErrorCode.UNTERMINATED_STRING_LITERAL
                    )
                );
                // MARK(ERROR STOP SCANNING)
                // TODO: continue scanning even if error is reported
                return false;
            } else {
                c = this._nextChar();
            }
        } 
        c = this._nextChar(); // consumption of '"'
        value = this._input.substring(offset, this._offset);

        // MARK(MAKE + ADD TOKEN)
        this._addToken(new StringToken(TokenKind.STRING, value, offset));
        return true;
    }

    bool _consumeEscapeSequence() {
        int c = this._nextChar();
        int offset = this._offset;
        if(c == CodePoint.$x) { // 'x'
            c = this._nextChar();
            for(int i = 0; i < 2; i++) {
                if(CodePoint.isHexadecimal(c)) {
                    c = this._nextChar();
                } else {
                    // MARK(REPORT ERROR)
                    this._reportError(
                        new AnalysisError(
                            this._source,
                            offset,
                            this._offset,
                            ScannerErrorCode.INVALID_HEX_SEQUENCE
                        )
                    );
                    // MARK(ERROR STOP SCANNING)
                    return false;
                }
            }
        } else if(c == CodePoint.$u) { // 'u'
            c = this._nextChar();
            for(int i = 0; i < 4; i++) {
                if(CodePoint.isHexadecimal(c)) {
                    c = this._nextChar();
                } else {
                    // MARK(REPORT ERROR)
                    this._reportError(
                        new AnalysisError(
                            this._source,
                            offset,
                            this._offset,
                            ScannerErrorCode.INVALID_HEX_SEQUENCE
                        )
                    );
                    // MARK(ERROR STOP SCANNING)
                    return false;
                }
            }
        } else if(CodePoint.isOctal(c)) {
            int value = c - CodePoint.$0;
            c = this._nextChar();
            while(CodePoint.isOctal(c)) {
                int nextValue = (value << 3) + (c - CodePoint.$0);
                if(nextValue > 0) {
                    break;
                }
                value = nextValue;
                c = this._nextChar();
            }
        } else {
            c = this._nextChar();
        }
        return true;
    }

    bool _scanByCodeUnit() {
        TokenKind kind;
        int status = 1,
            offset;

        offset = this._offset;
        int c = this._currentCodeUnit();
        switch(c) {
            // TODO: Windows line feed, and \r
            case CodePoint.LF: // '\n'
                kind = TokenKind.LINEFEED;
                this._nextChar();
                break;
            case CodePoint.SP: // ' '
                status = 0;
                this._nextChar();
                break;
            case CodePoint.BANG: // '!'
                c = this._nextChar();
                if(c == CodePoint.EQUAL) {
                    // it's "!="
                    this._nextChar();
                    kind = TokenKind.NOTEQUAL;
                } else {
                    // it's "!"
                    kind = TokenKind.UNARYNOT;
                }
                break;
            case CodePoint.PERCENT: // '%'
                c = this._nextChar();
                if(c == CodePoint.EQUAL) {
                    // it's "%="
                    this._nextChar();
                    kind = TokenKind.MODULOASSIGN;
                } else {
                    // it's "%"
                    kind = TokenKind.MODULO;
                }
                break;
            case CodePoint.AMPERSAND: // '&'
                c = this._nextChar();
                if(c == CodePoint.AMPERSAND) { // '&'
                    // it's "&&"
                    this._nextChar();
                    kind = TokenKind.LOGICALAND;
                } else if(c == CodePoint.EQUAL) { // '='
                    // it's "&="
                    this._nextChar();
                    kind = TokenKind.ANDASSIGN;
                } else {
                    // it's "&"
                    kind = TokenKind.BITWISEAND;
                }
                break;
            // TODO: (
            // TODO: )
            case CodePoint.ASTERISK: // '*'
                c = this._nextChar();
                if(c == CodePoint.ASTERISK) { // '*'
                    c = this._nextChar();
                    if(c == CodePoint.EQUAL) {
                        // it's "**="
                        this._nextChar();
                        kind = TokenKind.POWASSIGN;
                    } else {
                        // then it's "**"
                        kind = TokenKind.POWER;
                    }
                } else if(c == CodePoint.EQUAL) { // '='
                    // it's "*="
                    this._nextChar();
                    kind = TokenKind.MULTASSIGN;
                } else {
                    // it's "*"
                    kind = TokenKind.MULT;
                }
                break;
            case CodePoint.PLUS: // '+'
                c = this._nextChar();
                if(c == CodePoint.PLUS) { // '+'
                    // it's "++"
                    this._nextChar();
                    kind = TokenKind.INCRUPDATE;
                } else if(c == CodePoint.EQUAL) { // '='
                    // it's "+="
                    this._nextChar();
                    kind = TokenKind.ADDASSIGN;
                } else {
                    // it's "+"
                    kind = TokenKind.PLUS;
                }
                break;
            case CodePoint.COMMA: // ','
                this._nextChar();
                kind = TokenKind.COMMA;
                break;
            case CodePoint.MINUS: // '-'
                c = this._nextChar();
                if(c == CodePoint.MINUS) { // '-'
                    // it's "--"
                    this._nextChar();
                    kind = TokenKind.DECRUPDATE;
                } else if(c == CodePoint.EQUAL) { // '='
                    // it's "-="
                    this._nextChar();
                    kind = TokenKind.SUBASSIGN;
                } else {
                    // it's "-"
                    kind = TokenKind.MINUS;
                }
                break;
            case CodePoint.DOT: // '.'
                this._nextChar();
                kind = TokenKind.DOT;
                break;
            case CodePoint.SLASH: // '/'
                c = this._nextChar();
                if(c == CodePoint.EQUAL) { // '='
                    // it's "/="
                    this._nextChar();
                    kind = TokenKind.DIVASSIGN;
                } else {
                    // it's "/"
                    kind = TokenKind.DIV;
                }
                break;
            case CodePoint.COLON: // ':'
                this._nextChar();
                kind = TokenKind.COLON;
                break;
            case CodePoint.SEMICOLON: // ';'
                this._nextChar();
                kind = TokenKind.SEMICOLON;
                break;
            case CodePoint.LESSTHAN: // '<'
                c = this._nextChar();
                if(c == CodePoint.LESSTHAN) { // '<'
                    c = this._nextChar();
                    if(c == CodePoint.EQUAL) { // '='
                        // it's "<<="
                        this._nextChar();
                        kind = TokenKind.SHIFTLEFTASSIGN;
                    } else {
                        // it's "<<"
                        kind = TokenKind.SHIFTLEFT;
                    }
                } else if(c == CodePoint.EQUAL) { // '='
                    // it's "<="
                    this._nextChar();
                    kind = TokenKind.LESSTHANOREQUAL;
                } else {
                    // it's "<"
                    kind = TokenKind.LESSTHAN;
                }
                break;
            case CodePoint.EQUAL: // '='
                c = this._nextChar();
                if(c == CodePoint.EQUAL) { // '='
                    // it's "=="
                    this._nextChar();
                    kind = TokenKind.EQUAL;
                } else {
                    // it's "="
                    kind = TokenKind.EQUALASSIGN;
                }
                break;
            case CodePoint.GREATERTHAN: // '>'
                this._nextChar();
                kind = TokenKind.GREATERTHAN;
                // TODO: >= >>
                break;
            case CodePoint.QUESTIONMARK: // '?'
                this._nextChar();
                kind = TokenKind.QUESTIONMARK;
                break;
            // TODO: [ ]
            case CodePoint.CARET: // '^'
                c = this._nextChar();
                if(c == CodePoint.EQUAL) { // '='
                    // it's "^="
                    this._nextChar();
                    kind = TokenKind.XORASSIGN;
                } else {
                    // it's "^"
                    kind = TokenKind.BITWISEXOR;
                }
                break;
            // TODO: {
            case CodePoint.BAR: // '|'
                c = this._nextChar();
                if(c == CodePoint.BAR) { // '|'
                    // it's "||"
                    this._nextChar();
                    kind = TokenKind.LOGICALOR;
                } else if(c == CodePoint.EQUAL) { // '='
                    // it's "|="
                    this._nextChar();
                    kind = TokenKind.ORASSIGN;
                } else {
                    // it's "|"
                    kind = TokenKind.BITWISEOR;
                }
                break;
            // TODO: }
            case CodePoint.TILDE: // '~'
                this._nextChar();
                kind = TokenKind.UNARYBITWISENOT;
                break;
            default:
                status = 2;
        }

        switch(status) {
            case 0:
                return true;
            case 1:
                // MARK(MAKE + ADD TOKEN)
                this._addToken(new SimpleToken(kind, offset));
                return true;
            case 2:
            // TODO: report error
        }
        return false;
    }

    bool _isStartTag(int offset) {
        if(this._codeUnitAt(offset) == CodePoint.LBRACE && this._codeUnitAt(offset + 1) == CodePoint.LBRACE) {
            return true;
        }
        return false;
    }

    bool _isEndTag(int offset) {
        if(this._codeUnitAt(offset) == CodePoint.RBRACE && this._codeUnitAt(offset + 1) == CodePoint.RBRACE) {
            return true;
        }
        return false;
    }
}

class IndentationLevel {
    List<Indentation> _indenationtStack = new List<Indentation>();
    List<Token> _openedToken = new List<Token>();

    Indentation get currentIndent {
        if(this._indenationtStack.isNotEmpty) {
            return this._indenationtStack.first;
        }
        return null;
    }

    void shiftIndent(Indentation indentation) {
        this._indenationtStack.insert(0, indentation);
    }

    void shiftOpenedToken(Token token) {
        this._openedToken.insert(0, token);
    }
}

enum Radix {
    Binary,
    Octal,
    Decimal,
    Hexadecimal
}

typedef bool CheckCodeUnit(int c);
