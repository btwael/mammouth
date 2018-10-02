library mammouth.language.mammouth.ast.implementation;

import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/common/ast/precedence.dart";
import "package:mammouth/src/language/common/ast/token.dart" show Token;
import "package:mammouth/src/language/common/ast/visibility.dart";
import "package:mammouth/src/language/mammouth/ast/ast.dart";
import "package:mammouth/src/language/mammouth/element/element.dart";
import "package:mammouth/src/language/mammouth/type/type.dart";
import "package:mammouth/src/semantic/scope.dart" show Scope;

//*-- ArgumentListImpl
class ArgumentListImpl extends ArgumentList {
  @override
  final List<Expression> arguments;

  AstNode _parentNode;

  ArgumentListImpl(this.arguments);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ArrayLiteralImpl
class ArrayLiteralImpl extends ArrayLiteral {
  @override
  final TypeArgumentList typeArguments;

  @override
  final Token leftBracket;

  @override
  final List<Expression> elements;

  @override
  final Token rightBracket;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  ArrayLiteralImpl(this.typeArguments, this.elements)
      : this.leftBracket = null,
        this.rightBracket = null;

  ArrayLiteralImpl.syntactic(this.typeArguments, this.leftBracket,
      this.elements, this.rightBracket);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- AsExpressionImpl
class AsExpressionImpl extends AsExpression {
  @override
  final Expression argument;

  @override
  final Token asKeyword; // TODO: operator

  @override
  final TypeAnnotation type;

  @override
  bool asStatement;

  AstNode _parentNode;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AsExpressionImpl(this.argument, this.type)
      : this.asKeyword = null;

  AsExpressionImpl.syntactic(this.argument, this.asKeyword, this.type);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- AssignmentExpressionImpl
class AssignmentExpressionImpl extends AssignmentExpression {
  @override
  final Expression left;

  @override
  final AssignmentOperator operator;

  @override
  final Expression right;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  MethodElement setterElement;

  AstNode _parentNode;

  AssignmentExpressionImpl(this.left, this.operator, this.right);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- AssignmentOperatorImpl
class AssignmentOperatorImpl extends AssignmentOperator {
  @override
  final Token token;

  @override
  final String lexeme;

  AssignmentExpression _parentNode;

  AssignmentOperatorImpl(this.lexeme)
      : this.token = null;

  AssignmentOperatorImpl.syntactic(Token token)
      : this.token = token,
        this.lexeme = token.lexeme;

  @override
  AssignmentExpression get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AssignmentExpression) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- AtExpressionImpl
class AtExpressionImpl extends AtExpression {
  @override
  final Token atToken;

  @override
  final SimpleIdentifier property;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  List<Element> candidateElements = [];

  @override
  Element referredElement;

  AstNode _parentNode;

  AtExpressionImpl(this.property)
      : this.atToken = null;

  AtExpressionImpl.syntactic(this.atToken, this.property);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- BinaryExpressionImpl
class BinaryExpressionImpl extends BinaryExpression {
  @override
  final Expression left;

  @override
  final BinaryOperator operator;

  @override
  final Expression right;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  OperatorElement operatorElement;

  AstNode _parentNode;

  BinaryExpressionImpl(this.left, this.operator, this.right);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- BinaryOperatorImpl
class BinaryOperatorImpl extends BinaryOperator {
  @override
  final Token token;

  @override
  final String lexeme;

  @override
  final Precedence precedence;

  AstNode _parentNode;

  BinaryOperatorImpl(this.lexeme, this.precedence)
      : this.token = null;

  BinaryOperatorImpl.syntactic(Token token)
      : this.token = token,
        this.lexeme = token.lexeme,
        this.precedence = token.precedence;

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- BlockImpl
class BlockImpl extends Block {
  @override
  final List<Statement> statements;

  AstNode _parentNode;

  BlockImpl(this.statements);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- BooleanLiteralImpl
class BooleanLiteralImpl extends BooleanLiteral {
  @override
  final Token token;

  @override
  final String raw;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  BooleanLiteralImpl(this.raw)
      : this.token = null;

  BooleanLiteralImpl.syntactic(Token token)
      : this.token = token,
        this.raw = token.lexeme;

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- BreakStatementImpl
class BreakStatementImpl extends BreakStatement {
  @override
  final Token breakKeyword;

  AstNode _parentNode;

  BreakStatementImpl()
      : this.breakKeyword = null;

  BreakStatementImpl.syntactic(this.breakKeyword);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ClassExpressionImpl
class ClassExpressionImpl extends ClassExpression {
  @override
  final Token classKeyword;

  @override
  final SimpleIdentifier name;

  @override
  final TypeParameterList typeParameters;

  @override
  final ExtendsClause extendsClause;

  @override
  final ImplementsClause implementsClause;

  @override
  final List<ClassMember> members;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  ClassElement element;

  AstNode _parentNode;

  ClassExpressionImpl(this.name, this.typeParameters, this.extendsClause,
      this.implementsClause, this.members)
      : this.classKeyword = null;

  ClassExpressionImpl.syntactic(this.classKeyword, this.name,
      this.typeParameters, this.extendsClause, this.implementsClause,
      this.members);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ClosureParameterImpl
class ClosureParameterImpl extends ClosureParameter {
  @override
  final TypeAnnotation returnType;

  @override
  SimpleIdentifier name;

  @override
  final Token leftParenthesis;

  @override
  final List<TypeAnnotation> parameterTypes;

  @override
  final Token rightParenthesis;

  @override
  final bool isOptional;

  @override
  ParameterElement element;

  AstNode _parentNode;

  ClosureParameterImpl(this.returnType, this.name, this.parameterTypes,
      this.isOptional)
      : this.leftParenthesis = null,
        this.rightParenthesis = null;

  ClosureParameterImpl.syntactic(this.returnType, this.name,
      this.leftParenthesis, this.parameterTypes, this.rightParenthesis,
      this.isOptional);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ConstructorDeclarationImpl
class ConstructorDeclarationImpl extends ConstructorDeclaration {
  @override
  final Token visibilityToken;

  Visibility _visibility;

  @override
  final Token constructorKeyword;

  @override
  final ParameterList parameters;

  @override
  final Token inlineKeyword;

  @override
  final bool isInline;

  @override
  final Token arrow;

  @override
  final Block body;

  ConstructorElement _element;

  AstNode _parentNode;

  ConstructorDeclarationImpl(this._visibility, this.parameters, this.isInline,
      this.body)
      : this.visibilityToken = null,
        this.constructorKeyword = null,
        this.inlineKeyword = null,
        this.arrow = null;

  ConstructorDeclarationImpl.syntactic(this.visibilityToken,
      this.constructorKeyword, this.parameters, Token inlineKeyword, this.arrow,
      this.body)
      : this.inlineKeyword = inlineKeyword,
        this.isInline = inlineKeyword != null {
    if(this.visibilityToken == null) {
      _visibility = Visibility.DEFAULT;
    } else {
      if(this.isPrivate) {
        _visibility = Visibility.PRIVATE;
      } else if(this.isProtected) {
        _visibility = Visibility.PROTECTED;
      }
      _visibility = Visibility.PUBLIC;
    }
  }

  @override
  Visibility get visibility => _visibility;

  @override
  ConstructorElement get element => _element;

  @override
  void set element(Element element) {
    if(element is ConstructorElement) {
      _element = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ContinueStatementImpl
class ContinueStatementImpl extends ContinueStatement {
  @override
  final Token continueKeyword;

  AstNode _parentNode;

  ContinueStatementImpl()
      : this.continueKeyword = null;

  ContinueStatementImpl.syntactic(this.continueKeyword);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ConverterDeclarationImpl
class ConverterDeclarationImpl extends ConverterDeclaration {
  @override
  final Token abstractKeyword;

  @override
  bool isAbstract;

  @override
  final Token visibilityToken;

  Visibility _visibility;

  @override
  final TypeAnnotation returnType;

  @override
  final Token toKeyword;

  @override
  final Token inlineKeyword;

  @override
  final Token arrow;

  @override
  final Block body;

  ConverterElement _element;

  AstNode _parentNode;

  ConverterDeclarationImpl(this.isAbstract, this._visibility, this.returnType,
      this.body)
      : this.abstractKeyword = null,
        this.visibilityToken = null,
        this.toKeyword = null,
        this.inlineKeyword = null,
        this.arrow = null;

  ConverterDeclarationImpl.syntactic(Token abstractKeyword,
      this.visibilityToken, this.returnType, this.toKeyword, this.inlineKeyword,
      this.arrow, this.body)
      : this.abstractKeyword = abstractKeyword,
        this.isAbstract = abstractKeyword != null {
    if(this.visibilityToken == null) {
      _visibility = Visibility.DEFAULT;
    } else {
      if(this.isPrivate) {
        _visibility = Visibility.PRIVATE;
      } else if(this.isProtected) {
        _visibility = Visibility.PROTECTED;
      }
      _visibility = Visibility.PUBLIC;
    }
  }

  @override
  Visibility get visibility => _visibility;

  @override
  ConverterElement get element => _element;

  @override
  void set element(Element element) {
    if(element is ConverterElement) {
      _element = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- EchoExpressionImpl
class EchoExpressionImpl extends EchoExpression {
  @override
  final Token echoKeyword;

  @override
  final Expression argument;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  EchoExpressionImpl(this.argument)
      : this.echoKeyword = null;

  EchoExpressionImpl.syntactic(this.echoKeyword, this.argument);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ExistenceExpressionImpl
class ExistenceExpressionImpl extends ExistenceExpression {
  @override
  final ElementReferenceExpression argument;

  @override
  final Token questionMark;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  ExistenceExpressionImpl(this.argument)
      : this.questionMark = null;

  ExistenceExpressionImpl.syntactic(this.argument, this.questionMark);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ExpressionStatementImpl
class ExpressionStatementImpl extends ExpressionStatement {
  @override
  final Expression expression;

  AstNode _parentNode;

  ExpressionStatementImpl(this.expression) {
    this.expression.asStatement = true;
  }

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ExtendsClauseImpl
class ExtendsClauseImpl extends ExtendsClause {
  @override
  final Token extendsKeyword;

  @override
  final TypeName superclass;

  AstNode _parentNode;

  ExtendsClauseImpl(this.superclass)
      : this.extendsKeyword = null;

  ExtendsClauseImpl.syntactic(this.extendsKeyword, this.superclass);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- FieldDeclarationImpl
class FieldDeclarationImpl extends FieldDeclaration {
  @override
  final Token visibilityToken;

  Visibility _visibility;

  @override
  final Token staticKeyword;

  @override
  final bool isStatic;

  @override
  final TypeAnnotation type;

  @override
  final SimpleIdentifier name;

  @override
  final Token equal;

  @override
  final Expression initializer;

  FieldElement _element;

  AstNode _parentNode;

  FieldDeclarationImpl(this._visibility, this.isStatic, this.type, this.name,
      this.initializer)
      : this.visibilityToken = null,
        this.staticKeyword = null,
        this.equal = null;

  FieldDeclarationImpl.syntactic(this.visibilityToken, Token staticKeyword,
      this.type, this.name, this.equal, this.initializer)
      : this.staticKeyword = staticKeyword,
        this.isStatic = staticKeyword != null {
    if(this.visibilityToken == null) {
      _visibility = Visibility.DEFAULT;
    } else {
      if(this.isPrivate) {
        _visibility = Visibility.PRIVATE;
      } else if(this.isProtected) {
        _visibility = Visibility.PROTECTED;
      }
      _visibility = Visibility.PUBLIC;
    }
  }

  @override
  Visibility get visibility => _visibility;

  @override
  FieldElement get element => _element;

  @override
  void set element(Element element) {
    if(element is FieldElement) {
      _element = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- FloatLiteralImpl
class FloatLiteralImpl extends FloatLiteral {
  @override
  Token token;

  @override
  final String raw;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  FloatLiteralImpl(this.raw)
      : this.token = null;

  FloatLiteralImpl.syntactic(Token token)
      : this.token = token,
        this.raw = token.lexeme;

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ForExpressionImpl
class ForExpressionImpl extends ForExpression {
  @override
  final ForSource source;

  @override
  Statement body;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  ForExpressionImpl(this.source, this.body);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ForRangeSourceImpl
class ForRangeSourceImpl extends ForRangeSource {
  @override
  final Token forKeyword;

  @override
  final RangeLiteral source;

  @override
  final Token asKeyword;

  @override
  final ForVariable name;

  @override
  final Token byKeyword;

  @override
  final Expression step;

  @override
  final GuardSource guard;

  ForExpression _parentNode;

  ForRangeSourceImpl(this.source, this.name, this.step, this.guard)
      : this.forKeyword = null,
        this.asKeyword = null,
        this.byKeyword = null;

  ForRangeSourceImpl.syntactic(this.forKeyword, this.source, this.asKeyword,
      this.name, this.byKeyword, this.step, this.guard);

  @override
  ForExpression get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is ForExpression) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ForVariableImpl
class ForVariableImpl extends ForVariable {
  @override
  final TypeAnnotation type;

  @override
  final SimpleIdentifier name;

  @override
  VariableElement element;

  ForSource _parentNode;

  ForVariableImpl(this.type, this.name);

  @override
  ForSource get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is ForSource) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ForVariableSourceImpl
class ForVariableSourceImpl extends ForVariableSource {
  @override
  final Token forKeyword;

  @override
  final ForVariable firstVariable;

  @override
  final ForVariable secondVariable;

  @override
  final Token inKeyword;

  @override
  final Token ofKeyword;

  @override
  final ForVariableSourceKind kind;

  @override
  final Expression source;

  @override
  final Token byKeyword;

  @override
  final Expression step;

  @override
  final GuardSource guard;

  ForExpression _parentNode;

  ForVariableSourceImpl(this.firstVariable,
      this.secondVariable,
      this.kind,
      this.source,
      this.step,
      this.guard)
      : this.forKeyword = null,
        this.inKeyword = null,
        this.ofKeyword = null,
        this.byKeyword = null;

  ForVariableSourceImpl.syntactic(this.forKeyword,
      this.firstVariable,
      this.secondVariable,
      Token inKeyword,
      this.ofKeyword,
      this.source,
      this.byKeyword,
      this.step,
      this.guard)
      : this.inKeyword = inKeyword,
        this.kind = inKeyword != null
            ? ForVariableSourceKind.IN
            : ForVariableSourceKind.OF;

  @override
  ForExpression get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is ForExpression) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- FunctionExpressionImpl
class FunctionExpressionImpl extends FunctionExpression {
  @override
  final TypeAnnotation returnType;

  @override
  final SimpleIdentifier name;

  @override
  final ParameterList parameters;

  @override
  final Token inlineKeyword;

  @override
  final Token arrow;

  @override
  final Block body;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  FunctionElement element;

  AstNode _parentNode;

  // TODO: non syntactic version

  FunctionExpressionImpl.syntactic(this.returnType, this.name, this.parameters,
      this.inlineKeyword, this.arrow, this.body);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- GuardSourceImpl
class GuardSourceImpl extends GuardSource {
  @override
  final Token whenKeyword;

  @override
  final Expression condition;

  AstNode _parentNode;

  GuardSourceImpl(this.condition)
      : this.whenKeyword = null;

  GuardSourceImpl.syntactic(this.whenKeyword, this.condition);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- IfExpressionImpl
class IfExpressionImpl extends IfExpression {
  @override
  final IfSource ifSource;

  @override
  final Statement consequent;

  @override
  final Token elseKeyword;

  @override
  final Statement alternate;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  IfExpressionImpl(this.ifSource, this.consequent, this.alternate)
      : this.elseKeyword = null;

  IfExpressionImpl.syntactic(this.ifSource, this.consequent, this.elseKeyword,
      this.alternate);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- IfSourceImpl
class IfSourceImpl extends IfSource {
  @override
  final Token ifKeyword;

  @override
  final String keywordLexeme;

  @override
  final Expression condition;

  IfExpression _parentNode;

  IfSourceImpl(this.keywordLexeme, this.condition)
      : this.ifKeyword = null;

  IfSourceImpl.syntactic(Token ifKeyword, this.condition)
      : this.ifKeyword = ifKeyword,
        this.keywordLexeme = ifKeyword.lexeme;

  @override
  IfExpression get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is IfExpression) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ImplementsClauseImpl
class ImplementsClauseImpl extends ImplementsClause {
  @override
  final Token implementsKeyword;

  @override
  final List<TypeAnnotation> interfaces;

  AstNode _parentNode;

  ImplementsClauseImpl(this.interfaces)
      : this.implementsKeyword = null;

  ImplementsClauseImpl.syntactic(this.implementsKeyword, this.interfaces);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ImportDirectiveImpl
class ImportDirectiveImpl extends ImportDirective {
  @override
  final Token importKeyword;

  @override
  final StringLiteral uri;

  AstNode _parentNode;

  ImportDirectiveImpl(this.uri)
      : this.importKeyword = null;

  ImportDirectiveImpl.syntactic(this.importKeyword, this.uri);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- IndexExpressionImpl
class IndexExpressionImpl extends IndexExpression {
  @override
  final Expression target;

  @override
  final Token leftBracket;

  @override
  final Expression index;

  @override
  final Token rightBracket;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  OperatorElement operatorElement;

  AstNode _parentNode;

  IndexExpressionImpl(this.target, this.index)
      : this.leftBracket = null,
        this.rightBracket = null;

  IndexExpressionImpl.syntactic(this.target, this.leftBracket, this.index,
      this.rightBracket);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- InExpressionImpl
class InExpressionImpl extends InExpression {
  @override
  final Expression element;

  @override
  final Token inKeyword; // TODO: operator

  @override
  final Expression container;

  @override
  bool asStatement;

  AstNode _parentNode;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  MethodElement methodElement;

  InExpressionImpl(this.element, this.container)
      : this.inKeyword = null;

  InExpressionImpl.syntactic(this.element, this.inKeyword, this.container);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- IntegerLiteralImpl
class IntegerLiteralImpl extends IntegerLiteral {
  @override
  final Token token;

  @override
  final String raw;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  IntegerLiteralImpl(this.raw)
      : this.token = null;

  IntegerLiteralImpl.syntactic(Token token)
      : this.token = token,
        this.raw = token.lexeme;

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- InterfaceDeclarationImpl
class InterfaceDeclarationImpl extends InterfaceDeclaration {
  @override
  final Token interfaceKeyword;

  @override
  final SimpleIdentifier name;

  @override
  final ImplementsClause implementsClause;

  @override
  final List<ClassMember> members;

  @override
  InterfaceElement element;

  AstNode _parentNode;

  InterfaceDeclarationImpl(this.name, this.implementsClause, this.members)
      : this.interfaceKeyword = null;

  InterfaceDeclarationImpl.syntactic(this.interfaceKeyword, this.name,
      this.implementsClause, this.members);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- InvocationExpressionImpl
class InvocationExpressionImpl extends InvocationExpression {
  @override
  final ElementReferenceExpression callee;

  @override
  final Token leftParenthesis;

  @override
  final ArgumentList arguments;

  @override
  final Token rightParenthesis;

  Scope scope;

  @override
  bool asStatement = false;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  InvocationExpressionImpl(this.callee, this.arguments)
      : this.leftParenthesis = null,
        this.rightParenthesis = null;

  InvocationExpressionImpl.syntactic(this.callee, this.leftParenthesis,
      this.arguments, this.rightParenthesis);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- MMapEntryImpl
class MMapEntryImpl extends MMapEntry {
  @override
  final Expression key;

  @override
  final Token colon;

  @override
  final Expression value;

  MapLiteral _parentNode;

  MMapEntryImpl(this.key, this.value)
      : this.colon = null;

  MMapEntryImpl.syntactic(this.key, this.colon, this.value);

  @override
  MapLiteral get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is MapLiteral) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- MapLiteralImpl
class MapLiteralImpl extends MapLiteral {
  @override
  final TypeArgumentList typeArguments;

  @override
  final Token leftBrace;

  @override
  final List<MMapEntry> entries;

  @override
  final Token rightBrace;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  MapLiteralImpl(this.typeArguments, this.entries)
      : this.leftBrace = null,
        this.rightBrace = null;

  MapLiteralImpl.syntactic(this.typeArguments, this.leftBrace, this.entries,
      this.rightBrace);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- MemberExpressionImpl
class MemberExpressionImpl extends MemberExpression {
  @override
  final Expression target;

  @override
  final Token dot;

  @override
  final SimpleIdentifier property;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  List<Element> candidateElements = [];

  @override
  Element referredElement;

  AstNode _parentNode;

  MemberExpressionImpl(this.target, this.property)
      : this.dot = null;

  MemberExpressionImpl.syntactic(this.target, this.dot, this.property);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- MethodDeclarationImpl
class MethodDeclarationImpl extends MethodDeclaration {
  @override
  final Token abstractKeyword;

  @override
  final bool isAbstract;

  @override
  final Token visibilityToken;

  Visibility _visibility;

  @override
  final Token staticKeyword;

  @override
  final bool isStatic;

  @override
  final TypeAnnotation returnType;

  @override
  final Token propertyKeyword;

  @override
  final String propertyLexeme;

  @override
  final SimpleIdentifier name;

  @override
  final ParameterList parameters;

  @override
  final Token inlineKeyword;

  @override
  final bool isInline;

  @override
  final Token arrow;

  @override
  final Block body;

  MethodElement _element;

  AstNode _parentNode;

  MethodDeclarationImpl(this.isAbstract,
      this._visibility,
      this.isStatic,
      this.returnType,
      this.propertyLexeme,
      this.name,
      this.parameters,
      this.isInline,
      this.body)
      : this.abstractKeyword = null,
        this.visibilityToken = null,
        this.staticKeyword = null,
        this.propertyKeyword = null,
        this.inlineKeyword = null,
        this.arrow = null;

  MethodDeclarationImpl.syntactic(Token abstractKeyword,
      this.visibilityToken,
      Token staticKeyword,
      this.returnType,
      Token propertyKeyword,
      this.name,
      this.parameters,
      Token inlineKeyword,
      this.arrow,
      this.body)
      : this.abstractKeyword = abstractKeyword,
        this.isAbstract = abstractKeyword != null,
        this.staticKeyword = staticKeyword,
        this.isStatic = staticKeyword != null,
        this.propertyKeyword = propertyKeyword,
        this.propertyLexeme = propertyKeyword?.lexeme,
        this.inlineKeyword = inlineKeyword,
        this.isInline = inlineKeyword != null {
    if(this.visibilityToken == null) {
      _visibility = Visibility.DEFAULT;
    } else {
      if(this.isPrivate) {
        _visibility = Visibility.PRIVATE;
      } else if(this.isProtected) {
        _visibility = Visibility.PROTECTED;
      }
      _visibility = Visibility.PUBLIC;
    }
  }

  @override
  Visibility get visibility => _visibility;

  @override
  MethodElement get element => _element;

  @override
  void set element(Element element) {
    if(element is MethodElement) {
      _element = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- NativeExpressionImpl
class NativeExpressionImpl extends NativeExpression {
  @override
  final Token nativeKeyword;

  @override
  final Token leftParen;

  @override
  final ArgumentList arguments;

  @override
  final Token rightParen;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  NativeExpressionImpl(this.arguments)
      :this.nativeKeyword = null,
        this.leftParen = null,
        this.rightParen = null;

  NativeExpressionImpl.syntactic(this.nativeKeyword, this.leftParen,
      this.arguments, this.rightParen);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- NewExpressionImpl
class NewExpressionImpl extends NewExpression {
  @override
  final Token newKeyword;

  @override
  final TypeAnnotation callee;

  @override
  final Token leftParenthesis;

  @override
  final ArgumentList arguments;

  @override
  final Token rightParenthesis;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  NewExpressionImpl(this.callee, this.arguments)
      : this.newKeyword = null,
        this.leftParenthesis = null,
        this.rightParenthesis = null;

  NewExpressionImpl.syntactic(this.newKeyword, this.callee,
      this.leftParenthesis, this.arguments, this.rightParenthesis);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- OperatorDeclarationImpl
class OperatorDeclarationImpl extends OperatorDeclaration {
  @override
  final Token abstractKeyword;

  @override
  final bool isAbstract;

  @override
  final Token visibilityToken;

  Visibility _visibility;

  @override
  final TypeAnnotation returnType;

  @override
  final Token operatorKeyword;

  final String operatorType;

  @override
  final Operator operator;

  @override
  final ParameterList parameters;

  @override
  final Token inlineKeyword;

  @override
  final bool isInline;

  @override
  final Token arrow;

  @override
  final Block body;

  OperatorElement _element;

  AstNode _parentNode;

  OperatorDeclarationImpl(this.isAbstract,
      this._visibility,
      this.returnType,
      this.operatorType,
      this.operator,
      this.parameters,
      this.isInline,
      this.body)
      : this.abstractKeyword = null,
        this.visibilityToken = null,
        this.operatorKeyword = null,
        this.inlineKeyword = null,
        this.arrow = null;

  OperatorDeclarationImpl.syntactic(Token abstractKeyword,
      this.visibilityToken,
      this.returnType,
      Token operatorKeyword,
      this.operator,
      this.parameters,
      Token inlineKeyword,
      this.arrow,
      this.body)
      : this.abstractKeyword = abstractKeyword,
        this.operatorKeyword = operatorKeyword,
        this.operatorType = operatorKeyword.lexeme,
        this.isAbstract = abstractKeyword != null,
        this.inlineKeyword = inlineKeyword,
        this.isInline = inlineKeyword != null {
    if(this.visibilityToken == null) {
      _visibility = Visibility.DEFAULT;
    } else {
      if(this.isPrivate) {
        _visibility = Visibility.PRIVATE;
      } else if(this.isProtected) {
        _visibility = Visibility.PROTECTED;
      }
      _visibility = Visibility.PUBLIC;
    }
  }

  @override
  Visibility get visibility => _visibility;

  @override
  OperatorElement get element => _element;

  @override
  void set element(Element element) {
    if(element is OperatorElement) {
      _element = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ParameterListImpl
class ParameterListImpl extends ParameterList {
  @override
  final Token leftParenthesis;

  @override
  final List<Parameter> parameters;

  @override
  final Token rightParenthesis;

  AstNode _parentNode;

  ParameterListImpl(this.parameters)
      : this.leftParenthesis = null,
        this.rightParenthesis = null;

  ParameterListImpl.syntactic(this.leftParenthesis, this.parameters,
      this.rightParenthesis);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ParenthesisExpressionImpl
class ParenthesisExpressionImpl extends ParenthesisExpression {
  @override
  final Token leftParenthesis;

  @override
  final Expression expression;

  @override
  final Token rightParenthesis;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  ParenthesisExpressionImpl(this.expression)
      : this.leftParenthesis = null,
        this.rightParenthesis = null;

  ParenthesisExpressionImpl.syntactic(this.leftParenthesis, this.expression,
      this.rightParenthesis);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- RangeLiteralImpl
class RangeLiteralImpl extends RangeLiteral {
  @override
  final Token leftBracket;

  @override
  final Expression start;

  @override
  final Token operator;

  @override
  final Expression end;

  @override
  final Token rightBracket;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  RangeLiteralImpl(this.start, this.operator, this.end)
      : this.leftBracket = null,
        this.rightBracket = null;

  RangeLiteralImpl.syntactic(this.leftBracket, this.start, this.operator,
      this.end, this.rightBracket);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- RepetitionExpressionImpl
class RepetitionExpressionImpl extends RepetitionExpression {
  @override
  final RepetitionSource source;

  @override
  final Statement body;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  RepetitionExpressionImpl(this.source, this.body);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- RepetitionSourceImpl
class RepetitionSourceImpl extends RepetitionSource {
  @override
  final Token keyword;

  @override
  final Expression test;

  @override
  final GuardSource guard;

  RepetitionExpression _parentNode;

  RepetitionSourceImpl(this.keyword, this.test, this.guard);

  @override
  RepetitionExpression get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is RepetitionExpression) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ReturnStatementImpl
class ReturnStatementImpl extends ReturnStatement {
  @override
  final Token returnKeyword;

  @override
  final Expression expression;

  AstNode _parentNode;

  ReturnStatementImpl(this.expression)
      : this.returnKeyword = null;

  ReturnStatementImpl.syntactic(this.returnKeyword, this.expression);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ScriptImpl
class ScriptImpl extends Script {
  @override
  final Token startTag;

  @override
  final Block body;

  @override
  final Token endTag;

  @override
  Set<Element> usedElements = new Set<Element>();

  common.Document _parentNode;

  ScriptImpl(this.startTag, this.body, this.endTag);

  @override
  common.Document get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is common.Document) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- SimpleIdentifierImpl
class SimpleIdentifierImpl extends SimpleIdentifier {
  @override
  final Token token;

  @override
  final String name;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  List<Element> candidateElements = [];

  @override
  Element referredElement;

  AstNode _parentNode;

  SimpleIdentifierImpl(this.name)
      : this.token = null;

  SimpleIdentifierImpl.syntactic(Token token)
      : this.token = token,
        this.name = token.lexeme;

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- SimpleParameterImpl
class SimpleParameterImpl extends SimpleParameter {
  @override
  final TypeAnnotation type;

  @override
  final SimpleIdentifier name;

  @override
  final Token equal;

  @override
  final Expression initializer;

  @override
  final bool isOptional;

  @override
  ParameterElement element;

  AstNode _parentNode;

  SimpleParameterImpl(this.type, this.name, this.initializer, this.isOptional)
      : this.equal = null;

  SimpleParameterImpl.syntactic(this.type, this.name, this.equal,
      this.initializer,
      this.isOptional);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- SliceExpressionImpl
class SliceExpressionImpl extends SliceExpression {
  @override
  final Expression expression;

  @override
  final RangeLiteral slicingRange;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  MethodElement slicerElement;

  AstNode _parentNode;

  SliceExpressionImpl(this.expression, this.slicingRange);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- StringLiteralImpl
class StringLiteralImpl extends StringLiteral {
  @override
  final Token token;

  @override
  final String raw;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  StringLiteralImpl(this.raw)
      : this.token = null;

  StringLiteralImpl.syntactic(Token token)
      : this.token = token,
        this.raw = token.lexeme;

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- SwitchCaseImpl
class SwitchCaseImpl extends SwitchCase {
  @override
  final Token keyword;

  @override
  final Expression test;

  @override
  final Statement consequent;

  SwitchExpression _parentNode;

  SwitchCaseImpl(this.test, this.consequent)
      : this.keyword = null;

  SwitchCaseImpl.syntactic(this.keyword, this.test, this.consequent);

  @override
  SwitchExpression get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is SwitchExpression) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- SwitchDefault
class SwitchDefaultImpl extends SwitchDefault {
  @override
  final Token defaultKeyword;

  @override
  final Statement consequent;

  SwitchExpression _parentNode;

  SwitchDefaultImpl(this.consequent)
      : this.defaultKeyword = null;

  SwitchDefaultImpl.syntactic(this.defaultKeyword, this.consequent);

  @override
  SwitchExpression get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is SwitchExpression) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- SwitchExpressionImpl
class SwitchExpressionImpl extends SwitchExpression {
  @override
  final Token switchKeyword;

  @override
  final Expression discriminant;

  @override
  final List<SwitchCase> cases;

  @override
  final SwitchDefault defaultCase;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  SwitchExpressionImpl(this.discriminant, this.cases, this.defaultCase)
      : this.switchKeyword = null;

  SwitchExpressionImpl.syntactic(this.switchKeyword, this.discriminant,
      this.cases, this.defaultCase);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ThrowStatementImpl
class ThrowStatementImpl extends ThrowStatement {
  @override
  final Token throwKeyword;

  @override
  final Expression expression;

  AstNode _parentNode;

  ThrowStatementImpl(this.expression)
      : this.throwKeyword = null;

  ThrowStatementImpl.syntactic(this.throwKeyword, this.expression);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- ToExpressionImpl
class ToExpressionImpl extends ToExpression {
  @override
  final Expression argument;

  @override
  final Token toKeyword; // TODO: operator

  @override
  final TypeAnnotation type;

  @override
  bool asStatement;

  AstNode _parentNode;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  ConverterElement converter;

  ToExpressionImpl(this.argument, this.type)
      : this.toKeyword = null;

  ToExpressionImpl.syntactic(this.argument, this.toKeyword, this.type);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- TryExpressionImpl
class TryExpressionImpl extends TryExpression {
  @override
  final Token tryKeyword;

  @override
  final Statement tryStatement;

  @override
  final Token catchKeyword;

  @override
  final SimpleParameter catchVariable;

  @override
  final Statement catchStatement;

  @override
  final Token finallyKeyword;

  @override
  final Statement finallyStatement;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  AstNode _parentNode;

  TryExpressionImpl(this.tryStatement,
      this.catchVariable,
      this.catchStatement,
      this.finallyStatement)
      : this.tryKeyword = null,
        this.catchKeyword = null,
        this.finallyKeyword = null;

  TryExpressionImpl.syntactic(this.tryKeyword,
      this.tryStatement,
      this.catchKeyword,
      this.catchVariable,
      this.catchStatement,
      this.finallyKeyword,
      this.finallyStatement);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- TypeArgumentListImpl
class TypeArgumentListImpl extends TypeArgumentList {
  @override
  final Token leftAngle;

  @override
  final List<TypeAnnotation> arguments;

  @override
  final Token rightAngle;

  AstNode _parentNode;

  TypeArgumentListImpl(this.leftAngle, this.arguments, this.rightAngle);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- TypeNameImpl
class TypeNameImpl extends TypeName {
  @override
  final Identifier name;

  @override
  TypeArgumentList typeArguments;

  @override
  MammouthType annotatedType;

  AstNode _parentNode;

  TypeNameImpl(this.name, this.typeArguments);

  Element typeElement;

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- TypeParameterImpl
class TypeParameterImpl extends TypeParameter {
  @override
  final SimpleIdentifier name;

  TypeParameterList _parentNode;

  TypeParameterImpl(this.name);

  @override
  TypeParameterList get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is TypeParameterList) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- TypeParameterListImpl
class TypeParameterListImpl extends TypeParameterList {
  @override
  final Token leftAngle;

  @override
  final List<TypeParameter> parameters;

  @override
  final Token rightAngle;

  AstNode _parentNode;

  TypeParameterListImpl(this.parameters)
      : this.leftAngle = null,
        this.rightAngle = null;

  TypeParameterListImpl.syntactic(this.leftAngle, this.parameters,
      this.rightAngle);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- UnaryExpressionImpl
class UnaryExpressionImpl extends UnaryExpression {
  @override
  final UnaryOperator operator;

  @override
  final Expression argument;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  OperatorElement operatorElement;

  AstNode _parentNode;

  UnaryExpressionImpl(this.operator, this.argument);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- UnaryOperatorImpl
class UnaryOperatorImpl extends UnaryOperator {
  @override
  final Token token;

  @override
  final String lexeme;

  AstNode _parentNode;

  UnaryOperatorImpl(this.lexeme)
      : this.token = null;

  UnaryOperatorImpl.syntactic(Token token)
      : this.token = token,
        this.lexeme = token.lexeme;

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- UpdateExpressionImpl
class UpdateExpressionImpl extends UpdateExpression {
  @override
  final bool isPrefix;

  @override
  final UpdateOperator operator;

  @override
  final Expression argument;

  @override
  bool asStatement = false;

  @override
  Scope scope;

  @override
  ConverterElement converterElement;

  @override
  OperatorElement operatorElement;

  AstNode _parentNode;

  UpdateExpressionImpl(this.isPrefix, this.operator, this.argument);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- UpdateOperatorImpl
class UpdateOperatorImpl extends UpdateOperator {
  @override
  final Token token;

  @override
  final String lexeme;

  AstNode _parentNode;

  UpdateOperatorImpl(this.lexeme)
      : this.token = null;

  UpdateOperatorImpl.syntactic(Token token)
      : this.token = token,
        this.lexeme = token.lexeme;

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

//*-- VariableDeclarationStatementImpl
class VariableDeclarationStatementImpl extends VariableDeclarationStatement {
  @override
  final TypeAnnotation type;

  @override
  final SimpleIdentifier name;

  @override
  final Token equal;

  @override
  final Expression initializer;

  @override
  VariableElement element;

  AstNode _parentNode;

  VariableDeclarationStatementImpl(this.type, this.name, this.initializer)
      : this.equal = null;

  VariableDeclarationStatementImpl.syntactic(this.type, this.name, this.equal,
      this.initializer);

  @override
  AstNode get parentNode => _parentNode;

  @override
  void set parentNode(common.AstNode node) {
    if(node is AstNode) {
      _parentNode = node;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}
