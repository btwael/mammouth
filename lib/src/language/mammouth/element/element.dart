library mammouth.language.mammouth.element.element;

import 'package:mammouth/src/language/common/ast/visibility.dart';
import 'package:mammouth/src/language/mammouth/ast/ast.dart' as ast;
import 'package:mammouth/src/language/mammouth/type/type.dart';
import 'package:mammouth/src/language/php/ast/ast.dart' as php;
import 'package:mammouth/src/language/php/element/element.dart' as php;
import "package:mammouth/src/semantic/typeChecker.dart";

//*-- ClassElement
abstract class ClassElement implements TypeDefiningElement {
  List<ClassMemberElement> get members;

  List<String> get memberNames;

  VariableElement thisElement;

  List<ConstructorElement> get constructors;

  List<FieldElement> get fields;

  List<MethodElement> get methods;

  List<OperatorElement> get operators;

  List<ConverterElement> get converters;

  void addMember(ClassMemberElement member);

  void setup();

  List<ClassMemberElement> getElementsOf(String name);

  ast.ClassExpression node;

  MammouthType instantiate([List<
      MammouthType> typeArguments, TypeChecker tc, MammouthType dynamicType]);
}

//*-- ClassMemberElement
abstract class ClassMemberElement implements Element {
  bool get isOverride {
    return this.overrided != null;
  }

  ClassMemberElement get overrided;

  void set overrided(ClassMemberElement node);

  bool isOverrided = false;

  Visibility visibility;

  TypeDefiningElement get enclosingElement;

  void set enclosingElement(TypeDefiningElement element);

  ast.ClassMember node;
}

//*-- ConstructorElement
abstract class ConstructorElement extends ExecutableClassMemberElement {
  int id;

  @override
  bool get isOverloaded;

  @override
  void set isOverloaded(bool node);

  @override
  ConstructorElement get overrided;

  @override
  void set overrided(ClassMemberElement node);

  @override
  ast.ConstructorDeclaration get node;

  void set node(ast.ClassMember node);

  @override
  String get name {
    return "";
  }
}

//*-- Element
abstract class Element {
  String get name;
}

//*-- ExecutableClassMemberElement
abstract class ExecutableClassMemberElement extends ClassMemberElement
    implements ExecutableElement {
  bool get isOverloaded;

  void set isOverloaded(bool node);

  @override
  ExecutableClassMemberElement get overrided;

  @override
  void set overrided(ClassMemberElement node);

  php.NameElement resultName;

  MammouthType get enclosingType {
    return this.enclosingElement.type;
  }

  @override
  ast.ExecutableClassMember get node;

  @override
  void set node(ast.ClassMember node);
}

//*-- ExecutableElement
/**
 * An element representing an executable: function, method, constructor...
 */
abstract class ExecutableElement implements Element {
  ast.Executable get node;

  MammouthType returnType;

  List<ParameterElement> get parameters;

  FunctionType get type;
}

//*-- FieldElement
abstract class FieldElement extends ClassMemberElement {
  ClassElement get enclosingElement;

  void set enclosingElement(TypeDefiningElement element);

  @override
  ClassMemberElement get overrided;

  @override
  void set overrided(ClassMemberElement node);

  MammouthType type;

  @override
  ast.FieldDeclaration get node;

  @override
  void set node(ast.ClassMember node);
}

//*-- FunctionElement
abstract class FunctionElement implements ExecutableElement {
  @override
  ast.FunctionExpression node;
}

//*-- InterfaceElement
abstract class InterfaceElement implements TypeDefiningElement {
  /**
   * Members of the class, an unique name may refers to many members.
   */
  List<ClassMemberElement> get members;

  List<String> get memberNames;

  List<ConstructorElement> get constructors;

  List<MethodElement> get methods;

  List<OperatorElement> get operators;

  List<ConverterElement> get converters;

  void addMember(ClassMemberElement member);

  void setup();

  /**
   * Return an iterable of members with given [name].
   */
  List<ClassMemberElement> getElementsOf(String name);
}

//*-- MethodElement
abstract class MethodElement extends ExecutableClassMemberElement {
  @override
  bool get isOverloaded;

  @override
  void set isOverloaded(bool node);

  @override
  MethodElement get overrided;

  @override
  void set overrided(Element node);

  @override
  ast.MethodDeclaration get node;

  @override
  void set node(ast.ClassMember node);

  bool get isGetter {
    return this.node.isGetter;
  }

  bool get isSetter {
    return this.node.isSetter;
  }
}

//*-- OperatorElement
abstract class OperatorElement extends ExecutableClassMemberElement {
  @override
  bool get isOverloaded;

  @override
  void set isOverloaded(bool node);

  @override
  OperatorElement get overrided;

  @override
  void set overrided(Element node);

  @override
  ast.OperatorDeclaration get node;

  @override
  void set node(ast.ClassMember node);
}

//*-- OperatorElement
abstract class ConverterElement extends ExecutableClassMemberElement {
  @override
  bool get isOverloaded {
    return false;
  }

  @override
  void set isOverloaded(bool node) {
    // TODO: do nothing
  }

  @override
  ConverterElement get overrided;

  @override
  void set overrided(Element node);

  String get name {
    return "->";
  }

  List<ParameterElement> get parameters {
    return [];
  }

  @override
  ast.ConverterDeclaration get node;

  @override
  void set node(ast.ClassMember node);
}

//*-- ParameterElement
abstract class ParameterElement implements VariableElement {}

//*-- TypeDefiningElement
abstract class TypeDefiningElement implements Element {

  MammouthType type;
}

//*-- TypeParameterElement
abstract class TypeParameterElement implements TypeDefiningElement {}

//*-- VariableElement
abstract class VariableElement implements Element {

  MammouthType type;

  php.AstNode effectiveValue;
}
