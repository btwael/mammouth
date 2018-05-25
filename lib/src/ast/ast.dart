import "../grammar/syntacticEntity.dart" show SyntacticEntity;
import "../grammar/token.dart" show Token;

abstract class AstVisitor<E> {
    E visitDocument(Document node);
    E visitInline(Inline node);
    E visitScript(Script node);
    E visitBlock(Block node);
    E visitVariableDeclarationStatement(VariableDeclarationStatement node);
    E visitExpressionStatement(ExpressionStatement node);
    E visitSimpleIdentifier(SimpleIdentifier node);
    E visitTypeName(TypeName node);
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

abstract class Identifier extends Expression {
    String get name;
}

class SimpleIdentifier extends Identifier {
    Token _token;

    SimpleIdentifier(this._token);

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
