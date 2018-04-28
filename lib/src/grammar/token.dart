import "./precedence.dart" show Precedence;
import "./syntacticEntity.dart" show SyntacticEntity;

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
    static const TokenKind INLINE = const TokenKind("INLINE");
    static const TokenKind TAG = const TokenKind("TAG"); // abstract
    static const TokenKind STARTTAG = const TokenKind("START_TAG", lexeme: "{{", parentKind: TokenKind.TAG); // {{
    static const TokenKind ENDTAG = const TokenKind("END_TAG", lexeme: "}}", parentKind: TokenKind.TAG); // }}

    static const TokenKind LINEFEED = const TokenKind("LINE_FEED", lexeme: "\n");

    static const TokenKind COMMA = const TokenKind("COMMA", lexeme: ",");
    static const TokenKind DOT = const TokenKind("DOT", lexeme: ".");
    static const TokenKind COLON = const TokenKind("COLON", lexeme: ":");
    static const TokenKind SEMICOLON = const TokenKind("SEMICOLON", lexeme: ";");
    static const TokenKind QUESTIONMARK = const TokenKind("QUESTIONMARK", lexeme: "?");

    static const TokenKind UNARY = const TokenKind("UNARY"); // abstract
    static const TokenKind UNARYNOT = const TokenKind("UNARYNOT", lexeme: "!", parentKind: TokenKind.UNARY);
    static const TokenKind UNARYBITWISENOT = const TokenKind("UNARYBITWISENOT", lexeme: "~", parentKind: TokenKind.UNARY);

    static const TokenKind UPDATE = const TokenKind("UPDATE"); // abstract
    static const TokenKind INCRUPDATE = const TokenKind("INCRUPDATE", lexeme: "++", parentKind: TokenKind.UPDATE);
    static const TokenKind DECRUPDATE = const TokenKind("DECRUPDATE", lexeme: "--", parentKind: TokenKind.UPDATE);

    static const TokenKind ASSIGN = const TokenKind("ASSIGN"); // abstract
    static const TokenKind EQUALASSIGN = const TokenKind("EQUALASSIGN", lexeme: "=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind ORASSIGN = const TokenKind("ORASSIGN", lexeme: "|=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind XORASSIGN = const TokenKind("XORASSIGN", lexeme: "^=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind ANDASSIGN = const TokenKind("ANDASSIGN", lexeme: "&=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind SHIFTLEFTASSIGN = const TokenKind("SHIFTLEFTASSIGN", lexeme: "<<=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind SHIFTRIGHTASSIGN = const TokenKind("SHIFTRIGHTASSIGN", lexeme: ">>=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind ADDASSIGN = const TokenKind("ADDASSIGN", lexeme: "+=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind SUBASSIGN = const TokenKind("SUBASSIGN", lexeme: "-=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind MULTASSIGN = const TokenKind("MULTASSIGN", lexeme: "*=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind POWASSIGN = const TokenKind("POWASSIGN", lexeme: "**", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind DIVASSIGN = const TokenKind("DIVASSIGN", lexeme: "/=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
    static const TokenKind MODULOASSIGN = const TokenKind("MODULOASSIGN", lexeme: "%=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);

    static const TokenKind BINARY = const TokenKind("BINARY"); // abstract
    static const TokenKind LOGIC = const TokenKind("LOGIC", parentKind: TokenKind.BINARY); // abstract
    static const TokenKind LOGICALOR = const TokenKind("LOGICALOR", lexeme: "||", parentKind: TokenKind.LOGIC, precedence: Precedence.LogicalOr);
    static const TokenKind LOGICALAND = const TokenKind("LOGICALAND", lexeme: "&&", parentKind: TokenKind.LOGIC, precedence: Precedence.LogicalAnd);
    static const TokenKind BITWISE = const TokenKind("BITWISE", parentKind: TokenKind.BINARY); // abstract
    static const TokenKind BITWISEOR = const TokenKind("BITWISEOR", lexeme: "|", parentKind: TokenKind.BITWISE,  precedence: Precedence.BitwiseOr);
    static const TokenKind BITWISEAND = const TokenKind("BITWISEAND", lexeme: "&", parentKind: TokenKind.BITWISE, precedence: Precedence.BitwiseAnd);
    static const TokenKind BITWISEXOR = const TokenKind("BITWISEXOR", lexeme: "^", parentKind: TokenKind.BITWISE, precedence: Precedence.BitwiseXor);
    static const TokenKind EQUALITY = const TokenKind("EQUALITY", parentKind: TokenKind.BINARY); // abstract
    static const TokenKind NOTEQUAL = const TokenKind("NOT_EQUAL", lexeme: "!=", parentKind: TokenKind.EQUALITY, precedence: Precedence.Equality);
    static const TokenKind EQUAL = const TokenKind("EQUAL", lexeme: "==", parentKind: TokenKind.EQUALITY, precedence: Precedence.Equality);
    static const TokenKind RELATIONAL = const TokenKind("RELATIONAL", parentKind: TokenKind.BINARY); // abstract
    static const TokenKind LESSTHAN = const TokenKind("LESSTHAN", lexeme: "<", parentKind: TokenKind.RELATIONAL, precedence: Precedence.Relational);
    static const TokenKind GREATERTHAN = const TokenKind("GREATERTHAN", lexeme: ">", parentKind: TokenKind.RELATIONAL, precedence: Precedence.Relational);
    static const TokenKind LESSTHANOREQUAL = const TokenKind("LESSTHANOREQUAL", lexeme: "<=", parentKind: TokenKind.RELATIONAL, precedence: Precedence.Relational);
    static const TokenKind GREATERTHANOREQUAL = const TokenKind("GREATERTHANOREQUAL", lexeme: ">=", parentKind: TokenKind.RELATIONAL, precedence: Precedence.Relational);
    static const TokenKind SHIFT = const TokenKind("SHIFT", parentKind: TokenKind.BINARY); // abstract
    static const TokenKind SHIFTLEFT = const TokenKind("SHIFTLEFT", lexeme: "<<", parentKind: TokenKind.SHIFT, precedence: Precedence.Shift);
    static const TokenKind SHIFTRIGH = const TokenKind("SHIFTRIGH", lexeme: ">>", parentKind: TokenKind.SHIFT, precedence: Precedence.Shift);
    static const TokenKind PLUS = const TokenKind("PLUS", lexeme: "+", parentKind: TokenKind.BINARY, precedence: Precedence.Additive);
    static const TokenKind MINUS = const TokenKind("MINUS", lexeme: "-", parentKind: TokenKind.BINARY, precedence: Precedence.Additive);
    static const TokenKind MULT = const TokenKind("MULT", lexeme: "*", parentKind: TokenKind.BINARY, precedence: Precedence.Multiplicative);
    static const TokenKind POWER = const TokenKind("POWER", lexeme: "**", parentKind: TokenKind.BINARY, precedence: Precedence.Multiplicative);
    static const TokenKind DIV = const TokenKind("DIV", lexeme: "/", parentKind: TokenKind.BINARY, precedence: Precedence.Multiplicative);
    static const TokenKind MODULO = const TokenKind("MODULO", lexeme: "%", parentKind: TokenKind.BINARY, precedence: Precedence.Multiplicative);

    static const TokenKind INDENTTOK = const TokenKind("INDENTTOK"); // abstract
    static const TokenKind INDENT = const TokenKind("INDENT", parentKind: TokenKind.INDENTTOK);
    static const TokenKind MIDENT = const TokenKind("MIDENT", parentKind: TokenKind.INDENTTOK);
    static const TokenKind OUTDENT = const TokenKind("OUTDENT", parentKind: TokenKind.INDENTTOK);

    static const TokenKind NAME = const TokenKind("NAME");
    static const TokenKind BOOLEAN = const TokenKind("BOOLEAN");
    static const TokenKind NUMERIC = const TokenKind("NUMERIC"); // abstract
    static const TokenKind INTEGER = const TokenKind("INTEGER", parentKind: TokenKind.NUMERIC);
    static const TokenKind FLOAT = const TokenKind("FLOAT", parentKind: TokenKind.NUMERIC);
    static const TokenKind STRING = const TokenKind("STRING");

    static const TokenKind IF = const TokenKind("IF", lexeme: "if");
    static const TokenKind WHILE = const TokenKind("WHILE", lexeme: "while");
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
