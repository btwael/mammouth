library mammouth.language.common.ast.visitor;

import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/mammouth/ast/ast.dart" as mammouth;
import "package:mammouth/src/language/mammouth/type/type.dart";
import "package:mammouth/src/language/php/ast/ast.dart" as php;

abstract class Visitor<E> {
  E visitDocument(common.Document node);

  E visitInlineEntry(common.InlineEntry node);

  // mammouth

  E visitArgumentList(mammouth.ArgumentList node);

  E visitArrayLiteral(mammouth.ArrayLiteral node);

  E visitAsExpression(mammouth.AsExpression node);

  E visitAssignmentExpression(mammouth.AssignmentExpression node);

  E visitAtExpression(mammouth.AtExpression node);

  E visitBinaryExpression(mammouth.BinaryExpression node);

  E visitBinaryOperator(mammouth.BinaryOperator node);

  E visitAssignmentOperator(mammouth.AssignmentOperator node);

  E visitBlock(mammouth.Block node, {bool scope = true});

  E visitBooleanLiteral(mammouth.BooleanLiteral node);

  E visitBreakStatement(mammouth.BreakStatement node);

  E visitClassExpression(mammouth.ClassExpression node, {InterfaceType type});

  E visitClosureParameter(mammouth.ClosureParameter node);

  E visitConstructorDeclaration(mammouth.ConstructorDeclaration node);

  E visitConverterDeclaration(mammouth.ConverterDeclaration node);

  E visitContinueStatement(mammouth.ContinueStatement node);

  E visitEchoExpression(mammouth.EchoExpression node);

  E visitExistenceExpression(mammouth.ExistenceExpression node);

  E visitExpressionStatement(mammouth.ExpressionStatement node);

  E visitExtendsClause(mammouth.ExtendsClause node);

  E visitFieldDeclaration(mammouth.FieldDeclaration node);

  E visitFloatLiteral(mammouth.FloatLiteral node);

  E visitFunctionExpression(mammouth.FunctionExpression node);

  E visitForExpression(mammouth.ForExpression node);

  E visitForRangeSource(mammouth.ForRangeSource node);

  E visitForVariable(mammouth.ForVariable node);

  E visitForVariableSource(mammouth.ForVariableSource node);

  E visitGuardSource(mammouth.GuardSource node);

  E visitIfExpression(mammouth.IfExpression node);

  E visitIfSource(mammouth.IfSource node);

  E visitImplementsClause(mammouth.ImplementsClause node);

  E visitImportDirective(mammouth.ImportDirective node);

  E visitIndexExpression(mammouth.IndexExpression node);

  E visitInExpression(mammouth.InExpression node);

  E visitIntegerLiteral(mammouth.IntegerLiteral node);

  E visitInterfaceDeclaration(mammouth.InterfaceDeclaration node);

  E visitInvocationExpression(mammouth.InvocationExpression node);

  E visitMMapEntry(mammouth.MMapEntry node);

  E visitMapLiteral(mammouth.MapLiteral node);

  E visitMemberExpression(mammouth.MemberExpression node);

  E visitMethodDeclaration(mammouth.MethodDeclaration node);

  E visitNewExpression(mammouth.NewExpression node);

  E visitNativeExpression(mammouth.NativeExpression node);

  E visitOperatorDeclaration(mammouth.OperatorDeclaration node);

  E visitParameterList(mammouth.ParameterList node);

  E visitParenthesisExpression(mammouth.ParenthesisExpression node);

  E visitRangeLiteral(mammouth.RangeLiteral node);

  E visitRepetitionExpression(mammouth.RepetitionExpression node);

  E visitRepetitionSource(mammouth.RepetitionSource node);

  E visitReturnStatement(mammouth.ReturnStatement node);

  E visitScript(mammouth.Script node);

  E visitSimpleIdentifier(mammouth.SimpleIdentifier node);

  E visitSimpleParameter(mammouth.SimpleParameter node);

  E visitSliceExpression(mammouth.SliceExpression node);

  E visitStringLiteral(mammouth.StringLiteral node);

  E visitSwitchCase(mammouth.SwitchCase node);

  E visitSwitchDefault(mammouth.SwitchDefault node);

  E visitSwitchExpression(mammouth.SwitchExpression node);

  E visitThrowStatement(mammouth.ThrowStatement node);

  E visitToExpression(mammouth.ToExpression node);

  E visitTryExpression(mammouth.TryExpression node);

  E visitTypeArgumentList(mammouth.TypeArgumentList node);

  E visitTypeName(mammouth.TypeName node);

  E visitTypeParameter(mammouth.TypeParameter node) {} // TODO: implement those ever where

  E visitTypeParameterList(mammouth.TypeParameterList node) {}

  E visitUnaryExpression(mammouth.UnaryExpression node);

  E visitUnaryOperator(mammouth.UnaryOperator node);

  E visitUpdateExpression(mammouth.UpdateExpression node);

  E visitUpdateOperator(mammouth.UpdateOperator node);

  E visitVariableDeclarationStatement(
      mammouth.VariableDeclarationStatement node);

  // php

  E visitPHPArrayItem(php.ArrayItem node);

  E visitPHPArrayLiteral(php.ArrayLiteral node);

  E visitPHPAssignmentExpression(php.AssignmentExpression node);

  E visitPHPAssignmentOperator(php.AssignmentOperator node);

  E visitPHPBinaryExpression(php.BinaryExpression node);

  E visitPHPBinaryOperator(php.BinaryOperator node);

  E visitPHPBlock(php.Block node, {bool scope = true});

  E visitPHPBooleanLiteral(php.BooleanLiteral node);

  E visitPHPBreakStatement(php.BreakStatement node);

  E visitPHPCastExpression(php.CastExpression node);

  E visitPHPClassDeclaration(php.ClassDeclaration node);

  E visitPHPClosureExpression(php.ClosureExpression node);

  E visitPHPConcatenationExpression(php.ConcatenationExpression node);

  E visitPHPContinueStatement(php.ContinueStatement node);

  E visitPHPEchoStatement(php.EchoStatement node);

  E visitPHPExpressionStatement(php.ExpressionStatement node);

  E visitPHPFieldDeclaration(php.FieldDeclaration node);

  E visitPHPFloatLiteral(php.FloatLiteral node);

  E visitPHPForeachStatement(php.ForeachStatement node);

  E visitPHPForStatement(php.ForStatement node);

  E visitPHPFunctionCallExpression(php.FunctionCallExpression node);

  E visitPHPFunctionStatement(php.FunctionStatement node);

  E visitPHPGlobalStatement(php.GlobalStatement node);

  E visitPHPIfStatement(php.IfStatement node);

  E visitPHPIncludeExpression(php.IncludeExpression node);

  E visitPHPIntegerLiteral(php.IntegerLiteral node);

  E visitPHPInterfaceDeclaration(php.InterfaceDeclaration node);

  E visitPHPKeyValue(php.KeyValue node);

  E visitPHPMethodDeclaration(php.MethodDeclaration node);

  E visitPHPName(php.Name node);

  E visitPHPNewExpression(php.NewExpression node);

  E visitPHPParameter(php.Parameter node);

  E visitPHPParenthesisExpression(php.ParenthesisExpression node);

  E visitPHPPropertyFetch(php.PropertyFetch node);

  E visitPHPRawExpression(php.RawExpression node);

  E visitPHPReturnStatement(php.ReturnStatement node);

  E visitPHPScript(php.Script node);

  E visitPHPStaticPropertyFetch(php.StaticPropertyFetch node);

  E visitPHPStringLiteral(php.StringLiteral node);

  E visitPHPSwitchCase(php.SwitchCase node);

  E visitPHPSwitchDefault(php.SwitchDefault node);

  E visitPHPSwitchStatement(php.SwitchStatement node);

  E visitPHPThrowStatement(php.ThrowStatement node);

  E visitPHPTryStatement(php.TryStatement node);

  E visitPHPUnaryExpression(php.UnaryExpression node);

  E visitPHPUnaryOperator(php.UnaryOperator node);

  E visitPHPUpdateExpression(php.UpdateExpression node);

  E visitPHPUpdateOperator(php.UpdateOperator node);

  E visitPHPVariable(php.Variable node);

  E visitPHPWhileStatement(php.WhileStatement node);
}
