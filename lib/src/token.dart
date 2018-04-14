import "./precedence.dart";
import "./syntacticEntity.dart";

//*-- TokenKind
/**
 * TokenKind allows to classify tokens into kinds.
 */
class TokenKind {
    final String _name;
    final TokenKind _parentKind;
    final String _lexeme;
    final Precedence _precedence;

    const TokenKind(this._name, {String lexeme: null, TokenKind parentKind: null, Precedence precedence: Precedence.Zero})
            : this._parentKind = parentKind,
              this._lexeme = lexeme,
              this._precedence = precedence;

    /**
     * Returns the name of this token kind.
     */
    String get name {
        return this._name;
     }

    /**
     * Retuens the parent kind of this token kind, maybe `null`.
     */
    TokenKind get parentKind {
        return this._parentKind;
    }

    /**
     * Returns the default lexeme of this kind, maybe `null`.
     */
    String get lexeme {
        return this._lexeme;
    }

    /**
     * Returns the precedence of this kind.
     */
    Precedence get precedence {
        return this._precedence;
    }

    /**
     * Returns `true` if this kind is equal or a subkind of
     * given kind [other].
     */
    bool kindOf(TokenKind other) {
        TokenKind kind = this;
        while(kind != null) {
            if(kind == other) {
                return true;
            }
            kind = kind.parentKind;
        }
        return false;
    }

    static const TokenKind EOS = const TokenKind("EOS");
    static const TokenKind RAW = const TokenKind("RAW");
    static const TokenKind Tag = const TokenKind("TAG"); // abstract
    static const TokenKind STARTTAG = const TokenKind("START_TAG", lexeme: "{{", parentKind: TokenKind.Tag); // {{
    static const TokenKind ENDTAG = const TokenKind("END_TAG", lexeme: "}}", parentKind: TokenKind.Tag); // }}
    static const TokenKind LINEFEED = const TokenKind("LINE_FEED", lexeme: "\n");
    static const TokenKind INDENT = const TokenKind("INDENT");
    static const TokenKind MIDENT = const TokenKind("MIDENT");
    static const TokenKind OUTDENT = const TokenKind("OUTDENT");
    static const TokenKind NAME = const TokenKind("NAME");
}

//*-- Token
/**
 * Entity produced by scanner describing the lexicon used in source code.
 */
abstract class Token extends SyntacticEntity {
    /**
     * Retuens the kind of this token.
     */
    TokenKind get kind;

    /**
     * Returns the lexeme of this token.
     */
    String get lexeme;

    /**
     * Returns the precedence of this token.
     */
    Precedence get precedence;

    @override
    int get offset;

    @override
    int get length;

    /**
     * Returns the previous token in the token stream.
     */
    Token get previous;

    /**
     * Returns the next token in the token stream.
     */
    Token get next;

    /**
     * Sets the prevoius token in the token stream.
     */
     void set previous(Token token);

    /**
     * Sets the next token in the token stream.
     */
     void set next(Token token);
}

//*-- SimpleToken
/**
 * A `Token` whose lexeme depends of it's kind.
 */
class SimpleToken extends Token {
    TokenKind _kind;
    int _offset;
    Token _previous, _next;

    SimpleToken(this._kind, this._offset);

    @override
    TokenKind get kind {
        return this._kind;
    }

    @override
    String get lexeme {
        return this.kind.lexeme;
    }

    @override
    Precedence get precedence {
        return this.kind.precedence;
    }

    @override
    int get offset {
        return this._offset;
    }

    @override
    int get length {
        return this.lexeme != null ? this.lexeme.length : 0;
    }

    @override
    Token get previous {
        return this._previous;
    }

    @override
    Token get next {
        return this._next;
    }

    @override
    void set previous(Token token) {
        this._previous = token;
    }

    @override
    void set next(Token token) {
        this._next = token;
    }
}

//*-- StringToken
/**
 * A `Token` whose lexeme is independent of it's kind.
 */
class StringToken extends SimpleToken {
    String _lexeme;

    StringToken(TokenKind kind, this._lexeme, int offset): super(kind, offset);

    @override
    String get lexeme {
        return this._lexeme;
    }
}


