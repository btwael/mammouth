import "./source.dart";

//*-- ErrorSeverity
/**
 * The severity of an error type.
 */
class ErrorSeverity implements Comparable<ErrorSeverity> {
    final String _name;
    final int _ordinal;
    final String _machineCode;

    const ErrorSeverity(this._name, this._ordinal, this._machineCode);

    /**
     * Returns the name of this severity.
     */
    String get name {
        return this._name;
    }

    /**
     * Returns the ordinal of this severity.
     */
    int get ordinal {
        return this._ordinal;
    }

    /**
     * Returns the machine code of this severity.
     */
    String get machineCode {
        return this._machineCode;
    }

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
    final String _name;
    final ErrorSeverity _severity;

    const ErrorType(this._name, this._severity);

    /**
     * Returns the name of this error type.
     */
    String get name {
        return this._name;
    }

    /**
     * Returns the severity of this error type.
     */
    ErrorSeverity get severity {
        return this._severity;
    }

    static const ErrorType SYNTACTIC_ERROR = const ErrorType("SYNTACTIC_ERROR", ErrorSeverity.ERROR);
}

//*-- ErrorCode
/**
 * An error code associated with an `AnalysisError`.
 */
class ErrorCode {
    final String _name;
    final String _message;
    final String _correction;
    final ErrorType _errorType;

    const ErrorCode(this._name, this._message, this._errorType, [this._correction = null]);

    /**
     * Returns the name of this error code.
     */
    String get name {
        return this._name;
    }

    /**
     * Returns the template used to create the message to be displayed for this error.
     */
    String get message {
        return this._message;
    }

    /**
     * Returns the template used to create the correction to be displayed for this error.
     */
    String get correction {
        return this._correction;
    }

    /**
     * Returns the type of this error code.
     */
    ErrorType get type {
        return this._errorType;
    }

    /**
     * Returns the severity of the error code.
     */
    ErrorSeverity get severity {
        return this._errorType.severity;
    }
}

//*-- AnalysisError
/**
 * An error discovered during the analysis of some source code.
 */
class AnalysisError {
    String _message;
    String _correction;
    final ErrorCode _errorCode;
    final Source _source;
    int _offset;
    int _length;

    AnalysisError(this._source, this._offset, this._length, this._errorCode, [List<String> arguments = null]) {
        if(arguments != null) {
            this._message = _formatPatternArguments(this._errorCode.message, arguments);
        } else {
            this._message = this._errorCode.message;
        }
        if(this._errorCode.correction != null) {
            if(arguments != null) {
                this._correction = _formatPatternArguments(this._errorCode.correction, arguments);
            } else {
                this._correction = this._errorCode.correction;
            }
        }
    }

    /**
     * Returns the character offset from the beginning of the source (zero based) where
     * the error occurred.
     */
    int get offset {
        return this._offset;
    }

    /**
     * Returns the number of characters from the offset to the end of the source which
     * encompasses the compilation error.
     */
    int get length {
        return this._length;
    }

    /**
     * Returns the localized error message.
     */
    String get message {
        return this._message;
    }

    /**
     * Returns the correction to be displayed for this error, or `null` if there is no
     * correction information for this error.
     */
    String get correction {
        return this._correction;
    }

    /**
     * Returns the error code associated with the error.
     */
    ErrorCode get code {
        return this._errorCode;
    }

    /**
     * Returns the source in which the error occurred.
     */
    Source get source {
        return this._source;
    }

    String _formatPatternArguments(String pattern, List<String> arguments) {
        if(arguments.isEmpty) {
            return pattern;
        }
        return pattern.replaceAllMapped(new RegExp(r'\{([0-9]+)\}'), (Match match) => arguments[int.parse(match.group(1))]);
    }
}
