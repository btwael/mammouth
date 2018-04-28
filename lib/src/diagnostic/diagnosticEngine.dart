import "../basic/source.dart" show Source;
import "./error.dart" show AnalysisError;

class DiagnosticEngine {
    Map<Source, List<AnalysisError>> _errors = new Map<Source, List<AnalysisError>>();

    void report(Source source, AnalysisError error) {
        if(!this._errors.containsKey(source)) {
            this._errors[source] = new List<AnalysisError>();
        }
        this._errors[source].add(error);
    }

    List<AnalysisError> get(Source source) {
        if(this._errors.containsKey(source)) {
            return this._errors[source];
        }
        return new List<AnalysisError>();
    }
}
