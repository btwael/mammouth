import "./diagnostic/diagnosticEngine.dart";
import "./diagnostic/error.dart";
import "./grammar/token.dart";
import "./grammar/scanner.dart";
import "./basic/source.dart";

void main() {
    Source s = new BasicSource("wael is cool{{\nfirst\n if !j << m\n sdfds\n   t}}");
    DiagnosticEngine de = new DiagnosticEngine();
    Scanner scanner = new Scanner(de);
    scanner.setInput(s);
    scanner.scanAll().forEach((token) {
        print("${token.kind.name}${token.kind != TokenKind.LINEFEED && token.lexeme != null ? '[' + token.lexeme + ']' : ''}");
    });
    de.get(s).forEach((AnalysisError error) {
        print(error.message);
    });
}
