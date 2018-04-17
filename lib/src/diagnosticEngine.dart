import "./error.dart";
import "./source.dart";

class DiagnosticEngine {
    Map<Source, List<AnalysisError>> _errors = new Map<Source, List<AnalysisError>>();

    void report(Source source, AnalysisError error) {
        if(!this._errors.containsKey(source)) {
            this._errors[source] = new List<AnalysisError>();
        }
        this._errors[source].add(error);
    }
}
