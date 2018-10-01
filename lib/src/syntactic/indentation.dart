import "package:mammouth/src/language/common/ast/token.dart"
    show TokenKind, Token, StringToken;

class Indentation implements Comparable<Indentation> {
  String value;

  Indentation(this.value);

  int get tabulationCount {
    return "\t"
        .allMatches(this.value)
        .length;
  }

  int get spaceCount {
    return " "
        .allMatches(this.value)
        .length;
  }

  @override
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

  @override
  bool operator ==(Object other) {
    if(other is Indentation) {
      return this.compareTo(other) == 0;
    }
    return false;
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
}

//*-- IndentationToken
class IndentationToken extends StringToken {
  Indentation _indentation;

  IndentationToken(TokenKind kind, Indentation indentation, int offset)
      : _indentation = indentation,
        super(kind, indentation.value, offset);

  Indentation get indentation {
    return this._indentation;
  }
}

//*-- IndentationLevel
class IndentationLevel {
  List<Indentation> indenationtStack = new List<Indentation>();
  List<Token> openedToken = new List<Token>();

  Indentation get currentIndent {
    if(this.indenationtStack.isNotEmpty) {
      return this.indenationtStack.first;
    }
    return null;
  }

  void shiftIndent(Indentation indentation) {
    this.indenationtStack.insert(0, indentation);
  }

  void shiftOpenedToken(Token token) {
    this.openedToken.insert(0, token);
  }
}
