import "package:mammouth/src/basic/source.dart";
import "package:mammouth/src/diagnostic/diagnosticEngine.dart"
    show DiagnosticEngine;
import "package:mammouth/src/diagnostic/error.dart";
import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/common/ast/token.dart"
    show TokenKind, Token;
import "package:mammouth/src/language/php/version.dart";
import "package:mammouth/src/platform/vm/fileSystem.dart";
import "package:mammouth/src/platform/vm/session.dart";
import "package:mammouth/src/syntactic/lexer.dart";
import "package:mammouth/src/syntactic/parser.dart";
import "package:mammouth/src/semantic/parentResolver.dart";
import "package:mammouth/src/semantic/elementBuilder.dart";
import "package:mammouth/src/semantic/typeChecker.dart";
import "package:mammouth/src/codegen/codegen.dart";
import "package:mammouth/src/codegen/docgen.dart";
import "package:mammouth/src/codegen/resolver.dart";

/**
    (1)
 * TODO: argument, parameter, loop variable by reference
 * TODO: fix echo in while expression between
 * TODO: Check visibility on implements
 * TODO: more if and while as statement with expression
 * TODO: add () when needed example "new RGB->__mmt_converter_i()"
    (2)
 * TODO: ?.
 * TODO: heredoc/multiline String
 * TODO: generate .. ? .. : .. for if with just expression
 * TODO: range with step, also in slice
 * TODO: Test slicing more and more
 * TODO: clone
 * TODO: native statement
 * TODO: inline method must not have access to protected and private data / call the non-inlined version
 * TODO: improve visibility
 * TODO: Unused main method Converter
 * TODO: improve runtime functions
 */
String code = r"""
{{
number = 12
float var = 12.3

addVar = fn (x) -> x + x
fn multVar(int x) -> x * x

class RGB
  r
  g
  b
}}
""";

void main() {
  Source bisource = new VMSource("./sdk/core.mammouth");
  Source source = new BasicSource(code);
  DiagnosticEngine de = new DiagnosticEngine();
  Lexer lexer = new Lexer(de);
  lexer.setInput(source);
  Token token = lexer.scanAll();
  while(token != null) {
    print("${token.kind.name}${token.kind != TokenKind.LINE_FEED &&
        token.lexeme != null ? '[' + token.lexeme + ']' : ''}");
    token = token.next;
  }
  de.get(source).forEach((AnalysisError error) {
    print(error.message);
    print(error.offset);
  });
  Parser parser = new Parser(de);
  parser.setInput(source, lexer.scanAll());
  common.Document document = parser
      .parseDocument()
      .some;
  print(document);
  VMSession session = new VMSession()..target = new Version(5,3,0);
  TypeChecker tc = new TypeChecker(bisource, session, de);
  //
  lexer.setInput(bisource);
  parser.setInput(bisource, lexer.scanAll());
  common.Document bidocument = parser
      .parseDocument()
      .some;
  bidocument.accept(new ElementBuilder());
  bidocument.accept(tc);
  //
  tc.setSource(source);
  document.accept(new ParentResolver());
  document.accept(new ElementBuilder());
  document.accept(tc);
  print((document.accept(new CodeGenerator(session, source)) as common.Document).accept(
      new PHPResultResolver()).accept(new DocumentGenerator()));
}
