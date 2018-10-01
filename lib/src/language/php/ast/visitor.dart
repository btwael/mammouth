library mammouth.language.php.ast.visitor;

import "package:mammouth/src/language/common/ast/visitor.dart" as common;
import "package:mammouth/src/language/mammouth/ast/ast.dart" as mammouth;
import "package:mammouth/src/language/mammouth/type/type.dart";


abstract class Visitor<E> extends common.Visitor<E> {
  @override
  E visitArgumentList(mammouth.ArgumentList node) {
    return null;
  }

  @override
  E visitArrayLiteral(mammouth.ArrayLiteral node) {
    return null;
  }

  @override
  E visitAsExpression(mammouth.AsExpression node) {
    return null;
  }

  @override
  E visitAssignmentExpression(mammouth.AssignmentExpression node) {
    return null;
  }

  @override
  E visitAtExpression(mammouth.AtExpression node) {
    return null;
  }

  @override
  E visitBinaryExpression(mammouth.BinaryExpression node) {
    return null;
  }

  @override
  E visitBinaryOperator(mammouth.BinaryOperator node) {
    return null;
  }

  @override
  E visitAssignmentOperator(mammouth.AssignmentOperator node) {
    return null;
  }

  @override
  E visitBlock(mammouth.Block node, {bool scope = true}) {
    return null;
  }

  @override
  E visitBooleanLiteral(mammouth.BooleanLiteral node) {
    return null;
  }

  @override
  E visitBreakStatement(mammouth.BreakStatement node) {
    return null;
  }

  @override
  E visitClassExpression(mammouth.ClassExpression node, {InterfaceType type}) {
    return null;
  }

  @override
  E visitClosureParameter(mammouth.ClosureParameter node) {
    return null;
  }

  @override
  E visitConstructorDeclaration(mammouth.ConstructorDeclaration node) {
    return null;
  }

  @override
  E visitConverterDeclaration(mammouth.ConverterDeclaration node) {
    return null;
  }

  @override
  E visitContinueStatement(mammouth.ContinueStatement node) {
    return null;
  }

  @override
  E visitEchoExpression(mammouth.EchoExpression node) {
    return null;
  }

  @override
  E visitExistenceExpression(mammouth.ExistenceExpression node) {
    return null;
  }

  @override
  E visitExpressionStatement(mammouth.ExpressionStatement node) {
    return null;
  }

  @override
  E visitExtendsClause(mammouth.ExtendsClause node) {
    return null;
  }

  @override
  E visitFieldDeclaration(mammouth.FieldDeclaration node) {
    return null;
  }

  @override
  E visitFloatLiteral(mammouth.FloatLiteral node) {
    return null;
  }

  @override
  E visitFunctionExpression(mammouth.FunctionExpression node) {
    return null;
  }

  @override
  E visitForExpression(mammouth.ForExpression node) {
    return null;
  }

  @override
  E visitForRangeSource(mammouth.ForRangeSource node) {
    return null;
  }

  @override
  E visitForVariable(mammouth.ForVariable node) {
    return null;
  }

  @override
  E visitForVariableSource(mammouth.ForVariableSource node) {
    return null;
  }

  @override
  E visitGuardSource(mammouth.GuardSource node) {
    return null;
  }

  @override
  E visitIfExpression(mammouth.IfExpression node) {
    return null;
  }

  @override
  E visitIfSource(mammouth.IfSource node) {
    return null;
  }

  @override
  E visitImplementsClause(mammouth.ImplementsClause node) {
    return null;
  }

  @override
  E visitImportDirective(mammouth.ImportDirective node) {
    return null;
  }

  @override
  E visitIndexExpression(mammouth.IndexExpression node) {
    return null;
  }

  @override
  E visitInExpression(mammouth.InExpression node) {
    return null;
  }

  @override
  E visitIntegerLiteral(mammouth.IntegerLiteral node) {
    return null;
  }

  @override
  E visitInterfaceDeclaration(mammouth.InterfaceDeclaration node) {
    return null;
  }

  @override
  E visitInvocationExpression(mammouth.InvocationExpression node) {
    return null;
  }

  @override
  E visitMMapEntry(mammouth.MMapEntry node) {
    return null;
  }

  @override
  E visitMapLiteral(mammouth.MapLiteral node) {
    return null;
  }

  @override
  E visitMemberExpression(mammouth.MemberExpression node) {
    return null;
  }

  @override
  E visitMethodDeclaration(mammouth.MethodDeclaration node) {
    return null;
  }

  @override
  E visitNewExpression(mammouth.NewExpression node) {
    return null;
  }

  @override
  E visitNativeExpression(mammouth.NativeExpression node) {
    return null;
  }

  @override
  E visitOperatorDeclaration(mammouth.OperatorDeclaration node) {
    return null;
  }

  @override
  E visitParameterList(mammouth.ParameterList node) {
    return null;
  }

  @override
  E visitParenthesisExpression(mammouth.ParenthesisExpression node) {
    return null;
  }

  @override
  E visitRangeLiteral(mammouth.RangeLiteral node) {
    return null;
  }

  @override
  E visitRepetitionExpression(mammouth.RepetitionExpression node) {
    return null;
  }

  @override
  E visitRepetitionSource(mammouth.RepetitionSource node) {
    return null;
  }

  @override
  E visitReturnStatement(mammouth.ReturnStatement node) {
    return null;
  }

  @override
  E visitScript(mammouth.Script node) {
    return null;
  }

  @override
  E visitSimpleIdentifier(mammouth.SimpleIdentifier node) {
    return null;
  }

  @override
  E visitSimpleParameter(mammouth.SimpleParameter node) {
    return null;
  }

  @override
  E visitSliceExpression(mammouth.SliceExpression node) {
    return null;
  }

  @override
  E visitStringLiteral(mammouth.StringLiteral node) {
    return null;
  }

  @override
  E visitSwitchCase(mammouth.SwitchCase node) {
    return null;
  }

  @override
  E visitSwitchDefault(mammouth.SwitchDefault node) {
    return null;
  }

  @override
  E visitSwitchExpression(mammouth.SwitchExpression node) {
    return null;
  }

  @override
  E visitThrowStatement(mammouth.ThrowStatement node) {
    return null;
  }

  @override
  E visitToExpression(mammouth.ToExpression node) {
    return null;
  }

  @override
  E visitTryExpression(mammouth.TryExpression node) {
    return null;
  }

  @override
  E visitTypeArgumentList(mammouth.TypeArgumentList node) {
    return null;
  }

  @override
  E visitTypeName(mammouth.TypeName node) {
    return null;
  }

  @override
  E visitTypeParameter(mammouth.TypeParameter node) {
    return null;
  }

  @override
  E visitTypeParameterList(mammouth.TypeParameterList node) {
    return null;
  }

  @override
  E visitUnaryExpression(mammouth.UnaryExpression node) {
    return null;
  }

  @override
  E visitUnaryOperator(mammouth.UnaryOperator node) {
    return null;
  }

  @override
  E visitUpdateExpression(mammouth.UpdateExpression node) {
    return null;
  }

  @override
  E visitUpdateOperator(mammouth.UpdateOperator node) {
    return null;
  }

  @override
  E visitVariableDeclarationStatement(
      mammouth.VariableDeclarationStatement node) {
    return null;
  }
}
