import "package:mammouth/src/language/common/ast/ast.dart";
import "package:mammouth/src/language/mammouth/ast/ast.dart" as mammouth;
import "package:mammouth/src/language/mammouth/ast/implementation.dart" as mammouth;
import "package:mammouth/src/language/mammouth/ast/visitor.dart";
import "package:mammouth/src/language/mammouth/type/type.dart";

class Cloner extends Visitor<mammouth.AstNode> {
  @override
  mammouth.AstNode visitDocument(Document node) {
    return null;
  }

  @override
  mammouth.AstNode visitInlineEntry(InlineEntry node) {
    return null;
  }

  @override
  mammouth.ArgumentList visitArgumentList(mammouth.ArgumentList node) {
    return new mammouth.ArgumentListImpl(
        node.arguments.map((mammouth.Expression argument) {
          return argument.accept(this) as mammouth.Expression;
        }).toList());
  }

  @override
  mammouth.ArrayLiteral visitArrayLiteral(mammouth.ArrayLiteral node) {
    return new mammouth.ArrayLiteralImpl(
        node.typeArguments?.accept(this) as mammouth.TypeArgumentList,
        node.elements.map((mammouth.Expression element) {
          return element.accept(this) as mammouth.Expression;
        }));
  }

  @override
  mammouth.AsExpression visitAsExpression(mammouth.AsExpression node) {
    return new mammouth.AsExpressionImpl(
        node.argument.accept(this) as mammouth.Expression,
        node.type.accept(this) as mammouth.TypeAnnotation);
  }

  @override
  mammouth.AssignmentExpression visitAssignmentExpression(
      mammouth.AssignmentExpression node) {
    return new mammouth.AssignmentExpressionImpl(
        node.left.accept(this) as mammouth.Expression,
        node.operator.accept(this) as mammouth.AssignmentOperator,
        node.right.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.AssignmentOperator visitAssignmentOperator(
      mammouth.AssignmentOperator node) {
    return new mammouth.AssignmentOperatorImpl(node.lexeme);
  }

  @override
  mammouth.AtExpression visitAtExpression(mammouth.AtExpression node) {
    return new mammouth.AtExpressionImpl(
        node.property.accept(this) as mammouth.SimpleIdentifier);
  }

  @override
  mammouth.BinaryExpression visitBinaryExpression(
      mammouth.BinaryExpression node) {
    return new mammouth.BinaryExpressionImpl(
        node.left.accept(this) as mammouth.Expression,
        node.operator.accept(this) as mammouth.BinaryOperator,
        node.right.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.BinaryOperator visitBinaryOperator(mammouth.BinaryOperator node) {
    return new mammouth.BinaryOperatorImpl(node.lexeme, node.precedence);
  }

  @override
  mammouth.Block visitBlock(mammouth.Block node, {bool scope = true}) {
    return new mammouth.BlockImpl(
        node.statements.map((mammouth.Statement statement) {
          return statement.accept(this) as mammouth.Statement;
        }).toList());
  }

  @override
  mammouth.BooleanLiteral visitBooleanLiteral(mammouth.BooleanLiteral node) {
    return new mammouth.BooleanLiteralImpl(node.raw);
  }

  @override
  mammouth.BreakStatement visitBreakStatement(mammouth.BreakStatement node) {
    return new mammouth.BreakStatementImpl();
  }

  @override
  mammouth.ClassExpression visitClassExpression(mammouth.ClassExpression node,
      {InterfaceType type}) {
    // TODO: mangle the new class name
    return new mammouth.ClassExpressionImpl(
        new mammouth.SimpleIdentifierImpl(node.name.name + "____"),
        null,
        node.extendsClause?.accept(this) as mammouth.ExtendsClause,
        node.implementsClause?.accept(this) as mammouth.ImplementsClause,
        node.members.map((mammouth.ClassMember member) {
          return member.accept(this) as mammouth.ClassMember;
        }).toList());
  }

  @override
  mammouth.ClosureParameter visitClosureParameter(
      mammouth.ClosureParameter node) {
    return new mammouth.ClosureParameterImpl(
        node.returnType.accept(this) as mammouth.TypeAnnotation,
        node.name.accept(this) as mammouth.SimpleIdentifier,
        node.parameterTypes.map((mammouth.TypeAnnotation type) {
          return type.accept(this) as mammouth.TypeAnnotation;
        }),
        node.isOptional);
  }

  @override
  mammouth.ConstructorDeclaration visitConstructorDeclaration(
      mammouth.ConstructorDeclaration node) {
    return new mammouth.ConstructorDeclarationImpl(
        node.visibility,
        node.parameters.accept(this) as mammouth.ParameterList,
        node.isInline,
        node.body.accept(this) as mammouth.Block);
  }

  @override
  mammouth.ContinueStatement visitContinueStatement(
      mammouth.ContinueStatement node) {
    return new mammouth.ContinueStatementImpl();
  }

  @override
  mammouth.ConverterDeclaration visitConverterDeclaration(
      mammouth.ConverterDeclaration node) {
    return new mammouth.ConverterDeclarationImpl(
        node.isAbstract, node.visibility,
        node.returnType.accept(this) as mammouth.TypeAnnotation,
        node.body.accept(this) as mammouth.Block);
  }

  @override
  mammouth.EchoExpression visitEchoExpression(mammouth.EchoExpression node) {
    return new mammouth.EchoExpressionImpl(
        node.argument.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.ExistenceExpression visitExistenceExpression(
      mammouth.ExistenceExpression node) {
    return new mammouth.ExistenceExpressionImpl(
        node.argument.accept(this) as mammouth.ElementReferenceExpression);
  }

  @override
  mammouth.ExpressionStatement visitExpressionStatement(
      mammouth.ExpressionStatement node) {
    return new mammouth.ExpressionStatementImpl(
        node.expression.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.ExtendsClause visitExtendsClause(mammouth.ExtendsClause node) {
    return new mammouth.ExtendsClauseImpl(
        node.superclass.accept(this) as mammouth.TypeAnnotation);
  }

  @override
  mammouth.FieldDeclaration visitFieldDeclaration(
      mammouth.FieldDeclaration node) {
    return new mammouth.FieldDeclarationImpl(node.visibility, node.isStatic,
        node.type?.accept(this) as mammouth.TypeAnnotation,
        node.name.accept(this) as mammouth.SimpleIdentifier,
        node.initializer?.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.FloatLiteral visitFloatLiteral(mammouth.FloatLiteral node) {
    return new mammouth.FloatLiteralImpl(node.raw);
  }

  @override
  mammouth.ForExpression visitForExpression(mammouth.ForExpression node) {
    return new mammouth.ForExpressionImpl(
        node.source.accept(this) as mammouth.ForSource,
        node.body.accept(this) as mammouth.Statement);
  }

  @override
  mammouth.ForRangeSource visitForRangeSource(mammouth.ForRangeSource node) {
    return new mammouth.ForRangeSourceImpl(
        node.source.accept(this) as mammouth.RangeLiteral,
        node.name.accept(this) as mammouth.ForVariable,
        node.step?.accept(this) as mammouth.Expression,
        node.guard?.accept(this) as mammouth.GuardSource);
  }

  @override
  mammouth.ForVariable visitForVariable(mammouth.ForVariable node) {
    return new mammouth.ForVariableImpl(
        node.type.accept(this) as mammouth.TypeAnnotation,
        node.name.accept(this) as mammouth.SimpleIdentifier);
  }

  @override
  mammouth.ForVariableSource visitForVariableSource(
      mammouth.ForVariableSource node) {
    return new mammouth.ForVariableSourceImpl(
        node.firstVariable.accept(this) as mammouth.ForVariable,
        node.secondVariable?.accept(this) as mammouth.ForVariable,
        node.kind,
        node.source.accept(this) as mammouth.Expression,
        node.step?.accept(this) as mammouth.Expression,
        node.guard?.accept(this) as mammouth.GuardSource);
  }

  @override
  mammouth.FunctionExpression visitFunctionExpression(
      mammouth.FunctionExpression node) {
    return new mammouth.FunctionExpressionImpl.syntactic(
        node.returnType.accept(this) as mammouth.TypeAnnotation,
        node.name.accept(this) as mammouth.SimpleIdentifier,
        node.parameters?.accept(this) as mammouth.ParameterList,
        node.inlineKeyword,
        node.arrow,
        node.body.accept(this) as mammouth.Block);
  }

  @override
  mammouth.GuardSource visitGuardSource(mammouth.GuardSource node) {
    return new mammouth.GuardSourceImpl(
        node.condition.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.IfExpression visitIfExpression(mammouth.IfExpression node) {
    return new mammouth.IfExpressionImpl(
        node.ifSource.accept(this) as mammouth.IfSource,
        node.consequent.accept(this) as mammouth.Statement,
        node.alternate?.accept(this) as mammouth.Statement);
  }

  @override
  mammouth.IfSource visitIfSource(mammouth.IfSource node) {
    return new mammouth.IfSourceImpl(
        node.condition.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.ImplementsClause visitImplementsClause(
      mammouth.ImplementsClause node) {
    return new mammouth.ImplementsClauseImpl(
        node.interfaces.map((mammouth.TypeAnnotation interface) {
          return interface.accept(this) as mammouth.TypeAnnotation;
        }));
  }

  @override
  mammouth.ImportDirective visitImportDirective(mammouth.ImportDirective node) {
    return new mammouth.ImportDirectiveImpl(
        node.uri.accept(this) as mammouth.StringLiteral);
  }

  @override
  mammouth.IndexExpression visitIndexExpression(mammouth.IndexExpression node) {
    return new mammouth.IndexExpressionImpl(
        node.target.accept(this) as mammouth.Expression,
        node.index.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.InExpression visitInExpression(mammouth.InExpression node) {
    return new mammouth.InExpressionImpl(
        node.element.accept(this) as mammouth.Expression,
        node.container.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.IntegerLiteral visitIntegerLiteral(mammouth.IntegerLiteral node) {
    return new mammouth.IntegerLiteralImpl(node.raw);
  }

  @override
  mammouth.InterfaceDeclaration visitInterfaceDeclaration(
      mammouth.InterfaceDeclaration node) {
    return new mammouth.InterfaceDeclarationImpl(
        node.name.accept(this) as mammouth.SimpleIdentifier,
        node.implementsClause.accept(this) as mammouth.ImplementsClause,
        node.members.map((mammouth.ClassMember member) {
          return member.accept(this) as mammouth.ClassMember;
        }));
  }

  @override
  mammouth.InvocationExpression visitInvocationExpression(
      mammouth.InvocationExpression node) {
    return new mammouth.InvocationExpressionImpl(
        node.callee.accept(this) as mammouth.ElementReferenceExpression,
        node.arguments.accept(this) as mammouth.ArgumentList);
  }

  @override
  mammouth.MMapEntry visitMMapEntry(mammouth.MMapEntry node) {
    return new mammouth.MMapEntryImpl(
        node.key.accept(this) as mammouth.Expression,
        node.value.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.MapLiteral visitMapLiteral(mammouth.MapLiteral node) {
    return new mammouth.MapLiteralImpl(
        node.typeArguments?.accept(this) as mammouth.TypeArgumentList,
        node.entries.map((mammouth.MMapEntry entry) {
          return entry.accept(this) as mammouth.MMapEntry;
        }));
  }

  @override
  mammouth.MemberExpression visitMemberExpression(
      mammouth.MemberExpression node) {
    return new mammouth.MemberExpressionImpl(
        node.target.accept(this) as mammouth.Expression,
        node.property.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.MethodDeclaration visitMethodDeclaration(
      mammouth.MethodDeclaration node) {
    return new mammouth.MethodDeclarationImpl(
        node.isAbstract,
        node.visibility,
        node.isStatic,
        node.returnType.accept(this) as mammouth.TypeAnnotation,
        node.propertyLexeme,
        node.name.accept(this) as mammouth.SimpleIdentifier,
        node.parameters?.accept(this) as mammouth.ParameterList,
        node.isInline,
        node.body.accept(this) as mammouth.Block);
  }

  @override
  mammouth.NativeExpression visitNativeExpression(
      mammouth.NativeExpression node) {
    return new mammouth.NativeExpressionImpl(
        node.arguments.accept(this) as mammouth.ArgumentList);
  }

  @override
  mammouth.NewExpression visitNewExpression(mammouth.NewExpression node) {
    return new mammouth.NewExpressionImpl(
        node.callee.accept(this) as mammouth.TypeAnnotation,
        node.arguments?.accept(this) as mammouth.ArgumentList);
  }

  @override
  mammouth.OperatorDeclaration visitOperatorDeclaration(
      mammouth.OperatorDeclaration node) {
    return new mammouth.OperatorDeclarationImpl(
        node.isAbstract,
        node.visibility,
        node.returnType.accept(this) as mammouth.TypeAnnotation,
        node.operatorType,
        node.operator.accept(this) as mammouth.Operator,
        node.parameters?.accept(this) as mammouth.ParameterList,
        node.isInline,
        node.body.accept(this) as mammouth.Block);
  }

  @override
  mammouth.ParameterList visitParameterList(mammouth.ParameterList node) {
    return new mammouth.ParameterListImpl(
        node.parameters.map((mammouth.Parameter parameter) {
          return parameter.accept(this) as mammouth.Parameter;
        }).toList());
  }

  @override
  mammouth.ParenthesisExpression visitParenthesisExpression(
      mammouth.ParenthesisExpression node) {
    return new mammouth.ParenthesisExpressionImpl(
        node.expression.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.RangeLiteral visitRangeLiteral(mammouth.RangeLiteral node) {
    return new mammouth.RangeLiteralImpl(
        node.start.accept(this) as mammouth.Expression,
        node.operator, // TODO: clone
        node.end.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.RepetitionExpression visitRepetitionExpression(
      mammouth.RepetitionExpression node) {
    return new mammouth.RepetitionExpressionImpl(
        node.source.accept(this) as mammouth.RepetitionSource,
        node.body.accept(this) as mammouth.Statement);
  }

  @override
  mammouth.RepetitionSource visitRepetitionSource(
      mammouth.RepetitionSource node) {
    return new mammouth.RepetitionSourceImpl(
        node.keyword, //  TODO: clone
        node.test?.accept(this) as mammouth.Expression,
        node.guard.accept(this) as mammouth.GuardSource);
  }

  @override
  mammouth.ReturnStatement visitReturnStatement(mammouth.ReturnStatement node) {
    return new mammouth.ReturnStatementImpl(
        node.expression.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.Script visitScript(mammouth.Script node) {
    return null;
  }

  @override
  mammouth.SimpleIdentifier visitSimpleIdentifier(
      mammouth.SimpleIdentifier node) {
    return new mammouth.SimpleIdentifierImpl(node.name);
  }

  @override
  mammouth.SimpleParameter visitSimpleParameter(mammouth.SimpleParameter node) {
    return new mammouth.SimpleParameterImpl(
        node.type?.accept(this) as mammouth.TypeAnnotation,
        node.name.accept(this) as mammouth.SimpleIdentifier,
        node.initializer?.accept(this) as mammouth.Expression,
        node.isOptional);
  }

  @override
  mammouth.SliceExpression visitSliceExpression(mammouth.SliceExpression node) {
    return new mammouth.SliceExpressionImpl(
        node.expression.accept(this) as mammouth.Expression,
        node.slicingRange.accept(this) as mammouth.RangeLiteral);
  }

  @override
  mammouth.StringLiteral visitStringLiteral(mammouth.StringLiteral node) {
    return new mammouth.StringLiteralImpl(node.raw);
  }

  @override
  mammouth.SwitchCase visitSwitchCase(mammouth.SwitchCase node) {
    return new mammouth.SwitchCaseImpl(
        node.test.accept(this) as mammouth.Expression,
        node.consequent.accept(this) as mammouth.Statement);
  }

  @override
  mammouth.SwitchDefault visitSwitchDefault(mammouth.SwitchDefault node) {
    return new mammouth.SwitchDefaultImpl(
        node.consequent.accept(this) as mammouth.Statement);
  }

  @override
  mammouth.SwitchExpression visitSwitchExpression(
      mammouth.SwitchExpression node) {
    return new mammouth.SwitchExpressionImpl(
        node.discriminant.accept(this) as mammouth.Expression,
        node.cases.map((mammouth.SwitchCase scase) {
          return scase.accept(this) as mammouth.SwitchCase;
        }).toList(),
        node.defaultCase?.accept(this) as mammouth.SwitchDefault);
  }

  @override
  mammouth.ThrowStatement visitThrowStatement(mammouth.ThrowStatement node) {
    return new mammouth.ThrowStatementImpl(
        node.expression.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.ToExpression visitToExpression(mammouth.ToExpression node) {
    return new mammouth.ToExpressionImpl(
        node.argument.accept(this) as mammouth.Expression,
        node.type.accept(this) as mammouth.TypeAnnotation);
  }

  @override
  mammouth.TryExpression visitTryExpression(mammouth.TryExpression node) {
    return new mammouth.TryExpressionImpl(
        node.tryStatement.accept(this) as mammouth.Statement,
        node.catchVariable?.accept(this) as mammouth.SimpleParameter,
        node.catchStatement?.accept(this) as mammouth.Statement,
        node.finallyStatement?.accept(this) as mammouth.Statement);
  }

  @override
  mammouth.TypeArgumentList visitTypeArgumentList(
      mammouth.TypeArgumentList node) {
    return new mammouth.TypeArgumentListImpl(
        null, node.arguments.map((mammouth.TypeAnnotation argument) {
      return argument.accept(this) as mammouth.TypeAnnotation;
    }).toList(), null);
  }

  @override
  mammouth.TypeName visitTypeName(mammouth.TypeName node) {
    return new mammouth.TypeNameImpl(
        node.name.accept(this) as mammouth.SimpleIdentifier,
        node.typeArguments?.accept(this) as mammouth.TypeArgumentList);
  }

  @override
  mammouth.TypeParameter visitTypeParameter(mammouth.TypeParameter node) {
    return new mammouth.TypeParameterImpl(
        node.name.accept(this) as mammouth.SimpleIdentifier);
  }

  @override
  mammouth.TypeParameterList visitTypeParameterList(
      mammouth.TypeParameterList node) {
    return new mammouth.TypeParameterListImpl(
        node.parameters.map((mammouth.TypeParameter parameter) {
          return parameter.accept(this) as mammouth.TypeParameter;
        }).toList());
  }

  @override
  mammouth.UnaryExpression visitUnaryExpression(mammouth.UnaryExpression node) {
    return new mammouth.UnaryExpressionImpl(
        node.operator.accept(this) as mammouth.UnaryOperator,
        node.argument.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.UnaryOperator visitUnaryOperator(mammouth.UnaryOperator node) {
    return new mammouth.UnaryOperatorImpl(node.lexeme);
  }

  @override
  mammouth.UpdateExpression visitUpdateExpression(
      mammouth.UpdateExpression node) {
    return new mammouth.UpdateExpressionImpl(
        node.isPrefix, node.operator.accept(this) as mammouth.UpdateOperator,
        node.argument.accept(this) as mammouth.Expression);
  }

  @override
  mammouth.UpdateOperator visitUpdateOperator(mammouth.UpdateOperator node) {
    return new mammouth.UpdateOperatorImpl(node.lexeme);
  }

  @override
  mammouth.VariableDeclarationStatement visitVariableDeclarationStatement(
      mammouth.VariableDeclarationStatement node) {
    return new mammouth.VariableDeclarationStatementImpl(
        node.type.accept(this) as mammouth.TypeAnnotation,
        node.name.accept(this) as mammouth.SimpleIdentifier,
        node.initializer?.accept(this) as mammouth.Expression);
  }
}