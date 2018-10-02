import "package:path/path.dart" as p;
import "package:yaml/yaml.dart" show loadYaml, YamlMap;

import 'package:mammouth/src/basic/fileSystem/abstractDirectory.dart';
import 'package:mammouth/src/basic/fileSystem/abstractFile.dart';
import 'package:mammouth/src/basic/fileSystem/abstractFileSystemEntity.dart';
import 'package:mammouth/src/basic/session.dart' show Package, Session;
import 'package:mammouth/src/basic/option.dart' show Option;
import 'package:mammouth/src/basic/source.dart' show Source, BasicSource;
import 'package:mammouth/src/diagnostic/diagnosticEngine.dart'
    show DiagnosticEngine;
import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/common/ast/token.dart" show Token;
import "package:mammouth/src/language/php/version.dart" as php;
import "package:mammouth/src/syntactic/lexer.dart";
import "package:mammouth/src/syntactic/parser.dart";
import "package:mammouth/src/semantic/parentResolver.dart";
import "package:mammouth/src/semantic/elementBuilder.dart";
import "package:mammouth/src/semantic/typeChecker.dart";
import "package:mammouth/src/codegen/codegen.dart";
import "package:mammouth/src/codegen/docgen.dart";
import "package:mammouth/src/codegen/resolver.dart";

import 'package:mammouth/sdk/core.dart' as SDKContent;

class Mammouth {
  void compileFile(Source source, Session session, {String target}) {
    DiagnosticEngine de = new DiagnosticEngine();
    Lexer lexer = new Lexer(de);
    lexer.setInput(source);
    Token token = lexer.scanAll();
    Parser parser = new Parser(de);
    parser.setInput(source, token);
    common.Document document = parser
        .parseDocument()
        .some; // TODO: get option, then go
    TypeChecker tc = new TypeChecker(source, session, de);

    // inject SDK and core libraries
    Source coreSource = new BasicSource(SDKContent.content);
    lexer.setInput(coreSource);
    parser.setInput(coreSource, lexer.scanAll());
    common.Document coreDocument = parser
        .parseDocument()
        .some;
    coreDocument.accept(new ElementBuilder());
    coreDocument.accept(tc);

    tc.setSource(source);
    document.accept(new ParentResolver());
    document.accept(new ElementBuilder());
    document.accept(
        new TypeChecker(source, session, de, parentScope: tc.scopeStack.last));
    String result = (document.accept(
        new CodeGenerator(session, source)) as common
        .Document).accept(
        new PHPResultResolver()).accept(new DocumentGenerator());
    if(target == null) {
      target = source.uri.path.replaceAll(new RegExp(r"\.mammouth$"), "");
      target += ".php";
    }
    session.fileSystem.writeFile(target, result);
  }

  void compileFolder(String path, String target, Session session) {
    String targetx = target ?? path;
    Option<AbstractDirectory> dirResult = session.fileSystem.getDirectory(path);
    if(dirResult.isSome && dirResult.some.exist) {
      AbstractDirectory directory = dirResult.some;
      Iterable<AbstractFileSystemEntity> content = directory.content;
      session.fileSystem.createDir(targetx);
      content.forEach((AbstractFileSystemEntity entity) {
        if(entity is Source) {
          compileFile(entity, session,
              target: p.join(targetx, entity.name).replaceAll(
                  new RegExp(r"\.(mmt|mammouth)"), ".php"));
        } else if(entity is AbstractDirectory) {
          compileFolder(
              entity.uri.toString(), p.join(targetx, entity.name), session);
        } else if(entity is AbstractFile) {
          if(entity.name != "mammouth.yaml") {
            session.fileSystem.copyFile(entity, p.join(targetx, entity.name));
          }
        }
      });
    }
  }

  void compilePackage(String path, Session newSession()) {
    Session session = newSession();
    Option<AbstractDirectory> dirResult = session.fileSystem.getDirectory(path);
    if(dirResult.isSome && dirResult.some.exist) {
      Option<Source> packageFileResult = session.fileSystem.getSource(
          dirResult.some.uri.resolve("mammouth.yaml").toFilePath());
      if(packageFileResult.isSome && packageFileResult.some.exist) {
        YamlMap document = loadYaml((packageFileResult.some.content));
        Package package = _constructPackage(document, path);
        session.package = package;
        session.projectRoot = session.fileSystem
            .getDirectory(path)
            .some;
        compileFolder(path, p.join(path, package.buildDir), session);
        if(package.requireRuntime) {
          String runtimePackage = p.join(
              path, package.buildDir, "packages/runtime");
          session.fileSystem.createDir(runtimePackage);
          session.fileSystem.writeFile(p.join(runtimePackage, "runtime.php"), r"""
<?php
function mammouth_get_type($object) {
return gettype($object);
}
function mammouth_is_assignableTo($type1, $type2) {
$other = $type2;
$otheri = is_subclass_of($type1, $type2);
return $type1 == $other || $otheri;
}
function mammouth_call_method($object, $methodName) {
$arguments = func_get_args();
$argumentTypes = array();
for($i = 2; $i < count($arguments); $i++) {
$index = $i;
$element = mammouth_get_type($arguments[$index]);
array_push($argumentTypes, $element);
}
if(property_exists($object, "__mmt_runtime_map")) {
$other = 2;
foreach($object::$__mmt_runtime_map[$methodName][count($arguments) - $other] as $method => $types) {
$isValid = TRUE;
for($i = 1; $i < count($types); $i++) {
$index = $i;
$type = $types[$index];
$other = 1;
$indexi = $i - $other;
if(!mammouth_is_assignableTo($argumentTypes[$indexi], $type)) {
$isValid = FALSE;
break;
}
}
if($isValid) {
$result = $method;
break;
}
}
if(isset($result)) {
$start = 2;
$end = count($arguments) + 1;
$other = $start;
return call_user_func_array(array($object, $result), array_slice($arguments, $start, $end - $other));
} else throw "error";
} else {
switch(mammouth_get_type($object)) {
case "string":
switch($methodName) {
case "operator+":
$index = 2;
$other = $arguments[$index];
return ((string) $object).$other;
case "operator==":
$index = 2;
$other = $arguments[$index];
return ((string) $object) == $other;
case "operator!=":
$index = 2;
$other = $arguments[$index];
return ((string) $object) != $other;
}
}
throw "error";
}
}
function mammouth_call_converter($object, $targetType) {
if(property_exists($object, "__mmt_runtime_map")) {
foreach($object::$__mmt_runtime_map["->"][0] as $method => $types) {
$index = 0;
if(mammouth_is_assignableTo($targetType, $types[$index])) {
$result = $method;
break;
}
}
if(isset($result)) return call_user_func_array(array($object, $result), array()); else throw "error";
} else throw "error";
}
function mammouth_call_getter($object, $getterName) {
if(property_exists($object, "__mmt_runtime_map")) {
foreach($object::$__mmt_runtime_map[$getterName][0] as $method => $types) {
$result = $method;
break;
}
if(isset($result)) call_user_func_array(array($object, $result), array());
throw "error";
} else {
switch(mammouth_get_type($object)) {
case "string":
switch($getterName) {
case "length":
return strlen(((string) $object));
case "isEmpty":
$other = 0;
return strlen(((string) $object)) == $other;
case "isNotEmpty":
$other = 0;
return strlen(((string) $object)) != $other;
}
}
throw "error";
}
}
function mammouth_call_setter($object, $setterName, $value) {
if(property_exists($object, "__mmt_runtime_map")) {
foreach($object::$__mmt_runtime_map[$setterName][1] as $method => $types) {
$index = 1;
if(mammouth_is_assignableTo(mammouth_get_type($value), $types[$index])) {
$result = $method;
break;
}
}
if(isset($result)) return call_user_func_array(array($object, $result), array($value)); else throw "error";
} else throw "error";
}
          """);
        }
      } else {
        // TODO:
      }
    } else {
      // TODO:
    }
  }

  Package _constructPackage(YamlMap document, String path) {
    return new Package()
      ..name = document["name"] ?? p.basename(path)
      ..target = new php.Version.fromString(document["php"] ?? "7.2.9")
      ..buildDir = document["output"] ?? "build";
  }
}