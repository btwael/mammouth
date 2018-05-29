import "../grammar/syntacticEntity.dart" show SyntacticEntity;
import "../grammar/precedence.dart" show Precedence;
import "../grammar/token.dart" show Token;

abstract class AstVisitor<E> {
    E visitDocument(Document node);
    E visitInline(Inline node);
    E visitScript(Script node);
    E visitBlock(Block node);
    E visitVariableDeclarationStatement(VariableDeclarationStatement node);
    E visitTypeName(TypeName node);
    E visitExpressionStatement(ExpressionStatement node);
    E visitAssignmentExpression(AssignmentExpression node);
    E visitBinaryExpression(BinaryExpression node);
    E visitUpdateExpression(UpdateExpression node);
    E visitSimpleIdentifier(SimpleIdentifier node);
    E visitBooleanLiteral(BooleanLiteral node);
    E visitStringLiteral(StringLiteral node);
    E visitIntegerLiteral(IntegerLiteral node);
    E visitFloatLiteral(FloatLiteral node);
    E visitAssignmentOperator(AssignmentOperator node);
    E visitBinaryOperator(BinaryOperator node);
    E visitUpdateOperator(UpdateOperator node);
}

abstract class Node extends SyntacticEntity {
    Token get beginToken;

    Token get endToken;

    @override
    int get offset {
        return this.beginToken.offset;
    }

    @override
    int get length {
        return this.endOffset - this.offset;
    }

    @override
    int get endOffset {
        return this.endToken.endOffset;
    }

    E accept<E>(AstVisitor<E> visitor);
}

class Document extends Node {
    List<DocumentEntity> _elements;

    Document(this._elements);

    List<DocumentEntity> get elements {
        return this._elements;
    }

    @override
    Token get beginToken {
        if(this.elements.isEmpty) return null;
        return this.elements.first.endToken;
    }

    @override
    Token get endToken {
        if(this.elements.isEmpty) return null;
        return this.elements.last.endToken;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitDocument(this);
    }
}

abstract class DocumentEntity extends Node {}

class Inline extends DocumentEntity {
    Token _token;

    Inline(this._token);

    String get raw {
        return this.token.lexeme;
    }

    Token get token {
        return this._token;
    }

    @override
    Token get beginToken {
        return this.token;
    }

    @override
    Token get endToken {
        return this.token;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitInline(this);
    }
}

class Script extends DocumentEntity {
    Block _block;
    Token _startTag, _endTag;

    Script(this._startTag, this._block, this._endTag);

    Token get startTag {
        return this._startTag;
    }

    Block get body {
        return this._block;
    }

    Token get endTag {
        return this._endTag;
    }

    @override
    Token get beginToken {
        return this.startTag;
    }

    @override
    Token get endToken {
        return this.endTag;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitScript(this);
    }
}

abstract class Statement extends Node {}

class Block extends Statement {
    List<Statement> _statements;
    Token _indentToken, _outdentToken;

    Block(this._indentToken, this._statements, this._outdentToken);

    List<Statement> get statements {
        return this._statements;
    }

    Token get indentToken {
        return this._indentToken;
    }

    Token get outdentToken {
        return this._outdentToken;
    }

    @override
    Token get beginToken {
        if(this.statements.isEmpty) return null;
        return this.statements.first.endToken;
    }

    @override
    Token get endToken {
        if(this.statements.isEmpty) return null;
        return this.statements.last.endToken;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitBlock(this);
    }
}

class VariableDeclarationStatement extends Statement {
    TypeAnnotation _type;
    SimpleIdentifier _name;
    Token _equal;
    Expression _initializer;

    VariableDeclarationStatement(this._type, this._name, [this._equal = null, this._initializer = null]);

    TypeAnnotation get type {
        return this._type;
    }

    SimpleIdentifier get name {
        return this._name;
    }

    Token get equal {
        return this._equal;
    }

    Expression get initializer {
        return this._initializer;
    }

    @override
    Token get beginToken {
        return this.type.beginToken;
    }

    @override
    Token get endToken {
        if(this.initializer != null) return this.initializer.endToken;
        return this.name.endToken;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitVariableDeclarationStatement(this);
    }
}

class ExpressionStatement extends Statement {
    Expression _expression;

    ExpressionStatement(this._expression);

    Expression get expression {
        return this._expression;
    }

    @override
    Token get beginToken {
        return this.expression.beginToken;
    }

    @override
    Token get endToken {
        return this.expression.endToken;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitExpressionStatement(this);
    }
}

abstract class TypeAnnotation extends Node {

}

class TypeName extends TypeAnnotation {
    Identifier _name;

    TypeName(this._name);

    Identifier get name {
        return this._name;
    }

    @override
    Token get beginToken {
        return this.name.beginToken;
    }

    @override
    Token get endToken {
        return this.name.endToken;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitTypeName(this);
    }
}

abstract class Expression extends Node {}

class AssignmentExpression extends Expression {
    Expression _left, _right;
    AssignmentOperator _operator;

    AssignmentExpression(this._left, this._operator, this._right);

    Expression get left {
        return this._left;
    }

    AssignmentOperator get operat0r {
        return this._operator;
    }

    Expression get right {
        return this._right;
    }

    @override
    Token get beginToken {
        return this.left.beginToken;
    }

    @override
    Token get endToken {
        return this.right.endToken;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitAssignmentExpression(this);
    }
}

class BinaryExpression extends Expression {
    Expression _left, _right;
    BinaryOperator _operator;

    BinaryExpression(this._left, this._operator, this._right);

    Expression get left {
        return this._left;
    }

    BinaryOperator get operat0r {
        return this._operator;
    }

    Expression get right {
        return this._right;
    }

    @override
    Token get beginToken {
        return this.left.beginToken;
    }

    @override
    Token get endToken {
        return this.right.endToken;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitBinaryExpression(this);
    }
}

class UpdateExpression extends Expression {
    bool _prefix;
    Expression _argument;
    UpdateOperator _operator;

    UpdateExpression(this._argument, this._operator, this._prefix);

    bool get prefix {
        return this._prefix;
    }

    UpdateOperator get operat0r {
        return this._operator;
    }

    Expression get argument {
        return this._argument;
    }

    @override
    Token get beginToken {
        if(this.prefix) return this.operat0r.beginToken;
        return this.argument.beginToken;
    }

    @override
    Token get endToken {
        if(this.prefix) return this.argument.endToken;
        return this.operat0r.endToken;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitUpdateExpression(this);
    }
}

abstract class Identifier extends Expression {
    String get name;
}

class SimpleIdentifier extends Identifier {
    Token _token;

    SimpleIdentifier(this._token);

    @override
    String get name {
        return this.token.lexeme;
    }

    Token get token {
        return this._token;
    }

    @override
    Token get beginToken {
        return this.token;
    }

    @override
    Token get endToken {
        return this.token;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitSimpleIdentifier(this);
    }
}

abstract class Literal extends Expression {
    Token get token;

    @override
    Token get beginToken {
        return this.token;
    }

    @override
    Token get endToken {
        return this.token;
    }
}

class BooleanLiteral extends Literal {
    Token _token;

    BooleanLiteral(this._token);

    bool get value {
        return this.token.lexeme == "true";
    }

    @override
    Token get token {
        return this._token;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitBooleanLiteral(this);
    }
}

class StringLiteral extends Literal {
    Token _token;

    StringLiteral(this._token);

    String get value {
        return this.token.lexeme;
    }

    @override
    Token get token {
        return this._token;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitStringLiteral(this);
    }
}

abstract class NumericLiteral extends Literal {}

class IntegerLiteral extends NumericLiteral {
    Token _token;

    IntegerLiteral(this._token);

    String get value {
        return this.token.lexeme;
    }

    @override
    Token get token {
        return this._token;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitIntegerLiteral(this);
    }
}

class FloatLiteral extends NumericLiteral {
    Token _token;

    FloatLiteral(this._token);

    String get value {
        return this.token.lexeme;
    }

    @override
    Token get token {
        return this._token;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitFloatLiteral(this);
    }
}

abstract class Operator extends Node {
    Token get token;

    String get lexeme {
        return this.token.lexeme;
    }

    Precedence get precedence {
        return this.token.precedence;
    }

    @override
    Token get beginToken {
        return this.token;
    }

    @override
    Token get endToken {
        return this.token;
    }
}

class AssignmentOperator extends Operator {
    Token _token;

    AssignmentOperator(this._token);

    @override
    Token get token {
        return this._token;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitAssignmentOperator(this);
    }
}

class BinaryOperator extends Operator {
    Token _token;

    BinaryOperator(this._token);

    @override
    Token get token {
        return this._token;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitBinaryOperator(this);
    }
}

class UpdateOperator extends Operator {
    Token _token;

    UpdateOperator(this._token);

    @override
    Token get token {
        return this._token;
    }

    @override
    E accept<E>(AstVisitor<E> visitor) {
        return visitor.visitUpdateOperator(this);
    }
}
