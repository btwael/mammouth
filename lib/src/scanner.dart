import "./codepoint.dart";
import "./source.dart";
import "./token.dart";

class Scanner {
    int _offset;
    String _input;
    List<Token> _output;
    Source _source;

    bool _insideBlock;
    List<IndentationLevel> _indentationLevels;

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
                return this._scanRAW();
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
            // Indentation
            if(this._output.last.kind.kindOf(TokenKind.LINEFEED)) {
                this._output.removeLast();
                return this._scanIndent();
            }
            // Name
            if(CodePoint.isNameStart(c)) {
                return this._scanName();
            }
            return this._scanByCodeUnit();
        }
        // MARK(MAKE + ADD TOKEN)
        this._addToken(new SimpleToken(TokenKind.EOS, this._offset));
        return false;
    }

    bool _scanRAW() {
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
        this._addToken(new StringToken(TokenKind.RAW, lexeme, offset));
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
            token = new StringToken(TokenKind.INDENT, indentation.value, offset);
            this._indentationLevels.first.pushIndent(indentation);
            this._indentationLevels.first.pushOpenedToken(token);
        } else if(currentIndentation != null && indentation == currentIndentation) {
            token = new StringToken(TokenKind.MIDENT, indentation.value, offset);
        } else if(currentIndentation != null) {
            Indentation indent = this._currentIndent();
            while(indentation <= indent) {
                if(indentation == indent) {
                    // MARK(MAKE TOKEN)
                    token = new StringToken(TokenKind.MIDENT, indentation.value, offset);
                    break;
                } else if(indentation < indent) {
                    // MARK(MAKE + ADD TOKEN)
                    this._addToken(new StringToken(TokenKind.OUTDENT, indentation.value, offset));
                    this._indentationLevels.first._indenationtStack.removeAt(0);
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
            this._addToken(new StringToken(TokenKind.OUTDENT, "", this._offset));
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

        // MARK(ADD TOKEN)
        this._addToken(new StringToken(TokenKind.NAME, value, offset));
        return true;
    }

    bool _scanByCodeUnit() {
        TokenKind kind;
        int status = 0,
            offset;

        offset = this._offset;
        int c = this._currentCodeUnit();
        switch(c) {
            case CodePoint.LF: // '\n'
                status = 1;
                kind = TokenKind.LINEFEED;
                this._nextChar();
                break; 
            default:
        }

        switch(status) {
            case 1:
                // MARK(ADD TOKEN)
                this._addToken(new SimpleToken(kind, offset));
                return true;
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

    void pushIndent(Indentation indentation) {
        this._indenationtStack.insert(0, indentation);
    }

    void pushOpenedToken(Token token) {
        this._openedToken.insert(0, token);
    }
}

class Indentation implements Comparable<Indentation> {
    String value;

    Indentation(this.value);

    int get tabulationCount {
        return Indentation.HT.allMatches(this.value).length;
    }

    int get spaceCount {
        return Indentation.ST.allMatches(this.value).length;
    }

    int compareTo(Indentation other) {
        if(this.tabulationCount < other.tabulationCount) {
            return -1;
        } else if(this.tabulationCount > other.tabulationCount) {
            return 1;
        }
        if(this.spaceCount < other.spaceCount) {
            return -1;
        } else if(this.spaceCount > other.spaceCount) {
            return 1;
        }
        return this.value.compareTo(other.value);
    }

    bool operator ==(Indentation other) {
        return this.compareTo(other) == 0;
    }

    bool operator <(Indentation other) {
        return this.compareTo(other) == -1;
    }

    bool operator <=(Indentation other) {
        int comp = this.compareTo(other);
        return comp == -1 || comp == 0;
    }

    bool operator >(Indentation other) {
        return this.compareTo(other) == 1;
    }

    bool operator >=(Indentation other) {
        int comp = this.compareTo(other);
        return comp == 1 || comp == 0;
    }

    static const Pattern HT = "\t";
    static const Pattern ST = " ";
}
