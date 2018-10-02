library mammouth.semantic.parentResolver;

import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/mammouth/ast/ast.dart" as mammouth;
import "package:mammouth/src/language/mammouth/ast/visitor.dart" as mammouth;
import "package:mammouth/src/language/mammouth/type/type.dart";


//*-- ParentResolver
/**
 * Completes the ast with missing information about parent node of each node.
 */
class ParentResolver extends mammouth.Visitor {
  @override
  void visitDocument(common.Document node) {
    node.entries.forEach((common.DocumentEntry entry) {
      entry.parentNode = node;
      entry.accept(this);
    });
  }

  @override
  void visitInlineEntry(common.InlineEntry node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitArgumentList(mammouth.ArgumentList node) {
    node.arguments.forEach((mammouth.Expression argument) {
      argument.parentNode = node;
      argument.accept(this);
    });
  }

  @override
  void visitArrayLiteral(mammouth.ArrayLiteral node) {
    if(node.isTyped) {
      node.typeArguments.parentNode = node;
      node.typeArguments.accept(this);
    }
    node.elements.forEach((mammouth.Expression element) {
      element.parentNode = node;
      element.accept(this);
    });
  }

  @override
  void visitAsExpression(mammouth.AsExpression node) {
    node.argument.parentNode = node;
    node.argument.accept(this);
    node.type.parentNode = node;
    node.type.accept(this);
  }

  @override
  void visitAssignmentExpression(mammouth.AssignmentExpression node) {
    node.left.parentNode = node;
    node.operator.parentNode = node;
    node.right.parentNode = node;
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitAssignmentOperator(mammouth.AssignmentOperator node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  void visitAtExpression(mammouth.AtExpression node) {
    node.property.parentNode = node;
    node.property.accept(this);
  }

  @override
  void visitBinaryExpression(mammouth.BinaryExpression node) {
    node.left.parentNode = node;
    node.operator.parentNode = node;
    node.right.parentNode = node;
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitBinaryOperator(mammouth.BinaryOperator node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  void visitBlock(mammouth.Block node, {bool scope = true}) {
    node.statements.forEach((mammouth.Statement statement) {
      statement.parentNode = node;
      statement.accept(this);
    });
  }

  @override
  void visitBooleanLiteral(mammouth.BooleanLiteral node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitBreakStatement(mammouth.BreakStatement node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitClassExpression(mammouth.ClassExpression node,
      {InterfaceType type}) {
    if(!node.isAnonymous) {
      node.name.parentNode = node;
      node.name.accept(this);
    }
    if(node.typeParameters != null) {
      node.typeParameters.parentNode = node;
      node.typeParameters.accept(this);
    }
    if(node.extendsClause != null) {
      node.extendsClause.parentNode = node;
      node.extendsClause.accept(this);
    }
    if(node.implementsClause != null) {
      node.implementsClause.parentNode = node;
      node.implementsClause.accept(this);
    }
    node.members.forEach((mammouth.ClassMember member) {
      member.parentNode = node;
      member.accept(this);
    });
  }

  @override
  void visitClosureParameter(mammouth.ClosureParameter node) {
    node.returnType.parentNode = node;
    node.returnType.accept(this);
    node.name.parentNode = node;
    node.name.accept(this);
    node.parameterTypes.forEach((mammouth.TypeAnnotation type) {
      type.parentNode = node;
      type.accept(this);
    });
  }

  @override
  void visitConstructorDeclaration(mammouth.ConstructorDeclaration node) {
    if(node.hasParameters) {
      node.parameters.parentNode = node;
      node.parameters.accept(this);
    }
    node.body.parentNode = node;
    node.body.accept(this);
  }

  @override
  void visitContinueStatement(mammouth.ContinueStatement node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitConverterDeclaration(mammouth.ConverterDeclaration node) {
    node.returnType.parentNode = node;
    node.returnType.accept(this);
    node.body.parentNode = node;
    node.body.accept(this);
  }

  @override
  void visitEchoExpression(mammouth.EchoExpression node) {
    node.argument.parentNode = node;
    node.argument.accept(this);
  }

  @override
  void visitExistenceExpression(mammouth.ExistenceExpression node) {
    node.argument.parentNode = node;
    node.argument.accept(this);
  }

  @override
  void visitExpressionStatement(mammouth.ExpressionStatement node) {
    node.expression.parentNode = node;
    node.expression.accept(this);
  }

  @override
  void visitExtendsClause(mammouth.ExtendsClause node) {
    node.superclass.parentNode = node;
    node.superclass.accept(this);
  }

  @override
  void visitFieldDeclaration(mammouth.FieldDeclaration node) {
    if(node.isTyped) {
      node.type.parentNode = node;
      node.type.accept(this);
    }
    node.name.parentNode = node;
    node.name.accept(this);
    if(node.isInitialized) {
      node.initializer.parentNode = node;
      node.initializer.accept(this);
    }
  }

  @override
  void visitFloatLiteral(mammouth.FloatLiteral node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitFunctionExpression(mammouth.FunctionExpression node) {
    node.returnType.parentNode = node;
    node.returnType.accept(this);
    if(!node.isAnonymous) {
      node.name.parentNode = node;
      node.name.accept(this);
    }
    if(node.hasParameters) {
      node.parameters.parentNode = node;
      node.parameters.accept(this);
    }
    node.body.parentNode = node;
    node.body.accept(this);
  }

  @override
  void visitForExpression(mammouth.ForExpression node) {
    node.source.parentNode = node;
    node.source.accept(this);
    node.body.parentNode = node;
    node.body.accept(this);
  }

  @override
  void visitForRangeSource(mammouth.ForRangeSource node) {
    node.source.parentNode = node;
    node.source.accept(this);
    if(node.hasName) {
      node.name.parentNode = node;
      node.name.accept(this);
    }
    if(node.hasStep) {
      node.step.parentNode = node;
      node.step.accept(this);
    }
    if(node.hasGuard) {
      node.guard.parentNode = node;
      node.guard.accept(this);
    }
  }

  @override
  void visitForVariable(mammouth.ForVariable node) {
    if(node.isTyped) {
      node.type.parentNode = node;
      node.type.accept(this);
    }
    node.name.parentNode = node;
    node.name.accept(this);
  }

  @override
  void visitForVariableSource(mammouth.ForVariableSource node) {
    node.firstVariable.parentNode = node;
    node.firstVariable.accept(this);
    if(node.hasSecondVariable) {
      node.secondVariable.parentNode = node;
      node.secondVariable.accept(this);
    }
    if(node.hasStep) {
      node.step.parentNode = node;
      node.step.accept(this);
    }
    if(node.hasGuard) {
      node.guard.parentNode = node;
      node.guard.accept(this);
    }
  }

  @override
  void visitGuardSource(mammouth.GuardSource node) {
    node.condition.parentNode = node;
    node.condition.accept(this);
  }

  @override
  void visitIfExpression(mammouth.IfExpression node) {
    node.ifSource.parentNode = node;
    node.ifSource.accept(this);
    node.consequent.parentNode = node;
    node.consequent.accept(this);
    if(node.hasAlternate) {
      node.alternate.parentNode = node;
      node.alternate.accept(this);
    }
  }

  @override
  void visitIfSource(mammouth.IfSource node) {
    node.condition.parentNode = node;
    node.condition.accept(this);
  }

  @override
  void visitImplementsClause(mammouth.ImplementsClause node) {
    node.interfaces.forEach((mammouth.TypeAnnotation interface) {
      interface.parentNode = node;
      interface.accept(this);
    });
  }

  @override
  void visitImportDirective(mammouth.ImportDirective node) {
    node.uri.parentNode = node;
    node.uri.accept(this);
  }

  @override
  void visitIndexExpression(mammouth.IndexExpression node) {
    node.target.parentNode = node;
    node.target.accept(this);
    node.index.parentNode = node;
    node.index.accept(this);
  }

  @override
  void visitInExpression(mammouth.InExpression node) {
    node.element.parentNode = node;
    node.element.accept(this);
    node.container.parentNode = node;
    node.container.accept(this);
  }

  @override
  void visitInvocationExpression(mammouth.InvocationExpression node) {
    node.callee.parentNode = node;
    node.callee.accept(this);
    node.arguments.parentNode = node;
    node.arguments.accept(this);
  }

  @override
  void visitIntegerLiteral(mammouth.IntegerLiteral node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitInterfaceDeclaration(mammouth.InterfaceDeclaration node) {
    node.name.parentNode = node;
    node.name.accept(this);
    if(node.implementsClause != null) {
      node.implementsClause.parentNode = node;
      node.implementsClause.accept(this);
    }
    node.members.forEach((mammouth.ClassMember member) {
      member.parentNode = node;
      member.accept(this);
    });
  }

  @override
  void visitMMapEntry(mammouth.MMapEntry node) {
    node.key.parentNode = node;
    node.key.accept(this);
    node.value.parentNode = node;
    node.value.accept(this);
  }

  @override
  void visitMapLiteral(mammouth.MapLiteral node) {
    if(node.isTyped) {
      node.keyType.parentNode = node;
      node.keyType.accept(this);
      node.valueType.parentNode = node;
      node.valueType.accept(this);
    }
    node.entries.forEach((mammouth.MMapEntry entry) {
      entry.parentNode = node;
      entry.accept(this);
    });
  }

  @override
  void visitMemberExpression(mammouth.MemberExpression node) {
    node.target.parentNode = node;
    node.target.accept(this);
    node.property.parentNode = node;
    node.property.accept(this);
  }

  @override
  void visitMethodDeclaration(mammouth.MethodDeclaration node) {
    if(node.hasReturnType) {
      node.returnType.parentNode = node;
      node.returnType.accept(this);
    }
    node.name.parentNode = node;
    node.name.accept(this);
    if(node.hasParameters) {
      node.parameters.parentNode = node;
      node.parameters.accept(this);
    }
    if(!node.isSignature) {
      node.body.parentNode = node;
      node.body.accept(this);
    }
  }

  @override
  void visitNativeExpression(mammouth.NativeExpression node) {
    node.arguments.accept(this);
  }

  @override
  void visitNewExpression(mammouth.NewExpression node) {
    node.callee.parentNode = node;
    node.callee.accept(this);
    node.arguments.parentNode = node;
    node.arguments.accept(this);
  }

  @override
  void visitNullLiteral(mammouth.NullLiteral node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitOperatorDeclaration(mammouth.OperatorDeclaration node) {
    if(node.hasReturnType) {
      node.returnType.parentNode = node;
      node.returnType.accept(this);
    }
    node.operator.parentNode = node;
    if(node.hasParameters) {
      node.parameters.parentNode = node;
      node.parameters.accept(this);
    }
    if(!node.isSignature) {
      node.body.parentNode = node;
      node.body.accept(this);
    }
  }

  @override
  void visitParameterList(mammouth.ParameterList node) {
    node.parameters.forEach((mammouth.Parameter parameter) {
      parameter.parentNode = node;
      parameter.accept(this);
    });
  }

  @override
  void visitParenthesisExpression(mammouth.ParenthesisExpression node) {
    node.expression.parentNode = node;
    node.expression.accept(this);
  }

  @override
  void visitRangeLiteral(mammouth.RangeLiteral node) {
    if(node.start != null) {
      node.start.parentNode = node;
      node.start.accept(this);
    }
    if(node.end != null) {
      node.end.parentNode = node;
      node.end.accept(this);
    }
  }

  @override
  void visitRepetitionExpression(mammouth.RepetitionExpression node) {
    node.source.parentNode = node;
    node.source.accept(this);
    node.body.parentNode = node;
    node.body.accept(this);
  }

  @override
  void visitRepetitionSource(mammouth.RepetitionSource node) {
    if(!node.isLoop) {
      node.test.parentNode = node;
      node.test.accept(this);
    }
    if(node.hasGuard) {
      node.guard.parentNode = node;
      node.guard.accept(this);
    }
  }

  @override
  void visitReturnStatement(mammouth.ReturnStatement node) {
    if(node.expression != null) {
      node.expression.parentNode = node;
      node.expression.accept(this);
    }
  }

  @override
  void visitScript(mammouth.Script node) {
    node.body.parentNode = node;
    node.body.accept(this);
  }

  @override
  void visitSimpleIdentifier(mammouth.SimpleIdentifier node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitSimpleParameter(mammouth.SimpleParameter node) {
    if(node.isTyped) {
      node.type.parentNode = node;
      node.type.accept(this);
    }
    node.name.parentNode = node;
    node.name.accept(this);
  }

  @override
  void visitSliceExpression(mammouth.SliceExpression node) {
    node.expression.parentNode = node;
    node.expression.accept(this);
    node.slicingRange.parentNode = node;
    node.slicingRange.accept(this);
  }

  @override
  void visitStringLiteral(mammouth.StringLiteral node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitSwitchCase(mammouth.SwitchCase node) {
    node.test.parentNode = node;
    node.test.accept(this);
    node.consequent.parentNode = node;
    node.consequent.accept(this);
  }

  @override
  void visitSwitchDefault(mammouth.SwitchDefault node) {
    node.consequent.parentNode = node;
    node.consequent.accept(this);
  }

  @override
  void visitSwitchExpression(mammouth.SwitchExpression node) {
    node.discriminant.parentNode = node;
    node.discriminant.accept(this);
    node.cases.forEach((mammouth.SwitchCase switchCase) {
      switchCase.parentNode = node;
      switchCase.accept(this);
    });
    if(node.defaultCase != null) {
      node.defaultCase.parentNode = node;
      node.defaultCase.accept(this);
    }
  }

  @override
  void visitThrowStatement(mammouth.ThrowStatement node) {
    node.expression.parentNode = node;
    node.expression.accept(this);
  }

  @override
  void visitToExpression(mammouth.ToExpression node) {
    node.argument.parentNode = node;
    node.argument.accept(this);
    node.type.parentNode = node;
    node.type.accept(this);
  }

  @override
  void visitTryExpression(mammouth.TryExpression node) {
    node.tryStatement.parentNode = node;
    node.tryStatement.accept(this);
    if(node.hasCatch) {
      node.catchVariable.parentNode = node;
      node.catchVariable.accept(this);
      node.catchStatement.parentNode = node;
      node.catchStatement.accept(this);
    }
    if(node.hasFinally) {
      node.finallyStatement.parentNode = node;
      node.finallyStatement.accept(this);
    }
  }

  @override
  void visitTypeArgumentList(mammouth.TypeArgumentList node) {
    node.arguments.forEach((mammouth.TypeAnnotation typeArgument) {
      typeArgument.parentNode = node;
      typeArgument.accept(this);
    });
  }

  @override
  void visitTypeName(mammouth.TypeName node) {
    node.name.parentNode = node;
    node.name.accept(this);
  }

  @override
  void visitTypeParameter(mammouth.TypeParameter node) {
    node.name.parentNode = node;
    node.name.accept(this);
  }

  @override
  void visitTypeParameterList(mammouth.TypeParameterList node) {
    node.parameters.forEach((mammouth.TypeParameter typeParameter) {
      typeParameter.parentNode = node;
      typeParameter.accept(this);
    });
  }

  @override
  void visitUnaryExpression(mammouth.UnaryExpression node) {
    node.operator.parentNode = node;
    node.argument.parentNode = node;
    node.argument.accept(this);
  }

  @override
  void visitUnaryOperator(mammouth.UnaryOperator node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  void visitUpdateExpression(mammouth.UpdateExpression node) {
    node.operator.parentNode = node;
    node.argument.parentNode = node;
    node.argument.accept(this);
  }

  @override
  void visitUpdateOperator(mammouth.UpdateOperator node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  void visitVariableDeclarationStatement(
      mammouth.VariableDeclarationStatement node) {
    node.type.parentNode = node;
    node.type.accept(this);
    node.name.parentNode = node;
    node.name.accept(this);
    if(node.isInitialized) {
      node.initializer.parentNode = node;
      node.initializer.accept(this);
    }
  }
}
