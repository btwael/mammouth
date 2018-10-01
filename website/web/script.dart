import "dart:html";

import "package:mammouth/sdk/core.dart" as SDKCore;
import "package:mammouth/src/basic/source.dart";
import "package:mammouth/src/basic/session.dart";
import "package:mammouth/src/diagnostic/diagnosticEngine.dart"
    show DiagnosticEngine;
import "package:mammouth/src/diagnostic/error.dart";
import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/common/ast/token.dart" show Token;
import "package:mammouth/src/syntactic/lexer.dart";
import "package:mammouth/src/syntactic/parser.dart";
import "package:mammouth/src/semantic/parentResolver.dart";
import "package:mammouth/src/semantic/elementBuilder.dart";
import "package:mammouth/src/semantic/typeChecker.dart";
import "package:mammouth/src/codegen/codegen.dart";
import "package:mammouth/src/codegen/docgen.dart";
import "package:mammouth/src/codegen/resolver.dart";

int getHeight(Element element) {
  CssStyleDeclaration d = element.getComputedStyle();
  return int.parse(d.height.replaceAll(new RegExp("[a-z]"), ""));
}

/*const Map<String, String> features = const <String, String>{
  r"No '$' sign": r"""
{{
# Whether it's a variable, a parameter, a function or a
# class name, there no need to specify it with a '$' sign.
number = 12
float var = 12.3

addVar = fn (x) -> x + x
fn multVar(int x) ->
  x * x

class RGB
  r
  g
  b
}} 
""",
  "Optional Typing": r"""
{{
number = 12
int integer = 12

arr = []
Array<String> strings = []
Array<String> stringsi = <String>[]

addVar = fn (x) -> x + x
addVar1 = int (int x) ->
  x + x
}}
""",
  "Inline functions": """
{{
addVar = int (int x) inline ->
  x + x
}}
""",
  "Indented blocks": "",
  "Classes": "",
  "Inline methods": "",
  "Expressive": "",
  "Getters & setters": "",
  "Native PHP": ""
};

DivElement selected;*/

void main() {
  Element navbar = querySelector("#navbar");
  Element overview = querySelector("#body-area");
  Element tryView = querySelector("#body-area-try");
  overview.style.display = "inherit";
  tryView.style.display = "none";
  querySelector("#tryButton").onClick.listen((MouseEvent event) {
    navbar.classes.remove("mb-3");
    overview.style.display = "none";
    tryView.style.display = "inherit";
    tryView.style.height =
        (window.innerHeight - getHeight(navbar) - 10).toString() + "px";
  });
  Element outputArea = querySelector("#php-output");
  Element inputArea = querySelector("#mmt-input");
  inputArea.onKeyUp.listen((KeyboardEvent event) {
    try {
      Source bisource = new BasicSource(SDKCore.content);
      Source source = new BasicSource((inputArea as TextAreaElement).value);
      DiagnosticEngine de = new DiagnosticEngine();
      Lexer lexer = new Lexer(de);
      lexer.setInput(source);
      Token token = lexer.scanAll();
      Parser parser = new Parser(de);
      parser.setInput(source, token);
      common.Document document = parser
          .parseDocument()
          .some;
      de.get(source).forEach((AnalysisError error) {
        print(error.message);
        print(error.offset);
      });
      Session session = new WebSession();
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
      outputArea.text =
      ((document.accept(new CodeGenerator(session, source)) as common.Document)
          .accept(new PHPResultResolver())
          .accept(new DocumentGenerator()));
    } on Exception {

    }
  });
  // show features
  /*DivElement row;
  for(int i = 0; i < features.length; i++) {
    if(i % 3 == 0) {
      row = querySelector("#feature-table").append(new DivElement());
      row.classes.add("row");
      if(features.length - i > 3) {
        row.classes.add("mb-1");
      }
    }
    DivElement container = new DivElement()..classes.addAll(["col-4", "feature-btn-container"]);
    DivElement btn = new DivElement()..classes.add("feature-button");
    btn.text = features.keys.elementAt(i);
    container.append(btn);
    row.append(container);
    if(i == 0) {
      selected = btn;
      btn.classes.add("feature-button-active");
      querySelector("#feature-code").text = features.values.elementAt(i);
    }
    btn.onClick.listen((MouseEvent ev) {
      selected.classes.remove("feature-button-active");
      btn.classes.add("feature-button-active");
      selected = btn;
      querySelector("#feature-code").text = features.values.elementAt(i);
    });
  }*/
}
