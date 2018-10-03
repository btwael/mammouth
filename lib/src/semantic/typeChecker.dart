library mammouth.semantic.typeChecker;

import "package:path/path.dart" as p;

import "package:mammouth/src/basic/option.dart" show Option;
import "package:mammouth/src/basic/source.dart";
import "package:mammouth/src/basic/session.dart";
import "package:mammouth/src/diagnostic/diagnosticEngine.dart";
import "package:mammouth/src/language/common/ast/visibility.dart";
import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/mammouth/ast/visitor.dart" as mammouth;
import "package:mammouth/src/language/mammouth/ast/ast.dart" as mammouth;
import "package:mammouth/src/language/mammouth/element/element.dart";
import "package:mammouth/src/language/mammouth/element/implementation.dart";
import "package:mammouth/src/language/mammouth/type/type.dart";
import "package:mammouth/src/language/mammouth/type/implementation.dart";
import "package:mammouth/src/semantic/scope.dart";
import "package:mammouth/src/semantic/elementBuilder.dart";
import "package:mammouth/src/semantic/parentResolver.dart";
import "package:mammouth/src/semantic/typeSystem.dart";
import "package:mammouth/src/syntactic/lexer.dart";
import "package:mammouth/src/syntactic/parser.dart";

//*-- TypeChecker
/**
 * Traverses the AST, resolves and type-checks names and types.
 */
class TypeChecker extends mammouth.Visitor<MammouthType> {
  List<Scope> scopeStack = [];

  TypeProvider typeProvider;
  TypeSystem typeSystem;

  DiagnosticEngine _diagnosticEngine;

  Source _source;

  Session _session;

  TypeChecker(this._source, this._session, this._diagnosticEngine,
      {Scope parentScope = null}) {
    if(parentScope == null) {
      parentScope = new TypeProvider();
    }
    this.scopeStack.add(this.typeProvider = parentScope);
    this.typeSystem = new StrongTypeSystem(this.typeProvider);
  }

  void setSource(Source source) {
    this._source = source;
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
  MammouthType visitDocument(common.Document node) {
    node.entries.forEach((common.DocumentEntry entry) {
      entry.accept<MammouthType>(this);
    });
    return null;
  }

  @override
  MammouthType visitInlineEntry(common.InlineEntry node) {
    return null;
  }

  @override
  MammouthType visitArgumentList(mammouth.ArgumentList node) {
    node.arguments.forEach((mammouth.Expression expression) {
      expression.accept<MammouthType>(this);
    });
    return null;
  }

  @override
  MammouthType visitArrayLiteral(mammouth.ArrayLiteral node) {
    node.scope = this.scopeStack.last;
    node.elements.forEach((mammouth.Expression element) {
      element.accept(this);
    });
    ClassElement element = this.scopeStack.last.lookup("Array");
    return element.instantiate(
        node.typeArguments?.arguments?.map((mammouth.TypeAnnotation type) =>
            type.accept(this))?.toList() ?? [], this,
        this.typeProvider.dynamicType);
  }

  @override
  MammouthType visitAsExpression(mammouth.AsExpression node) {
    node.scope = this.scopeStack.last;
    node.argument.accept(this);
    node.type.accept(this);
    return node.type.accept(this);
  }

  @override
  MammouthType visitAssignmentExpression(mammouth.AssignmentExpression node) {
    node.scope = this.scopeStack.last;
    mammouth.Expression left = node.left;
    mammouth.Expression right = node.right;
    // TODO: Update type after assignment for dynamic type declaraed var
    if(left is mammouth.SimpleIdentifier &&
        this.scopeStack.last.lookup(left.name) == null) {
      this.scopeStack.last.define(new VariableElementImpl(left.name)
        ..type = this.typeProvider.dynamicType);
    }
    MammouthType leftType = left.accept<MammouthType>(this),
        rightType = right.accept<MammouthType>(this);
    node.usedElements.addAll(left.usedElements);
    node.usedElements.addAll(right.usedElements);
    if(rightType is InterfaceType) {
      Option<ConverterElement> converterResult =
      rightType.getConverterTo(leftType);
      if(converterResult.isSome) {
        right.converterElement = converterResult.some;
      }
    }
    if(left is mammouth.ElementReferenceExpression) {
      Element method = left.referredElement;
      if(method is MethodElement &&
          method.parameters.length == 1 &&
          rightType.isAssignableTo(method.parameters.first.type)) {
        node.setterElement = method;
        return leftType;
      } else {
        return this.typeProvider.dynamicType;
      }
    }
    if(node.operator.lexeme == "=") {
      if(rightType.isAssignableTo(leftType)) {
        return leftType;
      } else {
        // TODO: report error
        throw "invalid assignment";
      }
    } else {
      Option<OperatorElement> result = this.typeSystem.operateBinary(
          node.operator.lexeme.replaceAll("=", ""), leftType, rightType);
      if(result.isSome) {
        if(result.some == null) {
          return this.typeProvider.dynamicType;
        } else {
          return result.some.returnType;
        }
      } else {
        // TODO: report error
        throw "invalid assignment operation";
      }
    }
  }

  @override
  MammouthType visitAssignmentOperator(mammouth.AssignmentOperator node) {
    return null;
  }

  @override
  MammouthType visitAtExpression(mammouth.AtExpression node) {
    node.scope = this.scopeStack.last;
    Element thisElement = this.scopeStack.last.lookup("this");
    if(thisElement != null && thisElement is VariableElement) {
      InterfaceType targetType = thisElement.type;
      List<ClassMemberElement> members = targetType.lookup(node.property.name);
      node.candidateElements = members;
      if(members.length > 0) {
        if(members.length == 1) {
          ClassMemberElement member = members.first;
          if(member.visibility != Visibility.DEFAULT &&
              member.visibility != Visibility.PUBLIC) {
            if(this.scopeStack.last.thisType != targetType) {
              // TODO: report error
              throw "Cannot access non public property";
            }
          }
          node.referredElement = member;
          if(member is MethodElement) {
            return member.type;
          } else if(member is FieldElement) {
            return member.type;
          } else {
            // TODO: unreachable
          }
        }
      } else {
        // TODO: report error
        throw "undefined property";
      }
    } else {
      // TODO: report error
      throw "this outside of class!";
    }
  }

  @override
  MammouthType visitBlock(mammouth.Block node, {bool scope = true}) {
    if(scope) this.pushScope();
    MammouthType lastType;
    node.statements.forEach((mammouth.Statement statement) {
      lastType = statement.accept<MammouthType>(this);
      node.usedElements.addAll(statement.usedElements);
    });
    if(scope) this.popScope();
    return lastType;
  }

  @override
  MammouthType visitBinaryExpression(mammouth.BinaryExpression node) {
    node.scope = this.scopeStack.last;
    MammouthType leftType = node.left.accept<MammouthType>(this),
        rightType = node.right.accept<MammouthType>(this);
    node.usedElements.addAll(node.left.usedElements);
    node.usedElements.addAll(node.right.usedElements);
    Option<OperatorElement> result = this
        .typeSystem
        .operateBinary(node.operator.lexeme, leftType, rightType);
    if(result.isSome) {
      if(result.some == null) {
        return this.typeProvider.dynamicType;
      } else {
        node.operatorElement = result.some;
        return result.some.returnType;
      }
    } else {
      // TODO: report error
      throw "invalid operation";
    }
  }

  @override
  MammouthType visitBinaryOperator(mammouth.BinaryOperator node) {
    return null;
  }

  @override
  MammouthType visitBooleanLiteral(mammouth.BooleanLiteral node) {
    node.scope = this.scopeStack.last;
    TypeDefiningElement element = this.scopeStack.last.lookup("bool");
    return element.type;
  }

  @override
  MammouthType visitBreakStatement(mammouth.BreakStatement node) {
    // TODO: check if this is inside a loop
    return null;
  }

  @override
  MammouthType visitClassExpression(mammouth.ClassExpression node,
      {InterfaceType type}) {
    node.scope = this.scopeStack.last;
    this.scopeStack.last.define(node.element);

    this.pushScope();
    if(node.typeParameters != null) {
      node.typeParameters.accept(this);
    }
    List<ClassMemberElement> memberElements = <ClassMemberElement>[];
    node.members.forEach((mammouth.ClassMember member) {
      if(member is mammouth.FieldDeclaration) {
        if(member.isTyped) {
          member.element.type = member.type.accept<MammouthType>(this);
        } else {
          member.element.type = typeProvider.dynamicType;
        }
      } else if(member is mammouth.MethodDeclaration) {
        if(member.hasParameters) {
          member.parameters.parameters
              .forEach((mammouth.Parameter parameter) {
            if(parameter.isTyped) {
              if(parameter is mammouth.SimpleParameter) {
                parameter.element.type = parameter.type.accept(this);
              } else if(parameter is mammouth.ClosureParameter) {
                parameter.element.type = new FunctionTypeImpl(
                    parameter.returnType.accept(this),
                    parameter.parameterTypes.map((
                        mammouth.TypeAnnotation type) {
                      return type.accept<MammouthType>(this);
                    }).whereType<MammouthType>().toList());
              }
            } else {
              parameter.element.type = this.typeProvider.dynamicType;
            }
            parameter.name.referredElement = parameter.element;
          });
        }
        if(!member.hasReturnType) {
          member.element.returnType = this.typeProvider.dynamicType;
        } else {
          member.element.returnType =
              member.returnType.accept<MammouthType>(this);
        }
      } else if(member is mammouth.OperatorDeclaration) {
        if(member.hasParameters) {
          member.parameters.parameters
              .forEach((mammouth.Parameter parameter) {
            if(parameter.isTyped) {
              if(parameter is mammouth.SimpleParameter) {
                parameter.element.type = parameter.type.accept(this);
              } else if(parameter is mammouth.ClosureParameter) {
                parameter.element.type = new FunctionTypeImpl(
                    parameter.returnType.accept(this),
                    parameter.parameterTypes.map((
                        mammouth.TypeAnnotation type) {
                      return type.accept<MammouthType>(this);
                    }));
              }
            } else {
              parameter.element.type = this.typeProvider.dynamicType;
            }
            parameter.name.referredElement = parameter.element;
          });
        }
        if(!member.hasReturnType) {
          member.element.returnType = this.typeProvider.dynamicType;
        } else {
          member.element.returnType =
              member.returnType.accept<MammouthType>(this);
        }
      } else if(member is mammouth.ConverterDeclaration) {
        member.element.returnType =
            member.returnType.accept<MammouthType>(this);
      }
      if(!(member is mammouth.ConstructorDeclaration)) {
        this.scopeStack.last.define(node.element);
      }
      memberElements.add(member.element);
    });
    if(type == null) {
      // TODO: all other native type
      if(node.name.name == "String") {
        node.element.type = typeProvider.stringType;
        node.element.type.members.addAll(memberElements);
      } else if(node.name.name == "float") {
        node.element.type = typeProvider.floatType;
        node.element.type.members.addAll(memberElements);
      } else if(node.name.name == "int") {
        node.element.type = typeProvider.intType;
        node.element.type.members.addAll(memberElements);
      } else {
        node.element.type = new InterfaceTypeImpl(memberElements);
      }
    } else {
      node.element.type = type;
      type.addMember(memberElements);
    }
    if(node.extendsClause != null) {
      InterfaceType type = node.element.type as InterfaceType;
      type.superclass =
          node.extendsClause.superclass.accept<MammouthType>(this);
      memberElements.forEach((ClassMemberElement element) {
        if(element is ExecutableClassMemberElement) {
          element.overrided = type.superclass
              .getMethodFor(
              element.name,
              element.parameters.map((ParameterElement parameter) {
                return parameter.type;
              }).toList())
              .some;
          element.overrided?.isOverrided = true;
        } else if(element is FieldElement) {
          element.overrided = type.superclass
              .getField(element.name)
              .some;
          element.overrided?.isOverrided = true;
        }
      });

    }
    if(node.implementsClause != null) {
      node.implementsClause.interfaces.forEach((
          mammouth.TypeAnnotation interface) {
        InterfaceType type = node.element.type as InterfaceType;
        type.interfaces.add(interface.accept<MammouthType>(this));
      });
    }
    // TODO: check if all defined interface method are implemented

    node.element.thisElement = new VariableElementImpl("this")
      ..type = node.element.type;
    this.scopeStack.last.define(node.element.thisElement);
    this.scopeStack.last.localThisType = node.element.type;
    node.members.forEach((mammouth.ClassMember member) {
      member.accept<MammouthType>(this);
    });
    this.popScope();
    return null;
  }

  @override
  MammouthType visitClosureParameter(mammouth.ClosureParameter node) {
    this.scopeStack.last.define(node.element);
    node.element.type = new FunctionTypeImpl(node.returnType.accept(this),
        node.parameterTypes.map((mammouth.TypeAnnotation type) {
          return type.accept<MammouthType>(this);
        }).whereType<MammouthType>().toList());
    return node.element.type;
  }

  @override
  MammouthType visitConstructorDeclaration(
      mammouth.ConstructorDeclaration node) {
    this.pushScope();
    if(node.hasParameters) {
      node.parameters.accept<MammouthType>(this);
    }
    node.body.accept<MammouthType>(this, scope: false);
    this.popScope();
    node.usedElements.addAll(node.body.usedElements);
    // TODO: return void type
    return null;
  }

  @override
  MammouthType visitContinueStatement(mammouth.ContinueStatement node) {
    // TODO: check if this is inside a loop
    return null;
  }

  @override
  MammouthType visitConverterDeclaration(mammouth.ConverterDeclaration node) {
    // TODO: some code as visitOperatorDeclaration
    this.pushScope();
    MammouthType bodyType = node.body.accept<MammouthType>(this, scope: false);
    this.popScope();
    node.usedElements.addAll(node.body.usedElements);
    node.element.returnType = node.returnType.accept<MammouthType>(this);
    if(!bodyType.isAssignableTo(node.element.returnType)) {
      // TODO: report error
      throw "converter return type different from declaration";
    }
    return node.element.type;
  }

  @override
  MammouthType visitEchoExpression(mammouth.EchoExpression node) {
    node.scope = this.scopeStack.last;
    return node.argument.accept<MammouthType>(this);
  }

  @override
  MammouthType visitExistenceExpression(mammouth.ExistenceExpression node) {
    node.scope = this.scopeStack.last;
    node.argument.accept<MammouthType>(this);
    node.usedElements.addAll(node.argument.usedElements);
    // TODO: check is argument can be checked
    // TODO: allow undefined argument if argument is a variable
    return this._boolType;
  }

  @override
  MammouthType visitExpressionStatement(mammouth.ExpressionStatement node) {
    MammouthType type = node.expression.accept<MammouthType>(this);
    node.usedElements.addAll(node.expression.usedElements);
    return type;
  }

  @override
  MammouthType visitExtendsClause(mammouth.ExtendsClause node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  MammouthType visitFieldDeclaration(mammouth.FieldDeclaration node) {
    if(node.isInitialized) {
      MammouthType initializerType =
      node.initializer.accept<MammouthType>(this);
      node.usedElements.addAll(node.initializer.usedElements);
      if(!initializerType.isAssignableTo(node.element.type)) {
        // TODO: report error
        throw "invalid assignment";
      }
    }
    node.usedElements.add(node.element);
    return node.element.type;
  }

  @override
  MammouthType visitFloatLiteral(mammouth.FloatLiteral node) {
    node.scope = this.scopeStack.last;
    TypeDefiningElement element = this.scopeStack.last.lookup("float");
    return element.type;
  }

  @override
  MammouthType visitFunctionExpression(mammouth.FunctionExpression node) {
    node.scope = this.scopeStack.last;
    if(node.asStatement) {
      this.scopeStack.last.define(node.element);
    }
    this.pushScope();
    // TODO: if has parameters
    node.parameters.accept<MammouthType>(this);
    MammouthType bodyType = node.body.accept<MammouthType>(this, scope: false);
    this.popScope();
    node.usedElements.addAll(node.body.usedElements);
    node.element.returnType = node.returnType.accept<MammouthType>(this);
    if(!bodyType.isAssignableTo(node.element.returnType)) {
      // TODO: report error
      throw "function return type different from declaration";
    }
    node.element.node = node;
    return node.element.type;
  }

  @override
  MammouthType visitForExpression(mammouth.ForExpression node) {
    node.scope = this.scopeStack.last;
    this.pushScope();
    node.source.accept(this);
    node.usedElements.addAll(node.source.usedElements);
    if(node.source.hasGuard) {
      MammouthType guardType = node.source.guard.condition.accept<MammouthType>(
          this);
      node.usedElements.addAll(node.source.guard.usedElements);
      if(!guardType.isAssignableTo(this._boolType)) {
        // get the overrided bool type
        // TODO: report error
        throw "test must be bool";
      }
    }
    node.body.accept(this);
    this.popScope();
    if(node.source.hasGuard) {
      node.usedElements.addAll(node.source.guard.condition.usedElements);
    }
    node.usedElements.addAll(node.body.usedElements);
    // TODO: improve with parametrized types
    return typeProvider.arrayType;
  }

  @override
  MammouthType visitForRangeSource(mammouth.ForRangeSource node) {
    if(node.hasName) {
      node.name.accept(this);
      node.usedElements.addAll(node.name.usedElements);
    }
    node.source.accept(this);
    node.usedElements.addAll(node.source.usedElements);
    return null;
  }

  @override
  MammouthType visitForVariable(mammouth.ForVariable node) {
    this.scopeStack.last.define(node.element);
    if(node.isTyped) {
      node.element.type = node.type.accept<MammouthType>(this);
    } else {
      node.element.type = this.typeProvider.dynamicType;
    }
    node.usedElements.add(node.element);
    return node.element.type;
  }

  @override
  MammouthType visitForVariableSource(mammouth.ForVariableSource node) {
    node.firstVariable.accept(this);
    node.usedElements.addAll(node.firstVariable.usedElements);
    if(node.hasSecondVariable) {
      node.secondVariable.accept(this);
      node.usedElements.addAll(node.firstVariable.usedElements);
    }
    node.source.accept(this);
    node.usedElements.addAll(node.source.usedElements);
    // TODO: check if iterable
    // TODO: if "in" check if source has .length and []
    return null;
  }

  @override
  MammouthType visitGuardSource(mammouth.GuardSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  MammouthType visitIfExpression(mammouth.IfExpression node) {
    node.scope = this.scopeStack.last;
    // TODO: if condition must be a boolean
    mammouth.Expression condition = node.condition;
    mammouth.Statement consequent = node.consequent,
        alternate = node.alternate;
    MammouthType conditionType = condition.accept<MammouthType>(this);
    if(!conditionType.isAssignableTo(_boolType)) {
      // TODO: report error
      throw "condition must be bool";
    }
    if(consequent is mammouth.Block) {
      consequent.accept<MammouthType>(this, scope: false);
    } else {
      consequent.accept<MammouthType>(this);
    }
    node.usedElements.addAll(condition.usedElements);
    node.usedElements.addAll(consequent.usedElements);
    if(node.hasAlternate) {
      // TODO: retrieve names added in consequent if a name is being
      // TODO: re-declared in alternate with different type, declare it as dynamic
      if(alternate is mammouth.Block) {
        alternate.accept<MammouthType>(this, scope: false);
      } else {
        alternate.accept(this);
      }
      node.usedElements.addAll(alternate.usedElements);
    }
    // TODO: if consequent and alternate have the some type return that type
    // TODO: else return dynamic
    return this.typeProvider.dynamicType;
  }

  @override
  MammouthType visitIfSource(mammouth.IfSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
  }

  @override
  MammouthType visitImplementsClause(mammouth.ImplementsClause node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
    // MARK(STOP PROCESSING)
  }

  @override
  MammouthType visitImportDirective(mammouth.ImportDirective node) {
    _importURI(node.uri.value);
    return null;
  }

  @override
  MammouthType visitIndexExpression(mammouth.IndexExpression node) {
    node.scope = this.scopeStack.last;
    MammouthType targetType = node.target.accept<MammouthType>(this);
    MammouthType indexType = node.index.accept<MammouthType>(this);
    Option<OperatorElement> result =
    this.typeSystem.operateIndex(targetType, indexType);
    if(result.isSome) {
      if(result.some == null) {
        return this.typeProvider.dynamicType;
      } else {
        node.operatorElement = result.some;
        return result.some.returnType;
      }
    } else {
      // TODO: report error
      throw "invalid index operation";
    }
  }

  @override
  MammouthType visitInExpression(mammouth.InExpression node) {
    node.scope = this.scopeStack.last;
    MammouthType elementType = node.element.accept(this);
    InterfaceType containerType = node.container.accept(this) as InterfaceType;
    // TODO: check that containerType implements Contains
    Option<MethodElement> methodResult = containerType.getMethodFor(
        "contains", [elementType]);
    if(methodResult.isSome) {
      node.methodElement = methodResult.some;
    }
    return _boolType;
  }

  @override
  MammouthType visitInvocationExpression(mammouth.InvocationExpression node) {
    node.scope = this.scopeStack.last;
    MammouthType calleeType = node.callee.accept<MammouthType>(this);
    node.arguments.accept<MammouthType>(this);
    if(node.callee.referredElement == null) {
      if(node.callee.candidateElements.isNotEmpty) {
        List executableCandidates =
        node.callee.candidateElements.where((Element element) {
          if(element is ExecutableElement) {
            bool isOk = true;
            for(int i = 0; i < node.arguments.arguments.length; i++) {
              if(!node.arguments.arguments
                  .elementAt(i)
                  .accept<MammouthType>(this)
                  .isAssignableTo(element.parameters[i].type)) {
                isOk = false;
                break;
              }
            }
            return isOk;
          }
          return false;
        }).toList();
        if(executableCandidates.isNotEmpty) {
          int index = 0;
          if(executableCandidates.length > 1) {
            int besti;
            int bestScore;
            for(int i = 0; i < executableCandidates.length; i++) {
              int score = 0;
              for(int j = 0; j < executableCandidates[i].parameters.length;
              j++) {
                score +=
                    node.arguments.arguments[j].accept(this).assignabilityTo(
                        executableCandidates[i].parameters[j].type);
              }
              if(besti == null || score < bestScore) {
                besti = i;
                bestScore = score;
              }
            }
            index = besti;
          }
          ExecutableElement executableElement = executableCandidates[index];
          calleeType = executableElement.type;
          node.callee.referredElement = executableElement;
          for(int i = 0; i < executableElement.parameters.length; i++) {
            InterfaceType argType = node.arguments.arguments
                .elementAt(i)
                .accept<MammouthType>(this);
            Option<ConverterElement> converterResult =
            argType.getConverterTo(executableElement.parameters[i].type);
            if(converterResult.isSome) {
              node.arguments.arguments
                  .elementAt(i)
                  .converterElement =
                  converterResult.some;
            }
          }
        } else {
          // TODO: report error
          throw "no function found to call, or found property or field instead of func";
        }
      } else {
        // TODO: report error
        return typeProvider.dynamicType;
      }
    } else if(node.callee.referredElement is MethodElement) {
      calleeType = (node.callee.referredElement as MethodElement).type;
    }

    if(calleeType is FunctionType) {
      // TODO: check if function accepts given arguments
      for(int i = 0; i < node.arguments.arguments.length; i++) {
        ExecutableElement executableElement = node.callee
            .referredElement as ExecutableElement;
        MammouthType argType = node.arguments.arguments.elementAt(i).accept<
            MammouthType>(this);
        if(!argType.isAssignableTo(calleeType.parametersType[i])) {
          // TODO: report error
          throw "invalid argument type";
        }
        if(!executableElement.parameters[i].isOptional) {
          if(argType is InterfaceType) {
            Option<ConverterElement> converterResult = argType.getConverterTo(
                executableElement.parameters[i].type);
            if(converterResult.isSome) {
              node.arguments.arguments
                  .elementAt(i)
                  .converterElement =
                  converterResult.some;
            }
          }
        }
      }
      return calleeType.returnType;
    } else if(calleeType is DynamicType) {
      return this.typeProvider.dynamicType;
    } else {
      // TODO: report error
      throw "calling non function";
    }
  }

  @override
  MammouthType visitIntegerLiteral(mammouth.IntegerLiteral node) {
    node.scope = this.scopeStack.last;
    return _intType;
  }

  @override
  MammouthType visitInterfaceDeclaration(mammouth.InterfaceDeclaration node) {
    this.scopeStack.last.define(node.element);
    List<ClassMemberElement> memberElements = <ClassMemberElement>[];
    node.members.forEach((mammouth.ClassMember member) {
      if(member is mammouth.MethodDeclaration) {
        if(member.hasParameters) {
          member.parameters.parameters
              .forEach((mammouth.Parameter parameter) {
            if(parameter.isTyped) {
              if(parameter is mammouth.SimpleParameter) {
                parameter.element.type = parameter.type.accept(this);
              } else if(parameter is mammouth.ClosureParameter) {
                parameter.element.type = new FunctionTypeImpl(
                    parameter.returnType.accept(this),
                    parameter.parameterTypes.map((
                        mammouth.TypeAnnotation type) {
                      return type.accept<MammouthType>(this);
                    }));
              }
            } else {
              parameter.element.type = this.typeProvider.dynamicType;
            }
            parameter.name.referredElement = parameter.element;
          });
        }
        if(!member.hasReturnType) {
          member.element.returnType = this.typeProvider.dynamicType;
        } else {
          member.element.returnType =
              member.returnType.accept<MammouthType>(this);
        }
      } else if(member is mammouth.OperatorDeclaration) {
        if(member.hasParameters) {
          member.parameters.parameters
              .forEach((mammouth.Parameter parameter) {
            if(parameter.isTyped) {
              if(parameter is mammouth.SimpleParameter) {
                parameter.element.type = parameter.type.accept(this);
              } else if(parameter is mammouth.ClosureParameter) {
                parameter.element.type = new FunctionTypeImpl(
                    parameter.returnType.accept(this),
                    parameter.parameterTypes.map((
                        mammouth.TypeAnnotation type) {
                      return type.accept<MammouthType>(this);
                    }));
              }
            } else {
              parameter.element.type = this.typeProvider.dynamicType;
            }
            parameter.name.referredElement = parameter.element;
          });
        }
        if(!member.hasReturnType) {
          member.element.returnType = this.typeProvider.dynamicType;
        } else {
          member.element.returnType =
              member.returnType.accept<MammouthType>(this);
        }
      } else if(member is mammouth.ConverterDeclaration) {
        member.element.returnType =
            member.returnType.accept<MammouthType>(this);
      }
      memberElements.add(member.element);
    });
    node.element.type = new InterfaceTypeImpl(memberElements);
    if(node.implementsClause != null) {
      node.implementsClause.interfaces.forEach((
          mammouth.TypeAnnotation interface) {
        InterfaceType type = node.element.type as InterfaceType;
        type.interfaces.add(interface.accept<MammouthType>(this));
      });
    }
    // TODO: check parameter for declared members.
    return null;
  }

  @override
  MammouthType visitMMapEntry(mammouth.MMapEntry node) {
    // TODO: check that type of key and value is assignable to generic type
    node.key.accept(this);
    node.value.accept(this);
    return null;
  }

  @override
  MammouthType visitMapLiteral(mammouth.MapLiteral node) {
    node.scope = this.scopeStack.last;
    node.entries.forEach((mammouth.MMapEntry entry) {
      entry.accept(this);
    });
    // TODO: generic
    return this.typeProvider.mapType;
  }

  @override
  MammouthType visitMemberExpression(mammouth.MemberExpression node) {
    node.scope = this.scopeStack.last;
    mammouth.Expression target = node.target;
    MammouthType targetType = target.accept<MammouthType>(this);
    if(targetType is InterfaceType) {
      if(target is mammouth.ElementReferenceExpression &&
          target.referredElement is ClassElement) {
        ClassElement classElement = target.referredElement;
        List<ClassMemberElement> statics = classElement
            .getElementsOf(node.property.name)
            .where((ClassMemberElement element) {
          if(element is MethodElement && element.node.isStatic) return true;
          if(element is FieldElement && element.node.isStatic) return true;
          return false;
        });
        // TODO: asset statics.length == 1
        node.referredElement = statics.first;
        if(statics.first is MethodElement) {
          return (statics.first as MethodElement).type;
        } else if(statics.first is FieldElement) {
          return (statics.first as FieldElement).type;
        }
      }
      List<ClassMemberElement> members = targetType.lookup(node.property.name);
      node.candidateElements = members;
      if(members.length > 0) {
        if(members.length == 1) {
          ClassMemberElement member = members.first;
          if(member.visibility != Visibility.DEFAULT &&
              member.visibility != Visibility.PUBLIC) {
            if(this.scopeStack.last.thisType != targetType) {
              // TODO: report error
              throw "Cannot access non public property";
            }
          }
          node.referredElement = member;
          if(member is MethodElement) {
            if(member.node.isGetter) {
              return member.returnType;
            }
            return member.type;
          } else if(member is FieldElement) {
            return member.type;
          } else {
            // TODO: unreachable
          }
        }
      } else {
        // TODO: report error
        throw "undefined property";
      }
    } else {

    }
  }

  @override
  MammouthType visitMethodDeclaration(mammouth.MethodDeclaration node) {
    // TODO: some code as visitOperatorDeclaration
    this.pushScope();
    if(node.hasParameters) {
      node.parameters.accept<MammouthType>(this);
    }
    if(!node.isSignature) {
      MammouthType bodyType =
      node.body.accept<MammouthType>(this, scope: false);
      this.popScope();
      node.usedElements.addAll(node.body.usedElements);
      if(!node.hasReturnType) {
        node.element.returnType = typeProvider.dynamicType;
      } else {
        node.element.returnType = node.returnType.accept<MammouthType>(this);
        if(!bodyType.isAssignableTo(node.element.returnType)) {
          // TODO: report error
          throw "function return type different from declaration";
        }
      }
    }
    return node.element.type;
  }

  @override
  MammouthType visitNativeExpression(mammouth.NativeExpression node) {
    node.scope = this.scopeStack.last;
    if(node.arguments.arguments.isNotEmpty) {
      node.arguments.accept(this);
      // TODO: check it's a static string
      if(!(node.arguments.arguments.elementAt(0) is mammouth.StringLiteral)) {
        // TODO: report error
        throw "native first arg must be static string";
      }
    } else {
      // TODO: report error
      throw "native need at least one argument";
    }
    return this.typeProvider.dynamicType;
  }

  @override
  MammouthType visitNewExpression(mammouth.NewExpression node) {
    node.scope = this.scopeStack.last;
    InterfaceType type = node.callee.accept<MammouthType>(this);
    List<MammouthType> argTypes =
    node.arguments.arguments.map((mammouth.Expression argument) {
      return argument.accept<MammouthType>(this);
    }).toList();
    if(node.arguments.arguments.isEmpty) {
      Option<ConstructorElement> constructorResult = type
          .hasDefaultConstructor();
      if(constructorResult.isSome) {
        node.constructorElement = constructorResult.some;
      }
    } else {
      Option<ConstructorElement> constructorResult = type.getConstructorFor(
          argTypes);
      if(constructorResult.isSome) {
        node.constructorElement = constructorResult.some;
      } else {
        // TODO: report error
        throw "arguments error with constructor";
      }
    }
    return type;
  }

  @override
  MammouthType visitNullLiteral(mammouth.NullLiteral node) {
    return typeProvider.dynamicType;
  }

  @override
  MammouthType visitOperatorDeclaration(mammouth.OperatorDeclaration node) {
    // TODO: some code as visitMethodDeclaration
    this.pushScope();
    if(node.hasParameters) {
      node.parameters.accept<MammouthType>(this);
    }
    MammouthType bodyType = node.body.accept<MammouthType>(this, scope: false);
    this.popScope();
    node.usedElements.addAll(node.body.usedElements);
    if(!node.hasReturnType) {
      node.element.returnType = typeProvider.dynamicType;
    } else {
      node.element.returnType = node.returnType.accept<MammouthType>(this);
      if(!bodyType.isAssignableTo(node.element.returnType)) {
        // TODO: report error
        throw "function return type different from declaration";
      }
    }
    return node.element.type;
  }

  @override
  MammouthType visitParameterList(mammouth.ParameterList node) {
    node.parameters.forEach((mammouth.Parameter parameter) {
      parameter.accept<MammouthType>(this);
    });
    return null;
  }

  @override
  MammouthType visitParenthesisExpression(mammouth.ParenthesisExpression node) {
    return node.expression.accept<MammouthType>(this);
  }

  @override
  MammouthType visitRangeLiteral(mammouth.RangeLiteral node) {
    node.scope = this.scopeStack.last;
    // TODO: return with generic
    if(node.start != null) {
      node.start.accept(this); // TODO: assignable to num/int
    }
    if(node.end != null) {
      node.end.accept(this); // TODO: assignable to num/int
    }
    TypeDefiningElement element = this.scopeStack.last.lookup("Array");
    return element.type;
  }

  @override
  MammouthType visitRepetitionExpression(mammouth.RepetitionExpression node) {
    node.scope = this.scopeStack.last;
    mammouth.Expression test = node.test;
    mammouth.Statement body = node.body;
    if(!node.isLoop) {
      MammouthType testType = test.accept<MammouthType>(this);
      if(!testType.isAssignableTo(this._boolType)) {
        // get the overrided bool type
        // TODO: report error
        throw "test must be bool";
      }
    }
    if(node.hasGuard) {
      MammouthType guardType = node.guardCondition.accept<MammouthType>(this);
      if(!guardType.isAssignableTo(this._boolType)) {
        // get the overrided bool type
        // TODO: report error
        throw "test must be bool";
      }
    }
    body.accept<MammouthType>(this);
    if(!node.isLoop) {
      node.usedElements.addAll(test.usedElements);
    }
    if(node.hasGuard) {
      node.usedElements.addAll(node.guardCondition.usedElements);
    }
    node.usedElements.addAll(body.usedElements);
    // TODO: improve with parametrized types
    return typeProvider.arrayType;
  }

  @override
  MammouthType visitRepetitionSource(mammouth.RepetitionSource node) {
    // MARK(UNREACHABLE ZONE)
    throw "Unreachable zone!";
  }

  @override
  MammouthType visitReturnStatement(mammouth.ReturnStatement node) {
    // TODO: Check that the returned value has the some type as the function
    if(node.expression != null) {
      return node.expression.accept(this);
    } else {
      return this.typeProvider.dynamicType; // TODO: return void type
    }
  }

  @override
  MammouthType visitScript(mammouth.Script node) {
    node.body.accept<MammouthType>(this, scope: false);
    return null;
  }

  @override
  MammouthType visitSimpleParameter(mammouth.SimpleParameter node) {
    this.scopeStack.last.define(node.element);
    if(node.isTyped) {
      node.element.type = node.type.accept<MammouthType>(this);
    } else {
      node.element.type = this.typeProvider.dynamicType;
    }
    // TODO: check that initializer if presents can be assigned to this type
    if(node.isInitialized) {
      MammouthType initializerType =
      node.initializer.accept<MammouthType>(this);
      if(!initializerType.isAssignableTo(node.element.type)) {
        // TODO: report error;
        throw "";
      }
    }
    return node.element.type;
  }

  @override
  MammouthType visitSimpleIdentifier(mammouth.SimpleIdentifier node) {
    node.scope = this.scopeStack.last;
    Element element = this.scopeStack.last.lookup(node.name);
    node.referredElement = element;
    if(element != null) {
      node.usedElements.add(element);
      node.referredElement = element;
      if(element is VariableElement) {
        return element.type;
      } else if(element is FunctionElement) {
        return element.type;
      } else if(element is FieldElement) {
        return element.type;
      } else if(element is TypeDefiningElement) {
        return element.type;
      } else {
        // TODO:
      }
    } else {
      // TODO: report error: undefined
      throw "undefined";
    }
  }

  @override
  MammouthType visitSliceExpression(mammouth.SliceExpression node) {
    MammouthType targetType = node.expression.accept(this);
    // TODO: check if targetType implements Sliceable
    List<ClassMemberElement> methods = targetType.members.where((
        ClassMemberElement member) {
      return member is MethodElement &&
          member.name == "slice"; // TODO: check arguments too
    }).toList();
    if(methods.length == 1 && methods.first is MethodElement) {
      node.slicerElement = (methods.first as MethodElement);
      return (methods.first as MethodElement).returnType;
    } else {
      // TODO: report error
      throw "";
    }
  }

  @override
  MammouthType visitStringLiteral(mammouth.StringLiteral node) {
    node.scope = this.scopeStack.last;
    return _stringType;
  }

  @override
  MammouthType visitSwitchCase(mammouth.SwitchCase node) {
    node.test.accept(this);
    node.consequent.accept(this);
  }

  @override
  MammouthType visitSwitchDefault(mammouth.SwitchDefault node) {
    node.consequent.accept(this);
  }

  @override
  MammouthType visitSwitchExpression(mammouth.SwitchExpression node) {
    node.scope = this.scopeStack.last;
    node.discriminant.accept(this);
    node.cases.forEach((mammouth.SwitchCase scase) {
      scase.accept(this);
    });
    node.defaultCase?.accept(this);
    return this.typeProvider.dynamicType;
  }

  @override
  MammouthType visitThrowStatement(mammouth.ThrowStatement node) {
    // TODO: check that expression extends Exception, or convert to so.
    // TODO: add used element
    return this.typeProvider.dynamicType;
  }

  @override
  MammouthType visitToExpression(mammouth.ToExpression node) {
    node.scope = this.scopeStack.last;
    MammouthType type = node.type.accept(this);
    MammouthType argumentType = node.argument.accept(this);
    if(argumentType is InterfaceType) {
      Option<ConverterElement> converterResult = argumentType.getConverterTo(
          type);
      if(converterResult.isSome) {
        node.converter = converterResult.some;
      }
    }
    return node.type.annotatedType;
  }

  @override
  MammouthType visitTryExpression(mammouth.TryExpression node) {
    node.scope = this.scopeStack.last;
    MammouthType tryType, catchType, finallyType;
    // TODO: Try must have it's own scope
    tryType = node.tryStatement.accept(this);
    node.usedElements.addAll(node.tryStatement.usedElements);
    if(node.hasCatch) {
      // TODO: assert that catch variable type extends Exception
      // TODO: define a variable with type Exception in scope of catch
      this.pushScope();
      node.catchVariable.accept(this);
      if(node.catchStatement is mammouth.Block) {
        catchType =
            (node.catchStatement as mammouth.Block).accept(this, scope: false);
      } else {
        catchType = node.catchStatement.accept(this);
      }
      this.popScope();
      node.usedElements.addAll(node.catchStatement.usedElements);
    }
    if(node.hasFinally) {
      finallyType = node.finallyStatement.accept(this);
      node.usedElements.addAll(node.finallyStatement.usedElements);
    }
    return tryType;
  }

  @override
  MammouthType visitTypeArgumentList(mammouth.TypeArgumentList node) {
    // TODO:
    return null;
  }

  @override
  MammouthType visitTypeName(mammouth.TypeName node) {
    mammouth.Identifier identifier = node.name;
    if(node.annotatedType != null) return node.annotatedType;
    if(identifier is mammouth.SimpleIdentifier) {
      if(identifier.name == "fn") {
        node.annotatedType = this.typeProvider.dynamicType;
        return node.annotatedType;
      }
      Element element = this.scopeStack.last.lookup(identifier.name);
      if(element != null) {
        node.typeElement = element;
        if(element is ClassElement) {
          node.annotatedType = element.instantiate(
              node.hasTypeArguments ? node.typeArguments.arguments.map((
                  mammouth.TypeAnnotation type) {
                return type.accept(this);
              }).whereType<MammouthType>().toList() : [],
              this, this.typeProvider.dynamicType);
          return node.annotatedType;
        }
        if(element is TypeDefiningElement) {
          node.annotatedType = element.type;
          return element.type;
        } else {
          // TODO: report error: identifier is not a type
          throw "not a type";
        }
      } else {
        // TODO: report error: undefined
        throw "undefined type";
      }
    }
    return null;
  }

  @override
  MammouthType visitTypeParameter(mammouth.TypeParameter node) {
    this.scopeStack.last.define(node.element);
    node.element.type = typeProvider.dynamicType;
    return null;
  }

  @override
  MammouthType visitTypeParameterList(mammouth.TypeParameterList node) {
    node.parameters.forEach((mammouth.TypeParameter typeParameter) {
      typeParameter.accept(this);
    });
    return null;
  }

  @override
  MammouthType visitUnaryExpression(mammouth.UnaryExpression node) {
    node.scope = this.scopeStack.last;
    MammouthType argumentType = node.argument.accept<MammouthType>(this);
    node.usedElements.addAll(node.argument.usedElements);
    Option<OperatorElement> result = this
        .typeSystem
        .operateUnary(node.operator.lexeme, argumentType, true);
    if(result.isSome) {
      if(result.some == null) {
        return this.typeProvider.dynamicType;
      } else {
        node.operatorElement = result.some;
        return result.some.returnType;
      }
    } else {
      // TODO: report error
      throw "invalid unary operation";
    }
  }

  @override
  MammouthType visitUnaryOperator(mammouth.UnaryOperator node) {
    return null;
  }

  @override
  MammouthType visitUpdateExpression(mammouth.UpdateExpression node) {
    node.scope = this.scopeStack.last;
    MammouthType argumentType = node.argument.accept<MammouthType>(this);
    node.usedElements.addAll(node.argument.usedElements);
    Option<OperatorElement> result = this
        .typeSystem
        .operateUnary(node.operator.lexeme, argumentType, node.isPrefix);
    if(result.isSome) {
      if(result.some == null) {
        return this.typeProvider.dynamicType;
      } else {
        node.operatorElement = result.some;
        return result.some.returnType;
      }
    } else {
      // TODO: report error
      throw "invalid unary operation";
    }
  }

  @override
  MammouthType visitUpdateOperator(mammouth.UpdateOperator node) {
    return null;
  }

  @override
  MammouthType visitVariableDeclarationStatement(
      mammouth.VariableDeclarationStatement node) {
    this.scopeStack.last.define(node.element);
    node.element.type = node.type.accept<MammouthType>(this);
    if(node.isInitialized) {
      MammouthType initializerType =
      node.initializer.accept<MammouthType>(this);
      node.usedElements.addAll(node.initializer.usedElements);
      if(initializerType.isAssignableTo(node.element.type)) {
        if(initializerType is InterfaceType) {
          Option<ConverterElement> converterResult =
          initializerType.getConverterTo(node.element.type);
          if(converterResult.isSome) {
            node.initializer.converterElement = converterResult.some;
          }
        }
        return node.element.type;
      } else {
        // TODO: report error
        throw "invalid assignment";
      }
    }
    node.usedElements.add(node.element);
    return node.element.type;
  }

  MammouthType get _intType {
    TypeDefiningElement element = this.scopeStack.last.lookup("int");
    return element.type;
  }

  MammouthType get _boolType {
    TypeDefiningElement element = this.scopeStack.last.lookup("bool");
    return element.type;
  }

  MammouthType get _stringType {
    TypeDefiningElement element = this.scopeStack.last.lookup("String");
    return element.type;
  }

  _importURI(String uri) {
    if(uri.startsWith("package:")) {
      uri = _session.projectRoot.uri.resolve(
          p.join("packages", uri.replaceAll(new RegExp(r"^package:"), "")))
          .toFilePath();
    } else {
      uri = this._source.directory.uri.resolve(uri).toFilePath();
    }
    Option<Source> sourceResult = _session.fileSystem.getSource(uri);
    if(sourceResult.isSome && sourceResult.some.exist) {
      Source source = sourceResult.some;
      Lexer lexer = new Lexer(_diagnosticEngine);
      Parser parser = new Parser(_diagnosticEngine);
      lexer.setInput(source);
      parser.setInput(source, lexer.scanAll());
      common.Document document = parser
          .parseDocument()
          .some;
      document.accept(new ParentResolver());
      document.accept(new ElementBuilder());
      document.accept(new TypeChecker(source, _session, _diagnosticEngine,
          parentScope: this.scopeStack.first));
    } else {
      throw "no file";
    }
  }
}
