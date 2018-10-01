library mammouth.language.mammouth.ast.visitor;

import "package:mammouth/src/language/common/ast/visitor.dart" as common;
import "package:mammouth/src/language/php/ast/ast.dart" as php;

abstract class Visitor<E> extends common.Visitor<E> {
  @override
  E visitPHPArrayItem(php.ArrayItem node) {
    return null;
  }

  @override
  E visitPHPArrayLiteral(php.ArrayLiteral node) {
    return null;
  }

  @override
  E visitPHPAssignmentExpression(php.AssignmentExpression node) {
    return null;
  }

  @override
  E visitPHPAssignmentOperator(php.AssignmentOperator node) {
    return null;
  }

  @override
  E visitPHPBinaryExpression(php.BinaryExpression node) {
    return null;
  }

  @override
  E visitPHPBinaryOperator(php.BinaryOperator node) {
    return null;
  }

  @override
  E visitPHPBlock(php.Block node, {bool scope = true}) {
    return null;
  }

  @override
  E visitPHPBooleanLiteral(php.BooleanLiteral node) {
    return null;
  }

  @override
  E visitPHPBreakStatement(php.BreakStatement node) {
    return null;
  }

  @override
  E visitPHPCastExpression(php.CastExpression node) {
    return null;
  }

  @override
  E visitPHPClassDeclaration(php.ClassDeclaration node) {
    return null;
  }

  @override
  E visitPHPClosureExpression(php.ClosureExpression node) {
    return null;
  }

  @override
  E visitPHPConcatenationExpression(php.ConcatenationExpression node) {
    return null;
  }

  @override
  E visitPHPContinueStatement(php.ContinueStatement node) {
    return null;
  }

  @override
  E visitPHPEchoStatement(php.EchoStatement node) {
    return null;
  }

  @override
  E visitPHPExpressionStatement(php.ExpressionStatement node) {
    return null;
  }

  @override
  E visitPHPFieldDeclaration(php.FieldDeclaration node) {
    return null;
  }

  @override
  E visitPHPFloatLiteral(php.FloatLiteral node) {
    return null;
  }

  @override
  E visitPHPForeachStatement(php.ForeachStatement node) {
    return null;
  }

  @override
  E visitPHPForStatement(php.ForStatement node) {
    return null;
  }

  @override
  E visitPHPFunctionCallExpression(php.FunctionCallExpression node) {
    return null;
  }

  @override
  E visitPHPFunctionStatement(php.FunctionStatement node) {
    return null;
  }

  @override
  E visitPHPGlobalStatement(php.GlobalStatement node) {
    return null;
  }

  @override
  E visitPHPIfStatement(php.IfStatement node) {
    return null;
  }

  @override
  E visitPHPIncludeExpression(php.IncludeExpression node) {
    return null;
  }

  @override
  E visitPHPIntegerLiteral(php.IntegerLiteral node) {
    return null;
  }

  @override
  E visitPHPInterfaceDeclaration(php.InterfaceDeclaration node) {
    return null;
  }

  @override
  E visitPHPKeyValue(php.KeyValue node) {
    return null;
  }

  @override
  E visitPHPMethodDeclaration(php.MethodDeclaration node) {
    return null;
  }

  @override
  E visitPHPName(php.Name node) {
    return null;
  }

  @override
  E visitPHPNewExpression(php.NewExpression node) {
    return null;
  }

  @override
  E visitPHPParameter(php.Parameter node) {
    return null;
  }

  @override
  E visitPHPParenthesisExpression(php.ParenthesisExpression node) {
    return null;
  }

  @override
  E visitPHPPropertyFetch(php.PropertyFetch node) {
    return null;
  }

  @override
  E visitPHPRawExpression(php.RawExpression node) {
    return null;
  }

  @override
  E visitPHPReturnStatement(php.ReturnStatement node) {
    return null;
  }

  @override
  E visitPHPScript(php.Script node) {
    return null;
  }

  @override
  E visitPHPStaticPropertyFetch(php.StaticPropertyFetch node) {
    return null;
  }

  @override
  E visitPHPStringLiteral(php.StringLiteral node) {
    return null;
  }

  @override
  E visitPHPSwitchCase(php.SwitchCase node) {
    return null;
  }

  @override
  E visitPHPSwitchDefault(php.SwitchDefault node) {
    return null;
  }

  @override
  E visitPHPSwitchStatement(php.SwitchStatement node) {
    return null;
  }

  @override
  E visitPHPThrowStatement(php.ThrowStatement node) {
    return null;
  }

  @override
  E visitPHPTryStatement(php.TryStatement node) {
    return null;
  }

  @override
  E visitPHPUnaryExpression(php.UnaryExpression node) {
    return null;
  }

  @override
  E visitPHPUnaryOperator(php.UnaryOperator node) {
    return null;
  }

  @override
  E visitPHPUpdateExpression(php.UpdateExpression node) {
    return null;
  }

  @override
  E visitPHPUpdateOperator(php.UpdateOperator node) {
    return null;
  }

  @override
  E visitPHPVariable(php.Variable node) {
    return null;
  }

  @override
  E visitPHPWhileStatement(php.WhileStatement node) {
    return null;
  }
}
