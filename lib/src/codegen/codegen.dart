library mammouth.codegen.codegen;

import "package:path/path.dart" as p;

import "package:mammouth/src/basic/source.dart";
import "package:mammouth/src/basic/session.dart";
import "package:mammouth/src/codegen/namePicker.dart";
import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/common/ast/implementation.dart" as common;
import "package:mammouth/src/language/common/ast/token.dart"
    show TokenKind, SimpleToken, StringToken;
import "package:mammouth/src/language/mammouth/ast/ast.dart" as mammouth;
import "package:mammouth/src/language/mammouth/ast/implementation.dart" as mammouth;
import "package:mammouth/src/language/mammouth/ast/visitor.dart" as mammouth;
import "package:mammouth/src/language/mammouth/element/element.dart" as mammouth;
import "package:mammouth/src/language/mammouth/type/type.dart" as mammouth;
import "package:mammouth/src/language/php/ast/ast.dart" as php;
import "package:mammouth/src/language/php/ast/implementation.dart" as php;
import "package:mammouth/src/language/php/element/element.dart" as php;
import "package:mammouth/src/semantic/scope.dart";

// TODO: un-use syntactic node

//*-- CodeGenerator
/**
 * Builds a new AST containing just PHP nodes from the AST that may contains
 * mammouth nodes.
 */
class CodeGenerator extends mammouth.Visitor<Object> {
  Session _session;

  Source _source;

  NamePicker namePicker = new NamePicker();

  List<List<php.Statement>> beforeStatements = <List<php.Statement>>[];

  bool _requireRuntime = false;

  CodeGenerator(this._session, this._source);

  @override
  common.Document visitDocument(common.Document node) {
    List<common.DocumentEntry> entries = new List<common.DocumentEntry>();
    node.entries.forEach((common.DocumentEntry entry) {
      entries.add(entry.accept<Object>(this));
    });
    if(_requireRuntime && _session.package != null) {
      for(int i = 0, length = entries.length; i < length; i++) {
        common.DocumentEntry entry = entries[i];
        if(entry is php.Script) {
          entry.body.statements.insert(0, (new mammouth.ImportDirectiveImpl(
              new mammouth.StringLiteralImpl(
                  '"package:runtime/runtime.mammouth"'))).accept(this) as php
              .ExpressionStatement);
        }
      }
    }
    return new common.DocumentImpl.build(entries);
  }

  @override
  common.InlineEntry visitInlineEntry(common.InlineEntry node) {
    return new common.InlineEntryImpl.build(node.content);
  }

  @override
  Object visitArgumentList(mammouth.ArgumentList node) {
    return null;
  }

  @override
  php.Expression visitArrayLiteral(mammouth.ArrayLiteral node) {
    List<php.Expression> elements = node.elements.map((
        mammouth.Expression element) {
      return element.accept<Object>(this) as php.Expression;
    }).toList();
    return _finalizeExpression(_constructArray(elements), node);
  }

  @override
  php.Expression visitAsExpression(mammouth.AsExpression node) {
    return new php.CastExpressionImpl(_typeToString(node.type, forAs: true),
        node.argument.accept(this) as php.Expression);
  }

  @override
  php.Expression visitAssignmentExpression(mammouth.AssignmentExpression node) {
    if(node.setterElement != null) {
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  (node.left as mammouth.MemberExpression)
                      .target
                      .accept<Object>(this),
                  new php.NameImpl.build(
                      "__mmt_set_${node.setterElement.name}")),
              [node.right.accept<Object>(this)]),
          node);
    }
    if(node.left is mammouth.MemberExpression) {
      mammouth.MemberExpression left = node.left;
      if(left.referredElement == null) {
        return _finalizeExpression(_runtimeCallSetter(
            left.target.accept<Object>(this), left.property.name,
            node.right.accept<Object>(this)), node);
      }
    }
    return _finalizeExpression(
        new php.AssignmentExpressionImpl(
            node.left.accept<Object>(this),
            new php.AssignmentOperatorImpl(node.operator.token),
            node.right.accept<Object>(this)),
        node);
  }

  @override
  String visitAssignmentOperator(mammouth.AssignmentOperator node) {
    // TODO: use this from visitAssignmentOperator
    return node.token.lexeme;
  }

  @override
  php.Expression visitAtExpression(mammouth.AtExpression node) {
    mammouth.ClassMemberElement element = node.referredElement;
    mammouth.MemberExpression virtualNode = new mammouth.MemberExpressionImpl(
        new mammouth.SimpleIdentifierImpl.syntactic(
            new StringToken(TokenKind.NAME, "this", null))
          ..referredElement =
              (element.enclosingElement as mammouth.ClassElement).thisElement,
        node.property)
      ..converterElement = node.converterElement;
    virtualNode.referredElement = node.referredElement;
    return virtualNode.accept<Object>(this);
  }

  @override
  php.Expression visitBinaryExpression(mammouth.BinaryExpression node) {
    if(node.operatorElement != null) {
      List<php.Expression> arguments = [node.right.accept<Object>(this)];
      if(node.operatorElement.node.isInline) {
        return _finalizeExpression(
            this._inlineExecutable(node.operatorElement, arguments, node.scope,
                thisValue: node.left.accept<Object>(this)),
            node);
      }
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  node.left.accept<Object>(this),
                  new php.NameImpl.build(null)
                    ..element = node.operatorElement.resultName),
              arguments),
          node);
    }
    return _finalizeExpression(_runtimeCallArguments(
        node.left.accept<Object>(this),
        "operator${node.operator.lexeme}",
        [node.right.accept<Object>(this)]), node);
  }

  @override
  String visitBinaryOperator(mammouth.BinaryOperator node) {
    // TODO: use this from visitBinaryExpression
    return node.token.lexeme;
  }

  @override
  php.Block visitBlock(mammouth.Block node, {bool scope = true}) {
    List<php.Statement> statements = new List<php.Statement>();
    node.statements.forEach((mammouth.Statement statement) {
      this.beforeStatements.add(<php.Statement>[]);
      php.Statement resultStatement = statement.accept<Object>(this);
      if(this.beforeStatements.isNotEmpty) {
        statements.addAll(this.beforeStatements.removeLast());
      }
      if(resultStatement != null) {
        statements.add(resultStatement);
      }
    });
    return new php.BlockImpl.build(statements);
  }

  @override
  php.Expression visitBooleanLiteral(mammouth.BooleanLiteral node) {
    return _finalizeExpression(
        new php.BooleanLiteralImpl.build(node.value), node);
  }

  @override
  php.BreakStatement visitBreakStatement(mammouth.BreakStatement node) {
    return new php.BreakStatementImpl.build();
  }

  @override
  Object visitClassExpression(mammouth.ClassExpression node,
      {mammouth.InterfaceType type}) {
    if(node.asStatement) {
      List<php.ClassMember> members = <php.ClassMember>[];
      // build an unique php constructor from zero or many mammouth constructor
      php.MethodDeclaration constructor;
      if(node.element.constructors.length > 0) {
        List<php.Parameter> parameters = <php.Parameter>[];
        php.Block body;
        if(node.element.constructors.length == 1) {
          if(node.element.constructors.first.node.hasParameters) {
            parameters = node.element.constructors.first.node.parameters
                .accept<Object>(this);
          }
          body = _compileBody(
              node.element.constructors.first.node.body, forceBlock: true);
        } else {
          php.Variable cid = new php.VariableImpl.build(
              this.namePicker.pick("cid", new Set<String>()));
          parameters.add(new php.ParameterImpl(cid));
          body = new php.BlockImpl.build(<php.Statement>[]);
          php.Variable argumentVariable = new php.VariableImpl.build(
              this.namePicker.pick("arguments", new Set<String>()));
          body.statements.add(new php.ExpressionStatementImpl.build(
              new php.AssignmentExpressionImpl(
                  argumentVariable,
                  new php.AssignmentOperatorImpl(
                      new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
                  new php.FunctionCallExpressionImpl.build(
                      new php.NameImpl.build("func_get_args"),
                      <php.Expression>[]))));
          php.IfStatementImpl switcher;
          for(mammouth.ConstructorElement constructorElement in node.element
              .constructors) {
            mammouth.ConstructorDeclaration constructori =
                constructorElement.node;
            php.IfStatement statement = new php.IfStatementImpl.build(
                new php.BinaryExpressionImpl(
                    cid,
                    new php.BinaryOperatorImpl(
                        new SimpleToken(TokenKind.EQUAL, null)),
                    new php.IntegerLiteralImpl(new StringToken(
                        TokenKind.INTEGER,
                        constructori.element.id.toString(),
                        null))),
                _compileBody(constructori.body, forceBlock: true),
                null);
            if(constructori.hasParameters) {
              for(int j = 0;
              j < constructori.parameters.parameters.length;
              j++) {
                mammouth.SimpleParameter parameterj =
                constructori.parameters.parameters.elementAt(j);
                if(statement.consequent is php.Block) {
                  php.Block block = statement.consequent;
                  block.statements.insert(
                      j,
                      new php.ExpressionStatementImpl.build(
                          new php.AssignmentExpressionImpl(
                              parameterj.name.accept<Object>(this),
                              new php.AssignmentOperatorImpl(new SimpleToken(
                                  TokenKind.ASSIGN_EQUAL, null)),
                              new php.ArrayItemImpl.build(
                                  argumentVariable,
                                  new php.IntegerLiteralImpl(new StringToken(
                                      TokenKind.INTEGER,
                                      (j + 1).toString(),
                                      null))))));
                } else {
                  // TODO:
                }
              }
            }
            if(switcher == null) {
              switcher = statement;
            } else {
              switcher.alternate = statement;
            }
          }
          body.statements.add(switcher);
        }
        constructor = new php.MethodDeclarationImpl.build(
            new SimpleToken(TokenKind.PUBLIC, null), null,
            new php.NameImpl.build("__construct"), parameters, body);
      }
      php.ClassDeclaration result = new php.ClassDeclarationImpl.build(
          new php.NameImpl.build(node.name.name),
          node.extendsClause != null ? new php.NameImpl.build(
              (node.extendsClause?.superclass?.name as mammouth
                  .SimpleIdentifier)?.name) : null, <php.ClassMember>[]);
      if(constructor != null) {
        members.add(constructor);
      }
      List<mammouth.FieldElement> fields = <mammouth.FieldElement>[];
      List<String> overloaded_members = <String>[];
      node.element.memberNames.forEach((String name) {
        int insertIndex = members.length;
        List<mammouth.ExecutableClassMemberElement> elements = node.element
            .getElementsOf(name)
            .where((mammouth.ClassMemberElement element) {
          if(element is mammouth.FieldElement) {
            fields.add(element);
          }
          return element is mammouth.MethodElement ||
              element is mammouth.OperatorElement ||
              element is mammouth.ConverterElement;
        }).whereType<mammouth.ExecutableClassMemberElement>().toList();
        bool isOverloaded = false;
        elements.forEach((mammouth.ExecutableClassMemberElement element) {
          members.add(element.node.accept<Object>(this));
          if(element.isOverloaded) {
            isOverloaded = true;
          }
        });
        if(isOverloaded) {
          List<php.Parameter> parameters = [];
          overloaded_members.add(name);
          php.Block body;
          body = new php.BlockImpl.build([]);
          php.Variable argumentVariable = new php.VariableImpl.build(null)
            ..element = new php.LateName("arguments");
          body.statements.add(new php.ExpressionStatementImpl.build(
              new php.AssignmentExpressionImpl(
                  argumentVariable,
                  new php.AssignmentOperatorImpl(
                      new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
                  new php.FunctionCallExpressionImpl.build(
                      new php.NameImpl.build("func_get_args"), []))));
          if(elements.first is mammouth.MethodElement &&
              (elements.first as mammouth.MethodElement).isSetter) {
            php.Parameter value = new php.ParameterImpl(
                new php.VariableImpl.build("value"));
            parameters.add(value);
            body.statements.add(new php.ExpressionStatementImpl.build(
                _runtimeCallSetter(
                    new php.VariableImpl.build("this"), name,
                    value.variable)));
          } else {
            body.statements.add(new php.ExpressionStatementImpl.build(
                _runtimeCall(new php.VariableImpl.build("this"), name,
                    argumentVariable)));
          }
          body.enableAutoReturn((php.Expression expression) {
            return new php.ReturnStatementImpl.build(expression);
          });
          String resultName;
          if(elements.first is mammouth.MethodElement) {
            resultName = name;
          } else if(elements.first is mammouth.OperatorElement) {
            mammouth.OperatorElement ele = elements.first;
            if(ele.node.operatorKeyword.lexeme == "operator") {
              resultName =
              "__mmt_operator_${this.namePicker.operatorNames[ele.node.operator
                  .lexeme]}";
            } else {
              resultName =
              "__mmt_operator_${ele.node.operator.lexeme}_${this.namePicker
                  .operatorNames[ele.node.operator.lexeme]}";
            }
          } else if(elements.first is mammouth.ConverterElement) {
            resultName = "__mmt_converter";
          }
          php.MethodDeclaration method = new php.MethodDeclarationImpl.build(
              new SimpleToken(TokenKind.PUBLIC, null),
              null,
              new php.NameImpl.build(resultName),
              parameters,
              body);
          members.insert(insertIndex, method);
        } else {
          if(elements.isNotEmpty &&
              (elements.first is mammouth.OperatorElement ||
                  (elements.first is mammouth.MethodElement &&
                      ((elements.first as mammouth.MethodElement).isGetter) ||
                      (elements.first as mammouth.MethodElement).isSetter))) {
            overloaded_members.add(name);
          }
        }
      });
      for(int i = fields.length - 1; i >= 0; i--) {
        mammouth.FieldElement field = fields[i];
        members.insert(0, field.node.accept<Object>(this));
      }
      if(overloaded_members.isNotEmpty) {
        Map<String, Map<int, Map<php.Name, List<String>>>> runtime_map = {};
        overloaded_members.forEach((String name) {
          if(!runtime_map.containsKey(name)) runtime_map[name] = {};
          node.element
              .getElementsOf(name)
              .forEach((mammouth.ClassMemberElement element) {
            if(element is mammouth.ExecutableClassMemberElement) {
              if(!runtime_map[name].containsKey(element.parameters.length)) {
                runtime_map[name][element.parameters.length] = {};
              }
              php.Name methodKey = new php.NameImpl(null)
                ..element = element.resultName
                ..asString = true;
              runtime_map[name][element.parameters.length][methodKey] =
              element.node.parameters != null ? element.node.parameters
                  .parameters.map((mammouth.Parameter parameter) {
                if(parameter.isTyped) {
                  if(parameter is mammouth.SimpleParameter) {
                    return _typeToString(parameter.type);
                  } else if(parameter is mammouth.ClosureParameter) {
                    return ((parameter.returnType as mammouth.TypeName)
                        .name as mammouth.SimpleIdentifier).name + "(" +
                        parameter.parameterTypes.map((
                            mammouth.TypeAnnotation type) {
                          return ((type as mammouth.TypeName).name as mammouth
                              .SimpleIdentifier).name;
                        }).join(",") + ")";
                  }
                  // TODO:
                }
                return "dynamic";
              }).toList()
                  : <String>[];
              runtime_map[name][element.parameters.length][methodKey].insert(0,
                  element.returnType is mammouth.DynamicType
                      ? "dynamic"
                      : _typeToString(element.node.returnType));
            }
          });
        });
        members.add(new php.FieldDeclarationImpl.build(
            null,
            new SimpleToken(TokenKind.STATIC, null),
            new php.VariableImpl.build("__mmt_runtime_map"),
            Dart2PHP.convert(runtime_map)));
      }
      result.members.addAll(members);
      return result;
    }
    // TODO: class as anonymous
  }

  @override
  php.Parameter visitClosureParameter(mammouth.ClosureParameter node) {
    return new php.ParameterImpl(new php.VariableImpl.build(node.name.name));
  }

  @override
  Object visitConstructorDeclaration(mammouth.ConstructorDeclaration node) {
    // nothing to do here
  }

  @override
  php.ContinueStatement visitContinueStatement(
      mammouth.ContinueStatement node) {
    return new php.ContinueStatementImpl.build();
  }

  @override
  php.MethodDeclaration visitConverterDeclaration(
      mammouth.ConverterDeclaration node) {
    // This is used only to compile non-overloading converter
    // converter overloading is implemented in visitClassExpression
    php.Statement body = _compileBody(node.body, forceBlock: true);
    body.enableAutoReturn((php.Expression expression) {
      return new php.ReturnStatementImpl.build(expression);
    });
    php.Name name = new php.NameImpl.build("__mmt_converter");
    if(node.element.isOverride) {
      name.element = node.element.overrided.resultName;
      if(node.element.isOverloaded) {
        name.element = new php.LateName(name.name + "_");
      } else {
        name.element = new php.LateName(name.name);
      }
    } else {
      if(node.element.isOverloaded) {
        name.element = new php.LateName(name.name + "_");
      } else {
        name.element = new php.LateName(name.name);
      }
    }
    node.element.resultName = name.element;
    return new php.MethodDeclarationImpl.build(
        node.visibilityToken, null, name, [], body);
  }

  @override
  Object visitEchoExpression(mammouth.EchoExpression node) {
    php.Expression expression = node.argument.accept<Object>(this);
    php.Statement echoStatement = new php.EchoStatementImpl.build(expression);
    if(node.asStatement) {
      return echoStatement;
    }
    // TODO: hold expression in a variable then use it.
    this.beforeStatements.last.add(echoStatement);
    return _finalizeExpression(expression, node);
  }

  @override
  php.Expression visitExistenceExpression(mammouth.ExistenceExpression node) {
    return _finalizeExpression(
        new php.FunctionCallExpressionImpl.build(
            new php.NameImpl.build("isset"),
            [node.argument.accept<Object>(this)]),
        node);
  }

  @override
  Object visitExpressionStatement(mammouth.ExpressionStatement node) {
    common.AstNode result = node.expression.accept<Object>(this);
    if(result is php.Statement) {
      return result;
    }
    if(result == null) {
      return null;
    }
    return new php.ExpressionStatementImpl.build(result);
  }

  @override
  Object visitExtendsClause(mammouth.ExtendsClause node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  php.FieldDeclaration visitFieldDeclaration(mammouth.FieldDeclaration node) {
    return new php.FieldDeclarationImpl.build(
        node.visibilityToken,
        node.isStatic ? new SimpleToken(TokenKind.STATIC, null) : null,
        new php.VariableImpl.build(node.name.name),
        node.isInitialized ? node.initializer.accept<Object>(this) : null);
  }

  @override
  php.Expression visitFloatLiteral(mammouth.FloatLiteral node) {
    return _finalizeExpression(new php.FloatLiteralImpl(node.token), node);
  }

  @override
  Object visitFunctionExpression(mammouth.FunctionExpression node) {
    List<php.Parameter> parameters = node.parameters.accept<Object>(this);
    php.Statement body = _compileBody(node.body, forceBlock: true);
    body.enableAutoReturn((php.Expression expression) {
      return new php.ReturnStatementImpl.build(expression);
    });
    if(node.asStatement) {
      return new php.FunctionStatementImpl.build(
          new php.NameImpl.build(node.name.name), parameters, body);
    }
    // TODO: if name is given declare as statement then assign
    // TODO: do the some if php < 5.3.0
    return new php.ClosureExpressionImpl.build(parameters, body);
  }

  @override
  php.AstNode visitForExpression(mammouth.ForExpression node) {
    mammouth.ForSource source = node.source;
    List<php.Variable> variables = node.usedElements
        .where((mammouth.Element element) {
      return element is mammouth.VariableElement;
    }).whereType<mammouth.VariableElement>().map((
        mammouth.VariableElement element) {
      return new php.VariableImpl.build(element.name);
    }).toList();

    bool produceForEach = false;
    php.Expression init;
    php.Expression test;
    php.Expression update;

    php.Expression expression;
    php.Expression keyVariable;
    php.Expression valueVariable;

    php.Statement body = _compileBody(node.body);
    if(source is mammouth.ForRangeSourceImpl) {
      php.Variable indexVariable;
      if(source.hasName) {
        indexVariable = source.name.accept<Object>(this);
      } else {
        php.LateName indexElement = new php.LateName("");
        indexVariable = new php.VariableImpl(null)
          ..element = indexElement;
      }
      init = new php.AssignmentExpressionImpl(
          indexVariable,
          new php.AssignmentOperatorImpl(
              new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
          source.source.start.accept<Object>(this));
      // TODO: add length to init
      TokenKind kind;
      if(source.source.operator.kind == TokenKind.RANGE_DOUBLEDOT) {
        kind = TokenKind.LESS_THAN;
      } else {
        kind = TokenKind.LESS_THAN_OR_EQUAL;
      }
      test = new php.BinaryExpressionImpl(
          indexVariable,
          new php.BinaryOperatorImpl(new SimpleToken(kind, null)),
          source.source.end.accept<Object>(this));
      if(source.hasStep) {
        update = new php.AssignmentExpressionImpl(
            indexVariable,
            new php.AssignmentOperatorImpl(
                new SimpleToken(TokenKind.ASSIGN_ADD, null)),
            source.step.accept<Object>(this));
      } else {
        update = new php.UpdateExpressionImpl(
            false,
            new php.UpdateOperatorImpl(
                new SimpleToken(TokenKind.UPDATE_INCR, null)),
            indexVariable);
      }
      if(node.source.hasGuard) {
        body = new php.BlockImpl.build([
          body = new php.IfStatementImpl.build(
              node.source.guard.condition.accept<Object>(this), body, null)
        ]);
      }
    } else if(source is mammouth.ForVariableSource) {
      if(source.kind == mammouth.ForVariableSourceKind.IN) {
        php.Variable indexVariable;
        if(source.hasSecondVariable) {
          indexVariable = source.secondVariable.accept<Object>(this);
        } else {
          php.LateName indexElement = new php.LateName("");
          indexVariable = new php.VariableImpl(null)
            ..element = indexElement;
        }
        if(!(body is php.Block)) {
          body = new php.BlockImpl.build([body]);
        }
        if(source.source is mammouth.RangeLiteral) {
          mammouth.RangeLiteral range = source.source;
          init = new php.AssignmentExpressionImpl(
              indexVariable,
              new php.AssignmentOperatorImpl(
                  new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
              range.start.accept<Object>(this));
        } else {
          init = new php.AssignmentExpressionImpl(
              indexVariable,
              new php.AssignmentOperatorImpl(
                  new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
              new php.IntegerLiteralImpl(
                  new StringToken(TokenKind.INTEGER, "0", null)));
        }
        // TODO: add length to init
        if(source.source is mammouth.RangeLiteral) {
          mammouth.RangeLiteral range = source.source;
          TokenKind kind;
          if(range.operator.kind == TokenKind.RANGE_DOUBLEDOT) {
            kind = TokenKind.LESS_THAN;
          } else {
            kind = TokenKind.LESS_THAN_OR_EQUAL;
          }
          test = new php.BinaryExpressionImpl(
              indexVariable,
              new php.BinaryOperatorImpl(new SimpleToken(kind, null)),
              range.end.accept<Object>(this));
        } else {
          test = new php.BinaryExpressionImpl(
              indexVariable,
              new php.BinaryOperatorImpl(
                  new SimpleToken(TokenKind.LESS_THAN, null)),
              new php.FunctionCallExpressionImpl.build(
                  new php.NameImpl.build("count"),
                  [source.source.accept<Object>(this)]));
        }
        if(source.hasStep) {
          update = new php.AssignmentExpressionImpl(
              indexVariable,
              new php.AssignmentOperatorImpl(
                  new SimpleToken(TokenKind.ASSIGN_ADD, null)),
              source.step.accept<Object>(this));
        } else {
          update = new php.UpdateExpressionImpl(
              false,
              new php.UpdateOperatorImpl(
                  new SimpleToken(TokenKind.UPDATE_INCR, null)),
              indexVariable);
        }
        if(node.source.hasGuard) {
          body = new php.BlockImpl.build([
            body = new php.IfStatementImpl.build(
                node.source.guard.condition.accept<Object>(this), body, null)
          ]);
        }
        if(!(source.source is mammouth.RangeLiteral)) {
          (body as php.Block).statements.insert(
              0,
              new php.ExpressionStatementImpl.build(
                  new php.AssignmentExpressionImpl(
                      source.firstVariable.accept<Object>(this),
                      new php.AssignmentOperatorImpl(
                          new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
                      new php.ArrayItemImpl.build(
                          source.source.accept<Object>(this), indexVariable))));
        }
        // TODO: add length to init
        // TODO: add expression ref to init
      } else if(source.kind == mammouth.ForVariableSourceKind.OF) {
        produceForEach = true;
        expression = source.source.accept<Object>(this);
        if(source.hasSecondVariable) {
          keyVariable = source.firstVariable.accept<Object>(this);
          valueVariable = source.secondVariable.accept<Object>(this);
        } else {
          keyVariable = source.firstVariable.accept<Object>(this);
        }
        // REMARK(We didn't implement `by` for `for .. of ..`)
        if(node.source.hasGuard) {
          body = new php.BlockImpl.build([
            body = new php.IfStatementImpl.build(
                node.source.guard.condition.accept<Object>(this), body, null)
          ]);
        }
      }
    }

    php.Statement statement;
    if(produceForEach) {
      statement = new php.ForeachStatementImpl.build(
          expression, keyVariable, valueVariable, body);
    } else {
      statement = new php.ForStatementImpl.build(init, test, update, body);
    }
    if(node.asStatement) {
      return statement;
    }
    // if it's not a statement
    php.LateName arrayElement = new php.LateName("result");
    php.Variable arrayVariable = new php.VariableImpl(null)
      ..element = arrayElement;
    php.ClosureExpression function = new php.ClosureExpressionImpl.build(
        [],
        new php.BlockImpl.build([
          new php.ExpressionStatementImpl.build(
              new php.AssignmentExpressionImpl(
                  arrayVariable,
                  new php.AssignmentOperatorImpl(
                      new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
                  _constructArray())),
          statement
        ]));
    if(variables.isNotEmpty) {
      function.body.statements
          .insert(0, new php.GlobalStatementImpl.build(variables));
    }
    function.enableAutoReturn((php.Expression expression) {
      return new php.ExpressionStatementImpl.build(
          new php.FunctionCallExpressionImpl.build(
              new php.NameImpl.build("array_push"),
              [arrayVariable, expression]));
    });
    function.body.statements
        .add(new php.ReturnStatementImpl.build(arrayVariable));
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("call_user_func"), [function]);
  }

  @override
  Object visitForRangeSource(mammouth.ForRangeSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  php.Variable visitForVariable(mammouth.ForVariable node) {
    return new php.VariableImpl.build(node.name.name);
  }

  @override
  Object visitForVariableSource(mammouth.ForVariableSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  Object visitGuardSource(mammouth.GuardSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  common.AstNode visitIfExpression(mammouth.IfExpression node) {
    php.Expression condition = node.condition.accept<Object>(this);
    if(node.isUnless) {
      condition = new php.UnaryExpressionImpl(
          new php.UnaryOperatorImpl(new SimpleToken(TokenKind.UNARY_NOT, null)),
          condition);
    }
    php.Statement consequent = _compileBody(node.consequent);
    php.Statement alternate = node.hasAlternate
        ? _compileBody(node.alternate)
        : null;
    php.Statement statement =
    new php.IfStatementImpl.build(condition, consequent, alternate);
    if(node.asStatement) {
      return statement;
    }
    // if it's not a statement
    List<php.Variable> variables =
    node.usedElements.where((mammouth.Element element) {
      return element is mammouth.VariableElement;
    }).whereType<mammouth.VariableElement>()
        .map((mammouth.VariableElement element) {
      return new php.VariableImpl.build(element.name);
    }).toList();
    php.ClosureExpression function = new php.ClosureExpressionImpl.build(
        [], new php.BlockImpl.build([statement]));
    if(variables.isNotEmpty) {
      function.body.statements
          .insert(0, new php.GlobalStatementImpl.build(variables));
    }
    function.enableAutoReturn((php.Expression expression) {
      return new php.ReturnStatementImpl.build(expression);
    });
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("call_user_func"), [function]);
    // TODO: use USE if possible in some versions instead of call_user_func
    // TODO: _finalizeExpression for class if while..
  }

  @override
  common.AstNode visitIfSource(mammouth.IfSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
  }

  @override
  Object visitImplementsClause(mammouth.ImplementsClause node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  php.ExpressionStatement visitImportDirective(mammouth.ImportDirective node) {
    String uri = node.uri.value;
    if(uri.startsWith("package:")) {
      uri = p.join("packages",
          uri.replaceAll(new RegExp(r"(mammouth|mmt)$"), "php").replaceAll(
              new RegExp(r"^package:"), ""));
      uri = p.relative(_session.projectRoot.uri.resolve(uri).toFilePath(),
          from: p.dirname(_source.uri.toFilePath()));
    } else {
      uri = uri.replaceAll(new RegExp(r"(mammouth|mmt)$"), "php");
    }
    if(!uri.startsWith("/")) {
      uri = "/" + uri;
    }
    return new php.ExpressionStatementImpl.build(new php.IncludeExpressionImpl(
        new php.ConcatenationExpressionImpl(new php.NameImpl.build("__DIR__"),
            new php.StringLiteralImpl(new StringToken(null, '"$uri"', null))),
        true));
  }

  @override
  php.Expression visitIndexExpression(mammouth.IndexExpression node) {
    // TODO: []= operator
    if(node.operatorElement != null) {
      List<php.Expression> arguments = [node.index.accept<Object>(this)];
      if(node.operatorElement.node.isInline) {
        return _finalizeExpression(
            this._inlineExecutable(node.operatorElement, arguments, node.scope,
                thisValue: node.target.accept<Object>(this)),
            node);
      }
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  node.target.accept<Object>(this),
                  new php.NameImpl.build(null)
                    ..element = node.operatorElement.resultName),
              arguments),
          node);
    }
    return _finalizeExpression(
        new php.ArrayItemImpl.build(
            node.target.accept<Object>(this), node.index.accept<Object>(this)),
        node);
  }

  @override
  php.Expression visitInExpression(mammouth.InExpression node) {
    if(node.methodElement != null) {
      List<php.Expression> arguments = [node.element.accept<Object>(this)];
      if(node.methodElement.node.isInline) {
        return _finalizeExpression(
            this._inlineExecutable(node.methodElement, arguments, node.scope,
                thisValue: node.container.accept<Object>(this)),
            node);
      }
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  node.container.accept<Object>(this),
                  new php.NameImpl.build(null)
                    ..element = node.methodElement.resultName),
              arguments),
          node);
    }
    // TODO: call `contains` method
    return null;
  }

  @override
  php.Expression visitInvocationExpression(mammouth.InvocationExpression node) {
    List<php.Expression> arguments =
    node.arguments.arguments.map((mammouth.Expression expression) {
      return expression.accept<Object>(this) as php.Expression;
    }).toList();
    if(node.callee.referredElement is mammouth.ExecutableElement) {
      mammouth.ExecutableElement executable = node.callee.referredElement;
      if(executable.node.isInline) {
        php.AstNode thisValue = null;
        if(executable is mammouth.MethodElement) {
          thisValue = (node.callee as mammouth.MemberExpression)
              .target
              .accept<Object>(this);
        }
        return _finalizeExpression(
            this._inlineExecutable(executable, arguments, node.scope,
                thisValue: thisValue),
            node);
      }
    }
    return _finalizeExpression(
        new php.FunctionCallExpressionImpl.build(
            node.callee.accept<Object>(this), arguments),
        node);
  }

  @override
  php.Expression visitIntegerLiteral(mammouth.IntegerLiteral node) {
    return _finalizeExpression(new php.IntegerLiteralImpl(
        new StringToken(null, node.raw, null)), node);
  }

  @override
  Object visitInterfaceDeclaration(mammouth.InterfaceDeclaration node) {
    List<php.ClassMember> members = <php.ClassMember>[];
    // build an unique php constructor from zero or many mammouth constructor
    php.MethodDeclaration constructor;
    if(node.element.constructors.length > 0) {
      List<php.Parameter> parameters = <php.Parameter>[];
      php.Block body;
      if(node.element.constructors.length == 1) {
        if(node.element.constructors.first.node.hasParameters) {
          parameters = node.element.constructors.first.node.parameters
              .accept<Object>(this);
        }
        body = _compileBody(
            node.element.constructors.first.node.body, forceBlock: true);
        constructor = new php.MethodDeclarationImpl.build(
            new SimpleToken(TokenKind.PUBLIC, null),
            null,
            new php.NameImpl.build("__construct"),
            parameters,
            body);
      }
    }
    php.InterfaceDeclaration result = new php.InterfaceDeclarationImpl.build(
        new php.NameImpl.build(node.name.name), []);
    if(constructor != null) {
      members.add(constructor);
    }
    node.element.memberNames.forEach((String name) {
      List<mammouth.ClassMemberElement> elements =
      node.element.getElementsOf(name);
      if(elements.every((mammouth.ClassMemberElement element) {
        return element is mammouth.MethodElement ||
            element is mammouth.OperatorElement ||
            element is mammouth.ConverterElement;
      })) {
        if(elements.length == 1) {
          members.add(elements.first.node.accept<Object>(this));
        }
      }
    });
    result.members.addAll(members);
    return result;
  }

  @override
  php.KeyValue visitMMapEntry(mammouth.MMapEntry node) {
    return new php.KeyValueImpl.build(
        node.key.accept<Object>(this), node.value.accept<Object>(this));
  }

  @override
  php.Expression visitMapLiteral(mammouth.MapLiteral node) {
    return _finalizeExpression(
        _constructArray(node.entries.map((mammouth.MMapEntry entry) {
          return entry.accept<Object>(this);
        }).whereType<php.Expression>().toList()), node);
  }

  @override
  php.Expression visitMemberExpression(mammouth.MemberExpression node) {
    mammouth.Element element = node.referredElement;
    if(element is mammouth.MethodElement && element.node.isGetter) {
      if(element.node.isInline) {
        return _finalizeExpression(
            this._inlineExecutable(
                element, [], node.scope,
                thisValue: node.target.accept<Object>(this)),
            node);
      }
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  node.target.accept<Object>(this),
                  new php.NameImpl.build("__mmt_get_${node.property.name}")),
              []),
          node);
    }
    if(element is mammouth.MethodElement || element is mammouth.FieldElement) {
      php.Name property;
      if(element is mammouth.MethodElement && element.resultName != null) {
        property = new php.NameImpl(null)
          ..element = element.resultName;
      } else {
        property = node.property.accept<Object>(this);
      }
      if(element is mammouth.MethodElement && element.node.isStatic) {
        return _finalizeExpression(
            new php.StaticPropertyFetchImpl.build(
                node.target.accept<Object>(this), property),
            node);
      }
      if(element is mammouth.FieldElement && element.node.isStatic) {
        return _finalizeExpression(
            new php.StaticPropertyFetchImpl.build(
                node.target.accept<Object>(this),
                new php.VariableImpl.build(node.property.name)),
            node);
      }
      return _finalizeExpression(
          new php.PropertyFetchImpl.build(
              node.target.accept<Object>(this), property),
          node);
    }
    return _finalizeExpression(_runtimeCallGetter(
        node.target.accept<Object>(this), node.property.name), node);
  }

  @override
  php.MethodDeclaration visitMethodDeclaration(
      mammouth.MethodDeclaration node) {
    // This is used only to compile non-overloading method
    // method overloading is implemented in visitClassExpression
    List<php.Parameter> parameters = node.hasParameters ? node.parameters
        .accept<Object>(this) : [];
    php.Statement body;
    if(!node.isSignature) {
      body = _compileBody(node.body, forceBlock: true);
      body.enableAutoReturn((php.Expression expression) {
        return new php.ReturnStatementImpl.build(expression);
      });
    }
    php.Name name;
    if(node.isGetter) {
      name = new php.NameImpl.build("__mmt_get_${node.name.name}");
    } else if(node.isSetter) {
      name = new php.NameImpl.build("__mmt_set_${node.name.name}");
    } else {
      name = new php.NameImpl.build(node.name.name);
    }
    if(node.element.isOverride) {
      name.element = node.element.overrided.resultName;
      if(node.element.isOverloaded) {
        name.element = new php.LateName(name.name + "_");
      } else {
        name.element = new php.LateName(name.name);
      }
    } else {
      if(node.element.isOverloaded) {
        name.element = new php.LateName(name.name + "_");
      } else {
        name.element = new php.LateName(name.name);
      }
    }
    node.element.resultName = name.element;
    return new php.MethodDeclarationImpl.build(
        node.visibilityToken,
        node.isStatic ? new SimpleToken(TokenKind.STATIC, null) : null,
        name,
        parameters,
        body)
      ..isAbstract = node.isAbstract;
  }

  @override
  php.Expression visitNativeExpression(mammouth.NativeExpression node) {
    return _finalizeExpression(
        new php.RawExpressionImpl(
            (node.arguments.arguments.elementAt(0) as mammouth.StringLiteral)
                .value,
            node.arguments.arguments
                .toList()
                .sublist(1)
                .map((mammouth.Expression argument) {
              return argument.accept<Object>(this) as php.Expression;
            }).toList()),
        node);
  }

  @override
  php.MethodDeclaration visitOperatorDeclaration(
      mammouth.OperatorDeclaration node) {
    // This is used only to compile non-overloading operator
    // operator overloading is implemented in visitClassExpression
    List<php.Parameter> parameters = node.hasParameters ? node.parameters
        .accept<Object>(this) : [];
    php.Statement body;
    if(!node.isSignature) {
      body = _compileBody(node.body, forceBlock: true);
      body.enableAutoReturn((php.Expression expression) {
        return new php.ReturnStatementImpl.build(expression);
      });
    }
    php.Name name;
    if(node.operatorKeyword.lexeme == "operator") {
      name = new php.NameImpl.build(
          "__mmt_operator_${this.namePicker.operatorNames[node.operator.token
              .lexeme]}");
    } else {
      name = new php.NameImpl.build(
          "__mmt_operator_${node.operatorKeyword.lexeme}_${this.namePicker
              .operatorNames[node.operator.token.lexeme]}");
    }
    if(node.element.isOverride) {
      name.element = node.element.overrided.resultName;
      if(node.element.isOverloaded) {
        name.element = new php.LateName(name.name + "_");
      } else {
        name.element = new php.LateName(name.name);
      }
    } else {
      if(node.element.isOverloaded) {
        name.element = new php.LateName(name.name + "_");
      } else {
        name.element = new php.LateName(name.name);
      }
    }
    node.element.resultName = name.element;
    return new php.MethodDeclarationImpl.build(
        node.visibilityToken, null, name, parameters, body);
  }

  @override
  php.Expression visitNewExpression(mammouth.NewExpression node) {
    List<php.Expression> arguments = node.arguments.arguments
        .map((mammouth.Expression argument) {
      return argument.accept<Object>(this);
    }).whereType<php.Expression>().toList();
    if(node.constructorElement != null) {
      if((node.constructorElement.enclosingElement as mammouth.ClassElement)
          .constructors.length > 1) {
        arguments.insert(0, new php.IntegerLiteralImpl(new StringToken(
            TokenKind.INTEGER, node.constructorElement.id.toString(), null)));
      }
      if(node.constructorElement.node.isInline) {
        return _finalizeExpression(
            _inlineExecutable(node.constructorElement, arguments,
                node.scope), node);
      }
      return _finalizeExpression(
          new php.NewExpressionImpl.build(
              new php.NameImpl.build(
                  node.constructorElement.enclosingElement.name), arguments),
          node);
    }
    return _finalizeExpression(
        new php.NewExpressionImpl.build(
            new php.NameImpl.build(_typeToString(node.callee)), arguments),
        node);
  }

  @override
  php.NullLiteral visitNullLiteral(mammouth.NullLiteral node) {
    return new php.NullLiteralImpl.build();
  }

  @override
  List<php.Parameter> visitParameterList(mammouth.ParameterList node) {
    return node.parameters.map((mammouth.Parameter parameter) {
      return parameter.accept<Object>(this) as php.Parameter;
    }).toList();
  }

  @override
  php.Expression visitParenthesisExpression(
      mammouth.ParenthesisExpression node) {
    return _finalizeExpression(
        new php.ParenthesisExpressionImpl.build(
            node.expression.accept<Object>(this)),
        node);
  }

  php.Expression visitRangeLiteral(mammouth.RangeLiteral node) {
    mammouth.Expression start = node.start;
    mammouth.Expression end = node.end;
    php.Expression startResult;
    if(node.start != null) {
      startResult = start.accept<Object>(this);
    } else {
      startResult = new php.IntegerLiteralImpl(
          new StringToken(TokenKind.INTEGER, "0", null));
    }
    php.Expression endResult = end.accept<Object>(this);
    php.Expression resultNode;
    if(start is mammouth.IntegerLiteral &&
        end is mammouth.IntegerLiteral &&
        end.value - start.value <= 20) {
      List<php.IntegerLiteral> arguments = <php.IntegerLiteral>[];
      for(int i = start.value, l = end.value;
      node.operator.kind == TokenKind.RANGE_DOUBLEDOT ? i < l : i <= l;
      i++) {
        arguments.add(new php.IntegerLiteralImpl(
            new StringToken(TokenKind.INTEGER, i.toString(), null)));
      }
      resultNode = _constructArray(arguments);
    } else {
      List<php.Variable> variables =
      node.usedElements.where((mammouth.Element element) {
        return element is mammouth.VariableElement;
      }).whereType<mammouth.VariableElement>()
          .map((mammouth.VariableElement element) {
        return new php.VariableImpl.build(element.name);
      }).toList();
      php.LateName arrayElement = new php.LateName("result");
      php.Variable arrayVariable = new php.VariableImpl(null)
        ..element = arrayElement;
      php.LateName indexElement = new php.LateName("");
      php.Variable indexVariable = new php.VariableImpl(null)
        ..element = indexElement;
      php.ClosureExpression function = new php.ClosureExpressionImpl.build(
          [],
          new php.BlockImpl.build([
            new php.ExpressionStatementImpl.build(
                new php.AssignmentExpressionImpl(
                    arrayVariable,
                    new php.AssignmentOperatorImpl(
                        new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
                    _constructArray())),
            new php.ForStatementImpl.build(
                new php.AssignmentExpressionImpl(
                    indexVariable,
                    new php.AssignmentOperatorImpl(
                        new SimpleToken(TokenKind.EQUAL, null)),
                    startResult),
                new php.BinaryExpressionImpl(
                    indexVariable,
                    new php.BinaryOperatorImpl(new SimpleToken(
                        node.operator.kind == TokenKind.RANGE_DOUBLEDOT
                            ? TokenKind.LESS_THAN
                            : TokenKind.LESS_THAN_OR_EQUAL,
                        null)),
                    endResult),
                new php.UpdateExpressionImpl(
                    false,
                    new php.UpdateOperatorImpl(
                        new SimpleToken(TokenKind.UPDATE_INCR, null)),
                    indexVariable),
                new php.BlockImpl.build([
                  new php.ExpressionStatementImpl.build(
                      new php.FunctionCallExpressionImpl.build(
                          new php.NameImpl.build("array_push"),
                          [arrayVariable, indexVariable]))
                ])),
            new php.ReturnStatementImpl.build(arrayVariable)
          ]));
      // TODO: clone php node for multiple usage
      if(variables.isNotEmpty) {
        function.body.statements
            .insert(0, new php.GlobalStatementImpl.build(variables));
      }
      resultNode = new php.FunctionCallExpressionImpl.build(
          new php.NameImpl.build("call_user_func"), [function]);
    }
    return _finalizeExpression(resultNode, node);
  }

  @override
  common.AstNode visitRepetitionExpression(mammouth.RepetitionExpression node) {
    php.Expression test;
    php.Statement body = _compileBody(node.body);
    if(node.isLoop) {
      test = new php.BooleanLiteralImpl.build(true);
    } else {
      test = node.test.accept<Object>(this);
    }
    if(node.isUntil) {
      test = new php.UnaryExpressionImpl(
          new php.UnaryOperatorImpl(new SimpleToken(TokenKind.UNARY_NOT, null)),
          test);
    }
    if(node.hasGuard) {
      body = new php.BlockImpl.build([
        body = new php.IfStatementImpl.build(
            node.guardCondition.accept<Object>(this), body, null)
      ]);
    }
    php.Statement statement = new php.WhileStatementImpl.build(test, body);
    if(node.asStatement) {
      return statement;
    }
    // if it's not a statement
    List<php.Variable> variables =
    node.usedElements.where((mammouth.Element element) {
      return element is mammouth.VariableElement;
    }).whereType<mammouth.VariableElement>()
        .map((mammouth.VariableElement element) {
      return new php.VariableImpl.build(element.name);
    }).toList();
    php.LateName arrayElement = new php.LateName("result");
    php.Variable arrayVariable = new php.VariableImpl(null)
      ..element = arrayElement;
    php.ClosureExpression function = new php.ClosureExpressionImpl.build(
        [],
        new php.BlockImpl.build([
          new php.ExpressionStatementImpl.build(
              new php.AssignmentExpressionImpl(
                  arrayVariable,
                  new php.AssignmentOperatorImpl(
                      new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
                  _constructArray())),
          statement
        ]));
    if(variables.isNotEmpty) {
      function.body.statements
          .insert(0, new php.GlobalStatementImpl.build(variables));
    }
    function.enableAutoReturn((php.Expression expression) {
      return new php.ExpressionStatementImpl.build(
          new php.FunctionCallExpressionImpl.build(
              new php.NameImpl.build("array_push"),
              [arrayVariable, expression]));
    });
    function.body.statements
        .add(new php.ReturnStatementImpl.build(arrayVariable));
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("call_user_func"), [function]);
  }

  @override
  common.AstNode visitRepetitionSource(mammouth.RepetitionSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
  }

  @override
  php.ReturnStatement visitReturnStatement(mammouth.ReturnStatement node) {
    php.Expression expression;
    if(node.expression != null) {
      expression = node.expression.accept<Object>(this);
    }
    return new php.ReturnStatementImpl.build(expression);
  }

  @override
  php.Script visitScript(mammouth.Script node) {
    php.Block body = _compileBody(node.body, forceBlock: true);
    return new php.ScriptImpl.build(body);
  }

  @override
  common.AstNode visitSimpleIdentifier(mammouth.SimpleIdentifier node) {
    if(node.referredElement is mammouth.VariableElement) {
      mammouth.VariableElement element = node.referredElement;
      if(element.effectiveValue != null) {
        return element.effectiveValue;
      }
    }
    if(node.referredElement is mammouth.VariableElement ||
        node.referredElement is mammouth.ParameterElement ||
        node.referredElement is mammouth.FieldElement) {
      return _finalizeExpression(new php.VariableImpl.build(node.name), node);
    }
    return new php.NameImpl.build(node.name);
  }

  @override
  php.Parameter visitSimpleParameter(mammouth.SimpleParameter node) {
    // TODO: initialized
    return new php.ParameterImpl(new php.VariableImpl.build(node.name.name));
  }

  @override
  php.Expression visitSliceExpression(mammouth.SliceExpression node) {
    List<php.Expression> arguments = [];
    if(node.slicingRange.start != null) {
      arguments.add(node.slicingRange.start.accept<Object>(this));
    } else {
      arguments.add(new php.IntegerLiteralImpl(
          new StringToken(TokenKind.INTEGER, "0", null)));
    }
    php.Expression end;
    if(node.slicingRange.end != null) {
      end = node.slicingRange.end.accept<Object>(this);
    } else {
      end = new php.FunctionCallExpressionImpl.build(
          new php.NameImpl.build("count"), [
        node.expression.accept<Object>(this)
      ]); // TODO: inline count if inlineable
    }
    if(node.slicingRange.operator.kind == TokenKind.RANGE_TRIPLEDOT) {
      arguments.add(new php.BinaryExpressionImpl(
          end,
          new php.BinaryOperatorImpl(new SimpleToken(TokenKind.PLUS, null)),
          new php.IntegerLiteralImpl(
              new StringToken(TokenKind.INTEGER, "1", null))));
    } else {
      arguments.add(end);
    }
    if(node.slicerElement != null) {
      if(node.slicerElement.node.isInline) {
        return _finalizeExpression(
            this._inlineExecutable(node.slicerElement, arguments, node.scope,
                thisValue: node.expression.accept<Object>(this)),
            node);
      }
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  node.expression.accept<Object>(this),
                  new php.NameImpl.build("slice")
                    ..element = node.slicerElement.resultName),
              arguments),
          node);
    } else {
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  node.expression.accept<Object>(this),
                  new php.NameImpl.build("slice")),
              arguments),
          node);
    }
  }

  @override
  php.SwitchCase visitSwitchCase(mammouth.SwitchCase node) {
    php.Block consequent = _compileBody(node.consequent, forceBlock: true);
    return new php.SwitchCaseImpl.build(
        node.test.accept<Object>(this), consequent.statements);
  }

  @override
  php.SwitchDefault visitSwitchDefault(mammouth.SwitchDefault node) {
    php.Block consequent = _compileBody(node.consequent, forceBlock: true);
    return new php.SwitchDefaultImpl.build(consequent.statements);
  }

  @override
  php.AstNode visitSwitchExpression(mammouth.SwitchExpression node) {
    php.Expression discriminant = node.discriminant.accept<Object>(this);
    List<php.SwitchCase> cases = node.cases
        .map((mammouth.SwitchCase switchCase) {
      return switchCase.accept<Object>(this);
    })
        .whereType<php.SwitchCase>()
        .toList();
    php.SwitchDefault defaultCase;
    if(node.defaultCase != null) {
      defaultCase = node.defaultCase.accept<Object>(this);
    }
    php.Statement statement =
    new php.SwitchStatementImpl.build(discriminant, cases, defaultCase);
    if(node.asStatement) {
      return statement;
    }
    // if it's not a statement
    List<php.Variable> variables = node.usedElements
        .where((mammouth.Element element) {
      return element is mammouth.VariableElement;
    })
        .whereType<mammouth.VariableElement>()
        .map((mammouth.VariableElement element) {
      return new php.VariableImpl.build(element.name);
    })
        .toList();
    php.ClosureExpression function = new php.ClosureExpressionImpl.build(
        [], new php.BlockImpl.build([statement]));
    if(variables.isNotEmpty) {
      function.body.statements
          .insert(0, new php.GlobalStatementImpl.build(variables));
    }
    function.enableAutoReturn((php.Expression expression) {
      return new php.ReturnStatementImpl.build(expression);
    });
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("call_user_func"), [function]);
  }

  @override
  php.StringLiteral visitStringLiteral(mammouth.StringLiteral node) {
    return _finalizeExpression(new php.StringLiteralImpl(node.token), node);
  }

  @override
  php.ThrowStatement visitThrowStatement(mammouth.ThrowStatement node) {
    return new php.ThrowStatementImpl.build(
        node.expression.accept<Object>(this));
  }

  @override
  php.Expression visitToExpression(mammouth.ToExpression node) {
    if(node.converter != null) {
      if(node.converter.node.isInline) {
        return _finalizeExpression(
            this._inlineExecutable(node.converter, [], node.scope,
                thisValue: node.argument.accept<Object>(this)),
            node);
      }
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  node.argument.accept<Object>(this),
                  new php.NameImpl.build(null)
                    ..element = node.converter.resultName),
              []),
          node);
    }
    return _runtimeCallConverter(
        node.argument.accept<Object>(this), _typeToString(node.type));
  }

  @override
  php.AstNode visitTryExpression(mammouth.TryExpression node) {
    php.Statement tryStatement = _compileBody(
        node.tryStatement, forceBlock: true);
    php.Variable catchVariableName;
    php.Statement catchStatement;
    php.Statement finallyStatement;
    if(node.hasCatch) {
      // TODO: catch variable type
      catchVariableName =
          (node.catchVariable.accept<Object>(this) as php.Parameter).variable;
      catchStatement = _compileBody(node.catchStatement, forceBlock: true);
    } else {
      catchVariableName = new php.VariableImpl.build(null)
        ..element = new php.LateName("e");
      catchStatement = new php.BlockImpl.build([]);
    }
    if(node.hasFinally) {
      finallyStatement = _compileBody(node.finallyStatement, forceBlock: true);
    }
    php.Statement statement = new php.TryStatementImpl.build(
        tryStatement,
        null /*catchVariableType*/,
        catchVariableName,
        catchStatement,
        finallyStatement);
    if(node.asStatement) {
      return statement;
    }
    // if it's not a statement
    List<php.Variable> variables =
    node.usedElements.where((mammouth.Element element) {
      return element is mammouth.VariableElement;
    }).whereType<mammouth.VariableElement>()
        .map((mammouth.VariableElement element) {
      return new php.VariableImpl.build(element.name);
    }).toList();
    php.ClosureExpression function = new php.ClosureExpressionImpl.build(
        [], new php.BlockImpl.build([statement]));
    if(variables.isNotEmpty) {
      function.body.statements
          .insert(0, new php.GlobalStatementImpl.build(variables));
    }
    function.enableAutoReturn((php.Expression expression) {
      return new php.ReturnStatementImpl.build(expression);
    });
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("call_user_func"), [function]);
  }

  @override
  common.AstNode visitTypeArgumentList(mammouth.TypeArgumentList node) {
    // TODO:
    return null;
  }

  @override
  common.AstNode visitTypeName(mammouth.TypeName node) {
    return null;
  }

  @override
  php.Expression visitUnaryExpression(mammouth.UnaryExpression node) {
    if(node.operatorElement != null) {
      if(node.operatorElement.node.isInline) {
        return _finalizeExpression(
            this._inlineExecutable(node.operatorElement, [], node.scope,
                thisValue: node.argument.accept<Object>(this)),
            node);
      }
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  node.argument.accept<Object>(this),
                  new php.NameImpl.build(
                      "__mmt_operator_prefix_${this.namePicker
                          .operatorNames[node.operator.lexeme]}")),
              []),
          node);
    }
    return _finalizeExpression(_runtimeCallArguments(
        node.argument.accept<Object>(this), "prefix${node.operator.lexeme}",
        []), node);
  }

  @override
  php.UnaryOperator visitUnaryOperator(mammouth.UnaryOperator node) {
    return new php.UnaryOperatorImpl(node.token);
  }

  @override
  php.Expression visitUpdateExpression(mammouth.UpdateExpression node) {
    if(node.operatorElement != null) {
      if(node.operatorElement.node.isInline) {
        return _finalizeExpression(
            this._inlineExecutable(node.operatorElement, [], node.scope,
                thisValue: node.argument.accept<Object>(this)),
            node);
      }
      return _finalizeExpression(
          new php.FunctionCallExpressionImpl.build(
              new php.PropertyFetchImpl.build(
                  node.argument.accept<Object>(this),
                  new php.NameImpl.build(
                      "__mmt_operator_${node.isPrefix
                          ? "prefix"
                          : "postfix"}_${this.namePicker.operatorNames[node
                          .operator.lexeme]}")),
              []),
          node);
    }

    return _finalizeExpression(_runtimeCallArguments(
        node.argument.accept<Object>(this),
        "${node.isPrefix ? "prefix" : "postfix"}${node.operator.lexeme}", []),
        node);
  }

  @override
  php.UpdateOperator visitUpdateOperator(mammouth.UpdateOperator node) {
    return new php.UpdateOperatorImpl(node.token);
  }

  @override
  php.ExpressionStatement visitVariableDeclarationStatement(
      mammouth.VariableDeclarationStatement node) {
    if(node.isInitialized) {
      return new php.ExpressionStatementImpl.build(
          new php.AssignmentExpressionImpl(
              new php.VariableImpl.build(node.name.name),
              new php.AssignmentOperatorImpl(
                  new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
              node.initializer.accept<Object>(this)));
    }
    return null; // TODO: A statement that an identifier to scope
  }

// TODO: use USE if possible in some versions instad of global in call_user_func

  php.AstNode _inlineExecutable(mammouth.ExecutableElement executable,
      List<php.Expression> arguments, Scope scope,
      {php.AstNode thisValue = null}) {
    for(int i = 0; i < executable.parameters.length; i++) {
      if(!executable.parameters[i].isOptional || arguments.length - 1 >= i) {
        mammouth.ParameterElement parameter = executable.parameters[i];
        php.LateName paramElement = new php.LateName(parameter.name);
        php.Variable paramVar = new php.VariableImpl(null)
          ..element = paramElement;
        this.beforeStatements.last.add(new php.ExpressionStatementImpl.build(
            new php.AssignmentExpressionImpl(
                paramVar,
                new php.AssignmentOperatorImpl(
                    new SimpleToken(TokenKind.ASSIGN_EQUAL, null)),
                arguments.elementAt(i))));
        parameter.effectiveValue = paramVar;
      }
    }
    if(thisValue != null) {
      if(executable is mammouth.ExecutableClassMemberElement) {
        (executable.enclosingElement as mammouth.ClassElement)
            .thisElement
            .effectiveValue = thisValue;
      }
    }
    List<php.Statement> compiledBody = (_compileBody(
        executable.node.body, forceBlock: true) as php.Block).statements;
    if(compiledBody.last is php.ExpressionStatement) {
      this.beforeStatements.last.addAll(
          compiledBody.sublist(0, compiledBody.length - 1));
      return (compiledBody.last as php.ExpressionStatement).expression;
    } else {
      this.beforeStatements.last.addAll(compiledBody);
      return null;
    }
  }

  php.Expression _finalizeExpression(php.Expression result,
      mammouth.Expression source) {
    if(source.converterElement != null) {
      if(source.converterElement.node.isInline) {
        return this._inlineExecutable(source.converterElement, [], source.scope,
            thisValue: result);
      }
      return new php.FunctionCallExpressionImpl.build(
          new php.PropertyFetchImpl.build(
              result,
              new php.NameImpl.build(null)
                ..element = source.converterElement.resultName),
          []);
    }
    return result;
  }

  php.Statement _compileBody(mammouth.Statement body,
      {bool forceBlock: false}) {
    List<php.Statement> statements = new List<php.Statement>();
    this.beforeStatements.add(<php.Statement>[]);
    php.Statement resultStatement = body.accept<Object>(this);
    if(this.beforeStatements.isNotEmpty) {
      statements.addAll(this.beforeStatements.removeLast());
    }
    if(resultStatement != null) {
      if(resultStatement is php.Block) {
        statements.addAll(resultStatement.statements);
      } else {
        statements.add(resultStatement);
      }
    }
    if(!forceBlock && statements.length == 1) {
      return statements.first;
    }
    return new php.BlockImpl.build(statements);
  }

  php.Expression _runtimeCall(php.Expression object, String method,
      php.Expression arguments) {
    _requireRuntime = true;
    _session.package?.requireRuntime = true;
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("call_user_func_array"),
        [
          new php.StringLiteralImpl(
              new StringToken(null, '"mammouth_call_method"', null)),
          new php.FunctionCallExpressionImpl.build(
              new php.NameImpl.build("array_merge"), [
            _constructArray([
              object,
              new php.StringLiteralImpl(
                  new StringToken(null, '"$method"', null)),
            ]),
            arguments
          ])
        ]);
  }

  php.Expression _runtimeCallArguments(php.Expression object, String method,
      List<php.Expression> arguments) {
    _requireRuntime = true;
    _session.package?.requireRuntime = true;
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("mammouth_call_method"), [
      object,
      new php.StringLiteralImpl(
          new StringToken(null, '"$method"', null)),
    ].followedBy(arguments).toList());
  }

  php.Expression _constructArray([List<php.Expression> elements]) {
    if(_session.target.supportBracketArray) {
      return new php.ArrayLiteralImpl.build(elements);
    } else {
      return new php.FunctionCallExpressionImpl.build(
          new php.NameImpl.build("array"), elements ?? <php.Expression>[]);
    }
  }

  String _typeToString(mammouth.TypeAnnotation type, {bool forAs = false}) {
    if(type is mammouth.TypeName) {
      mammouth.Identifier identifier = type.name;
      if(identifier is mammouth.SimpleIdentifier) {
        if(identifier.name == "bool") {
          return "boolean";
        } else if(identifier.name == "int") {
          return "integer";
        } else if(identifier.name == "float") {
          return "double";
        } else if(identifier.name == "Array") {
          return "array";
        } else if(identifier.name == "String") {
          return "string";
        }
        if(forAs) {
          return "object";
        }
        return identifier.name;
      }
    }
    return "dynamic";
  }

  php.Expression _runtimeCallConverter(php.Expression object,
      String targetType) {
    _requireRuntime = true;
    _session.package?.requireRuntime = true;
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("mammouth_call_converter"), [
      object,
      new php.StringLiteralImpl(
          new StringToken(null, '"->"', null)),
      new php.StringLiteralImpl(
          new StringToken(null, '"$targetType"', null))
    ]);
  }

  php.Expression _runtimeCallGetter(php.Expression object, String getterName) {
    _requireRuntime = true;
    _session.package?.requireRuntime = true;
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("mammouth_call_getter"), [
      object,
      new php.StringLiteralImpl(
          new StringToken(null, '"$getterName"', null))
    ]);
  }

  php.Expression _runtimeCallSetter(php.Expression object, String setterName,
      php.Expression value) {
    _requireRuntime = true;
    _session.package?.requireRuntime = true;
    return new php.FunctionCallExpressionImpl.build(
        new php.NameImpl.build("mammouth_call_setter"), [
      object,
      new php.StringLiteralImpl(
          new StringToken(null, '"$setterName"', null)),
      value
    ]);
  }
}

class Dart2PHP {
  static php.AstNode convert(dynamic object) {
    if(object is Map) {
      List<php.Expression> arguments = <php.Expression>[];
      object.forEach((dynamic key, dynamic value) {
        arguments.add(new php.KeyValueImpl.build(
            Dart2PHP.convert(key), Dart2PHP.convert(value)));
      });
      return new php.FunctionCallExpressionImpl.build(
          new php.NameImpl.build("array"), arguments);
    } else if(object is List) {
      List<php.Expression> arguments = <php.Expression>[];
      object.forEach((dynamic value) {
        arguments.add(Dart2PHP.convert(value));
      });
      return new php.FunctionCallExpressionImpl.build(
          new php.NameImpl.build("array"), arguments);
    } else if(object is int) {
      return new php.IntegerLiteralImpl(
          new StringToken(null, object.toString(), null));
    } else if(object is String) {
      return new php.StringLiteralImpl(
          new StringToken(null, "\"${object}\"", null));
    } else if(object is php.AstNode) {
      return object;
    }
    return null;
  }
}
