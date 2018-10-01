import "../basic/source.dart" show Source;

//*-- ErrorSeverity
/**
 * The severity of an error type.
 */
class ErrorSeverity implements Comparable<ErrorSeverity> {
  const ErrorSeverity(this.name, this.ordinal, this.machineCode);

  /**
   * The name of this severity.
   */
  final String name;

  /**
   * The ordinal of this severity.
   */
  final int ordinal;

  /**
   * The machine code of this severity.
   */
  final String machineCode;

  @override
  int compareTo(ErrorSeverity other) {
    return this.ordinal - other.ordinal;
  }

  bool operator <(ErrorSeverity other) {
    return this.compareTo(other) < 0;
  }

  bool operator <=(ErrorSeverity other) {
    int comp = this.compareTo(other);
    return comp < 0 || comp == 0;
  }

  bool operator >(ErrorSeverity other) {
    return this.compareTo(other) > 0;
  }

  bool operator >=(ErrorSeverity other) {
    int comp = this.compareTo(other);
    return comp > 1 || comp == 0;
  }

  /**
   * The severity representing a non-error. This is never used for any error
   * code, but is maybe useful.
   */
  static const ErrorSeverity NONE = const ErrorSeverity("NONE", 0, " ");

  /**
   * The severity representing an informational level analysis issue.
   */
  static const ErrorSeverity INFO = const ErrorSeverity("INFO", 1, "I");

  /**
   * The severity representing a warning.
   */
  static const ErrorSeverity WARNING = const ErrorSeverity("WARNING", 2, "W");

  /**
   * The severity representing an error.
   */
  static const ErrorSeverity ERROR = const ErrorSeverity("ERROR", 3, "E");

  /**
   * List of all possible error severities
   */
  static const List<ErrorSeverity> values = const <ErrorSeverity>[
    NONE,
    INFO,
    WARNING,
    ERROR
  ];
}

//*-- ErrorType
/**
 * The type of an error code.
 */
class ErrorType {
  const ErrorType(this.name, this.severity);

  /**
   * The name of this error type.
   */
  final String name;

  /**
   * The severity of this error type.
   */
  final ErrorSeverity severity;

  static const ErrorType SYNTACTIC_ERROR =
  const ErrorType("SYNTACTIC_ERROR", ErrorSeverity.ERROR);
}

//*-- ErrorCode
/**
 * An error code associated with an `AnalysisError`.
 */
class ErrorCode {
  const ErrorCode(this.name, this.message, this.type, [this.correction = null]);

  /**
   * The name of this error code.
   */
  final String name;

  /**
   * The template used to create the message to be displayed for this error.
   */
  final String message;

  /**
   * The template used to create the correction to be displayed for this error.
   */
  final String correction;

  /**
   * The type of this error code.
   */
  final ErrorType type;

  /**
   * The severity of the error code.
   */
  ErrorSeverity get severity {
    return this.type.severity;
  }
}

//*-- AnalysisError
/**
 * An error discovered during the analysis of some source code.
 */
class AnalysisError {
  AnalysisError(this.source, this.offset, this.length, this.code,
      [List<String> arguments = null]) {
    if(arguments != null) {
      this.message = _formatPatternArguments(this.code.message, arguments);
    } else {
      this.message = this.code.message;
    }
    if(this.code.correction != null) {
      if(arguments != null) {
        this.correction =
            _formatPatternArguments(this.code.correction, arguments);
      } else {
        this.correction = this.code.correction;
      }
    }
  }

  /**
   * The character offset from the beginning of the source (zero based) where
   * the error occurred.
   */
  int offset;

  /**
   * The number of characters from the offset to the end of the source which
   * encompasses the compilation error.
   */
  int length;

  /**
   * The localized error message.
   */
  String message;

  /**
   * The correction to be displayed for this error, or `null` if there is no
   * correction information for this error.
   */
  String correction;

  /**
   * The error code associated with the error.
   */
  final ErrorCode code;

  /**
   * The source in which the error occurred.
   */
  final Source source;

  String _formatPatternArguments(String pattern, List<String> arguments) {
    if(arguments.isEmpty) {
      return pattern;
    }
    return pattern.replaceAllMapped(new RegExp(r'\{([0-9]+)\}'),
            (Match match) => arguments[int.parse(match.group(1))]);
  }
}
