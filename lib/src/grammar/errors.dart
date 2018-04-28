import "../diagnostic/error.dart" show ErrorType, ErrorCode;

class ScannerErrorCode extends ErrorCode {
    const ScannerErrorCode(String name, String message, [String correction])
            : super(name, message, ErrorType.SYNTACTIC_ERROR, correction);

    static const ScannerErrorCode MISSING_DEC_DIGIT = const ScannerErrorCode("MISSING_DEC_DIGIT", "Decimal digit expected after '{0}'.");
    static const ScannerErrorCode MISSING_BIN_DIGIT = const ScannerErrorCode("MISSING_BIN_DIGIT", "Binary digit expected after '{0}'.");
    static const ScannerErrorCode MISSING_OCT_DIGIT = const ScannerErrorCode("MISSING_OCT_DIGIT", "Octal digit expected after '{0}'.");
    static const ScannerErrorCode MISSING_HEX_DIGIT = const ScannerErrorCode("MISSING_HEX_DIGIT", "Hexadecimal digit expected after '{0}'.");
    static const ScannerErrorCode UNTERMINATED_STRING_LITERAL = const ScannerErrorCode("UNTERMINATED_STRING_LITERAL", "Unterminated string literal.");
    static const ScannerErrorCode INVALID_HEX_SEQUENCE = const ScannerErrorCode("INVALID_HEX_SEQUENCE", "Invalid hexadecimal sequence after '\\u'.");
}
