import "../diagnostic/error.dart" show ErrorType, ErrorCode;

class ScannerErrorCode extends ErrorCode {
  const ScannerErrorCode(String name, String message, [String correction])
      : super(name, message, ErrorType.SYNTACTIC_ERROR, correction);

  static const ScannerErrorCode MISSING_DEC_DIGIT = const ScannerErrorCode(
      "MISSING_DEC_DIGIT", "Decimal digit expected after '{0}'.");
  static const ScannerErrorCode MISSING_BIN_DIGIT = const ScannerErrorCode(
      "MISSING_BIN_DIGIT", "Binary digit expected after '{0}'.");
  static const ScannerErrorCode MISSING_OCT_DIGIT = const ScannerErrorCode(
      "MISSING_OCT_DIGIT", "Octal digit expected after '{0}'.");
  static const ScannerErrorCode MISSING_HEX_DIGIT = const ScannerErrorCode(
      "MISSING_HEX_DIGIT", "Hexadecimal digit expected after '{0}'.");
  static const ScannerErrorCode MISSING_EXPONENT_DIGIT = const ScannerErrorCode(
      "MISSING_EXPONENT_DIGIT", "Missign exponent decimal digit after '{0}'.");
  static const ScannerErrorCode UNTERMINATED_STRING_LITERAL = const ScannerErrorCode(
      "UNTERMINATED_STRING_LITERAL", "Unterminated string literal.");
  static const ScannerErrorCode INVALID_HEX_SEQUENCE = const ScannerErrorCode(
      "INVALID_HEX_SEQUENCE", "Invalid hexadecimal sequence after '\\u'.");
  static const ScannerErrorCode ILLEGAL_CHARACTER = const ScannerErrorCode(
      'ILLEGAL_CHARACTER', "Illegal character '{0}'.");
}

class ParserErrorCode extends ErrorCode {
  const ParserErrorCode(String name, String message, [String correction])
      : super(name, message, ErrorType.SYNTACTIC_ERROR, correction);

  static const ParserErrorCode EXPECTED_END_TAG = const ParserErrorCode(
      "EXPECTED_END_TAG", "Expected end tag '}}' but {0}.");
  static const ParserErrorCode EXPECTED_INDENT_BLOCK = const ParserErrorCode(
      "EXPECTED_INDENT_BLOCK", "Expected an indented block");
  static const ParserErrorCode INDENTATION_LEVEL_IN_BETWEEN = const ParserErrorCode(
      "INDENTATION_LEVEL_IN_BETWEEN",
      "Cannot determine if the statement is nested in the previous block or not.");
  static const ParserErrorCode EXPECTED_EXPRESSION_AFTER_EQUAL =
  const ParserErrorCode("EXPECTED_EXPRESSION_AFTER_EQUAL",
      "An initializing expression is expected after '='.");
  static const ParserErrorCode INVALID_CLASS_NAME = const ParserErrorCode(
      "INVALID_CLASS_NAME",
      "Only valid identifiers are accepted as class names.");
  static const ParserErrorCode EXPECTED_RIGHT_ARROW_CONSTRUCTOR =
  const ParserErrorCode("EXPECTED_RIGHT_ARROW_CONSTRUCTOR",
      "Expected a right arrow '->' to define a constructor body.");
  static const ParserErrorCode EXPECTED_FN_RETURN_TYPE_METHOD =
  const ParserErrorCode("EXPECTED_FN_RETURN_TYPE_METHOD",
      "A method declaration must start with 'fn' or a return type.");
  static const ParserErrorCode METHOD_REQUIRES_NAME = const ParserErrorCode(
      "METHOD_REQUIRES_NAME",
      "A method declaration can not be declared without a name.");
}
