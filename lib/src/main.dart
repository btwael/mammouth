import "./diagnostic/diagnosticEngine.dart";
import "./diagnostic/error.dart";
import "./grammar/token.dart";
import "./grammar/scanner.dart";
import "./grammar/parser.dart";
import "./basic/source.dart";
import "./ast/ast.dart" as ast;

void main() {
    Source s = new BasicSource("wael{{\n int m = j\n int l = 12\n j = m = 3}}");
    DiagnosticEngine de = new DiagnosticEngine();
    Scanner scanner = new Scanner(de);
    scanner.setInput(s);
    scanner.scanAll().forEach((token) {
        print("${token.kind.name}${token.kind != TokenKind.LINEFEED && token.lexeme != null ? '[' + token.lexeme + ']' : ''}");
    });
    de.get(s).forEach((AnalysisError error) {
        print(error.message);
    });
    Parser parser = new Parser(de);
    parser.setInput(scanner.scanAll());
    //print((((parser.parseDocument().some.elements[1] as ast.Script).body.statements.first as ast.ExpressionStatement).expression as ast.SimpleIdentifier).name);
    print(((parser.parseDocument().some.elements[1] as ast.Script).body.statements[1] as ast.VariableDeclarationStatement).initializer.value);
}
