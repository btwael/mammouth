import "package:mammouth/src/basic/source.dart" show Source;
import "package:mammouth/src/basic/radix.dart" show Radix;
import "package:mammouth/src/diagnostic/diagnosticEngine.dart"
    show DiagnosticEngine;
import "package:mammouth/src/diagnostic/error.dart" show AnalysisError;
import "package:mammouth/src/language/common/ast/token.dart"
    show TokenKind, Token, SimpleToken, StringToken;
import "package:mammouth/src/syntactic/codepoint.dart" show CodePoint;
import "package:mammouth/src/language/mammouth/ast/constants.dart"
as Constants;
import "package:mammouth/src/syntactic/errors.dart" show ScannerErrorCode;
import "package:mammouth/src/syntactic/indentation.dart"
    show Indentation, IndentationToken, IndentationLevel;

// TODO: continue scanning even if error is reported

//*-- Lexer
/**
 * The lexer takes a source code as input, and produces a stream of tokens as
 * output, and reports found diagnostic messages.
 */
class Lexer {
  int _offset;
  String _input;
  Source _source;
  Token _output, _lastOutput;

  bool _insideScript;
  List<IndentationLevel> _indentationLevels;

  DiagnosticEngine _diagnosticEngine;

  Lexer(this._diagnosticEngine);

  void setInput(Source source) {
    _offset = 0;
    _source = source;
    _input = source.content;
    _output = null;
    _lastOutput = null;

    _insideScript = false;
    _indentationLevels = new List<IndentationLevel>();
  }

  Token scanAll() {
    while(_scanNext());
    return _output;
  }

  void _addToken(Token token) {
    if(_output == null) {
      _output = token;
    } else {
      _lastOutput.next = token;
      token.previous = _lastOutput;
    }
    _lastOutput = token;
  }

  void _reportError(AnalysisError error) {
    _diagnosticEngine.report(_source, error);
  }

  bool _hasNextChar() {
    if(_input != null && _offset < _input.length) {
      return true;
    }
    return false;
  }

  int _codeUnitAt(int offset) {
    if(_input != null && offset < _input.length) {
      return _input.codeUnitAt(offset);
    }
    return CodePoint.NUL;
  }

  int _currentCodeUnit() {
    return _codeUnitAt(_offset);
  }

  int _nextChar() {
    _offset++;
    return _currentCodeUnit();
  }

  bool _scanNext() {
    if(_hasNextChar()) {
      if(!_insideScript) {
        return _scanInline();
      }
      // "{{"
      if(_isStartTag(_offset)) {
        return _scanStartTag();
      }
      // "}}"
      if(_isEndTag(_offset)) {
        return _scanEndTag();
      }
      int c = _currentCodeUnit();
      // Indentation
      if(_lastOutput.kind == TokenKind.LINE_FEED) {
        // Line feeds are used to determine the start of lines,
        // but ignored by the language.
        _lastOutput = _lastOutput.previous;
        int index = _offset;
        bool isEmptyLine = true;
        while(_codeUnitAt(index) != CodePoint.LF) {
          if(!CodePoint.isIndent(_codeUnitAt(index))) {
            isEmptyLine = false;
            break;
          }
          index++;
        }
        if(!isEmptyLine) {
          return _scanIndent();
        }
      }
      // Name
      if(CodePoint.isNameStart(c)) {
        return _scanName();
      }
      // Numeric
      if(CodePoint.isDigit(c)) {
        return _scanNumeric();
      }
      // String
      if(c == CodePoint.DOUBLEQUOTE || c == CodePoint.SINGLEQUOTE) {
        return _scanString(c);
      }
      return _scanByCodeUnit();
    }
    if(_insideScript && _indentationLevels.length > 0) {
      _closeIndentLevel(_indentationLevels.removeAt(0));
    }
    // MARK(MAKE TOKEN) + MARK(ADD TOKEN)
    _addToken(new SimpleToken(TokenKind.EOS, _offset));
    return false;
  }

  bool _scanInline() {
    String lexeme;
    int offset;

    int c = _currentCodeUnit();
    offset = _offset;
    while(c != CodePoint.NUL && !_isStartTag(_offset)) {
      c = _nextChar();
    }
    lexeme = _input.substring(offset, _offset);
    _insideScript = true;

    // MARK(MAKE TOKEN) + MARK(ADD TOKEN)
    _addToken(new StringToken(TokenKind.INLINE_ENTRY, lexeme, offset));
    return true;
  }

  bool _scanStartTag() {
    int offset;

    offset = _offset;
    _offset += 2;
    _indentationLevels.insert(0, new IndentationLevel());

    // MARK(MAKE TOKEN) + MARK(ADD TOKEN)
    _addToken(new SimpleToken(TokenKind.START_TAG, offset));
    return true;
  }

  bool _scanEndTag() {
    int offset;

    offset = _offset;
    _offset += 2;
    _insideScript = false;
    _closeIndentLevel(_indentationLevels.removeAt(0));

    // MARK(MAKE TOKEN) + MARK(ADD TOKEN)
    _addToken(new SimpleToken(TokenKind.END_TAG, offset));
    return true;
  }

  bool _scanIndent() {
    int offset;
    Token token;
    Indentation indentation;

    offset = _offset;
    int c = _currentCodeUnit();
    while(_hasNextChar() && CodePoint.isIndent(c)) {
      c = _nextChar();
    }
    indentation = new Indentation(_input.substring(offset, _offset));

    Indentation currentIndentation = _currentIndent();
    if(currentIndentation == null || indentation > currentIndentation) {
      // MARK(MAKE TOKEN)
      token = new IndentationToken(TokenKind.INDENT, indentation, offset);
      _indentationLevels.first.shiftIndent(indentation);
      _indentationLevels.first.shiftOpenedToken(token);
    } else if(currentIndentation != null &&
        indentation == currentIndentation) {
      token = new IndentationToken(TokenKind.MINDENT, indentation, offset);
    } else if(currentIndentation != null) {
      Indentation indent = _currentIndent();
      while(indentation <= indent) {
        if(indentation == indent) {
          // MARK(MAKE TOKEN)
          token = new IndentationToken(TokenKind.MINDENT, indentation, offset);
          break;
        } else if(indentation < indent) {
          // MARK(MAKE TOKEN) + MARK(ADD TOKEN)
          _addToken(
              new IndentationToken(TokenKind.OUTDENT, indent, offset));
          _indentationLevels.first.indenationtStack.removeAt(0);
          _indentationLevels.first.openedToken.removeAt(0);
          indent = _currentIndent();
          if(indent == null) {
            return true;
          }
        }
      }
      if(indentation > indent) {
        // MARK(MAKE TOKEN)
        token = new IndentationToken(TokenKind.INDENT, indentation, offset);
        _indentationLevels.first.shiftIndent(indentation);
        _indentationLevels.first.shiftOpenedToken(token);
      }
    } else {
      return false;
    }

    // MARK(ADD TOKEN)
    _addToken(token);
    return true;
  }

  Indentation _currentIndent() {
    if(_indentationLevels.isNotEmpty) {
      return _indentationLevels.first.currentIndent;
    }
    return null;
  }

  void _closeIndentLevel(IndentationLevel indentationLevel) {
    if(_lastOutput.kind == TokenKind.LINE_FEED) {
      _lastOutput = _lastOutput.previous;
    }
    while(indentationLevel.indenationtStack.isNotEmpty) {
      Indentation indentation = indentationLevel.indenationtStack.removeAt(0);
      // Token openedIn = indentationLevel.openedToken.removeAt(0);
      // MARK(MAKE TOKEN) + MARK(ADD TOKEN)
      _addToken(
          new IndentationToken(TokenKind.OUTDENT, indentation, _offset));
    }
  }

  bool _scanName() {
    int offset;
    Token token;
    String value;

    offset = _offset;
    int c = _currentCodeUnit();
    while(_hasNextChar() && CodePoint.isNamePart(c)) {
      c = _nextChar();
    }
    value = _input.substring(offset, _offset);

    if(Constants.booleans.contains(value)) {
      // MARK(MAKE TOKEN)
      token = new StringToken(TokenKind.BOOLEAN, value, offset);
    } else if(Constants.keywords.containsKey(value)) {
      // MARK(MAKE TOKEN)
      token = new SimpleToken(Constants.keywords[value], offset);
    } else {
      // MARK(MAKE TOKEN)
      token = new StringToken(TokenKind.NAME, value, offset);
    }

    // MARK(ADD TOKEN)
    _addToken(token);
    return true;
  }

  bool _scanNumeric() {
    int offset;
    String value;
    TokenKind kind = TokenKind.INTEGER;

    offset = _offset;
    int dotOffset = null,
        eOffset = null;
    int c = _currentCodeUnit();
    Radix radix = Radix.Decimal;
    // CheckCodeUnit is defined in the bottom of this file
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
      return [
        CodePoint.$b,
        CodePoint.$B,
        CodePoint.$o,
        CodePoint.$O,
        CodePoint.$x,
        CodePoint.$X
      ].contains(c);
    };
    CheckCodeUnit checkCodeUnit = (int c) => isInRadix(c);
    while(checkCodeUnit(c)) {
      if(_offset == offset || _offset == offset + 1) {
        checkCodeUnit = (int c) =>
        isRadixLetter(c) ||
            isInRadix(c) ||
            c == CodePoint.DOT ||
            [CodePoint.$e, CodePoint.$E].contains(c);
        if(_offset == offset + 1) {
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
      }
      if(dotOffset == null && c == CodePoint.DOT) {
        kind = TokenKind.FLOAT;
        radix = Radix.Decimal;
        dotOffset = _offset;
        checkCodeUnit =
            (int c) => isInRadix(c) || [CodePoint.$e, CodePoint.$E].contains(c);
      }
      if(eOffset == null && [CodePoint.$e, CodePoint.$E].contains(c)) {
        kind = TokenKind.FLOAT;
        radix = Radix.Decimal;
        eOffset = _offset;
        checkCodeUnit = (int c) =>
        isInRadix(c) || [CodePoint.PLUS, CodePoint.MINUS].contains(c);
      }
      if(eOffset != null && eOffset == _offset + 1) {
        checkCodeUnit = (int c) => isInRadix(c);
      }
      c = _nextChar();
    }
    if(isRadixLetter(_codeUnitAt(offset + 1)) &&
        _offset == offset + 2) {
      ScannerErrorCode errorCode;
      int c = _codeUnitAt(offset + 1);
      if(c == CodePoint.$b || c == CodePoint.$B) {
        errorCode = ScannerErrorCode.MISSING_BIN_DIGIT;
      } else if(c == CodePoint.$o || c == CodePoint.$O) {
        errorCode = ScannerErrorCode.MISSING_OCT_DIGIT;
      } else if(c == CodePoint.$x || c == CodePoint.$X) {
        errorCode = ScannerErrorCode.MISSING_HEX_DIGIT;
      }
      // MARK(REPORT ERROR)
      _reportError(new AnalysisError(_source, offset, 1, errorCode,
          [_input.substring(offset, _offset)]));
      // MARK(ERROR STOP SCANNING)
      return false;
    }
    if(dotOffset != null && _offset == dotOffset + 1) {
      if(_codeUnitAt(dotOffset + 1) == CodePoint.DOT) {
        kind = TokenKind.INTEGER;
        _offset = dotOffset;
      } else {
        // MARK(REPORT ERROR)
        _reportError(new AnalysisError(
            _source,
            offset,
            1,
            ScannerErrorCode.MISSING_DEC_DIGIT,
            [_input.substring(offset, _offset)]));
        // MARK(ERROR STOP SCANNING)
        return false;
      }
    }
    if(eOffset != null && (_offset == eOffset + 1 || (_offset == eOffset + 2 &&
        [CodePoint.PLUS, CodePoint.MINUS].contains(
            _codeUnitAt(eOffset + 1))))) {
      // MARK(REPORT ERROR)
      _reportError(new AnalysisError(
          _source,
          offset,
          1,
          ScannerErrorCode.MISSING_EXPONENT_DIGIT,
          [_input.substring(offset, _offset)]));
      // MARK(ERROR STOP SCANNING)
      return false;
    }
    value = _input.substring(offset, _offset);

    // MARK(MAKE TOKEN) + MARK(ADD TOKEN)
    _addToken(new StringToken(kind, value, offset));
    return true;
  }

  bool _scanString(int delimiter) {
    int offset;
    String value;

    offset = _offset;
    int c = _nextChar(); // consumption of '"'
    while(c != delimiter) {
      if(c == CodePoint.BACKSLASH) {
        bool ok = _consumeEscapeSequence();
        if(ok == false) {
          // MARK(ERROR STOP SCANNING)
          return false;
        }
        c = _currentCodeUnit();
      } else if(c == CodePoint.NUL || c == CodePoint.LF) {
        // MARK(REPORT ERROR)
        _reportError(new AnalysisError(_source, offset, 1,
            ScannerErrorCode.UNTERMINATED_STRING_LITERAL));
        // MARK(ERROR STOP SCANNING)
        return false;
      } else {
        c = _nextChar();
      }
    }
    c = _nextChar(); // consumption of '"' or "'"
    value = _input.substring(offset, _offset);

    // MARK(MAKE TOKEN) + MARK(ADD TOKEN)
    _addToken(new StringToken(TokenKind.STRING, value, offset));
    return true;
  }

  bool _consumeEscapeSequence() {
    int c = _nextChar();
    int offset = _offset;
    if(c == CodePoint.$x) {
      // 'x'
      c = _nextChar();
      for(int i = 0; i < 2; i++) {
        if(CodePoint.isHexadecimal(c)) {
          c = _nextChar();
        } else {
          // MARK(REPORT ERROR)
          _reportError(new AnalysisError(_source, offset,
              _offset, ScannerErrorCode.INVALID_HEX_SEQUENCE));
          // MARK(ERROR STOP SCANNING)
          return false;
        }
      }
    } else if(c == CodePoint.$u) {
      // 'u'
      c = _nextChar();
      for(int i = 0; i < 4; i++) {
        if(CodePoint.isHexadecimal(c)) {
          c = _nextChar();
        } else {
          // MARK(REPORT ERROR)
          _reportError(new AnalysisError(_source, offset,
              _offset, ScannerErrorCode.INVALID_HEX_SEQUENCE));
          // MARK(ERROR STOP SCANNING)
          return false;
        }
      }
    } else if(CodePoint.isOctal(c)) {
      int value = c - CodePoint.$0;
      c = _nextChar();
      while(CodePoint.isOctal(c)) {
        int nextValue = (value << 3) + (c - CodePoint.$0);
        if(nextValue > 0) {
          break;
        }
        value = nextValue;
        c = _nextChar();
      }
    } else {
      c = _nextChar();
    }
    return true;
  }

  bool _scanByCodeUnit() {
    TokenKind kind;
    int status = 1,
        offset;

    offset = _offset;
    int c = _currentCodeUnit();
    switch(c) {
    // TODO: Windows line feed, and \r
      case CodePoint.LF: // '\n'
        kind = TokenKind.LINE_FEED;
        _nextChar();
        break;
      case CodePoint.SP: // ' '
        status = 0;
        _nextChar();
        break;
      case CodePoint.BANG: // '!'
        c = _nextChar();
        if(c == CodePoint.EQUAL) {
          // it's "!="
          _nextChar();
          kind = TokenKind.NOT_EQUAL;
        } else {
          // it's "!"
          kind = TokenKind.UNARY_NOT;
        }
        break;
      case CodePoint.PERCENT: // '%'
        c = _nextChar();
        if(c == CodePoint.EQUAL) {
          // it's "%="
          _nextChar();
          kind = TokenKind.ASSIGN_MODULO;
        } else {
          // it's "%"
          kind = TokenKind.MODULO;
        }
        break;
      case CodePoint.AMPERSAND: // '&'
        c = _nextChar();
        if(c == CodePoint.AMPERSAND) {
          // '&'
          // it's "&&"
          _nextChar();
          kind = TokenKind.LOGICAL_AND;
        } else if(c == CodePoint.EQUAL) {
          // '='
          // it's "&="
          _nextChar();
          kind = TokenKind.ASSIGN_AND;
        } else {
          // it's "&"
          kind = TokenKind.BITWISE_AND;
        }
        break;
      case CodePoint.LPAREN: // '('
        _nextChar();
        kind = TokenKind.LEFT_PAREN;
        _indentationLevels.insert(0, new IndentationLevel());
        break;
      case CodePoint.RPAREN: // ')'
        _nextChar();
        kind = TokenKind.RIGHT_PAREN;
        _closeIndentLevel(_indentationLevels.removeAt(0));
        break;
      case CodePoint.ASTERISK: // '*'
        c = _nextChar();
        if(c == CodePoint.ASTERISK) {
          c = _nextChar();
          if(c == CodePoint.EQUAL) {
            // it's "**="
            _nextChar();
            kind = TokenKind.ASSIGN_POW;
          } else {
            // then it's "**"
            kind = TokenKind.POWER;
          }
        } else if(c == CodePoint.EQUAL) {
          // it's "*="
          _nextChar();
          kind = TokenKind.ASSIGN_MULT;
        } else {
          // it's "*"
          kind = TokenKind.MULT;
        }
        break;
      case CodePoint.PLUS: // '+'
        c = _nextChar();
        if(c == CodePoint.PLUS) {
          // it's "++"
          _nextChar();
          kind = TokenKind.UPDATE_INCR;
        } else if(c == CodePoint.EQUAL) {
          // it's "+="
          _nextChar();
          kind = TokenKind.ASSIGN_ADD;
        } else {
          // it's "+"
          kind = TokenKind.PLUS;
        }
        break;
      case CodePoint.COMMA: // ','
        _nextChar();
        kind = TokenKind.COMMA;
        break;
      case CodePoint.MINUS: // '-'
        c = _nextChar();
        if(c == CodePoint.GREATERTHAN) {
          // it's "->"
          _nextChar();
          kind = TokenKind.RIGHT_ARROW;
        } else if(c == CodePoint.MINUS) {
          // it's "--"
          _nextChar();
          kind = TokenKind.UPDATE_DECR;
        } else if(c == CodePoint.EQUAL) {
          // it's "-="
          _nextChar();
          kind = TokenKind.ASSIGN_SUB;
        } else {
          // it's "-"
          kind = TokenKind.MINUS;
        }
        break;
      case CodePoint.DOT: // '.'
        c = _nextChar();
        if(c == CodePoint.DOT) {
          // '.'
          c = _nextChar();
          if(c == CodePoint.DOT) {
            _nextChar();
            // it's "..."
            kind = TokenKind.RANGE_TRIPLEDOT;
          } else {
            // it's ".."
            kind = TokenKind.RANGE_DOUBLEDOT;
          }
        } else {
          // it's "."
          kind = TokenKind.DOT;
        }
        break;
      case CodePoint.SLASH: // '/'
        c = _nextChar();
        if(c == CodePoint.EQUAL) {
          // it's "/="
          _nextChar();
          kind = TokenKind.ASSIGN_DIV;
        } else {
          // it's "/"
          kind = TokenKind.DIV;
        }
        break;
      case CodePoint.COLON: // ':'
        _nextChar();
        kind = TokenKind.COLON;
        break;
      case CodePoint.SEMICOLON: // ';'
        _nextChar();
        kind = TokenKind.SEMICOLON;
        break;
      case CodePoint.LESSTHAN: // '<'
        c = _nextChar();
        if(c == CodePoint.LESSTHAN) {
          // '<'
          c = _nextChar();
          if(c == CodePoint.EQUAL) {
            // it's "<<="
            _nextChar();
            kind = TokenKind.ASSIGN_SHIFTLEFT;
          } else {
            // it's "<<"
            kind = TokenKind.SHIFT_LEFT;
          }
        } else if(c == CodePoint.EQUAL) {
          // it's "<="
          _nextChar();
          kind = TokenKind.LESS_THAN_OR_EQUAL;
        } else {
          // it's "<"
          kind = TokenKind.LESS_THAN;
        }
        break;
      case CodePoint.EQUAL: // '='
        c = _nextChar();
        if(c == CodePoint.EQUAL) {
          // it's "=="
          _nextChar();
          kind = TokenKind.EQUAL;
        } else {
          // it's "="
          kind = TokenKind.ASSIGN_EQUAL;
        }
        break;
      case CodePoint.GREATERTHAN: // '>'
        c = _nextChar();
        if(c == CodePoint.EQUAL) {
          // it's ">="
          _nextChar();
          kind = TokenKind.GREATER_THAN_OR_EQUAL;
        } else {
          // it's ">"
          kind = TokenKind.GREATER_THAN;
        }
        // TODO: >= >>
        break;
      case CodePoint.QUESTIONMARK: // '?'
        _nextChar();
        kind = TokenKind.QUESTIONMARK;
        break;
      case CodePoint.AT: // '@'
        _nextChar();
        kind = TokenKind.AT;
        break;
      case CodePoint.LBRACKET:
        _nextChar();
        kind = TokenKind.LEFT_BRACKET;
        break;
      case CodePoint.RBRACKET:
        _nextChar();
        kind = TokenKind.RIGHT_BRACKET;
        break;
      case CodePoint.CARET: // '^'
        c = _nextChar();
        if(c == CodePoint.EQUAL) {
          // it's "^="
          _nextChar();
          kind = TokenKind.ASSIGN_XOR;
        } else {
          // it's "^"
          kind = TokenKind.BITWISE_XOR;
        }
        break;
      case CodePoint.LBRACE: // '{'
        _nextChar();
        kind = TokenKind.LEFT_BRACE;
        _indentationLevels.insert(0, new IndentationLevel());
        break;
      case CodePoint.BAR: // '|'
        c = _nextChar();
        if(c == CodePoint.BAR) {
          // it's "||"
          _nextChar();
          kind = TokenKind.LOGICAL_OR;
        } else if(c == CodePoint.EQUAL) {
          // it's "|="
          _nextChar();
          kind = TokenKind.ASSIGN_OR;
        } else {
          // it's "|"
          kind = TokenKind.BITWISE_OR;
        }
        break;
      case CodePoint.RBRACE: // '}'
        _nextChar();
        kind = TokenKind.RIGHT_BRACE;
        _closeIndentLevel(_indentationLevels.removeAt(0));
        break;
      case CodePoint.TILDE: // '~'
        _nextChar();
        kind = TokenKind.UNARY_BITWISE_NOT;
        break;
      default:
        status = 2;
    }

    switch(status) {
      case 0:
        return true;
      case 1:
      // MARK(MAKE TOKEN) + MARK(ADD TOKEN)
        _addToken(new SimpleToken(kind, offset));
        return true;
      case 2:
      // MARK(REPORT ERROR)
        _reportError(new AnalysisError(
            _source, offset, 1, ScannerErrorCode.ILLEGAL_CHARACTER,
            [_input.substring(offset, offset + 1)]));
    // MARK(ERROR STOP SCANNING)
    }
    return false;
  }

  bool _isStartTag(int offset) {
    if(_codeUnitAt(offset) == CodePoint.LBRACE &&
        _codeUnitAt(offset + 1) == CodePoint.LBRACE) {
      return true;
    }
    return false;
  }

  bool _isEndTag(int offset) {
    if(_codeUnitAt(offset) == CodePoint.RBRACE &&
        _codeUnitAt(offset + 1) == CodePoint.RBRACE) {
      return true;
    }
    return false;
  }
}

typedef bool CheckCodeUnit(int c);