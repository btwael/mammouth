import "./token.dart" show TokenKind, StringToken;

class Indentation implements Comparable<Indentation> {
    String value;

    Indentation(this.value);

    int get tabulationCount {
        return "\t".allMatches(this.value).length;
    }

    int get spaceCount {
        return " ".allMatches(this.value).length;
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
