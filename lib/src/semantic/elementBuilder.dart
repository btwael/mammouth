library mammouth.semantic.elementBuilder;

import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/mammouth/ast/ast.dart" as mammouth;
import "package:mammouth/src/language/mammouth/ast/visitor.dart" as mammouth;
import "package:mammouth/src/language/mammouth/element/element.dart" as mammouth;
import "package:mammouth/src/language/mammouth/element/implementation.dart" as mammouth;
import "package:mammouth/src/language/mammouth/type/type.dart";


//*-- ElementBuilder
/**
 * Builds semantic elements for AST nodes.
 */
class ElementBuilder extends mammouth.Visitor {
  @override
  void visitDocument(common.Document node) {
    node.entries.forEach((common.DocumentEntry entry) {
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
      argument.accept(this);
    });
  }

  @override
  void visitArrayLiteral(mammouth.ArrayLiteral node) {
    if(node.isTyped) {
      node.elementType.accept(this);
    }
    node.elements.forEach((mammouth.Expression element) {
      element.accept(this);
    });
  }

  @override
  void visitAsExpression(mammouth.AsExpression node) {
    node.argument.accept(this);
    node.type.accept(this);
  }

  @override
  void visitAssignmentExpression(mammouth.AssignmentExpression node) {
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
    node.property.accept(this);
  }

  @override
  void visitBinaryExpression(mammouth.BinaryExpression node) {
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
    if(node.typeParameters != null) {
      node.typeParameters.parentNode = node;
      node.typeParameters.accept(this);
    }
    node.element = new mammouth.ClassElementImpl(node.name.name);
    node.members.forEach((mammouth.ClassMember member) {
      member.accept(this);
      node.element.addMember(member.element);
      member.element.enclosingElement = node.element;
      member.element.visibility = member.visibility;
    });
    node.element.setup();
    node.element.node = node;
  }

  @override
  void visitClosureParameter(mammouth.ClosureParameter node) {
    node.element = new mammouth.ParameterElementImpl(node.name.name);
  }

  @override
  void visitConstructorDeclaration(mammouth.ConstructorDeclaration node) {
    if(node.hasParameters) {
      node.parameters.accept(this);
    }
    node.element = new mammouth.ConstructorElementImpl(
        null,
        null,
        node.hasParameters
            ? node.parameters.parameters
            .map((mammouth.Parameter parameter) {
          return parameter.element;
        }).toList()
            : []);
    node.body.accept(this);
    node.element.node = node;
  }

  @override
  void visitContinueStatement(mammouth.ContinueStatement node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitConverterDeclaration(mammouth.ConverterDeclaration node) {
    node.element = new mammouth.ConverterElementImpl(null, null);
    node.body.accept(this);
    node.element.node = node;
  }

  @override
  void visitEchoExpression(mammouth.EchoExpression node) {
    node.argument.accept(this);
  }

  @override
  void visitExistenceExpression(mammouth.ExistenceExpression node) {
    node.argument.accept(this);
  }

  @override
  void visitExpressionStatement(mammouth.ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  void visitExtendsClause(mammouth.ExtendsClause node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  void visitFieldDeclaration(mammouth.FieldDeclaration node) {
    if(node.isInitialized) {
      node.initializer.accept(this);
    }
    node.element = new mammouth.FieldElementImpl(null, node.name.name);
    node.element.node = node;
  }

  @override
  void visitFloatLiteral(mammouth.FloatLiteral node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitFunctionExpression(mammouth.FunctionExpression node) {
    if(node.hasParameters) {
      node.parameters.accept(this);
    }
    node.element = new mammouth.FunctionElementImpl(
        node.isAnonymous ? "" : node.name.name,
        null,
        node.hasParameters
            ? node.parameters.parameters
            .map((mammouth.Parameter parameter) {
          return parameter.element;
        }).toList()
            : []);
    node.body.accept(this);
  }

  @override
  void visitForExpression(mammouth.ForExpression node) {
    node.source.accept(this);
    node.body.accept(this);
  }

  @override
  void visitForRangeSource(mammouth.ForRangeSource node) {
    node.source.accept(this);
    if(node.hasName) {
      node.name.accept(this);
    }
    if(node.hasStep) {
      node.step.accept(this);
    }
    if(node.hasGuard) {
      node.guard.accept(this);
    }
  }

  @override
  void visitForVariable(mammouth.ForVariable node) {
    node.element = new mammouth.VariableElementImpl(node.name.name);
  }

  @override
  void visitForVariableSource(mammouth.ForVariableSource node) {
    node.firstVariable.accept(this);
    if(node.hasSecondVariable) {
      node.secondVariable.accept(this);
    }
    if(node.hasStep) {
      node.step.accept(this);
    }
    if(node.hasGuard) {
      node.guard.accept(this);
    }
  }

  void visitGuardSource(mammouth.GuardSource node) {
    node.condition.accept(this);
  }

  @override
  void visitIfExpression(mammouth.IfExpression node) {
    node.condition.accept(this);
    node.consequent.accept(this);
    if(node.hasAlternate) {
      node.alternate.accept(this);
    }
  }

  @override
  void visitIfSource(mammouth.IfSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  void visitImplementsClause(mammouth.ImplementsClause node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  void visitImportDirective(mammouth.ImportDirective node) {
    node.uri.accept(this);
  }

  @override
  void visitIndexExpression(mammouth.IndexExpression node) {
    node.target.accept(this);
    node.index.accept(this);
  }

  @override
  void visitInExpression(mammouth.InExpression node) {
    node.element.accept(this);
    node.container.accept(this);
  }

  @override
  void visitInterfaceDeclaration(mammouth.InterfaceDeclaration node) {
    node.element = new mammouth.InterfaceElementImpl(node.name.name);
    node.members.forEach((mammouth.ClassMember member) {
      member.accept(this);
      node.element.addMember(member.element);
      member.element.enclosingElement = node.element;
      member.element.visibility = member.visibility;
    });
    node.element.setup();
  }

  @override
  void visitInvocationExpression(mammouth.InvocationExpression node) {
    node.callee.accept(this);
    node.arguments.accept(this);
  }

  @override
  void visitIntegerLiteral(mammouth.IntegerLiteral node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitMMapEntry(mammouth.MMapEntry node) {
    node.key.accept(this);
    node.value.accept(this);
  }

  @override
  void visitMapLiteral(mammouth.MapLiteral node) {
    if(node.isTyped) {
      node.keyType.accept(this);
      node.valueType.accept(this);
    }
    node.entries.forEach((mammouth.MMapEntry entry) {
      entry.accept(this);
    });
  }

  @override
  void visitMemberExpression(mammouth.MemberExpression node) {
    node.target.accept(this);
  }

  @override
  void visitMethodDeclaration(mammouth.MethodDeclaration node) {
    String name;
    if(node.isAnonymous) {
      name = "";
    } else {
      name = node.name.name;
    }
    if(node.hasParameters) {
      node.parameters.accept(this);
    }
    node.element = new mammouth.MethodElementImpl(
        null,
        name,
        null,
        node.hasParameters
            ? node.parameters.parameters
            .map((mammouth.Parameter parameter) {
          return parameter.element;
        }).toList()
            : []);
    if(!node.isSignature) {
      node.body.accept(this);
    }
    node.element.node = node;
  }

  @override
  void visitNativeExpression(mammouth.NativeExpression node) {
    node.arguments.accept(this);
  }

  @override
  void visitNewExpression(mammouth.NewExpression node) {
    node.callee.accept(this);
    node.arguments.accept(this);
  }

  @override
  void visitOperatorDeclaration(mammouth.OperatorDeclaration node) {
    if(node.hasParameters) {
      node.parameters.accept(this);
    }
    node.element = new mammouth.OperatorElementImpl(
        null,
        node.operatorType + node.operator.lexeme,
        null,
        node.hasParameters
            ? node.parameters.parameters
            .map((mammouth.Parameter parameter) {
          return parameter.element;
        }).toList()
            : []);
    if(!node.isSignature) {
      node.body.accept(this);
    }
    node.element.node = node;
  }

  @override
  void visitParameterList(mammouth.ParameterList node) {
    node.parameters.forEach((mammouth.Parameter parameter) {
      parameter.accept(this);
    });
  }

  @override
  void visitParenthesisExpression(mammouth.ParenthesisExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitRangeLiteral(mammouth.RangeLiteral node) {
    if(node.start != null) {
      node.start.accept(this);
    }
    if(node.end != null) {
      node.end.accept(this);
    }
  }

  @override
  void visitRepetitionExpression(mammouth.RepetitionExpression node) {
    if(!node.isLoop) {
      node.test.accept(this);
    }
    if(node.hasGuard) {
      node.guardCondition.accept(this);
    }
    node.body.accept(this);
  }

  @override
  void visitRepetitionSource(mammouth.RepetitionSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  void visitReturnStatement(mammouth.ReturnStatement node) {
    if(node.expression != null) {
      node.expression.accept(this);
    }
  }

  @override
  void visitScript(mammouth.Script node) {
    node.body.accept(this);
  }

  @override
  void visitSimpleParameter(mammouth.SimpleParameter node) {
    node.element = new mammouth.ParameterElementImpl(node.name.name);
  }

  @override
  void visitSimpleIdentifier(mammouth.SimpleIdentifier node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitSliceExpression(mammouth.SliceExpression node) {
    node.expression.accept(this);
    node.slicingRange.accept(this);
  }

  @override
  void visitStringLiteral(mammouth.StringLiteral node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitSwitchCase(mammouth.SwitchCase node) {
    node.test.accept(this);
    node.consequent.accept(this);
  }

  @override
  void visitSwitchDefault(mammouth.SwitchDefault node) {
    node.consequent.accept(this);
  }

  @override
  void visitSwitchExpression(mammouth.SwitchExpression node) {
    node.discriminant.accept(this);
    node.cases.forEach((mammouth.SwitchCase switchCase) {
      switchCase.accept(this);
    });
    if(node.defaultCase != null) {
      node.defaultCase.accept(this);
    }
  }

  @override
  void visitThrowStatement(mammouth.ThrowStatement node) {
    node.expression.accept(this);
  }

  @override
  void visitToExpression(mammouth.ToExpression node) {
    node.argument.accept(this);
    node.type.accept(this);
  }

  @override
  void visitTryExpression(mammouth.TryExpression node) {
    node.tryStatement.accept(this);
    if(node.hasCatch) {
      node.catchVariable.element =
      new mammouth.ParameterElementImpl(node.catchVariable.name.name);
      node.catchStatement.accept(this);
    }
    if(node.hasFinally) {
      node.finallyStatement.accept(this);
    }
  }

  @override
  void visitTypeArgumentList(mammouth.TypeArgumentList node) {
    node.arguments.forEach((mammouth.TypeAnnotation type) {
      type.accept(this);
    });
  }

  @override
  void visitTypeName(mammouth.TypeName node) {
    // MARK(DO NOTHING)
  }

  @override
  void visitTypeParameter(mammouth.TypeParameter node) {
    node.element = new mammouth.TypeParameterElementImpl(node.name.name);
  }

  @override
  void visitTypeParameterList(mammouth.TypeParameterList node) {
    node.parameters.forEach((mammouth.TypeParameter typeParameter) {
      typeParameter.accept(this);
    });
  }

  @override
  void visitUnaryExpression(mammouth.UnaryExpression node) {
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
    if(node.isInitialized) {
      node.initializer.accept(this);
    }
    node.element = new mammouth.VariableElementImpl(node.name.name);
  }
}
