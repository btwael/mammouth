import "../grammar/syntacticEntity.dart" show SyntacticEntity;
import "../grammar/token.dart" show Token;

abstract class AstVisitor<E> {
    E visitDocument(Document node);
    E visitInline(Inline node);
    E visitMammouthScript(MammouthScript node);
    E visitBlock(Block node);
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
        return this.endToken.offset + this.endToken.length;
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

abstract class MammouthScript extends DocumentEntity {
    Token get startTag;

    Block get body;

    Token get endTag;

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
        return visitor.visitMammouthScript(this);
    }
}

abstract class Statement extends Node {}

abstract class Block extends Statement {
    List<Statement> get statements;

    Token get indentToken;

    Token get outdentToken;

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

abstract class VariableDeclarationStatement extends Statement {
    VariableDeclarationList get variables;
}

abstract class VariableDeclarationList extends Node {
    TypeAnnotation get type;

    List<VariableDeclaration> get variables;
}

abstract class VariableDeclaration extends Node {
    Identifier get name;

    Token get equal;

    Expression get initializer;
}

abstract class Expression extends Node {}

abstract class Identifier extends Node {
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

abstract class TypeAnnotation extends Node {}

abstract class TypeName extends TypeAnnotation {
    Identifier _identifier;

    TypeName(this._identifier);

    Identifier get name {
        return this._identifier;
    }

    @override
    Token get beginToken {
        return this.name.endToken;
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
