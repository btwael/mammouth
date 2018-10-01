library mammouth.language.common.ast.implementation;

import "package:mammouth/src/language/common/ast/ast.dart";
import "package:mammouth/src/language/common/ast/token.dart"
    show TokenKind, Token, StringToken;

//*-- DocumentImpl
class DocumentImpl extends Document {
  @override
  final Iterable<DocumentEntry> entries;

  @override
  final Token EOS;

  DocumentImpl(this.entries, this.EOS);

  DocumentImpl.build(this.entries) : this.EOS = null;
}

//*-- DocumentImpl
class InlineEntryImpl extends InlineEntry {
  @override
  final Token token;

  Document _parentNode;

  InlineEntryImpl(this.token);

  InlineEntryImpl.build(String content)
      : this.token = new StringToken(TokenKind.INLINE_ENTRY, content, null);

  @override
  Document get parentNode => _parentNode;

  @override
  void set parentNode(AstNode node) {
    if(node is Document) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}
