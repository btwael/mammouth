library mammouth.language.common.ast.ast;

import "package:mammouth/src/language/common/ast/syntacticEntity.dart"
    show SyntacticEntity;
import "package:mammouth/src/language/common/ast/token.dart" show Token;
import "package:mammouth/src/language/common/ast/visitor.dart" show Visitor;

// AstNode
/**
 * A node in the AST structure for a document.
 */
abstract class AstNode implements SyntacticEntity {
  /**
   * The first token included in this node.
   */
  Token get beginToken;

  /**
   * The last token included in this node.
   */
  Token get endToken;

  /**
   * The parent node of this node in the AST structure.
   */
  AstNode get parentNode;

  /**
   * Sets the parent node of this node.
   */
  void set parentNode(AstNode node);

  @override
  int get offset {
    return this.beginToken.offset;
  }

  @override
  int get length {
    return this.endOffset - this.offset;
  }

  @override
  int get endOffset {
    return this.endToken.endOffset;
  }

  /**
   * Visits this node using the given [visitor].
   */
  E accept<E>(Visitor<E> visitor);
}

//*-- Document
/**
 * A node representing a document that may contain zero or many mammouth and/or
 * php scripts.
 */
abstract class Document extends AstNode {
  /**
   * List of entries of this document.
   */
  Iterable<DocumentEntry> get entries;

  /**
   * The EOS token that marks the end of the document.
   */
  Token get EOS;

  @override
  Token get beginToken {
    if(this.entries.isEmpty) {
      return null;
    }
    return this.entries.first.beginToken;
  }

  @override
  Token get endToken {
    if(this.entries.isEmpty) {
      return null;
    }
    return this.entries.last.beginToken;
  }

  @override
  AstNode get parentNode {
    return null;
  }

  @override
  void set parentNode(AstNode node) {
    return;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitDocument(this);
  }
}

//*-- DocumentEntry
/**
 * The base class of all document entries.
 */
abstract class DocumentEntry extends AstNode {
  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  Document get parentNode;

  @override
  void set parentNode(AstNode node);

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- InlineEntry
/**
 * Represents the inline/raw section (generally html/text/..) in the document.
 */
abstract class InlineEntry extends DocumentEntry {
  /**
   * The token representing the inline entry.
   */
  Token get token;

  /**
   * The text content of the inline entry.
   */
  String get content {
    return this.token.lexeme;
  }

  @override
  Document get parentNode;

  @override
  void set parentNode(AstNode node);

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitInlineEntry(this);
  }
}
