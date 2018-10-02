library mammouth.codegen.docgen;

import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/common/ast/visibility.dart";
import "package:mammouth/src/language/php/ast/ast.dart" as php;
import "package:mammouth/src/language/php/ast/visitor.dart" as php;

//*-- DocumentGenerator
/**
 * Converts the AST with only PHP nodes to string.
 */
class DocumentGenerator extends php.Visitor<String> {
  @override
  String visitDocument(common.Document node) {
    String code = "";
    node.entries.forEach((common.DocumentEntry entry) {
      code += entry.accept<String>(this);
    });
    return code;
  }

  @override
  String visitInlineEntry(common.InlineEntry node) {
    return node.content;
  }

  @override
  String visitPHPArrayItem(php.ArrayItem node) {
    return "${node.target.accept<String>(this)}[${node.property.accept<String>(
        this)}]";
  }

  @override
  String visitPHPArrayLiteral(php.ArrayLiteral node) {
    String code = "[";
    for(int i = 0; i < node.elements.length; i++) {
      code += node.elements.elementAt(i).accept<String>(this);
      if(i != node.elements.length - 1) {
        code += ", ";
      }
    }
    code += "]";
    return code;
  }

  @override
  String visitPHPAssignmentExpression(php.AssignmentExpression node) {
    return "${node.leftHandSide.accept<String>(this)} ${node.operator.accept<
        String>(this)} ${node.rightHandSide.accept<String>(this)}";
  }

  @override
  String visitPHPAssignmentOperator(php.AssignmentOperator node) {
    return node.token.lexeme;
  }

  @override
  String visitPHPBinaryExpression(php.BinaryExpression node) {
    return "${node.left.accept<String>(this)} ${node.operator.accept<String>(
        this)} ${node.right.accept<String>(this)}";
  }

  @override
  String visitPHPBinaryOperator(php.BinaryOperator node) {
    return node.token.lexeme;
  }

  @override
  String visitPHPBlock(php.Block node, {bool scope = true}) {
    String code;
    if(scope) {
      code = "{\n";
    } else {
      code = "";
    }
    node.statements.forEach((php.Statement statement) {
      code += statement.accept<String>(this) + "\n";
    });
    if(scope) {
      code += "}";
    }
    return code;
  }

  @override
  String visitPHPBooleanLiteral(php.BooleanLiteral node) {
    return node.token.lexeme;
  }

  @override
  String visitPHPBreakStatement(php.BreakStatement node) {
    return "break;";
  }

  @override
  String visitPHPCastExpression(php.CastExpression node) {
    return "(${node.type}) ${node.expression.accept<String>(this)}";
  }

  @override
  String visitPHPClassDeclaration(php.ClassDeclaration node) {
    String code = "class ${node.name.accept<String>(this)}";
    if(node.superclass != null) {
      code += " extends ${node.superclass.name}";
    }
    code += " {\n";
    node.members.forEach((php.ClassMember member) {
      code += member.accept<String>(this) + "\n";
    });
    code += "}";
    return code;
  }

  @override
  String visitPHPClosureExpression(php.ClosureExpression node) {
    String code = "function(";
    for(int i = 0; i < node.parameters.length; i++) {
      code += node.parameters[i].accept<String>(this);
      if(i != node.parameters.length - 1) {
        code += ", ";
      }
    }
    code += ") ";
    code += node.body.accept<String>(this);
    return code;
  }

  @override
  String visitPHPConcatenationExpression(php.ConcatenationExpression node) {
    return "${node.left.accept<String>(this)}.${node.right.accept<String>(
        this)}";
  }

  @override
  String visitPHPContinueStatement(php.ContinueStatement node) {
    return "continue;";
  }

  @override
  String visitPHPEchoStatement(php.EchoStatement node) {
    return "echo ${node.expression.accept<String>(this)};";
  }

  @override
  String visitPHPExpressionStatement(php.ExpressionStatement node) {
    return "${node.expression.accept<String>(this)};";
  }

  @override
  String visitPHPFieldDeclaration(php.FieldDeclaration node) {
    String code;
    switch(node.visibility) {
      case Visibility.DEFAULT:
      case Visibility.PUBLIC:
        code = "public ";
        break;
      case Visibility.PRIVATE:
        code = "private ";
        break;
      case Visibility.PROTECTED:
        code = "protected ";
        break;
    }
    if(node.staticKeyword != null) {
      code += "static ";
    }
    code += "${node.variable.accept<String>(this)}";
    if(node.initializer != null) {
      code += " = ${node.initializer.accept<String>(this)}";
    }
    code += ";";
    return code;
  }

  @override
  String visitPHPFloatLiteral(php.FloatLiteral node) {
    return node.token.lexeme;
  }

  @override
  String visitPHPForeachStatement(php.ForeachStatement node) {
    String code = "foreach(${node.expression.accept<String>(this)} as ";
    if(node.keyVariable != null) {
      code += node.keyVariable.accept(this) + " => ";
    }
    code +=
    "${node.valueVariable.accept(this)}) ${node.body.accept<String>(this)}";
    return code;
  }

  @override
  String visitPHPForStatement(php.ForStatement node) {
    return "for(${node.init.accept<String>(this)}; ${node.test.accept<String>(
        this)}; ${node.update.accept<String>(this)}) ${node.body.accept<String>(
        this)}";
  }

  @override
  String visitPHPFunctionCallExpression(php.FunctionCallExpression node) {
    String code = node.function.accept<String>(this);
    code += "(";
    for(int i = 0; i < node.arguments.length; i++) {
      code += node.arguments[i].accept<String>(this);
      if(i != node.arguments.length - 1) {
        code += ", ";
      }
    }
    code += ")";
    return code;
  }

  @override
  String visitPHPFunctionStatement(php.FunctionStatement node) {
    String code = "function ${node.name.accept<String>(this)}(";
    for(int i = 0; i < node.parameters.length; i++) {
      code += node.parameters[i].accept<String>(this);
      if(i != node.parameters.length - 1) {
        code += ", ";
      }
    }
    code += ") ";
    code += node.body.accept<String>(this);
    return code;
  }

  @override
  String visitPHPGlobalStatement(php.GlobalStatement node) {
    String code = "global ";
    for(int i = 0; i < node.variables.length; i++) {
      code += node.variables[i].accept<String>(this);
      if(i != node.variables.length - 1) {
        code += ", ";
      }
    }
    code += ";";
    return code;
  }

  @override
  String visitPHPIfStatement(php.IfStatement node) {
    String code = "if(";
    code += node.condition.accept<String>(this);
    code += ") ";
    code += node.consequent.accept<String>(this);
    if(node.alternate != null) {
      code += " else ";
      code += node.alternate.accept<String>(this);
    }
    return code;
  }

  @override
  String visitPHPIncludeExpression(php.IncludeExpression node) {
    String code = "include";
    if(node.isOnce) {
      code += "_once";
    }
    code += " ${node.uri.accept<String>(this)}";
    return code;
  }

  @override
  String visitPHPIntegerLiteral(php.IntegerLiteral node) {
    return node.token.lexeme;
  }

  @override
  String visitPHPInterfaceDeclaration(php.InterfaceDeclaration node) {
    String code = "interface ${node.name.accept<String>(this)} {\n";
    node.members.forEach((php.ClassMember member) {
      code += member.accept<String>(this) + "\n";
    });
    code += "}";
    return code;
  }

  @override
  String visitPHPKeyValue(php.KeyValue node) {
    return "${node.key.accept<String>(this)} => ${node.value.accept<String>(
        this)}";
  }

  @override
  String visitPHPMethodDeclaration(php.MethodDeclaration node) {
    String code;
    switch(node.visibility) {
      case Visibility.DEFAULT:
        code = "";
        break;
      case Visibility.PRIVATE:
        code = "private ";
        break;
      case Visibility.PROTECTED:
        code = "protected ";
        break;
      case Visibility.PUBLIC:
        code = "public ";
        break;
    }
    if(node.isAbstract) {
      code = "abstract " + code;
    }
    code += "function ${node.name.accept<String>(this)}(";
    for(int i = 0; i < node.parameters.length; i++) {
      code += node.parameters[i].accept<String>(this);
      if(i != node.parameters.length - 1) {
        code += ", ";
      }
    }
    code += ")";
    if(node.body == null) {
      code += ";";
    } else {
      code += " " + node.body.accept<String>(this);
    }
    return code;
  }

  @override
  String visitPHPName(php.Name node) {
    if(node.element != null) {
      if(node.asString) {
        return "\"${node.element.name}\"";
      }
      return node.element.name;
    }
    return node.name;
  }

  @override
  String visitPHPNewExpression(php.NewExpression node) {
    String code = "new ${node.target.accept<String>(this)}";
    if(node.arguments.length > 0) {
      code += "(";
      for(int i = 0; i < node.arguments.length; i++) {
        code += node.arguments[i].accept<String>(this);
        if(i != node.arguments.length - 1) {
          code += ", ";
        }
      }
      code += ")";
    }
    return code;
  }

  @override
  String visitPHPNullLiteral(php.NullLiteral node) {
    return "NULL";
  }

  @override
  String visitPHPParameter(php.Parameter node) {
    return node.variable.accept<String>(this);
  }

  @override
  String visitPHPParenthesisExpression(php.ParenthesisExpression node) {
    return "(${node.expression.accept<String>(this)})";
  }

  @override
  String visitPHPPropertyFetch(php.PropertyFetch node) {
    // TODO: if property is expression
    return "${node.target.accept<String>(this)}->${node.property.accept<String>(
        this)}";
  }

  @override
  String visitPHPStaticPropertyFetch(php.StaticPropertyFetch node) {
    // TODO: if property is expression
    return "${node.target.accept<String>(this)}::${node.property.accept<String>(
        this)}";
  }

  @override
  String visitPHPRawExpression(php.RawExpression node) {
    return node.content.replaceAllMapped(new RegExp(r'\$([0-9]+)'),
            (Match match) {
          return node.arguments[int.parse(match.group(1)) - 1].accept<String>(
              this);
        });
  }

  @override
  String visitPHPReturnStatement(php.ReturnStatement node) {
    return "return" +
        (node.argument != null
            ? " " + node.argument.accept<String>(this)
            : "") +
        ";";
  }

  @override
  String visitPHPScript(php.Script node) {
    String code = "<?php\n";
    code += node.body.accept<String>(this, scope: false);
    return code + "?>";
  }

  @override
  String visitPHPStringLiteral(php.StringLiteral node) {
    return node.token.lexeme;
  }

  @override
  String visitPHPSwitchCase(php.SwitchCase node) {
    String code = "case ${node.test.accept<String>(this)}:\n";
    node.consequent.forEach((php.Statement statement) {
      code += statement.accept<String>(this) + "\n";
    });
    return code;
  }

  @override
  String visitPHPSwitchDefault(php.SwitchDefault node) {
    String code = "default:\n";
    node.consequent.forEach((php.Statement statement) {
      code += statement.accept<String>(this) + "\n";
    });
    return code;
  }

  @override
  String visitPHPSwitchStatement(php.SwitchStatement node) {
    String code = "switch(${node.discriminant.accept<String>(this)}) {\n";
    node.cases.forEach((php.SwitchCase switchCase) {
      code += switchCase.accept<String>(this);
    });
    if(node.defaultCase != null) {
      code += node.defaultCase.accept<String>(this);
    }
    code += "}";
    return code;
  }

  @override
  String visitPHPThrowStatement(php.ThrowStatement node) {
    return "throw ${node.expression.accept<String>(this)};";
  }

  @override
  String visitPHPTryStatement(php.TryStatement node) {
    // TODO;verify if {} needed
    String code = "try ";
    code += node.tryStatement.accept(this);
    if(node.hasCatch) {
      code +=
      " catch(Exception ${node.catchVariableName.accept<String>(this)}) ";
      code += node.catchStatement.accept(this);
    }
    if(node.hasFinally) {
      code += " finally ";
      code += node.tryStatement.accept(this);
    }
    return code;
  }

  @override
  String visitPHPUnaryExpression(php.UnaryExpression node) {
    String code = node.operator.accept<String>(this);
    code += node.argument.accept<String>(this);
    return code;
  }

  @override
  String visitPHPUnaryOperator(php.UnaryOperator node) {
    return node.token.lexeme;
  }

  @override
  String visitPHPUpdateExpression(php.UpdateExpression node) {
    String code = node.argument.accept<String>(this);
    if(node.isPrefix) {
      code = node.operator.accept<String>(this) + code;
    } else {
      code += node.operator.accept<String>(this);
    }
    return code;
  }

  @override
  String visitPHPUpdateOperator(php.UpdateOperator node) {
    return node.token.lexeme;
  }

  @override
  String visitPHPVariable(php.Variable node) {
    if(node.element != null) {
      return "\$${node.element.name}";
    }
    return "\$${node.name}";
  }

  @override
  String visitPHPWhileStatement(php.WhileStatement node) {
    String code = "while(";
    code += node.test.accept<String>(this);
    code += ") ";
    code += node.body.accept<String>(this);
    return code;
  }
}
