library mammouth.language.php.ast.ast;

import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/common/ast/visibility.dart"
    show Visibility;
import "package:mammouth/src/language/common/ast/token.dart"
    show TokenKind, Token;
import "package:mammouth/src/language/common/ast/visitor.dart" show Visitor;
import "package:mammouth/src/language/php/element/element.dart";

//*-- AutoReturnable
/**
 * Interface that helps implement last value return in php.
 */
abstract class AutoReturnable {
  Statement enableAutoReturn(ReturnGenerator generator);
}

typedef Statement ReturnGenerator(Expression expression);

//*-- ArrayItem
/**
 * Expression to access array item using index or key.
 */
abstract class ArrayItem extends Expression {
  /**
   * The value to access using index or key.
   */
  Expression get target;

  /**
   * The left bracket.
   */
  Token get leftBracket;

  /**
   * The expression to be used to compute the key or index to be used.
   */
  Expression get property;

  /**
   * The right bracket.
   */
  Token get rightBracket;

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
    return visitor.visitPHPArrayItem(this);
  }
}

//*-- ArrayLiteral
/**
 * Expression to construct a new array using [].
 */
abstract class ArrayLiteral extends Expression {
  /**
   * The left bracket.
   */
  Token get leftBracket;

  /**
   * The array elements.
   */
  List<Expression> get elements;

  /**
   * The right bracket.
   */
  Token get rightBracket;

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
    return visitor.visitPHPArrayLiteral(this);
  }
}

//*-- AssignmentExpression
/**
 * An assignment expression.
 */
abstract class AssignmentExpression extends Expression {
  /**
   * The expression used to compute the left hand side.
   */
  Expression get leftHandSide;

  /**
   * The assignment operator.
   */
  AssignmentOperator get operator;

  /**
   * The expression used to compute the right hand side.
   */
  Expression get rightHandSide;

  @override
  Token get beginToken {
    return this.leftHandSide.beginToken;
  }

  @override
  Token get endToken {
    return this.rightHandSide.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPAssignmentExpression(this);
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
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPAssignmentOperator(this);
  }
}

//*-- AstNode
abstract class AstNode extends common.AstNode {
  @override
  common.AstNode get parentNode {
    return null;
  }

  @override
  void set parentNode(common.AstNode node) {}

  @override
  Token get beginToken;

  @override
  Token get endToken;

  @override
  E accept<E>(Visitor<E> visitor);
}

//*-- BinaryExpression
/**
 * An assignment expression.
 */
abstract class BinaryExpression extends Expression {
  /**
   * The expression used to compute the left operand.
   */
  Expression get left;

  /**
   * The binary operator.
   */
  BinaryOperator get operator;

  /**
   * The expression used to compute the right operand.
   */
  Expression get right;

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
    return visitor.visitPHPBinaryExpression(this);
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
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPBinaryOperator(this);
  }
}

//*-- Block
/**
 * A block of code.
 */
abstract class Block extends Statement {
  /**
   * The left brace.
   */
  Token get leftBrace;

  /**
   * List of statements in block.
   */
  List<Statement> get statements;

  /**
   * The right brace.
   */
  Token get rightBrace;

  @override
  Block enableAutoReturn(ReturnGenerator generator);

  @override
  Token get beginToken {
    return this.leftBrace;
  }

  @override
  Token get endToken {
    return this.rightBrace;
  }

  @override
  E accept<E>(Visitor<E> visitor, {bool scope = true}) {
    return visitor.visitPHPBlock(this, scope: scope);
  }
}

//*-- BooleanLiteral
/**
 * Represents a boolean literal.
 */
abstract class BooleanLiteral extends Literal {
  /**
   * The value of boolean literal.
   */
  bool get value {
    return this.token.lexeme == "TRUE";
  }

  @override
  Token get token;

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPBooleanLiteral(this);
  }
}

//*-- BreakStatement
abstract class BreakStatement extends Statement {
  /**
   * The break keyword.
   */
  Token get breakKeyword;

  @override
  BreakStatement enableAutoReturn(ReturnGenerator generator);

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
    return visitor.visitPHPBreakStatement(this);
  }
}

//*-- CastExpression
abstract class CastExpression extends Expression {
  String get type;

  // TODO: parenthesis

  Expression get expression;

  @override
  Token get beginToken {
    return null; // TODO:
  }

  @override
  Token get endToken {
    return this.expression.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPCastExpression(this);
  }
}

//*-- ClassDeclaration
/**
 * A class declaration statement.
 */
abstract class ClassDeclaration extends Statement {
  /**
   * The class keyword.
   */
  Token get classKeyword;

  /**
   * The name of the class
   */
  Name get name;

  Name get superclass;

  /**
   * The left brace.
   */
  Token get leftBrace;

  /**
   * List of members of this class.
   */
  List<ClassMember> get members;

  /**
   * The right brace.
   */
  Token get rightBrace;

  @override
  Token get beginToken {
    return this.classKeyword;
  }

  @override
  Token get endToken {
    return this.rightBrace;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPClassDeclaration(this);
  }
}

//*-- ClassMember
/**
 * The base class of all class members.
 */
abstract class ClassMember extends AstNode {
  /**
   * The visibility token, `null` if no explicit visibility is cited.
   */
  Token get visibilityToken;

  /**
   * The static keyword.
   */
  Token get staticKeyword;

  /**
   * The visibility of this member.
   */
  Visibility get visibility {
    if(this.isPrivate) {
      return Visibility.PRIVATE;
    } else if(this.isProtected) {
      return Visibility.PROTECTED;
    } else if(this.visibilityToken == null) {
      return Visibility.DEFAULT;
    }
    return Visibility.PUBLIC;
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

  bool get isStatic {
    return this.staticKeyword != null;
  }
}

//*-- ConcatenationExpression
abstract class ConcatenationExpression extends Expression {
  Expression get left;

  Expression get right;

  @override
  Token get beginToken {
    return null;
  }

  @override
  Token get endToken {
    return null;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPConcatenationExpression(this);
  }
}

//*-- ContinueStatement
abstract class ContinueStatement extends Statement {
  /**
   * The continue keyword.
   */
  Token get continueKeyword;

  @override
  ContinueStatement enableAutoReturn(ReturnGenerator generator);

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
    return visitor.visitPHPContinueStatement(this);
  }
}

//*-- FieldDeclaration
/**
 * A class field declaration.
 */
abstract class FieldDeclaration extends ClassMember {
  /**
   * The variable declared by the field.
   */
  Variable get variable;

  /**
   * The equal operator of the field is initialized, or `null` otherwise.
   */
  Token get equal;

  /**
   * The expression use to initialize the field, or `null` otherwise.
   */
  Expression get initializer;

  /**
   * The semicolon.
   */
  Token get semicolon;

  @override
  Token get beginToken {
    return this.variable.beginToken;
  }

  @override
  Token get endToken {
    return this.semicolon;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPFieldDeclaration(this);
  }
}

//*-- ClosureExpression
/**
 * A lambda/anonymous function expression.
 */
abstract class ClosureExpression extends Expression {
  /**
   * The `function` keyword.
   */
  Token get functionKeyword;

  /**
   * The parameters left parenthesis.
   */
  Token get leftParen;

  /**
   * List of function's parameters.
   */
  List<Parameter> get parameters;

  /**
   * The parameters right parenthesis.
   */
  Token get rightParen;

  /**
   * The function body.
   */
  Block get body;

  /**
   * Makes this return the value of the last expression statement on.
   */
  void enableAutoReturn(ReturnGenerator generator);

  @override
  Token get beginToken {
    return this.functionKeyword;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPClosureExpression(this);
  }
}

//*-- EchoStatement
/**
 * An echo statement.
 */
abstract class EchoStatement extends Statement {
  /**
   * The echo keyword.
   */
  Token get echoKeyword;

  /**
   * The expression to compute the value to be printed.
   * TODO: multiple expressions
   */
  Expression get expression;

  /**
   * The semicolon.
   */
  Token get semicolon;

  @override
  Statements enableAutoReturn(ReturnGenerator generator);

  @override
  Token get beginToken {
    return this.echoKeyword;
  }

  @override
  Token get endToken {
    return this.semicolon;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPEchoStatement(this);
  }
}

//*-- Expression
/**
 * Represents an expression.
 */
abstract class Expression extends AstNode {}

//*-- ExpressionStatement
/**
 * An expression used as a statement.
 */
abstract class ExpressionStatement extends Statement {
  /**
   * The expression being used as statement.
   */
  Expression get expression;

  /**
   * The semicolon terminating the expression statement.
   */
  Token get semicolon;

  @override
  Token get beginToken {
    return this.expression.beginToken;
  }

  @override
  Token get endToken {
    return this.semicolon;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPExpressionStatement(this);
  }
}

//*-- FloatLiteral
/**
 * Represents a float literal.
 */
abstract class FloatLiteral extends Literal {
  /**
   * The value of float literal.
   */
  num get value {
    return num.parse(this.token.lexeme);
  }

  @override
  Token get token;

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPFloatLiteral(this);
  }
}

//*-- ForeachStatement
abstract class ForeachStatement extends Statement {
  Token get foreachToken;

  /**
   * The left parenthesis.
   */
  Token get leftParen;

  Expression get expression;

  Token get asKeyword;

  Variable get keyVariable;

  Token get arrow;

  Variable get valueVariable;

  /**
   * The right parenthesis.
   */
  Token get rightParen;

  Statement get body;

  @override
  ForeachStatement enableAutoReturn(ReturnGenerator generator);

  @override
  Token get beginToken {
    return this.foreachToken;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPForeachStatement(this);
  }
}

//*-- ForStatement
abstract class ForStatement extends Statement {
  Token get forToken;

  /**
   * The left parenthesis.
   */
  Token get leftParen;

  Expression get init;

  Expression get test;

  Expression get update;

  /**
   * The right parenthesis.
   */
  Token get rightParen;

  Statement get body;

  @override
  ForStatement enableAutoReturn(ReturnGenerator generator);

  @override
  Token get beginToken {
    return this.forToken;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPForStatement(this);
  }
}

//*-- FunctionCallExpression
/**
 * A function invocation.
 */
abstract class FunctionCallExpression extends Expression {
  /**
   * The function to be invoked.
   */
  Expression get function;

  /**
   * The left parenthesis.
   */
  Token get leftParen;

  /**
   * The arguments for which the function is applied.
   */
  List<Expression> get arguments;

  /**
   * The right parenthesis.
   */
  Token get rightParen;

  @override
  Token get beginToken {
    return this.function.beginToken;
  }

  @override
  Token get endToken {
    return this.rightParen;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPFunctionCallExpression(this);
  }
}

//*-- FunctionStatement
/**
 * A function declaration.
 */
abstract class FunctionStatement extends Statement {
  /**
   * The `function` keyword.
   */
  Token get functionKeyword;

  /**
   * The name of the function.
   */
  Name get name;

  /**
   * The parameters left parenthesis.
   */
  Token get leftParen;

  /**
   * List of function's parameters.
   */
  List<Parameter> get parameters;

  /**
   * The parameters right parenthesis.
   */
  Token get rightParen;

  /**
   * The function body.
   */
  Block get body;

  @override
  Token get beginToken {
    return this.functionKeyword;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPFunctionStatement(this);
  }
}

//*-- GlobalStatement
/**
 * A php global statement.
 */
abstract class GlobalStatement extends Statement {
  /**
   * The global keyword.
   */
  Token get globalKeyword;

  /**
   * The global variables to be accessible in local scope.
   */
  List<Variable> get variables;

  /**
   * The semicolon terminating the global statement.
   */
  Token get semicolon;

  @override
  GlobalStatement enableAutoReturn(ReturnGenerator generator);

  @override
  Token get beginToken {
    return this.globalKeyword;
  }

  @override
  Token get endToken {
    return this.semicolon;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPGlobalStatement(this);
  }
}

//*-- IfStatement
/**
 * An if statement.
 */
abstract class IfStatement extends Statement {
  /**
   * The if keyword.
   */
  Token get ifKeyword;

  /**
   * The left parenthesis.
   */
  Token get leftParen;

  /**
   * The condition to be satisfied.
   */
  Expression get condition;

  /**
   * The right parenthesis.
   */
  Token get rightParen;

  /**
   * The consequent statement to be executed if condition is satisfied.
   */
  Statement get consequent;

  /**
   * The else keyword, or `null` if no alternate statement is defined.
   */
  Token get elseKeyword;

  /**
   * The alternate statement to be executed if condition is not satisfied,
   * `null` if no alternate statement is given.
   */
  Statement get alternate;

  @override
  Token get beginToken {
    return this.ifKeyword;
  }

  @override
  Token get endToken {
    if(this.alternate == null) {
      return this.consequent.endToken;
    }
    return this.consequent.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPIfStatement(this);
  }
}

//*-- IncludeExpression
abstract class IncludeExpression extends Expression {
  Expression get uri;

  bool get isOnce;

  @override
  Token get beginToken {
    return null;
  }

  @override
  Token get endToken {
    return null;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPIncludeExpression(this);
  }
}

//*-- IntegerLiteral
/**
 * Represents a integer literal.
 */
abstract class IntegerLiteral extends Literal {
  /**
   * The value of integer literal.
   */
  int get value {
    return int.parse(this.token.lexeme);
  }

  @override
  Token get token;

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPIntegerLiteral(this);
  }
}

//*-- InterfaceDeclaration
/**
 * An interface declaration statement.
 */
abstract class InterfaceDeclaration extends Statement {
  /**
   * The interface keyword.
   */
  Token get interfaceKeyword;

  /**
   * The name of the interface
   */
  Name get name;

  /**
   * The left brace.
   */
  Token get leftBrace;

  /**
   * List of members of this interface.
   */
  List<ClassMember> get members;

  /**
   * The right brace.
   */
  Token get rightBrace;

  @override
  Token get beginToken {
    return this.interfaceKeyword;
  }

  @override
  Token get endToken {
    return this.rightBrace;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPInterfaceDeclaration(this);
  }
}

//*-- KeyValue
abstract class KeyValue extends Expression {
  Expression get key;

  Token get arrow;

  Expression get value;

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
    return visitor.visitPHPKeyValue(this);
  }
}

//*-- Literal
/**
 * Represents a literal expression
 */
abstract class Literal extends Expression {
  /**
   * The token that represents the literal.
   */
  Token get token;

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }
}

//*-- MethodDeclaration
/**
 * A method declaration member.
 */
abstract class MethodDeclaration extends ClassMember {
  /**
   * The `function` keyword.
   */
  Token get functionKeyword;

  /**
   * The name of the method.
   */
  Name get name;

  /**
   * The parameters left parenthesis.
   */
  Token get leftParen;

  /**
   * List of function's parameters.
   */
  List<Parameter> get parameters;

  /**
   * The parameters right parenthesis.
   */
  Token get rightParen;

  /**
   * The function body.
   */
  Block get body;

  bool get isAbstract;

  void set isAbstract(bool value);

  /**
   * Makes this return the value of the last expression statement on.
   */
  void enableAutoReturn(ReturnGenerator generator);

  @override
  Token get beginToken {
    return this.functionKeyword;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPMethodDeclaration(this);
  }
}

//*-- Name
/**
 * A name, used to represents names of function, classes...
 */
abstract class Name extends Expression {
  /**
   * The token that represents the name.
   */
  Token get token;

  /**
   * The name.
   */
  String get name {
    return this.token.lexeme;
  }

  NameElement get element;

  void set element(NameElement element);

  bool asString = false;

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
    return visitor.visitPHPName(this);
  }
}

//*-- NewExpression
/**
 * a new expression.
 */
abstract class NewExpression extends Expression {
  /**
   * The new keyword.
   */
  Token get newKeyword;

  /**
   * The class to be instantiated.
   */
  Expression get target;

  /**
   * The parameters left parenthesis.
   */
  Token get leftParen;

  /**
   * List of arguments for the constructor.
   */
  List<Expression> get arguments;

  /**
   * The parameters right parenthesis.
   */
  Token get rightParen;

  @override
  Token get beginToken {
    return this.newKeyword;
  }

  @override
  Token get endToken {
    if(this.leftParen != null) {
      return this.rightParen;
    }
    return this.target.beginToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPNewExpression(this);
  }
}

//*-- NullLiteral
abstract class NullLiteral extends Literal {
  dynamic get value {
    return null;
  }

  @override
  Token get token;

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPNullLiteral(this);
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

  @override
  Token get beginToken {
    return this.token;
  }

  @override
  Token get endToken {
    return this.token;
  }
}

//*-- Parameter
/**
 * Represents a parameter definitions.
 */
abstract class Parameter extends AstNode {
  /**
   * The parameter's variable.
   */
  Variable get variable;

  @override
  Token get beginToken {
    return this.variable.beginToken;
  }

  @override
  Token get endToken {
    return this.variable.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPParameter(this);
  }
}

//*-- ParenthesisExpression
/**
 * TOO:
 */
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
  Token get beginToken {
    return this.leftParenthesis;
  }

  @override
  Token get endToken {
    return this.rightParenthesis;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPParenthesisExpression(this);
  }
}

//*-- PropertyFetch
/**
 * Accessing an object property or method expression.
 */
abstract class PropertyFetch extends Expression {
  /**
   * The object holding the property to be fetched.
   */
  Expression get target;

  /**
   * The right arrow symbol.
   */
  Token get operator;

  /**
   * The property to be accessed.
   */
  Expression get property;

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
    return visitor.visitPHPPropertyFetch(this);
  }
}

//*-- RawExpression
abstract class RawExpression extends Expression {
  String get content;

  List<Expression> get arguments;

  @override
  Token get beginToken {
    return null;
  }

  @override
  Token get endToken {
    return null;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPRawExpression(this);
  }
}

//*-- ReturnStatement
/**
 * A return statement.
 */
abstract class ReturnStatement extends Statement {
  /**
   * The return keyword;
   */
  Token get returnKeyword;

  /**
   * The value to be returned, `null` if this function doesn't return any
   * value.
   */
  Expression get argument;

  /**
   * The semicolon terminating the return statement.
   */
  Token get semicolon;

  @override
  Token get beginToken {
    return this.returnKeyword;
  }

  @override
  Token get endToken {
    return this.semicolon;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPReturnStatement(this);
  }
}

//*-- Script
/**
 * Represents a php script in the document.
 */
abstract class Script extends common.DocumentEntry implements AstNode {
  /**
   * The start tag of the php script.
   */
  Token get startTag;

  /**
   * The statements of the script.
   */
  Block get body;

  /**
   * The end tag of the php script.
   */
  Token get endTag;

  @override
  common.Document get parentNode {
    return null;
  }

  @override
  void set parentNode(common.AstNode node) {}

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
    return visitor.visitPHPScript(this);
  }
}

// TODO: SequenceExpression

//*-- Statement
/**
 * Represents a statement.
 */
abstract class Statement extends AstNode implements AutoReturnable {}

// TODO: rename to SequenceStatement
//*-- Statements
/**
 * A temporary object to hold many php statements.
 */
abstract class Statements extends Statement {
  /**
   * The list of statements.
   */
  List<Statement> statements;

  @override
  Token get beginToken {
    return null;
  }

  @override
  Token get endToken {
    return null;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return null;
  }
}

//*-- StaticPropertyFetch
/**
 * Accessing a static object property or method expression.
 */
abstract class StaticPropertyFetch extends Expression {
  /**
   * The object holding the property to be fetched.
   */
  Expression get target;

  /**
   * The double dot symbol.
   */
  Token get operator;

  /**
   * The property to be accessed.
   */
  Expression get property;

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
    return visitor.visitPHPStaticPropertyFetch(this);
  }
}

//*-- StringLiteral
/**
 * Represents a string literal.
 */
abstract class StringLiteral extends Literal {
  /**
   * The value of string literal.
   */
  String get value {
    // TODO: may not need this
    return this.token.lexeme;
  }

  @override
  Token get token;

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPStringLiteral(this);
  }
}

//*-- SwitchCase
abstract class SwitchCase extends AstNode {
  Token get caseKeyword;

  Expression get test;

  Token get colon;

  List<Statement> get consequent;

  void set consequent(List<Statement> statements);

  @override
  Token get beginToken {
    return this.caseKeyword;
  }

  @override
  Token get endToken {
    return this.consequent.last.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPSwitchCase(this);
  }
}

//*-- SwitchDefault
abstract class SwitchDefault extends AstNode {
  Token get defaultKeyword;

  Token get colon;

  List<Statement> get consequent;

  void set consequent(List<Statement> statements);

  @override
  Token get beginToken {
    return this.defaultKeyword;
  }

  @override
  Token get endToken {
    return this.consequent.last.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPSwitchDefault(this);
  }
}

//*-- SwitchStatement
abstract class SwitchStatement extends Statement {
  Token get switchKeyword;

  Expression get discriminant;

  List<SwitchCase> get cases;

  SwitchDefault get defaultCase;

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
    return visitor.visitPHPSwitchStatement(this);
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
  Token get beginToken {
    return this.throwKeyword;
  }

  @override
  Token get endToken {
    return this.expression.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPThrowStatement(this);
  }
}

//*-- TryStatement
abstract class TryStatement extends Statement {
  Token get tryKeyword;

  Statement get tryStatement;

  Token get catchKeyword;

  Name get catchVariableType;

  Variable get catchVariableName;

  Statement get catchStatement;

  Token get finallyKeyword;

  Statement get finallyStatement;

  bool get hasCatch {
    return this.catchStatement != null;
  }

  bool get isCatchVariableTyped {
    return this.catchVariableType != null;
  }

  bool get hasFinally {
    return this.finallyStatement != null;
  }

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
    return visitor.visitPHPTryStatement(this);
  }
}

//*-- UnaryExpression
/**
 * An unary expression.
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
  Token get beginToken {
    return this.operator.beginToken;
  }

  @override
  Token get endToken {
    return this.argument.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPUnaryExpression(this);
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
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPUnaryOperator(this);
  }
}

//*-- UpdateExpression
/**
 * An update expression.
 */
abstract class UpdateExpression extends Expression {
  /**
   * `true` if the update operator is used as prefix.
   */
  bool get isPrefix;

  /**
   * The update operator.
   */
  UpdateOperator get operator;

  /**
   * The expression used to compute (the variable) to be updated.
   */
  Expression get argument;

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
    return visitor.visitPHPUpdateExpression(this);
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
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPUpdateOperator(this);
  }
}

//*-- Variable
/**
 * A variable identifier.
 */
abstract class Variable extends Expression {
  /**
   * The token that represents the variable.
   */
  Token get token;

  /**
   * The name of the variable, without "$".
   */
  String get name {
    return this.token.lexeme;
  }

  NameElement get element;

  void set element(NameElement element);

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
    return visitor.visitPHPVariable(this);
  }
}

//*-- WhileStatement
/**
 * An while statement.
 */
abstract class WhileStatement extends Statement {
  /**
   * The while keyword.
   */
  Token get whileKeyword;

  /**
   * The left parenthesis.
   */
  Token get leftParen;

  /**
   * The test to be satisfied.
   */
  Expression get test;

  /**
   * The right parenthesis.
   */
  Token get rightParen;

  /**
   * The body statement to be executed while test is satisfied.
   */
  Statement get body;

  @override
  WhileStatement enableAutoReturn(ReturnGenerator generator);

  @override
  Token get beginToken {
    return this.whileKeyword;
  }

  @override
  Token get endToken {
    return this.body.endToken;
  }

  @override
  E accept<E>(Visitor<E> visitor) {
    return visitor.visitPHPWhileStatement(this);
  }
}

// TODO: Mammouth node and php nodes must have similarities
