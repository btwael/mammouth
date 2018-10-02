library mammouth.language.php.ast.implementation;

import "package:mammouth/src/language/common/ast/token.dart"
    show TokenKind, Token, SimpleToken, StringToken;
import "package:mammouth/src/language/php/ast/ast.dart";
import "package:mammouth/src/language/php/element/element.dart";

class ArrayItemImpl extends ArrayItem {
  final Expression target;
  final Token leftBracket;
  final Expression property;
  final Token rightBracket;

  ArrayItemImpl(this.target, this.leftBracket, this.property,
      this.rightBracket);

  ArrayItemImpl.build(this.target, this.property)
      : this.leftBracket = null,
        this.rightBracket = null;
}

class ArrayLiteralImpl extends ArrayLiteral {
  final Token leftBracket;
  final List<Expression> elements;
  final Token rightBracket;

  ArrayLiteralImpl(this.leftBracket, this.elements, this.rightBracket);

  ArrayLiteralImpl.build(this.elements)
      : this.leftBracket = null,
        this.rightBracket = null;
}

class AssignmentExpressionImpl extends AssignmentExpression {
  final Expression leftHandSide;
  final AssignmentOperator operator;
  final Expression rightHandSide;

  AssignmentExpressionImpl(this.leftHandSide, this.operator,
      this.rightHandSide);
}

class AssignmentOperatorImpl extends AssignmentOperator {
  final Token token;

  AssignmentOperatorImpl(this.token);

  AssignmentOperatorImpl.build()
      : this.token = null; // TODO: replace with a token
}

class BinaryExpressionImpl extends BinaryExpression {
  final Expression left;
  final BinaryOperatorImpl operator;
  final Expression right;

  BinaryExpressionImpl(this.left, this.operator, this.right);
}

class BinaryOperatorImpl extends BinaryOperator {
  final Token token;

  BinaryOperatorImpl(this.token);

  BinaryOperatorImpl.build() : this.token = null; // TODO: replace with a token
}

class BlockImpl extends Block {
  final Token leftBrace;
  final List<Statement> statements;
  final Token rightBrace;

  BlockImpl(this.leftBrace, this.statements, this.rightBrace);

  BlockImpl.build(this.statements)
      : this.leftBrace = new SimpleToken(TokenKind.PHP_LEFT_BRACE, null),
        this.rightBrace = new SimpleToken(TokenKind.PHP_RIGHT_BRACE, null);

  Block enableAutoReturn(ReturnGenerator generator) {
    if(this.statements.isEmpty) {
      statements.add(generator(new IntegerLiteralImpl(
          new StringToken(TokenKind.INTEGER, '00', null)))); // TODO: null
    } else {
      Statement result = this.statements.last.enableAutoReturn(generator);
      if(result is Statements) {
        this.statements.removeLast();
        this.statements.addAll(result.statements);
      } else {
        this.statements[this.statements.length - 1] = result;
      }
    }
    return this;
  }
}

class BooleanLiteralImpl extends BooleanLiteral {
  final Token token;

  BooleanLiteralImpl(this.token);

  BooleanLiteralImpl.build(bool value)
      : this.token = new StringToken(
      TokenKind.PHP_BOOLEAN, value ? "TRUE" : "FALSE", null);
}

class BreakStatementImpl extends BreakStatement {
  final Token breakKeyword;

  @override
  BreakStatement enableAutoReturn(ReturnGenerator generator) {
    return this;
  }

  BreakStatementImpl(this.breakKeyword);

  BreakStatementImpl.build() : this.breakKeyword = null;
}

//*-- CastExpressionImpl
class CastExpressionImpl extends CastExpression {
  final String type;
  final Expression expression;

  CastExpressionImpl(this.type, this.expression);
}

class ClassDeclarationImpl extends ClassDeclaration {
  final Token classKeyword;
  final Name name;
  final Name superclass;
  final Token leftBrace;
  final List<ClassMember> members;
  final Token rightBrace;

  ClassDeclarationImpl(this.classKeyword, this.name, this.superclass, this.leftBrace,
      this.members, this.rightBrace);

  ClassDeclarationImpl.build(this.name, this.superclass, this.members)
      : this.classKeyword = null,
        this.leftBrace = new SimpleToken(TokenKind.PHP_LEFT_BRACE, null),
        this.rightBrace = new SimpleToken(TokenKind.PHP_RIGHT_BRACE, null);

  ClassDeclaration enableAutoReturn(ReturnGenerator generator) {
    return this;
  }
}

class ClosureExpressionImpl extends ClosureExpression {
  final Token functionKeyword;
  final Token leftParen;
  final List<Parameter> parameters;
  final Token rightParen;
  final Block body;

  ClosureExpressionImpl(this.functionKeyword, this.leftParen, this.parameters,
      this.rightParen, this.body);

  ClosureExpressionImpl.build(this.parameters, this.body)
      : this.functionKeyword = null,
  // TODO: replace with a token
        this.leftParen = null,
  // TODO: replace with a token
        this.rightParen = null;

  // TODO: replace with a token

  void enableAutoReturn(ReturnGenerator generator) {
    this.body.enableAutoReturn(generator);
  }
}

//*-- ConcatenationExpression
class ConcatenationExpressionImpl extends ConcatenationExpression {
  final Expression left;

  final Expression right;

  ConcatenationExpressionImpl(this.left, this.right);
}

class ContinueStatementImpl extends ContinueStatement {
  final Token continueKeyword;

  @override
  ContinueStatement enableAutoReturn(ReturnGenerator generator) {
    return this;
  }

  ContinueStatementImpl(this.continueKeyword);

  ContinueStatementImpl.build() : this.continueKeyword = null;
}

class EchoStatementImpl extends EchoStatement {
  final Token echoKeyword;
  final Expression expression;
  final Token semicolon;

  EchoStatementImpl(this.echoKeyword, this.expression, this.semicolon);

  EchoStatementImpl.build(this.expression)
      : this.echoKeyword = null,
        this.semicolon = null;

  Statements enableAutoReturn(ReturnGenerator generator) {
    return new StatementsImpl()
      ..statements = [this, generator(this.expression)];
  }
}

class ExpressionStatementImpl extends ExpressionStatement {
  Expression expression;
  final Token semicolon;

  ExpressionStatementImpl(this.expression, this.semicolon);

  ExpressionStatementImpl.build(this.expression) : this.semicolon = null;

// TODO: replace with a token

  Statement enableAutoReturn(ReturnGenerator generator) {
    return generator(this.expression);
  }
}

class FieldDeclarationImpl extends FieldDeclaration {
  final Token visibilityToken;
  final Token staticKeyword;
  final Variable variable;
  final Token equal;
  final Expression initializer;
  final Token semicolon;

  FieldDeclarationImpl(this.visibilityToken, this.staticKeyword, this.variable,
      this.equal, this.initializer, this.semicolon);

  FieldDeclarationImpl.build(this.visibilityToken, this.staticKeyword,
      this.variable, this.initializer)
      : this.equal = null,
        this.semicolon = null;
}

class FloatLiteralImpl extends FloatLiteral {
  final Token token;

  FloatLiteralImpl(this.token);
}

class FunctionCallExpressionImpl extends FunctionCallExpression {
  final Expression function;
  final Token leftParen;
  final List<Expression> arguments;
  final Token rightParen;

  FunctionCallExpressionImpl(this.function, this.leftParen, this.arguments,
      this.rightParen);

  FunctionCallExpressionImpl.build(this.function, this.arguments)
      : this.leftParen = null,
  // TODO: replace with a token
        this.rightParen = null; // TODO: replace with a token
}

class ForeachStatementImpl extends ForeachStatement {
  final Token foreachToken;
  final Token leftParen;
  final Expression expression;
  final Token asKeyword;
  final Variable keyVariable;
  final Token arrow;
  final Variable valueVariable;
  final Token rightParen;
  Statement body;

  ForeachStatementImpl(this.foreachToken,
      this.leftParen,
      this.expression,
      this.asKeyword,
      this.keyVariable,
      this.arrow,
      this.valueVariable,
      this.rightParen,
      this.body);

  ForeachStatementImpl.build(this.expression, this.keyVariable,
      this.valueVariable, this.body)
      : this.foreachToken = null,
        this.leftParen = null,
        this.asKeyword = null,
        this.arrow = null,
        this.rightParen = null;

  ForeachStatement enableAutoReturn(ReturnGenerator generator) {
    this.body = this.body.enableAutoReturn(generator);
    return this;
  }
}

class ForStatementImpl extends ForStatement {
  final Token forToken;
  final Token leftParen;
  final Expression init;
  final Expression test;
  final Expression update;
  final Token rightParen;
  Statement body;

  ForStatementImpl(this.forToken, this.leftParen, this.init, this.test,
      this.update, this.rightParen, this.body);

  ForStatementImpl.build(this.init, this.test, this.update, this.body)
      : this.forToken = null,
        this.leftParen = null,
        this.rightParen = null;

  ForStatement enableAutoReturn(ReturnGenerator generator) {
    this.body = this.body.enableAutoReturn(generator);
    return this;
  }
}

class FunctionStatementImpl extends FunctionStatement {
  final Token functionKeyword;
  final Name name;
  final Token leftParen;
  final List<Parameter> parameters;
  final Token rightParen;
  final Block body;

  FunctionStatementImpl(this.functionKeyword, this.name, this.leftParen,
      this.parameters, this.rightParen, this.body);

  FunctionStatementImpl.build(this.name, this.parameters, this.body)
      : this.functionKeyword = null,
  // TODO: replace with a token
        this.leftParen = null,
  // TODO: replace with a token
        this.rightParen = null;

// TODO: replace with a token

  FunctionStatement enableAutoReturn(ReturnGenerator generator) {
    return this;
  }
}

class GlobalStatementImpl extends GlobalStatement {
  final Token globalKeyword;
  final List<Variable> variables;
  final Token semicolon;

  GlobalStatementImpl(this.globalKeyword, this.variables, this.semicolon);

  GlobalStatementImpl.build(this.variables)
      : this.globalKeyword = null,
  // TODO: replace with a token
        this.semicolon = null;

// TODO: replace with a token

  @override
  GlobalStatement enableAutoReturn(ReturnGenerator generator) {
    return this;
  }
}

class IfStatementImpl extends IfStatement {
  final Token ifKeyword;
  final Token leftParen;
  final Expression condition;
  final Token rightParen;
  Statement consequent;
  final Token elseKeyword;
  Statement alternate;

  IfStatementImpl(this.ifKeyword, this.leftParen, this.condition,
      this.rightParen, this.consequent, this.elseKeyword, this.alternate);

  IfStatementImpl.build(this.condition, this.consequent, this.alternate)
      : this.ifKeyword = null,
  // TODO: replace with a token
        this.leftParen = null,
  // TODO: replace with a token
        this.rightParen = null,
  // TODO: replace with a token
        this.elseKeyword = null; // TODO: replace with a token

  IfStatement enableAutoReturn(ReturnGenerator generator) {
    this.consequent = this.consequent.enableAutoReturn(generator);
    if(this.alternate != null) {
      this.alternate = this.alternate.enableAutoReturn(generator);
    }
    return this;
  }
}

class IncludeExpressionImpl extends IncludeExpression {
  final Expression uri;
  final bool isOnce;

  IncludeExpressionImpl(this.uri, this.isOnce);
}

class IntegerLiteralImpl extends IntegerLiteral {
  final Token token;

  IntegerLiteralImpl(this.token);
}

class InterfaceDeclarationImpl extends InterfaceDeclaration {
  final Token interfaceKeyword;
  final Name name;
  final Token leftBrace;
  final List<ClassMember> members;
  final Token rightBrace;

  InterfaceDeclarationImpl(this.interfaceKeyword, this.name, this.leftBrace,
      this.members, this.rightBrace);

  InterfaceDeclarationImpl.build(this.name, this.members)
      : this.interfaceKeyword = null,
        this.leftBrace = new SimpleToken(TokenKind.PHP_LEFT_BRACE, null),
        this.rightBrace = new SimpleToken(TokenKind.PHP_RIGHT_BRACE, null);

  InterfaceDeclaration enableAutoReturn(ReturnGenerator generator) {
    return this;
  }
}

class KeyValueImpl extends KeyValue {
  final Expression key;
  final Token arrow;
  final Expression value;

  KeyValueImpl(this.key, this.arrow, this.value);

  KeyValueImpl.build(this.key, this.value) : this.arrow = null;
// TODO: replace with a token
}

class MethodDeclarationImpl extends MethodDeclaration {
  final Token visibilityToken;
  final Token staticKeyword;
  final Token functionKeyword;
  final Name name;
  final Token leftParen;
  final List<Parameter> parameters;
  final Token rightParen;
  final Block body;
  bool isAbstract = false;

  MethodDeclarationImpl(this.visibilityToken,
      this.staticKeyword,
      this.functionKeyword,
      this.name,
      this.leftParen,
      this.parameters,
      this.rightParen,
      this.body);

  MethodDeclarationImpl.build(this.visibilityToken, this.staticKeyword,
      this.name, this.parameters, this.body)
      : this.functionKeyword = null,
  // TODO: replace with a token
        this.leftParen = null,
  // TODO: replace with a token
        this.rightParen = null;

  // TODO: replace with a token

  void enableAutoReturn(ReturnGenerator generator) {
    this.body.enableAutoReturn(generator);
  }
}

class NameImpl extends Name {
  final Token token;
  NameElement element;
  bool asString = false;

  NameImpl(this.token);

  NameImpl.build(String name)
      : this.token = new StringToken(TokenKind.PHP_NAME, name, null);
}

class NewExpressionImpl extends NewExpression {
  Token newKeyword;
  Expression target;
  Token leftParen;
  List<Expression> arguments;
  Token rightParen;

  NewExpressionImpl(this.newKeyword, this.target, this.leftParen,
      this.arguments, this.rightParen);

  NewExpressionImpl.build(this.target, this.arguments)
      : this.newKeyword = null,
        this.leftParen = null,
        this.rightParen = null;
}

class NullLiteralImpl extends NullLiteral {
  final Token token;

  NullLiteralImpl(this.token);

  NullLiteralImpl.build()
      : this.token = null;
}

class ParameterImpl extends Parameter {
  final Variable variable;

  ParameterImpl(this.variable);
}

class ParenthesisExpressionImpl extends ParenthesisExpression {
  final Token leftParenthesis;
  final Expression expression;
  final Token rightParenthesis;

  ParenthesisExpressionImpl(this.leftParenthesis, this.expression,
      this.rightParenthesis);

  ParenthesisExpressionImpl.build(this.expression)
      : this.leftParenthesis = null,
        this.rightParenthesis = null;
}

class PropertyFetchImpl extends PropertyFetch {
  final Expression target;
  final Token operator;
  final Expression property;

  PropertyFetchImpl(this.target, this.operator, this.property);

  PropertyFetchImpl.build(this.target, this.property) : this.operator = null;
}

class RawExpressionImpl extends RawExpression {
  final String content;
  final List<Expression> arguments;

  RawExpressionImpl(this.content, this.arguments);
}

class ReturnStatementImpl extends ReturnStatement {
  final Token returnKeyword;
  final Expression argument;
  final Token semicolon;

  ReturnStatementImpl(this.returnKeyword, this.argument, this.semicolon);

  ReturnStatementImpl.build(this.argument)
      : this.returnKeyword = null,
  // TODO: replace with a token
        this.semicolon = null;

// TODO: replace with a token

  ReturnStatement enableAutoReturn(ReturnGenerator generator) {
    return this;
  }
}

class ScriptImpl extends Script {
  final Token startTag;
  final Block body;
  final Token endTag;

  ScriptImpl(this.startTag, this.body, this.endTag);

  ScriptImpl.build(this.body)
      : this.startTag = new SimpleToken(TokenKind.PHP_START_TAG, null),
        this.endTag = new SimpleToken(TokenKind.PHP_END_TAG, null);
}

class StatementsImpl extends Statements {
  List<Statement> statements;

  StatementsImpl enableAutoReturn(ReturnGenerator generator) {
    return this;
  }
}

class StaticPropertyFetchImpl extends StaticPropertyFetch {
  final Expression target;
  final Token operator;
  final Expression property;

  StaticPropertyFetchImpl(this.target, this.operator, this.property);

  StaticPropertyFetchImpl.build(this.target, this.property)
      : this.operator = null;
}

class StringLiteralImpl extends StringLiteral {
  final Token token;

  StringLiteralImpl(this.token);
}

class SwitchCaseImpl extends SwitchCase {
  final Token caseKeyword;
  final Expression test;
  final Token colon;
  List<Statement> consequent;

  SwitchCaseImpl(this.caseKeyword, this.test, this.colon, this.consequent);

  SwitchCaseImpl.build(this.test, this.consequent)
      : this.caseKeyword = null,
        this.colon = null;
}

class SwitchDefaultImpl extends SwitchDefault {
  final Token defaultKeyword;
  final Token colon;
  List<Statement> consequent;

  SwitchDefaultImpl(this.defaultKeyword, this.colon, this.consequent);

  SwitchDefaultImpl.build(this.consequent)
      : this.defaultKeyword = null,
        this.colon = null;
}

class SwitchStatementImpl extends SwitchStatement {
  final Token switchKeyword;
  final Expression discriminant;
  final List<SwitchCase> cases;
  final SwitchDefault defaultCase;

  SwitchStatementImpl(this.switchKeyword, this.discriminant, this.cases,
      this.defaultCase);

  SwitchStatementImpl.build(this.discriminant, this.cases, this.defaultCase)
      : this.switchKeyword = null;

  SwitchStatement enableAutoReturn(ReturnGenerator generator) {
    this.cases.forEach((SwitchCase switchCase) {
      switchCase.consequent = ((new BlockImpl.build(switchCase.consequent))
        ..enableAutoReturn(generator))
          .statements;
    });
    if(this.defaultCase != null) {
      this.defaultCase.consequent =
          ((new BlockImpl.build(this.defaultCase.consequent))
            ..enableAutoReturn(generator))
              .statements;
    }
    return this;
  }
}

class ThrowStatementImpl extends ThrowStatement {
  final Token throwKeyword;
  final Expression expression;

  ThrowStatementImpl(this.throwKeyword, this.expression);

  ThrowStatementImpl.build(this.expression) : this.throwKeyword = null;

  ThrowStatement enableAutoReturn(ReturnGenerator generator) {
    return this;
  }
}

//*-- TryStatementImpl
/**
 * TODO:
 */
class TryStatementImpl extends TryStatement {
  final Token tryKeyword;
  final Statement tryStatement;
  final Token catchKeyword;
  final Name catchVariableType;
  final Variable catchVariableName;
  final Statement catchStatement;
  final Token finallyKeyword;
  final Statement finallyStatement;

  TryStatementImpl(this.tryKeyword,
      this.tryStatement,
      this.catchKeyword,
      this.catchVariableType,
      this.catchVariableName,
      this.catchStatement,
      this.finallyKeyword,
      this.finallyStatement);

  TryStatementImpl.build(this.tryStatement, this.catchVariableType,
      this.catchVariableName, this.catchStatement, this.finallyStatement)
      : this.tryKeyword = null,
        this.catchKeyword = null,
        this.finallyKeyword = null;

  TryStatement enableAutoReturn(ReturnGenerator generator) {
    this.tryStatement.enableAutoReturn(generator);
    return this;
  }
}

class UnaryExpressionImpl extends UnaryExpression {
  final UnaryOperator operator;
  final Expression argument;

  UnaryExpressionImpl(this.operator, this.argument);
}

class UnaryOperatorImpl extends UnaryOperator {
  final Token token;

  UnaryOperatorImpl(this.token);

  UnaryOperatorImpl.build() : this.token = null; // TODO: replace with a token
}

class UpdateExpressionImpl extends UpdateExpression {
  final bool isPrefix;
  final UpdateOperator operator;
  final Expression argument;

  UpdateExpressionImpl(this.isPrefix, this.operator, this.argument);
}

class UpdateOperatorImpl extends UpdateOperator {
  final Token token;

  UpdateOperatorImpl(this.token);

  UpdateOperatorImpl.build() : this.token = null; // TODO: replace with a token
}

class VariableImpl extends Variable {
  final Token token;
  NameElement element;

  VariableImpl(this.token);

  VariableImpl.build(String name)
      : this.token = new StringToken(TokenKind.PHP_VARIABLE, name, null);
}

class WhileStatementImpl extends WhileStatement {
  final Token whileKeyword;
  final Token leftParen;
  final Expression test;
  final Token rightParen;
  Statement body;

  WhileStatementImpl(this.whileKeyword, this.leftParen, this.test,
      this.rightParen, this.body);

  WhileStatementImpl.build(this.test, this.body)
      : this.whileKeyword = null,
  // TODO: replace with a token
        this.leftParen = null,
  // TODO: replace with a token
        this.rightParen = null; // TODO: replace with a token

  WhileStatement enableAutoReturn(ReturnGenerator generator) {
    this.body = this.body.enableAutoReturn(generator);
    return this;
  }
}
