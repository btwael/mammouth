library mammouth.language.common.ast.token;

import "package:mammouth/src/language/common/ast/precedence.dart"
    show Precedence;
import "package:mammouth/src/language/common/ast/syntacticEntity.dart"
    show SyntacticEntity;

//*-- TokenKind
/**
 * Helps to identify tokens produced by the scanner.
 */
class TokenKind {
  /**
   * An abstract constructor that initialize a newly created kind with given
   * [name], and optionally given [parentKind].
   */
  const TokenKind(this.name,
      {String lexeme = null,
        Precedence precedence = Precedence.Zero,
        TokenKind parentKind = null})
      : this.lexeme = lexeme,
        this.precedence = precedence,
        this.parentKind = parentKind;

  /**
   * The name of this kind of token.
   */
  final String name;

  /**
   * The lexeme that defines this kind of token, or `null` if this is an
   * abstract kind or this have multiple possible lexeme.
   */
  final String lexeme;

  /**
   * The precedence of this kind of token,
   */
  final Precedence precedence;

  /**
   * The parent kind of this kind.
   */
  final TokenKind parentKind;

  /**
   * Returns `true` if this kind is equal to [other] or [other] is a direct or
   * indirect parent kind of this kind of token, `false` otherwise.
   */
  @override
  bool operator ==(Object other) {
    if(other is TokenKind) {
      TokenKind kind = this;
      while(kind != null) {
        if(kind.name == other.name) {
          return true;
        }
        kind = kind.parentKind;
      }
    }
    return false;
  }

  static const TokenKind EOS = const TokenKind("EOS"); // end of source
  static const TokenKind INLINE_ENTRY = const TokenKind("INLINE_ENTRY");

  static const TokenKind TAG = const TokenKind("TAG");
  static const TokenKind START_TAG = const TokenKind(
      "START_TAG", lexeme: "{{", parentKind: TokenKind.TAG);
  static const TokenKind END_TAG = const TokenKind(
      "END_TAG", lexeme: "}}", parentKind: TokenKind.TAG);

  static const TokenKind INDENTATION = const TokenKind("INDENTATION");
  static const TokenKind INDENT = const TokenKind(
      "INDENT", parentKind: TokenKind.INDENTATION);
  static const TokenKind MINDENT = const TokenKind(
      "MINDENT", parentKind: TokenKind.INDENTATION);
  static const TokenKind OUTDENT = const TokenKind(
      "OUTDENT", parentKind: TokenKind.INDENTATION);

  static const TokenKind LINE_FEED = const TokenKind("LINE_FEED", lexeme: "\n");
  static const TokenKind COMMA = const TokenKind("COMMA", lexeme: ",");
  static const TokenKind DOT = const TokenKind("DOT", lexeme: ".");
  static const TokenKind COLON = const TokenKind("COLON", lexeme: ":");
  static const TokenKind SEMICOLON = const TokenKind("SEMICOLON", lexeme: ";");
  static const TokenKind QUESTIONMARK = const TokenKind(
      "QUESTIONMARK", lexeme: "?");
  static const TokenKind RIGHT_ARROW = const TokenKind(
      "RIGHT_ARROW", lexeme: "->");
  static const TokenKind AT = const TokenKind("AT", lexeme: "@");

  static const TokenKind RANGE_DOUBLEDOT = const TokenKind(
      "RANGE_DOUBLEDOT", lexeme: "..");
  static const TokenKind RANGE_TRIPLEDOT = const TokenKind(
      "RANGE_TRIPLEDOT", lexeme: "...");

  static const TokenKind PAREN = const TokenKind("PAREN");
  static const TokenKind LEFT_PAREN = const TokenKind(
      "LEFT_PAREN", lexeme: "(", parentKind: TokenKind.PAREN);
  static const TokenKind RIGHT_PAREN = const TokenKind(
      "RIGHT_PAREN", lexeme: ")", parentKind: TokenKind.PAREN);

  static const TokenKind BRACKET = const TokenKind("BRACKET");
  static const TokenKind LEFT_BRACKET = const TokenKind("LEFT_BRACKET",
      lexeme: "[", parentKind: TokenKind.BRACKET);
  static const TokenKind RIGHT_BRACKET = const TokenKind("RIGHT_BRACKET",
      lexeme: "]", parentKind: TokenKind.BRACKET);
  static const TokenKind INDEX_OPERATOR = const TokenKind(
      "INDEX_OPERATOR", lexeme: "[]");

  static const TokenKind BRACE = const TokenKind("BRACE");
  static const TokenKind LEFT_BRACE = const TokenKind(
      "LEFT_BRACE", lexeme: "{", parentKind: TokenKind.BRACE);
  static const TokenKind RIGHT_BRACE = const TokenKind(
      "RIGHT_BRACE", lexeme: "}", parentKind: TokenKind.BRACE);

  static const TokenKind UNARY = const TokenKind("UNARY");
  static const TokenKind UNARY_NOT = const TokenKind(
      "UNARY_NOT", lexeme: "!", parentKind: TokenKind.UNARY);
  static const TokenKind UNARY_BITWISE_NOT = const TokenKind(
      "UNARY_BITWISE_NOT",
      lexeme: "~",
      parentKind: TokenKind.UNARY);

  static const TokenKind UPDATE = const TokenKind("UPDATE");
  static const TokenKind UPDATE_INCR = const TokenKind("UPDATE_INCR",
      lexeme: "++", parentKind: TokenKind.UPDATE);
  static const TokenKind UPDATE_DECR = const TokenKind("UPDATE_DECR",
      lexeme: "--", parentKind: TokenKind.UPDATE);

  static const TokenKind ASSIGN = const TokenKind("ASSIGN");
  static const TokenKind ASSIGN_EQUAL = const TokenKind("ASSIGN_EQUAL",
      lexeme: "=", parentKind: TokenKind.ASSIGN, precedence: Precedence.Assign);
  static const TokenKind ASSIGN_OR = const TokenKind("ASSIGN_OR",
      lexeme: "|=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_XOR = const TokenKind("ASSIGN_XOR",
      lexeme: "^=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_AND = const TokenKind("ASSIGN_AND",
      lexeme: "&=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_SHIFTLEFT = const TokenKind("ASSIGN_SHIFTLEFT",
      lexeme: "<<=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_SHIFTRIGHT = const TokenKind(
      "ASSIGN_SHIFTRIGHT",
      lexeme: ">>=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_ADD = const TokenKind("ASSIGN_ADD",
      lexeme: "+=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_SUB = const TokenKind("ASSIGN_SUB",
      lexeme: "-=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_MULT = const TokenKind("ASSIGN_MULT",
      lexeme: "*=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_POW = const TokenKind("ASSIGN_POW",
      lexeme: "**=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_DIV = const TokenKind("ASSIGN_DIV",
      lexeme: "/=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);
  static const TokenKind ASSIGN_MODULO = const TokenKind("ASSIGN_MODULO",
      lexeme: "%=",
      parentKind: TokenKind.ASSIGN,
      precedence: Precedence.Assign);

  static const TokenKind BINARY = const TokenKind("BINARY");
  static const TokenKind LOGIC = const TokenKind(
      "LOGIC", parentKind: TokenKind.BINARY);
  static const TokenKind LOGICAL_OR = const TokenKind("LOGICAL_OR",
      lexeme: "||",
      parentKind: TokenKind.LOGIC,
      precedence: Precedence.LogicalOr);
  static const TokenKind LOGICAL_AND = const TokenKind("LOGICAL_AND",
      lexeme: "&&",
      parentKind: TokenKind.LOGIC,
      precedence: Precedence.LogicalAnd);
  static const TokenKind BITWISE = const TokenKind(
      "BITWISE", parentKind: TokenKind.BINARY);
  static const TokenKind BITWISE_OR = const TokenKind("BITWISE_OR",
      lexeme: "|",
      parentKind: TokenKind.BITWISE,
      precedence: Precedence.BitwiseOr);
  static const TokenKind BITWISE_AND = const TokenKind("BITWISE_AND",
      lexeme: "&",
      parentKind: TokenKind.BITWISE,
      precedence: Precedence.BitwiseAnd);
  static const TokenKind BITWISE_XOR = const TokenKind("BITWISE_XOR",
      lexeme: "^",
      parentKind: TokenKind.BITWISE,
      precedence: Precedence.BitwiseXor);
  static const TokenKind EQUALITY = const TokenKind(
      "EQUALITY", parentKind: TokenKind.BINARY);
  static const TokenKind NOT_EQUAL = const TokenKind("NOT_EQUAL",
      lexeme: "!=",
      parentKind: TokenKind.EQUALITY,
      precedence: Precedence.Equality);
  static const TokenKind EQUAL = const TokenKind("EQUAL",
      lexeme: "==",
      parentKind: TokenKind.EQUALITY,
      precedence: Precedence.Equality);
  static const TokenKind RELATIONAL = const TokenKind(
      "RELATIONAL", parentKind: TokenKind.BINARY);
  static const TokenKind LESS_THAN = const TokenKind("LESS_THAN",
      lexeme: "<",
      parentKind: TokenKind.RELATIONAL,
      precedence: Precedence.Relational);
  static const TokenKind GREATER_THAN = const TokenKind("GREATER_THAN",
      lexeme: ">",
      parentKind: TokenKind.RELATIONAL,
      precedence: Precedence.Relational);
  static const TokenKind LESS_THAN_OR_EQUAL = const TokenKind(
      "LESS_THAN_OR_EQUAL",
      lexeme: "<=",
      parentKind: TokenKind.RELATIONAL,
      precedence: Precedence.Relational);
  static const TokenKind GREATER_THAN_OR_EQUAL = const TokenKind(
      "GREATER_THAN_OR_EQUAL",
      lexeme: ">=",
      parentKind: TokenKind.RELATIONAL,
      precedence: Precedence.Relational);
  static const TokenKind SHIFT = const TokenKind(
      "SHIFT", parentKind: TokenKind.BINARY);
  static const TokenKind SHIFT_LEFT = const TokenKind("SHIFT_LEFT",
      lexeme: "<<", parentKind: TokenKind.SHIFT, precedence: Precedence.Shift);
  static const TokenKind SHIFT_RIGH = const TokenKind("SHIFT_RIGH",
      lexeme: ">>", parentKind: TokenKind.SHIFT, precedence: Precedence.Shift);
  static const TokenKind PLUS = const TokenKind("PLUS",
      lexeme: "+",
      parentKind: TokenKind.BINARY,
      precedence: Precedence.Additive);
  static const TokenKind MINUS = const TokenKind("MINUS",
      lexeme: "-",
      parentKind: TokenKind.BINARY,
      precedence: Precedence.Additive);
  static const TokenKind MULT = const TokenKind("MULT",
      lexeme: "*",
      parentKind: TokenKind.BINARY,
      precedence: Precedence.Multiplicative);
  static const TokenKind POWER = const TokenKind("POWER",
      lexeme: "**",
      parentKind: TokenKind.BINARY,
      precedence: Precedence.Multiplicative);
  static const TokenKind DIV = const TokenKind("DIV",
      lexeme: "/",
      parentKind: TokenKind.BINARY,
      precedence: Precedence.Multiplicative);
  static const TokenKind MODULO = const TokenKind("MODULO",
      lexeme: "%",
      parentKind: TokenKind.BINARY,
      precedence: Precedence.Multiplicative);

  static const TokenKind LITERAL = const TokenKind("LITERAL");
  static const TokenKind BOOLEAN = const TokenKind(
      "BOOLEAN", parentKind: TokenKind.LITERAL);
  static const TokenKind STRING = const TokenKind(
      "STRING", parentKind: TokenKind.LITERAL);
  static const TokenKind NUMERIC = const TokenKind(
      "NUMERIC", parentKind: TokenKind.LITERAL);
  static const TokenKind INTEGER = const TokenKind(
      "INTEGER", parentKind: TokenKind.NUMERIC);
  static const TokenKind FLOAT = const TokenKind(
      "FLOAT", parentKind: TokenKind.NUMERIC);

  static const TokenKind ABSTRACT = const TokenKind(
      "ABSTRACT", lexeme: "abstract");
  static const TokenKind AS = const TokenKind("AS", lexeme: "as");
  static const TokenKind BREAK = const TokenKind("BREAK", lexeme: "break");
  static const TokenKind BY = const TokenKind("BY", lexeme: "by");
  static const TokenKind CATCH = const TokenKind("CATCH", lexeme: "catch");
  static const TokenKind CASE = const TokenKind("CASE", lexeme: "case");
  static const TokenKind CLASS = const TokenKind("CLASS", lexeme: "class");
  static const TokenKind CONSTRUCTOR = const TokenKind(
      "CONSTRUCTOR", lexeme: "constructor");
  static const TokenKind CONTINUE = const TokenKind(
      "CONTINUE", lexeme: "continue");
  static const TokenKind DEFAULT = const TokenKind(
      "DEFAULT", lexeme: "default");
  static const TokenKind ECHO = const TokenKind("ECHO", lexeme: "echo");
  static const TokenKind ELSE = const TokenKind("ELSE", lexeme: "else");
  static const TokenKind EXTENDS = const TokenKind(
      "EXTENDS", lexeme: "extends");
  static const TokenKind FINALLY = const TokenKind(
      "FINALLY", lexeme: "finally");
  static const TokenKind FOR = const TokenKind("FOR", lexeme: "for");
  static const TokenKind IF = const TokenKind("IF", lexeme: "if");
  static const TokenKind IMPLEMENTS = const TokenKind(
      "IMPLEMENTS", lexeme: "implements");
  static const TokenKind IMPORT = const TokenKind("IMPORT", lexeme: "import");
  static const TokenKind IN = const TokenKind("IN", lexeme: "in");
  static const TokenKind INLINE = const TokenKind("INLINE", lexeme: "inline");
  static const TokenKind INTERFACE = const TokenKind(
      "INTERFACE", lexeme: "interface");
  static const TokenKind LOOP = const TokenKind("LOOP", lexeme: "loop");
  static const TokenKind NATIVE = const TokenKind("NATIVE", lexeme: "native");
  static const TokenKind NEW = const TokenKind("NEW", lexeme: "new");
  static const TokenKind OF = const TokenKind("OF", lexeme: "of");
  static const TokenKind PRIVATE = const TokenKind(
      "PRIVATE", lexeme: "private");
  static const TokenKind PROTECTED = const TokenKind(
      "PROTECTED", lexeme: "protected");
  static const TokenKind PUBLIC = const TokenKind("PUBLIC", lexeme: "public");
  static const TokenKind RETURN = const TokenKind("RETURN", lexeme: "return");
  static const TokenKind STATIC = const TokenKind("STATIC", lexeme: "static");
  static const TokenKind SWITCH = const TokenKind("SWITCH", lexeme: "switch");
  static const TokenKind THEN = const TokenKind("THEN", lexeme: "then");
  static const TokenKind THROW = const TokenKind("THROW", lexeme: "throw");
  static const TokenKind TO = const TokenKind("TO", lexeme: "to");
  static const TokenKind TRY = const TokenKind("TRY", lexeme: "try");
  static const TokenKind UNLESS = const TokenKind("UNLESS", lexeme: "unless");
  static const TokenKind UNTIL = const TokenKind("UNTIL", lexeme: "until");
  static const TokenKind WHEN = const TokenKind("WHEN", lexeme: "when");
  static const TokenKind WHILE = const TokenKind("WHILE", lexeme: "while");
  static const TokenKind NAME = const TokenKind("NAME");

  static const TokenKind PHP_TAG = const TokenKind("TAG");
  static const TokenKind PHP_START_TAG = const TokenKind(
      "START_TAG", lexeme: "<?php", parentKind: TokenKind.TAG);
  static const TokenKind PHP_END_TAG = const TokenKind(
      "PHP_END_TAG", lexeme: "?>", parentKind: TokenKind.TAG);
  static const TokenKind PHP_BRACE = const TokenKind("PHP_BRACE");
  static const TokenKind PHP_LEFT_BRACE = const TokenKind("PHP_LEFT_BRACE",
      lexeme: "{", parentKind: TokenKind.PHP_BRACE);
  static const TokenKind PHP_RIGHT_BRACE = const TokenKind("PHP_RIGHT_PAREN",
      lexeme: "}", parentKind: TokenKind.PHP_BRACE);
  static const TokenKind PHP_FUNCTION = const TokenKind(
      "PHP_FUNCTION", lexeme: "function");
  static const TokenKind PHP_BOOLEAN = const TokenKind("PHP_BOOLEAN");
  static const TokenKind PHP_NAME = const TokenKind("PHP_NAME");
  static const TokenKind PHP_VARIABLE = const TokenKind("PHP_VARIABLE");
}

//*-- Token
/**
 * Entity produced by lexer describing the lexicon used in source code.
 */
abstract class Token implements SyntacticEntity {
  /**
   * The kind of this token.
   */
  TokenKind get kind;

  /**
   * The lexeme that represents this token.
   */
  String get lexeme;

  /**
   * The precedence of this token.
   */
  Precedence get precedence;

  @override
  int get offset;

  @override
  int get length;

  @override
  int get endOffset;

  /**
   * The previous token in the token stream, or `null` if this is the first
   * token in the stream.
   */
  Token get previous;

  /**
   * The next token in the token stream, or `null` if this is the last token
   * in the stream.
   */
  Token get next;

  /**
   * Sets the previous token in the token stream.
   */
  void set previous(Token token);

  /**
   * Sets the next token in the token stream.
   */
  void set next(Token token);
}

//*-- SimpleToken
/**
 * A token whose lexeme depends of it's kind.
 */
class SimpleToken extends Token {
  /**
   * Constructs a new token from a given [kind] and [offset].
   */
  SimpleToken(this.kind, this.offset);

  @override
  TokenKind kind;

  @override
  String get lexeme {
    return this.kind.lexeme;
  }

  @override
  Precedence get precedence {
    return this.kind.precedence;
  }

  @override
  final int offset;

  @override
  int get length {
    return this.lexeme != null ? this.lexeme.length : 0;
  }

  @override
  int get endOffset {
    return this.offset + this.length;
  }

  @override
  Token previous;

  @override
  Token next;
}

//*-- StringToken
/**
 * A token whose lexeme is independent of it's kind.
 */
class StringToken extends SimpleToken {
  /**
   * Constructs a new token from a given [kind], [lexeme] and [offset].
   */
  StringToken(TokenKind kind, this.lexeme, int offset) : super(kind, offset);

  @override
  final String lexeme;
}
