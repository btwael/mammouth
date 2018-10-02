library mammouth.language.mammouth.ast.ast;

import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/common/ast/precedence.dart";
import "package:mammouth/src/language/common/ast/token.dart"
    show TokenKind, Token;
import "package:mammouth/src/language/common/ast/visibility.dart"
    show Visibility;
import "package:mammouth/src/language/common/ast/visitor.dart" show Visitor;
import "package:mammouth/src/language/mammouth/element/element.dart";
import "package:mammouth/src/language/mammouth/type/type.dart";
import "package:mammouth/src/semantic/scope.dart" show Scope;

//*-- ArgumentList
/**
 * List of arguments.
 */
abstract class ArgumentList extends AstNode {
  /**
   * An iterable over the list of arguments.
   */
  List<Expression> get arguments;

  /**
   * `true` if this is empty, `false` otherwise.
   */
  bool get isEmpty {
    return this.arguments.isEmpty;
  }

  /**
   * `true` if this is not empty, `false` otherwise.
   */
  bool get isNotEmpty {
    return this.arguments.isNotEmpty;
  }

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    if(this.arguments.isEmpty) {
      return null;
    }
    return this.arguments.first.beginToken;
  }

  @override
  Token get endToken {
    if(this.arguments.isEmpty) {
      return null;
    }
    return this.arguments.last.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitArgumentList(this);
  }
}

//*-- ArrayLiteral
/**
 * An array literal.
 */
abstract class ArrayLiteral extends TypedLiteral {
  @override
  TypeArgumentList get typeArguments;

  /**
   * The type of elements.
   */
  TypeAnnotation get elementType {
    if(this.typeArguments.isEmpty) {
      return null;
    }
    return this.typeArguments.arguments.first;
  }

  /**
   * The left bracket token.
   */
  Token get leftBracket;

  /**
   * List over arguments expression.
   */
  List<Expression> get elements;

  /**
   * The right bracket token.
   */
  Token get rightBracket;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    if(this.isTyped) {
      return this.typeArguments.beginToken;
    }
    return this.leftBracket;
  }

  @override
  Token get endToken {
    return this.rightBracket;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitArrayLiteral(this);
  }
}

//*-- AsExpression
abstract class AsExpression extends Expression {
  Expression get argument;

  Token get asKeyword; // TODO: operator

  TypeAnnotation get type;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  Token get beginToken {
    return this.argument.beginToken;
  }

  @override
  Token get endToken {
    return this.type.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitAsExpression(this);
  }
}

//*-- AssignmentExpression
/**
 * An assignment expression.
 */
abstract class AssignmentExpression extends Expression {
  /**
   * The expression to compute the left hand side of the assignment.
   */
  Expression get left;

  /**
   * The assignment operator.
   */
  AssignmentOperator get operator;

  /**
   * The expression to compute the right hand side of the assignment.
   */
  Expression get right;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  MethodElement get setterElement;

  void set setterElement(MethodElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.left.beginToken;
  }

  @override
  Token get endToken {
    return this.right.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitAssignmentExpression(this);
  }
}

//*-- AssignmentOperator
/**
 * An assignment operator.
 */
abstract class AssignmentOperator extends Operator {
  @override
  Token get token;

  @override
  String get lexeme;

  @override
  AssignmentExpression get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitAssignmentOperator(this);
  }
}

//*-- AstNode
/**
 * The base class of all mammouth node in AST structure.
 *
 * Remark: This is different from `common.AstNode`.
 */
abstract class AstNode extends common.AstNode {
  @override
  common.AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  Set<Element> usedElements = new Set<Element>();

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- AtExpression
/**
 * Expression to access property of `this` in the body of an executable class
 * member like constructors, methods, getters and setters.
 */
abstract class AtExpression extends ElementReferenceExpression {
  /**
   * The "at" (@) token.
   */
  Token get atToken;

  /**
   * The name of the property being accessed.
   */
  SimpleIdentifier get property;

  @override
  List<Element> get candidateElements;

  @override
  void set candidateElements(List<Element> element);

  @override
  Element get referredElement;

  @override
  void set referredElement(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.atToken;
  }

  @override
  Token get endToken {
    return this.property.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitAtExpression(this);
  }
}

//*-- BinaryExpression
/**
 * A binary expression.
 */
abstract class BinaryExpression extends Expression {
  /**
   * The expression to compute the left operand.
   */
  Expression get left;

  /**
   * The binary operator.
   */
  BinaryOperator get operator;

  /**
   * The expression to compute the right operand.
   */
  Expression get right;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  Scope get scope;

  @override
  void set scope(Scope scope);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  OperatorElement get operatorElement;

  void set operatorElement(OperatorElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.left.beginToken;
  }

  @override
  Token get endToken {
    return this.right.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitBinaryExpression(this);
  }
}

//*-- BinaryOperator
/**
 * A binary operator.
 */
abstract class BinaryOperator extends Operator {
  @override
  Token get token;

  @override
  String get lexeme;

  /**
   * The binary operator's precedence.
   */
  Precedence get precedence;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitBinaryOperator(this);
  }
}

//*-- Block
/**
 * A block of statements
 */
abstract class Block extends Statement {
  /**
   * List over statements constituting the block.
   */
  List<Statement> get statements;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    if(this.statements.isNotEmpty) {
      return this.statements.first.beginToken;
    }
    return null;
  }

  @override
  Token get endToken {
    if(this.statements.isNotEmpty) {
      return this.statements.last.endToken;
    }
    return null;
  }

  @override
  E accept<E>(Visitor<E> visitor, {bool scope = true}) {
    return visitor.visitBlock(this, scope: scope);
  }
}

//*-- BooleanLiteral
/**
 * A boolean literal.
 */
abstract class BooleanLiteral extends SingleTokenLiteral {
  @override
  Token get token;

  @override
  bool get value {
    return this.raw == "true";
  }

  @override
  String get raw;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitBooleanLiteral(this);
  }
}

//*-- BreakStatement
/**
 * A break statement.
 */
abstract class BreakStatement extends Statement {
  /**
   * The break keyword.
   */
  Token get breakKeyword;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.breakKeyword;
  }

  @override
  Token get endToken {
    return this.breakKeyword;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitBreakStatement(this);
  }
}

//*-- ClassExpression
/**
 * An expression defining a class.
 */
abstract class ClassExpression extends Expression implements Declaration {
  /**
   * The class keyword.
   */
  Token get classKeyword;

  /**
   * The name of the class, or `null` if this is an anonymous class.
   */
  SimpleIdentifier get name;

  TypeParameterList get typeParameters;

  ExtendsClause get extendsClause;

  ImplementsClause get implementsClause;

  /**
   * List over members of this class.
   */
  List<ClassMember> get members;

  /**
   * `true` if this is an anonymous class, `false` otherwise.
   */
  bool get isAnonymous {
    return this.name == null;
  }

  bool get hasSuperclass {
    return this.extendsClause != null;
  }

  bool get doesImplementsInterface {
    return this.implementsClause != null;
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  ClassElement get element;

  /**
   * Sets the associated element with this class declaration.
   */
  void set element(ClassElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.classKeyword;
  }

  @override
  Token get endToken {
    if(this.members.isNotEmpty) {
      return this.members.last.endToken;
    }
    if(!this.isAnonymous) {
      return this.name.endToken;
    }
    return null;
  }

  @override
  E accept<E>(Visitor<E> visitor, {InterfaceType type}) {
    return visitor.visitClassExpression(this, type: type);
  }
}

//*-- ClassMember
/**
 * A base class for class members
 */
abstract class ClassMember extends AstNode implements Declaration {
  /**
   * The visibility token, `null` if no explicit visibility is cited.
   */
  Token get visibilityToken;

  /**
   * The visibility of this member.
   */
  Visibility get visibility {
    if(this.visibilityToken == null) {
      return Visibility.DEFAULT;
    } else {
      if(this.isPrivate) {
        return Visibility.PRIVATE;
      } else if(this.isProtected) {
        return Visibility.PROTECTED;
      }
      return Visibility.PUBLIC;
    }
  }

  /**
   * `true` if this is explicitly a private member.
   */
  bool get isPrivate {
    return this.visibilityToken != null &&
        this.visibilityToken.kind == TokenKind.PRIVATE;
  }

  /**
   * `true` if this is explicitly a protected member.
   */
  bool get isProtected {
    return this.visibilityToken != null &&
        this.visibilityToken.kind == TokenKind.PROTECTED;
  }

  /**
   * `true` if this is explicitly or implicitly a public member.
   */
  bool get isPublic {
    return this.visibilityToken == null ||
        this.visibilityToken.kind == TokenKind.PUBLIC;
  }

  @override
  ClassMemberElement get element;

  /**
   * Sets the associated element with this member declaration.
   */
  void set element(ClassMemberElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- ClosureParameter
abstract class ClosureParameter extends Parameter {
  TypeAnnotation get returnType;

  @override
  SimpleIdentifier get name;

  Token get leftParenthesis;

  List<TypeAnnotation> get parameterTypes;

  Token get rightParenthesis;

  @override
  bool get isTyped => true;

  @override
  bool get isOptional;

  @override
  bool get isInitialized => false;

  @override
  Token get beginToken => this.returnType.beginToken;

  @override
  Token get endToken => this.rightParenthesis;

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitClosureParameter(this);
  }
}

//*-- ConstructorDeclaration
/**
 * A constructor declaration in a class declaration.
 */
abstract class ConstructorDeclaration extends ExecutableClassMember {
  @override
  Token get visibilityToken;

  /**
   * The constructor keyword
   */
  Token get constructorKeyword;

  @override
  ParameterList get parameters;

  @override
  Token get inlineKeyword;

  @override
  Token get arrow;

  @override
  Block get body;

  @override
  TypeAnnotation get returnType {
    return null;
  }

  @override
  bool get hasReturnType {
    return false;
  }

  @override
  bool get hasParameters {
    return this.parameters != null;
  }

  @override
  bool get isInline;

  @override
  ConstructorElement get element;

  @override
  void set element(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.constructorKeyword;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitConstructorDeclaration(this);
  }
}

//*-- ContinueStatement
/**
 * A continue statement.
 */
abstract class ContinueStatement extends Statement {
  /**
   * The continue keyword.
   */
  Token get continueKeyword;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.continueKeyword;
  }

  @override
  Token get endToken {
    return this.continueKeyword;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitContinueStatement(this);
  }
}

//*-- ConverterDeclaration
abstract class ConverterDeclaration extends ExecutableClassMember {
  Token get abstractKeyword;

  @override
  Token get visibilityToken;

  @override
  TypeAnnotation get returnType;

  /**
   * The `to` keyword.
   */
  Token get toKeyword;

  @override
  ParameterList get parameters {
    return null;
  }

  @override
  Token get inlineKeyword;

  @override
  Token get arrow;

  @override
  Block get body;

  bool get isAbstract {
    return this.isAbstract != null;
  }

  @override
  bool get hasReturnType {
    return true;
  }

  @override
  bool get hasParameters {
    return false;
  }

  @override
  bool get isInline {
    return this.inlineKeyword != null;
  }

  @override
  ConverterElement get element;

  @override
  void set element(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.toKeyword;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitConverterDeclaration(this);
  }
}

//*-- Declaration
/**
 * A declaration must implement this interface.
 */
abstract class Declaration {
  /**
   * The element associated with this declaration
   */
  Element get element;
}

//*-- EchoExpression
/**
 * An echo expression.
 */
abstract class EchoExpression extends Expression {
  /**
   * The `echo`keyword.
   */
  Token get echoKeyword;

  /**
   * The expression to compute the value to be printed.
   */
  Expression get argument;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.echoKeyword;
  }

  @override
  Token get endToken {
    return this.argument.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitEchoExpression(this);
  }
}

//*-- ElementReferenceExpression
/**
 * An expression that may refer to one or many elements.
 */
abstract class ElementReferenceExpression extends Expression {
  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  /**
   * To support overloading, an expression may refers to many elements during the
   * resolving-time.
   */
  List<Element> get candidateElements;

  void set candidateElements(List<Element> element);

  /**
   * The referred element, or `null` if this expression does not refer to any
   * element, such situation may occur if this is a SimpleIdentifier or the
   * referred element is not found/declared.
   */
  Element get referredElement;

  void set referredElement(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- Executable
/**
 * An executable node must implements this interface.
 */
abstract class Executable extends AstNode implements Declaration {
  /**
   * The return type of the executable.
   */
  TypeAnnotation get returnType;

  /**
   * Parameters of this executable.
   */
  ParameterList get parameters;

  /**
   * The inline keyword if this is an inline function.
   */
  Token get inlineKeyword;

  /**
   * The right arrow token.
   */
  Token get arrow;

  /**
   * The body of the executable.
   */
  Block get body;

  /**
   * `true` if this has a parameters list, `false` otherwise.
   */
  bool get hasParameters {
    return this.parameters != null;
  }

  /**
   * `true` if this is an inline executable, `false` otherwise.
   */
  bool get isInline {
    return this.inlineKeyword != null;
  }

  @override
  ExecutableElement get element;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- ExecutableClassMember
abstract class ExecutableClassMember extends ClassMember implements Executable {
  @override
  Token get visibilityToken;

  @override
  TypeAnnotation get returnType;

  @override
  ParameterList get parameters;

  @override
  Token get inlineKeyword;

  @override
  Token get arrow;

  @override
  Block get body;

  bool get isSignature {
    return this.body == null;
  }

  @override
  bool get hasReturnType {
    return this.returnType != null;
  }

  @override
  bool get hasParameters {
    return this.parameters != null;
  }

  @override
  bool get isInline {
    return this.inlineKeyword != null;
  }

  @override
  ExecutableClassMemberElement get element;

  @override
  void set element(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- ExistenceExpression
/**
 * An expression to determine if a variable is set and is not null.
 */
abstract class ExistenceExpression extends Expression {
  /**
   * The expression to compute the variable to be verified if it iss set and is
   * not null.
   */
  ElementReferenceExpression get argument;

  /**
   * The question mark token.
   */
  Token get questionMark;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.argument.beginToken;
  }

  @override
  Token get endToken {
    return this.questionMark;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitExistenceExpression(this);
  }
}

//*-- Expression
/**
 * The base class of all expressions.
 */
abstract class Expression extends AstNode {
  /**
   * `true` if this expression is used as a statement, or `false` otherwise.
   */
  bool get asStatement;

  /**
   * Sets `true` if this is used as statement, or `false` otherwise.
   */
  void set asStatement(bool value);

  Scope get scope;

  void set scope(Scope scope);

  ConverterElement get converterElement;

  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- ExpressionStatement
/**
 * An expression used as a statement.
 */
abstract class ExpressionStatement extends Statement {
  /**
   * The expression being used as statement.
   */
  Expression get expression;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.expression.beginToken;
  }

  @override
  Token get endToken {
    return this.expression.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitExpressionStatement(this);
  }
}

//*-- ExtendsClause
abstract class ExtendsClause extends AstNode {
  Token get extendsKeyword;

  TypeName get superclass;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.extendsKeyword;
  }

  @override
  Token get endToken {
    return this.superclass.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitExtendsClause(this);
  }
}

//*-- FieldDeclaration
/**
 * A field declaration in a class declaration.
 */
abstract class FieldDeclaration extends ClassMember {
  @override
  Token get visibilityToken;

  Token get staticKeyword;

  /**
   * The type of the field being declared, or `null` if no type is given.
   */
  TypeAnnotation get type;

  /**
   * The name of the field being declared.
   */
  SimpleIdentifier get name;

  /**
   * The assignment token if the field is initialized, `null` otherwise.
   */
  Token get equal;

  /**
   * The expression used to compute the initial value for the field, or
   * `null` if the variable is not initialized.
   */
  Expression get initializer;

  /**
   * `true` if the declared field has a specified type, `false` otherwise.
   */
  bool get isTyped {
    return this.type != null;
  }

  /**
   * `true` if the declared field is to be initialized, `false` otherwise.
   */
  bool get isInitialized {
    return this.initializer != null;
  }

  bool get isStatic;

  @override
  FieldElement get element;

  @override
  void set element(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    if(this.type != null) {
      return this.type.beginToken;
    }
    return this.name.beginToken;
  }

  @override
  Token get endToken {
    if(this.equal != null) {
      return this.initializer.endToken;
    }
    return this.name.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitFieldDeclaration(this);
  }
}

//*-- FloatLiteral
/**
 * A float literal.
 */
abstract class FloatLiteral extends SingleTokenLiteral {
  @override
  Token get token;

  @override
  num get value {
    return num.parse(this.raw);
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitFloatLiteral(this);
  }
}

//*-- ForExpression
abstract class ForExpression extends Expression {
  /**
   * The for source.
   */
  ForSource get source;

  Statement get body;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.source.beginToken;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitForExpression(this);
  }
}

//*-- ForSource
abstract class ForSource extends AstNode {
  Token get forKeyword;

  GuardSource get guard;

  bool get hasGuard {
    return this.guard != null;
  }

  @override
  ForExpression get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.forKeyword;
  }

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- ForRangeSource
abstract class ForRangeSource extends ForSource {
  RangeLiteral get source;

  Token get asKeyword;

  ForVariable get name;

  Token get byKeyword;

  Expression get step;

  bool get hasName {
    return this.name != null;
  }

  bool get hasStep {
    return this.step != null;
  }

  @override
  ForExpression get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get endToken {
    if(this.hasGuard) {
      return this.guard.endToken;
    }
    if(this.hasName && this.hasStep) {
      if(this.name.endOffset < this.step.endOffset) {
        return this.step.endToken;
      } else {
        return this.name.endToken;
      }
    }
    if(this.hasName && !this.hasStep) {
      return this.name.endToken;
    }
    if(!this.hasName && this.hasStep) {
      return this.step.endToken;
    }
    return this.source.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitForRangeSource(this);
  }
}

//*-- ForVariable
// TODO: replace this with SimpleParameter
abstract class ForVariable extends AstNode {
  TypeAnnotation get type;

  SimpleIdentifier get name;

  bool get isTyped {
    return this.type != null;
  }

  VariableElement get element;

  void set element(VariableElement element);

  @override
  ForSource get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    if(this.isTyped) {
      return this.type.beginToken;
    }
    return this.name.beginToken;
  }

  @override
  Token get endToken {
    return this.name.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitForVariable(this);
  }
}


enum ForVariableSourceKind {
  IN,
  OF
}
//*-- ForVariableSource
abstract class ForVariableSource extends ForSource {
  ForVariable get firstVariable;

  ForVariable get secondVariable;

  Token get inKeyword;

  Token get ofKeyword;

  ForVariableSourceKind get kind;

  Expression get source;

  Token get byKeyword;

  Expression get step;

  bool get hasSecondVariable {
    return this.secondVariable != null;
  }

  bool get hasStep {
    return this.step != null;
  }

  @override
  ForExpression get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get endToken {
    if(this.hasGuard) {
      return this.guard.endToken;
    }
    if(this.hasStep) {
      return this.step.endToken;
    }
    return this.source.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitForVariableSource(this);
  }
}

//*-- FunctionExpression
/**
 * A function expression.
 */
abstract class FunctionExpression extends Expression implements Executable {
  @override
  TypeAnnotation get returnType;

  /**
   * The name of the function, or `null` if it's an anonymous function.
   */
  SimpleIdentifier get name;

  @override
  ParameterList get parameters;

  @override
  Token get inlineKeyword;

  @override
  Token get arrow;

  @override
  Block get body;

  /**
   * `true` if this is not an anonymous function, `false` otherwise.
   */
  bool get isAnonymous {
    return this.name == null;
  }

  @override
  bool get hasParameters {
    return this.parameters != null;
  }

  @override
  bool get isInline {
    return this.inlineKeyword != null;
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  FunctionElement get element;

  /**
   * Sets the associated element to this function.
   */
  void set element(FunctionElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.returnType.beginToken;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitFunctionExpression(this);
  }
}

//*-- GuardSource
abstract class GuardSource extends AstNode {
  Token get whenKeyword;

  Expression get condition;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.whenKeyword;
  }

  @override
  Token get endToken {
    return this.condition.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitGuardSource(this);
  }
}

//*-- Identifier
/**
 * An identifier.
 */
abstract class Identifier extends ElementReferenceExpression {
  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  List<Element> get candidateElements;

  @override
  void set candidateElements(List<Element> element);

  @override
  Element get referredElement;

  @override
  void set referredElement(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- IfExpression
/**
 * An if expression
 * TODO: rename to ConditionalExpression
 */
abstract class IfExpression extends Expression {
  /**
   * The if source.
   */
  IfSource get ifSource;

  /**
   * The if keyword.
   */
  Token get ifKeyword {
    return this.ifSource.ifKeyword;
  }

  /**
   * The condition to be satisfied.
   */
  Expression get condition {
    return this.ifSource.condition;
  }

  /**
   * The consequent statement to be executed if the condition evaluates to
   * `true`.
   */
  Statement get consequent;

  /**
   * The else keyword, `null` if no alternate sequence is defined.
   */
  Token get elseKeyword;

  /**
   * The alternate statement to be executed if the condition evaluates to
   * `false`.
   */
  Statement get alternate;

  bool get isUnless {
    return this.ifSource.isUnless;
    // TODO: reformate always use kind when comparing
  }

  /**
   * `true` if this has an alternate statement, `false` otherwise.
   */
  bool get hasAlternate {
    return this.alternate != null;
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.ifKeyword;
  }

  @override
  Token get endToken {
    return this.elseKeyword == null
        ? this.consequent.endToken
        : this.alternate.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitIfExpression(this);
  }
}

//*-- IfSource
/**
 * Is the header of an if expression or statement, it's the container of the if
 * keyword and the condition to be satisfied.
 * TODO: rename to ConditionalSource
 */
abstract class IfSource extends AstNode {
  /**
   * The if keyword.
   */
  Token get ifKeyword;

  String get keywordLexeme;

  /**
   * The condition to be satisfied.
   */
  Expression get condition;

  bool get isUnless {
    return this.keywordLexeme == "unless";
  }

  @override
  IfExpression get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.ifKeyword;
  }

  @override
  Token get endToken {
    return this.condition.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitIfSource(this);
  }
}

//*-- ImplementsClause
abstract class ImplementsClause extends AstNode {
  Token get implementsKeyword;

  List<TypeAnnotation> get interfaces;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.implementsKeyword;
  }

  @override
  Token get endToken {
    return this.interfaces.last.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitImplementsClause(this);
  }
}

//*-- ImportDirective
abstract class ImportDirective extends Statement {
  Token get importKeyword;

  StringLiteral get uri;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.importKeyword;
  }

  @override
  Token get endToken {
    return this.uri.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitImportDirective(this);
  }
}

//*-- IndexExpression
/**
 * An index or key member expression.
 */
abstract class IndexExpression extends Expression {
  /**
   * The expression used to compute the object to be indexed.
   */
  Expression get target;

  /**
   * The left bracket.
   */
  Token get leftBracket;

  /**
   * The expression used to compute the index.
   */
  Expression get index;

  /**
   * The right bracket.
   */
  Token get rightBracket;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  OperatorElement get operatorElement;

  void set operatorElement(OperatorElement element);

  @override
  Token get beginToken {
    return this.target.beginToken;
  }

  @override
  Token get endToken {
    return this.rightBracket;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitIndexExpression(this);
  }
}

//*-- InExpression
abstract class InExpression extends Expression {
  Expression get element;

  Token get inKeyword; // TODO: operator

  Expression get container;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  MethodElement get methodElement;

  void set methodElement(MethodElement element);

  @override
  Token get beginToken {
    return this.element.beginToken;
  }

  @override
  Token get endToken {
    return this.container.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitInExpression(this);
  }
}

//*-- IntegerLiteral
/**
 * An integer literal.
 */
abstract class IntegerLiteral extends SingleTokenLiteral {
  @override
  Token get token;

  @override
  int get value {
    return int.parse(this.raw);
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitIntegerLiteral(this);
  }
}

//*-- InterfaceDeclaration
abstract class InterfaceDeclaration extends Statement implements Declaration {
  /**
   * The interface keyword.
   */
  Token get interfaceKeyword;

  /**
   * The name of the interface.
   */
  SimpleIdentifier get name;

  ImplementsClause get implementsClause;

  /**
   * List over members of this interface.
   */
  List<ClassMember> get members;

  @override
  InterfaceElement get element;

  /**
   * Sets the associated element with this interface declaration.
   */
  void set element(InterfaceElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.interfaceKeyword;
  }

  @override
  Token get endToken {
    if(this.members.isNotEmpty) {
      return this.members.last.endToken;
    }
    return null;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitInterfaceDeclaration(this);
  }
}

//*-- InvocationExpression
/**
 * A function or method invocation expression.
 */
abstract class InvocationExpression extends Expression {
  /**
   * The expression that refers to a function or a method to be invoked.
   * TODO: function returning a function
   */
  ElementReferenceExpression get callee;

  /**
   * The arguments left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * The arguments in which the function is invoked.
   */
  ArgumentList get arguments;

  /**
   * The arguments right parenthesis.
   */
  Token get rightParenthesis;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  Scope get scope;

  @override
  void set scope(Scope scope);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.callee.beginToken;
  }

  @override
  Token get endToken {
    return this.rightParenthesis;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitInvocationExpression(this);
  }
}

//*-- Literal
/**
 * A literal.
 */
abstract class Literal extends Expression {
  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- MapEntry
/**
 * A key/value declaration in a map literal body.
 */
abstract class MMapEntry extends AstNode {
  /**
   * The expression to compute the key of this entry.
   */
  Expression get key;

  /**
   * The colon that separate the key and the value.
   */
  Token get colon;

  /**
   * The expression to compute the value of this entry.
   */
  Expression get value;

  @override
  MapLiteral get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.key.beginToken;
  }

  @override
  Token get endToken {
    return this.value.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitMMapEntry(this);
  }
}

//*-- MapLiteral
/**
 * A map literal.
 */
abstract class MapLiteral extends TypedLiteral {
  @override
  TypeArgumentList get typeArguments;

  /**
   * The type annotation of keys.
   */
  TypeAnnotation get keyType {
    if(this.typeArguments.isEmpty) {
      return null;
    }
    return this.typeArguments.arguments.first;
  }

  /**
   * The type of values.
   */
  TypeAnnotation get valueType {
    if(this.typeArguments.isEmpty) {
      return null;
    }
    return this.typeArguments.arguments.elementAt(1);
  }

  /**
   * The left bracket token.
   */
  Token get leftBrace;

  /**
   * List over map entries.
   */
  List<MMapEntry> get entries;

  /**
   * The right bracket token.
   */
  Token get rightBrace;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    if(this.isTyped) {
      return this.typeArguments.beginToken;
    }
    return this.leftBrace;
  }

  @override
  Token get endToken {
    return this.rightBrace;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitMapLiteral(this);
  }
}

//*-- MemberExpression
/**
 * An index or key member expression.
 */
abstract class MemberExpression extends ElementReferenceExpression {
  /**
   * The expression used to compute the object defining the property to be
   * accessed.
   */
  Expression get target;

  /**
   * The property access operator, dot.
   */
  Token get dot;

  /**
   * The name of the property being accessed.
   */
  SimpleIdentifier get property;

  @override
  Scope get scope;

  @override
  void set scope(Scope scope);

  @override
  List<Element> get candidateElements;

  @override
  void set candidateElements(List<Element> element);

  @override
  Element get referredElement;

  @override
  void set referredElement(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.target.beginToken;
  }

  @override
  Token get endToken {
    return this.property.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitMemberExpression(this);
  }
}

//*-- MethodDeclaration
/**
 * A method declaration in a class declaration.
 */
abstract class MethodDeclaration extends ExecutableClassMember {
  Token get abstractKeyword;

  @override
  Token get visibilityToken;

  /**
   * The `static` keyword if this is a static method.
   */
  Token get staticKeyword;

  @override
  TypeAnnotation get returnType;

  /**
   * Token representing 'set' or 'get' keyword.
   */
  Token get propertyKeyword;

  String get propertyLexeme;

  /**
   * The name of the method being declared.
   */
  SimpleIdentifier get name;

  @override
  ParameterList get parameters;

  @override
  Token get inlineKeyword;

  @override
  Token get arrow;

  @override
  Block get body;

  /**
   * `true` if this is an abstract method, `false` otherwise.
   */
  bool get isAbstract;

  /**
   * `true` if this is a static method, `false` otherwise.
   */
  bool get isStatic;

  /**
   * `true` if this is a getter declaration, `false` otherwise.
   */
  bool get isGetter {
    return this.propertyLexeme == "get";
  }

  /**
   * `true` if this is a setter declaration, `false` otherwise.
   */
  bool get isSetter {
    return this.propertyLexeme == "set";
  }

  /**
   * `true` if this is not an anonymous method, `false` otherwise.
   */
  bool get isAnonymous {
    return this.name == null;
  }

  @override
  bool get hasParameters {
    return this.parameters != null;
  }

  @override
  bool get isInline;

  @override
  MethodElement get element;

  @override
  void set element(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.returnType.beginToken;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitMethodDeclaration(this);
  }
}

//*-- NativeExpression
/**
 * A native expression.
 * TODO: other native support style
 */
abstract class NativeExpression extends Expression {
  /**
   * The native keyword.
   */
  Token get nativeKeyword;

  /**
   * The arguments left parenthesis.
   */
  Token get leftParen;

  /**
   * The arguments in which the function is invoked.
   */
  ArgumentList get arguments;

  /**
   * The arguments right parenthesis.
   */
  Token get rightParen;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.nativeKeyword;
  }

  @override
  Token get endToken {
    return this.rightParen;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitNativeExpression(this);
  }
}

//*-- NewExpression
/**
 * An index or key member expression.
 */
abstract class NewExpression extends Expression {
  /**
   * The new keyword.
   */
  Token get newKeyword;

  TypeAnnotation get callee;

  /**
   * The arguments left parenthesis.
   */
  Token get leftParenthesis;

  /**
   * The arguments to be used to construct the new instance.
   */
  ArgumentList get arguments;

  /**
   * The arguments right parenthesis.
   */
  Token get rightParenthesis;

  /**
   * `true` if this has a list of arguments (maybe empty) to be used to
   *  construct the new instance, `false` otherwise.
   */
  bool get hasArguments {
    return this.arguments != null;
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  ConstructorElement constructorElement;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.newKeyword;
  }

  @override
  Token get endToken {
    if(this.hasArguments) {
      return this.rightParenthesis;
    }
    return this.callee.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitNewExpression(this);
  }
}

//*-- NullLiteral
abstract class NullLiteral extends SingleTokenLiteral {
  @override
  Token get token;

  @override
  dynamic get value => null;

  @override
  String get raw => "null";

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitNullLiteral(this);
  }
}

//*-- Operator
/**
 * An operator.
 */
abstract class Operator extends AstNode {
  /**
   * The token representing the operator.
   */
  Token get token;

  String get lexeme;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- OperatorDeclaration
abstract class OperatorDeclaration extends ExecutableClassMember {
  Token get abstractKeyword;

  bool get isAbstract;

  @override
  Token get visibilityToken;

  @override
  TypeAnnotation get returnType;

  /**
   * The `operator`keyword, if this is an operator overloading method.
   */
  Token get operatorKeyword;

  String get operatorType;

  /**
   * The operator being overloaded.
   */
  Operator get operator;

  @override
  ParameterList get parameters;

  @override
  Token get inlineKeyword;

  @override
  Token get arrow;

  @override
  Block get body;

  @override
  bool get hasReturnType {
    return this.returnType != null;
  }

  @override
  bool get hasParameters {
    return this.parameters != null;
  }

  @override
  bool get isInline;

  @override
  OperatorElement get element;

  @override
  void set element(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.returnType.beginToken;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitOperatorDeclaration(this);
  }
}

//*-- Parameter
abstract class Parameter extends AstNode implements Declaration {
  SimpleIdentifier get name;

  bool get isTyped;

  bool get isOptional;

  bool get isInitialized;

  @override
  ParameterElement get element;

  void set element(ParameterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- ParameterList
/**
 * Parameters list of a method, setter or a function.
 */
abstract class ParameterList extends AstNode {
  /**
   * The left parenthesis token.
   */
  Token get leftParenthesis;

  /**
   * List of parameters.
   */
  List<Parameter> get parameters;

  /**
   * The right parenthesis token.
   */
  Token get rightParenthesis;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.leftParenthesis;
  }

  @override
  Token get endToken {
    return this.rightParenthesis;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitParameterList(this);
  }
}

//*-- ParenthesisExpression
abstract class ParenthesisExpression extends Expression {
  /**
   * The left parenthesis token.
   */
  Token get leftParenthesis;

  Expression get expression;

  /**
   * The right parenthesis token.
   */
  Token get rightParenthesis;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  Scope get scope;

  @override
  void set scope(Scope scope);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.leftParenthesis;
  }

  @override
  Token get endToken {
    return this.rightParenthesis;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitParenthesisExpression(this);
  }
}

//*-- RangeLiteral
abstract class RangeLiteral extends Literal {
  /**
   * The left bracket token.
   */
  Token get leftBracket;

  Expression get start;

  Token get operator; // TODO: range operator

  Expression get end;

  /**
   * The right bracket token.
   */
  Token get rightBracket;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.leftBracket;
  }

  @override
  Token get endToken {
    return this.rightBracket;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitRangeLiteral(this);
  }
}

//*-- RepetitionExpression
/**
 * A repetition expression
 */
abstract class RepetitionExpression extends Expression {
  /**
   * The repetition source.
   */
  RepetitionSource get source;

  /**
   * The source keyword.
   */
  Token get keyword {
    return this.source.keyword;
  }

  /**
   * The test to be satisfied if this is a `while` expression or to not be
   * satisfied if this is an `until` expression, `null` if this is a `loop`
   * expression.
   */
  Expression get test {
    return this.source.test;
  }

  GuardSource get guard {
    return this.source.guard;
  }

  Expression get guardCondition {
    if(this.hasGuard) {
      return this.guard.condition;
    }
    return null;
  }

  /**
   * The statement to be executed while the test is satisfied if while or not
   * satisfied if until.
   */
  Statement get body;

  /**
   * `true` if this is a `while` expression, or `false` otherwise.
   */
  bool get isWhile {
    return this.source.isWhile;
  }

  /**
   * `true` if this is an `until` expression, or `false` otherwise.
   */
  bool get isUntil {
    return this.source.isUntil;
  }

  /**
   * `true` if this is a `loop` expression, or `false` otherwise.
   */
  bool get isLoop {
    return this.source.isLoop;
  }

  bool get hasGuard {
    return this.source.hasGuard;
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.source.beginToken;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitRepetitionExpression(this);
  }
}

//*-- RepetitionSource
/**
 * The header of a while/until/loop expression.
 */
abstract class RepetitionSource extends AstNode {
  /**
   * The repetition keyword.
   */
  Token get keyword;

  /**
   * The test to be satisfied if this is the source of a `while` expression
   * or to not be satisfied if this is the source of an `until` expression,
   * `null` if this is the source of a `loop` expression.
   */
  Expression get test;

  GuardSource get guard;

  /**
   * `true` if this is the source of a `while` expression, or `false` otherwise.
   */
  bool get isWhile {
    return this.keyword.kind == TokenKind.WHILE;
  }

  /**
   * `true` if this is the source of a `until` expression, or `false` otherwise.
   */
  bool get isUntil {
    return this.keyword.kind == TokenKind.UNTIL;
  }

  /**
   * `true` if this is the source of a `loop` expression, or `false` otherwise.
   */
  bool get isLoop {
    return this.keyword.kind == TokenKind.LOOP;
  }

  bool get hasGuard {
    return this.guard != null;
  }

  @override
  RepetitionExpression get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.keyword;
  }

  @override
  Token get endToken {
    if(this.isLoop) {
      return this.keyword;
    }
    if(this.hasGuard) {
      return this.guard.endToken;
    }
    return this.test.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitRepetitionSource(this);
  }
}

//*-- ReturnStatement
/**
 * A return statement.
 */
abstract class ReturnStatement extends Statement {
  /**
   * The return keyword.
   */
  Token get returnKeyword;

  /**
   * The expression to compute the value to be returned.
   */
  Expression get expression;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.returnKeyword;
  }

  @override
  Token get endToken {
    if(this.expression != null) {
      return this.expression.endToken;
    }
    return this.returnKeyword;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitReturnStatement(this);
  }
}

//*-- Script
/**
 * A mammouth script in a document.
 */
abstract class Script extends common.DocumentEntry implements AstNode {
  /**
   * The token of the opening tag of the script.
   */
  Token get startTag;

  /**
   * The body of the script.
   */
  Block get body;

  /**
   * The token of the closing tag of the script.
   */
  Token get endTag;

  @override
  common.Document get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.startTag;
  }

  @override
  Token get endToken {
    return this.endTag;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitScript(this);
  }
}

//*-- SimpleIdentifier
/**
 * A simple identifier.
 */
abstract class SimpleIdentifier extends Identifier {
  /**
   * The token representing the simple identifier.
   */
  Token get token;

  /**
   * The simple identifier name.
   */
  String get name;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  List<Element> get candidateElements;

  @override
  void set candidateElements(List<Element> element);

  @override
  Element get referredElement;

  @override
  void set referredElement(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitSimpleIdentifier(this);
  }
}

//*-- SimpleParameter
/**
 * Represents a parameter definitions.
 */
abstract class SimpleParameter extends Parameter {
  /**
   * The parameter type, or `null` if parameter has no type, for dynamic typing.
   */
  TypeAnnotation get type;

  @override
  SimpleIdentifier get name;

  /**
   * The equal token.
   */
  Token get equal;

  /**
   * The expression to compute the value used to initialize this parameter.
   */
  Expression get initializer;

  @override
  bool get isTyped {
    return this.type != null;
  }

  @override
  bool get isOptional;

  @override
  bool get isInitialized {
    return this.initializer != null;
  }

  @override
  ParameterElement get element;

  @override
  void set element(ParameterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    if(this.isTyped) {
      return this.type.beginToken;
    }
    return this.name.beginToken;
  }

  @override
  Token get endToken {
    return this.name.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitSimpleParameter(this);
  }
}

//*-- SingleTokenLiteral
/**
 * A single token literal.
 */
abstract class SingleTokenLiteral extends Literal {
  /**
   * The token that represents the literal.
   */
  Token get token;

  /**
   * The value of this literal.
   */
  Object get value;

  /**
   * The raw value of the literal.
   */
  String get raw;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- SliceExpression
abstract class SliceExpression extends Expression {
  Expression get expression;

  RangeLiteral get slicingRange;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  Scope get scope;

  @override
  void set scope(Scope scope);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  MethodElement get slicerElement;

  void set slicerElement(MethodElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.expression.beginToken;
  }

  @override
  Token get endToken {
    return this.slicingRange.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitSliceExpression(this);
  }
}

//*-- Statement
/**
 * The base class of all statements.
 */
abstract class Statement extends AstNode {
  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- StringLiteral
/**
 * A string literal.
 */
abstract class StringLiteral extends SingleTokenLiteral {
  @override
  Token get token;

  @override
  String get value {
    return this.raw.substring(1, this.raw.length - 1);
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitStringLiteral(this);
  }
}

//*-- SwitchCase
abstract class SwitchCase extends AstNode {
  Token get keyword;

  Expression get test;

  Statement get consequent;

  @override
  common.AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.keyword;
  }

  @override
  Token get endToken {
    return this.consequent.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitSwitchCase(this);
  }
}

//*-- SwitchDefault
abstract class SwitchDefault extends AstNode {
  Token get defaultKeyword;

  Statement get consequent;

  @override
  common.AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.defaultKeyword;
  }

  @override
  Token get endToken {
    return this.consequent.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitSwitchDefault(this);
  }
}

//*-- SwitchExpression
abstract class SwitchExpression extends Expression {
  Token get switchKeyword;

  Expression get discriminant;

  List<SwitchCase> get cases;

  SwitchDefault get defaultCase;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  Scope get scope;

  @override
  void set scope(Scope scope);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.switchKeyword;
  }

  @override
  Token get endToken {
    if(this.defaultCase != null) {
      return this.defaultCase.endToken;
    }
    return this.cases.last.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitSwitchExpression(this);
  }
}

//*-- ThrowStatement
/**
 * A throw statement.
 */
abstract class ThrowStatement extends Statement {
  /**
   * The throw keyword.
   */
  Token get throwKeyword;

  /**
   * The expression to compute the value to be thrown.
   */
  Expression get expression;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.throwKeyword;
  }

  @override
  Token get endToken {
    return this.expression.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitThrowStatement(this);
  }
}

//*-- ToExpression
abstract class ToExpression extends Expression {
  Expression get argument;

  Token get toKeyword; // TODO: operator

  TypeAnnotation get type;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  ConverterElement get converter;

  void set converter(ConverterElement element);

  @override
  Token get beginToken {
    return this.argument.beginToken;
  }

  @override
  Token get endToken {
    return this.type.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitToExpression(this);
  }
}

//*-- TryExpression
abstract class TryExpression extends Expression {
  Token get tryKeyword;

  Statement get tryStatement;

  Token get catchKeyword;

  SimpleParameter get catchVariable;

  Statement get catchStatement;

  Token get finallyKeyword;

  Statement get finallyStatement;

  bool get hasCatch {
    return this.catchStatement != null;
  }

  bool get isCatchVariableTyped {
    return this.catchVariable != null;
  }

  bool get hasFinally {
    return this.finallyStatement != null;
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  Scope get scope;

  @override
  void set scope(Scope scope);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.tryKeyword;
  }

  @override
  Token get endToken {
    if(this.hasFinally) {
      return this.finallyStatement.endToken;
    }
    if(this.hasCatch) {
      return this.catchStatement.endToken;
    }
    return this.tryStatement.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitTryExpression(this);
  }
}

//*-- TypeAnnotation
/**
 * A type.
 */
abstract class TypeAnnotation extends AstNode {
  /**
   * The referenced type by this annotation.
   */
  MammouthType get annotatedType;

  /**
   * Sets the referenced type by this annotation.
   */
  void set annotatedType(MammouthType type);

  Element get typeElement;

  void set typeElement(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- TypeArgumentList
/**
 * A list of type arguments.
 */
abstract class TypeArgumentList extends AstNode {
  /**
   * The left angle bracket.
   */
  Token get leftAngle;

  /**
   * An iterable over type arguments.
   */
  List<TypeAnnotation> get arguments;

  /**
   * The right angle bracket.
   */
  Token get rightAngle;

  /**
   * `true` if this is empty, `false` otherwise.
   */
  bool get isEmpty {
    return this.arguments.isEmpty;
  }

  /**
   * `true` if this is not empty, `false` otherwise.
   */
  bool get isNotEmpty {
    return this.arguments.isNotEmpty;
  }

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.leftAngle;
  }

  @override
  Token get endToken {
    return this.rightAngle;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitTypeArgumentList(this);
  }
}

//*-- TypedLiteral
/**
 * Literal that may have specified type.
 */
abstract class TypedLiteral extends Literal {
  /**
   * The type arguments, or `null` if this has no type specified.
   */
  TypeArgumentList get typeArguments;

  /**
   * `true` if this has type arguments specified, `null` otherwise.
   */
  bool get isTyped {
    return this.typeArguments != null;
  }

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- TypeName
/**
 * A type defined with its name.
 */
abstract class TypeName extends TypeAnnotation {
  /**
   * The identifier of the type name.
   */
  Identifier get name;

  /**
   * Type arguments associated with this type name, or `null` if no type arguments
   * are specified.
   */
  TypeArgumentList get typeArguments;

  bool get hasTypeArguments {
    return this.typeArguments != null;
  }

  @override
  MammouthType get annotatedType;

  @override
  void set annotatedType(MammouthType type);

  @override
  Element get typeElement;

  @override
  void set typeElement(Element element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.name.beginToken;
  }

  @override
  Token get endToken {
    return this.name.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitTypeName(this);
  }
}

//*-- TypeParameter
abstract class TypeParameter extends AstNode {
  SimpleIdentifier get name;

  TypeParameterElement element;

  @override
  TypeParameterList get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.name.beginToken;
  }

  @override
  Token get endToken {
    return this.name.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitTypeParameter(this);
  }
}

//*-- TypeParameterList
/**
 * A list of type parameters.
 */
abstract class TypeParameterList extends AstNode {
  /**
   * The left angle bracket.
   */
  Token get leftAngle;

  /**
   * An iterable over type parameters.
   */
  List<TypeParameter> get parameters;

  /**
   * The right angle bracket.
   */
  Token get rightAngle;

  /**
   * `true` if this is empty, `false` otherwise.
   */
  bool get isEmpty {
    return this.parameters.isEmpty;
  }

  /**
   * `true` if this is not empty, `false` otherwise.
   */
  bool get isNotEmpty {
    return this.parameters.isNotEmpty;
  }

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.leftAngle;
  }

  @override
  Token get endToken {
    return this.rightAngle;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitTypeParameterList(this);
  }
}

//*-- UnaryExpression
/**
 * An unary expression
 */
abstract class UnaryExpression extends Expression {
  /**
   * The unary operator.
   */
  UnaryOperator get operator;

  /**
   * The expression used to compute the operand for the operator.
   */
  Expression get argument;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  Scope get scope;

  @override
  void set scope(Scope scope);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  OperatorElement get operatorElement;

  void set operatorElement(OperatorElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.operator.beginToken;
  }

  @override
  Token get endToken {
    return this.argument.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitUnaryExpression(this);
  }
}

//*-- UnaryOperator
/**
 * An unary operator.
 */
abstract class UnaryOperator extends Operator {
  @override
  Token get token;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitUnaryOperator(this);
  }
}

//*-- UpdateExpression
/**
 * An update expression
 */
abstract class UpdateExpression extends Expression {
  /**
   * `true` if the update operator is used as prefix, `false` otherwise (pstfix).
   */
  bool get isPrefix;

  /**
   * The update operator.
   */
  UpdateOperator get operator;

  /**
   * The expression used to compute the operand for the operator.
   */
  Expression get argument;

  @override
  bool get asStatement;

  @override
  void set asStatement(bool value);

  @override
  Scope get scope;

  @override
  void set scope(Scope scope);

  @override
  ConverterElement get converterElement;

  @override
  void set converterElement(ConverterElement element);

  OperatorElement get operatorElement;

  void set operatorElement(OperatorElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.isPrefix ? this.operator.beginToken : this.argument.beginToken;
  }

  @override
  Token get endToken {
    return this.isPrefix ? this.argument.endToken : this.operator.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitUpdateExpression(this);
  }
}

//*-- UpdateOperator
/**
 * An update operator.
 */
abstract class UpdateOperator extends Operator {
  @override
  Token get token;

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitUpdateOperator(this);
  }
}

//*-- VariableDeclarationStatement
/**
 * A typed variable declaration.
 */
abstract class VariableDeclarationStatement extends Statement
    implements Declaration {
  /**
   * The type of the variable being declared.
   */
  TypeAnnotation get type;

  /**
   * The name of the variable being declared.
   */
  SimpleIdentifier get name;

  /**
   * The assignment token if the variable is initialized, `null` otherwise.
   */
  Token get equal;

  /**
   * The expression used to compute the initial value for the variable, or
   * `null` if the variable is not initialized.
   */
  Expression get initializer;

  /**
   * `true` if the declared variable is to be initialized, `false` otherwise.
   */
  bool get isInitialized {
    return this.initializer != null;
  }

  @override
  VariableElement get element;

  /**
   * Sets the associated element to this variable declaration.
   */
  void set element(VariableElement element);

  @override
  AstNode get parentNode;

  @override
  void set parentNode(common.AstNode node);

  @override
  Token get beginToken {
    return this.type.beginToken;
  }

  @override
  Token get endToken {
    return this.equal == null ? this.name.endToken : this.initializer.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitVariableDeclarationStatement(this);
  }
}
