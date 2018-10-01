library mammouth.language.common.ast.syntacticEntity;

//*-- SyntacticEntity
/**
 * Interface representing a syntactic entity (either a token or an AST node)
 * which has a location in the source file.
 */
abstract class SyntacticEntity {
  /**
   * The offset from the beginning of the file to the first character in the
   * syntactic entity.
   */
  int get offset;

  /**
   * The number of characters in the syntactic entity's source range.
   */
  int get length;

  /**
   * The offset from the beginning of the file to the character after the last
   * character of the syntactic entity.
   */
  int get endOffset {
    return this.offset + this.length;
  }
}
