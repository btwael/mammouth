import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/php/ast/ast.dart" as php;
import "package:mammouth/src/language/php/ast/visitor.dart" as php;
import "package:mammouth/src/language/php/element/element.dart";

// TODO: complete this
class PHPResultResolver extends php.Visitor {
  List<Scope> scopeStack = [];

  PHPResultResolver() {
    this.scopeStack.add(new Scope());
  }

  void pushScope() {
    this.scopeStack.add(
        new Scope(this.scopeStack.isNotEmpty ? this.scopeStack.last : null));
  }

  void popScope() {
    if(this.scopeStack.isNotEmpty) {
      this.scopeStack.removeLast();
    }
  }

  @override
  common.Document visitDocument(common.Document node) {
    node.entries.forEach((common.DocumentEntry entry) {
      entry.accept(this);
    });
    return node;
  }

  @override
  void visitInlineEntry(common.InlineEntry node) {}

  @override
  void visitPHPArrayItem(php.ArrayItem node) {
    node.target.accept(this);
    node.property.accept(this);
  }

  @override
  void visitPHPArrayLiteral(php.ArrayLiteral node) {
    node.elements.forEach((php.Expression element) {
      element.accept(this);
    });
  }

  @override
  void visitPHPAssignmentExpression(php.AssignmentExpression node) {
    node.leftHandSide.accept(this);
    node.rightHandSide.accept(this);
  }

  @override
  void visitPHPAssignmentOperator(php.AssignmentOperator node) {}

  @override
  void visitPHPBinaryExpression(php.BinaryExpression node) {
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitPHPBinaryOperator(php.BinaryOperator node) {}

  @override
  void visitPHPBlock(php.Block node, {bool scope = true}) {
    if(scope) {
      this.pushScope();
    }
    node.statements.forEach((php.Statement statement) {
      statement.accept(this);
    });
    if(scope) {
      this.popScope();
    }
  }

  @override
  void visitPHPBooleanLiteral(php.BooleanLiteral node) {}

  @override
  void visitPHPBreakStatement(php.BreakStatement node) {}

  @override
  void visitPHPCastExpression(php.CastExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitPHPClassDeclaration(php.ClassDeclaration node) {
    this.pushScope();
    node.members.forEach((php.ClassMember member) {
      member.accept(this);
    });
    this.popScope();
  }

  @override
  void visitPHPClosureExpression(php.ClosureExpression node) {
    node.parameters.forEach((php.Parameter parameter) {
      parameter.accept(this);
    });
    node.body.accept(this);
  }

  @override
  void visitPHPConcatenationExpression(php.ConcatenationExpression node) {
    node.left.accept(this);
    node.right.accept(this);
  }

  @override
  void visitPHPContinueStatement(php.ContinueStatement node) {}

  @override
  void visitPHPEchoStatement(php.EchoStatement node) {
    node.expression.accept(this);
  }

  @override
  void visitPHPExpressionStatement(php.ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  void visitPHPFieldDeclaration(php.FieldDeclaration node) {}

  @override
  void visitPHPFloatLiteral(php.FloatLiteral node) {}

  @override
  void visitPHPForeachStatement(php.ForeachStatement node) {
    node.expression.accept(this);
    this.pushScope();
    node.keyVariable?.accept(this);
    node.valueVariable?.accept(this);
    if(node.body is php.Block) {
      (node.body as php.Block).accept(this, scope: false);
    } else {
      node.body.accept(this);
    }
    this.popScope();
  }

  @override
  void visitPHPForStatement(php.ForStatement node) {
    node.init.accept(this);
    node.test.accept(this);
    node.update.accept(this);
    node.body.accept(this);
  }

  @override
  void visitPHPFunctionCallExpression(php.FunctionCallExpression node) {
    node.function.accept(this);
    node.arguments.forEach((php.Expression argument) {
      argument.accept(this);
    });
  }

  @override
  void visitPHPFunctionStatement(php.FunctionStatement node) {
    node.name.accept(this);
    node.parameters.forEach((php.Parameter parameter) {
      parameter.accept(this);
    });
    node.body.accept(this);
  }

  @override
  void visitPHPGlobalStatement(php.GlobalStatement node) {}

  @override
  void visitPHPIfStatement(php.IfStatement node) {
    node.condition.accept(this);
    node.consequent.accept(this);
    node.alternate?.accept(this);
  }

  @override
  void visitPHPIncludeExpression(php.IncludeExpression node) {}

  @override
  void visitPHPIntegerLiteral(php.IntegerLiteral node) {}

  @override
  void visitPHPInterfaceDeclaration(php.InterfaceDeclaration node) {}

  @override
  void visitPHPKeyValue(php.KeyValue node) {
    node.key.accept(this);
    node.value.accept(this);
  }

  @override
  void visitPHPMethodDeclaration(php.MethodDeclaration node) {
    node.name.accept(this);
    node.parameters.forEach((php.Parameter parameter) {
      parameter.accept(this);
    });
    node.body?.accept(this);
  }

  @override
  void visitPHPName(php.Name node) {
    if(node.element != null) {
      node.element.scopes.add(this.scopeStack.last);
      this.scopeStack.last.addLateName(node.element);
    } else {
      this.scopeStack.last.add(node.name);
    }
  }

  @override
  void visitPHPNewExpression(php.NewExpression node) {}

  @override
  void visitPHPParameter(php.Parameter node) {}

  @override
  void visitPHPParenthesisExpression(php.ParenthesisExpression node) {}

  @override
  void visitPHPPropertyFetch(php.PropertyFetch node) {}

  @override
  void visitPHPRawExpression(php.RawExpression node) {}

  @override
  void visitPHPReturnStatement(php.ReturnStatement node) {
    node.argument.accept(this);
  }

  @override
  void visitPHPScript(php.Script node) {
    node.body.accept(this, scope: false);
  }

  @override
  void visitPHPStaticPropertyFetch(php.StaticPropertyFetch node) {}

  @override
  void visitPHPStringLiteral(php.StringLiteral node) {}

  @override
  void visitPHPSwitchCase(php.SwitchCase node) {}

  @override
  void visitPHPSwitchDefault(php.SwitchDefault node) {}

  @override
  void visitPHPSwitchStatement(php.SwitchStatement node) {}

  @override
  void visitPHPThrowStatement(php.ThrowStatement node) {}

  @override
  void visitPHPTryStatement(php.TryStatement node) {}

  @override
  void visitPHPUnaryExpression(php.UnaryExpression node) {
    node.argument.accept(this);
  }

  @override
  void visitPHPUnaryOperator(php.UnaryOperator node) {}

  @override
  void visitPHPUpdateExpression(php.UpdateExpression node) {
    node.argument.accept(this);
  }

  @override
  void visitPHPUpdateOperator(php.UpdateOperator node) {}

  @override
  void visitPHPVariable(php.Variable node) {
    if(node.element != null) {
      node.element.scopes.add(this.scopeStack.last);
      this.scopeStack.last.addLateName(node.element);
    } else {
      this.scopeStack.last.add(node.name);
    }
  }

  @override
  void visitPHPWhileStatement(php.WhileStatement node) {
    node.test.accept(this);
    node.body.accept(this);
  }
}
