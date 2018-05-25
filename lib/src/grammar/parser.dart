import "../basic/option.dart" show Option;
import "../diagnostic/diagnosticEngine.dart" show DiagnosticEngine;
import "../ast/ast.dart" as ast;
import "./token.dart" show TokenKind, Token;

class Parser {
    Token _current;

    DiagnosticEngine _diagnosticEngine;

    Parser(this._diagnosticEngine);

    void setInput(List<Token> input) {
        this._current = input.first;
    }

    Option<ast.Document> parseDocument() {
        List<ast.DocumentEntity> elements = <ast.DocumentEntity>[];
        while(this._current != null) {
            if(this._current.kind.kindOf(TokenKind.INLINE)) {
                Option<ast.Inline> result = this.parseInline();
                if(result.isNone()) {
                    // TODO:: error already reported
                    return new Option<ast.Document>();
                }
                elements.add(result.some);
            } else if(this._current.kind.kindOf(TokenKind.STARTTAG)) {
                Option<ast.Script> result = this.parseScript();
                if(result.isNone()) {
                    // TODO:: error already reported
                    return new Option<ast.Document>();
                }
                elements.add(result.some);
            } else if(this._current.kind.kindOf(TokenKind.EOS)) {
                this._current = this._current.next;
                continue;
            } else {
                // TODO: report error
            }
        }
        return new Option()..some = new ast.Document(elements);
    }

    Option<ast.Inline> parseInline([bool reportError = true]) {
        Token token;
        if(!this._current.kind.kindOf(TokenKind.INLINE)) {
            // TODO: report error
            return new Option<ast.Inline>();
        }
        token = this._current;
        // MARK(MOVE TOKEN)
        this._current = this._current.next;
        // MARK(MAKE NODE)
        return new Option<ast.Inline>()..some = new ast.Inline(token);
    }

    Option<ast.Script> parseScript([bool reportError = true]) {
        ast.Block block;
        Token startTag, endTag;
        if(!this._current.kind.kindOf(TokenKind.STARTTAG)) {
            // TODO: throw an error
            return new Option<ast.Script>();
        }
        startTag = this._current;
        // MARK(MOVE TOKEN)
        this._current = this._current.next;
        Option<ast.Block> result = this.parseBlock();
        if(result.isNone()) {
            // TODO: throw an error
            return new Option<ast.Script>();
        }
        block = result.some;
        if(!this._current.kind.kindOf(TokenKind.ENDTAG)) {
            // TODO: throw an error
            return new Option<ast.Script>();
        }
        endTag = this._current;
        // MARK(MOVE TOKEN)
        this._current = this._current.next;
        // MARK(MAKE NODE)
        return new Option<ast.Script>()..some = new ast.Script(startTag, block, endTag);
    }

    Option<ast.Block> parseBlock() {
        Token indentToken, outdentToken;
        List<ast.Statement> statements = new List<ast.Statement>();
        if(!this._current.kind.kindOf(TokenKind.INDENT)) {
            // TODO: throw an error
            return new Option<ast.Block>();
        }
        indentToken = this._current;
        // MARK(MOVE TOKEN)
        this._current = this._current.next;
        while(this._current != null && !this._current.kind.kindOf(TokenKind.OUTDENT)) {
            Option<ast.Statement> result = this.parseStatement();
            if(result.isNone()) {
                // TODO: throw an error
                return new Option<ast.Block>();
            }
            statements.add(result.some);
            if(!this._current.kind.kindOf(TokenKind.OUTDENT)) {
                if(!this._current.kind.kindOf(TokenKind.MIDENT)) {
                    // TODO: throw an error
                    return new Option<ast.Block>();
                }
            }
        }
        if(!this._current.kind.kindOf(TokenKind.OUTDENT)) {
            // TODO: throw an error
            return new Option<ast.Block>();
        }
        outdentToken = this._current;
        // MARK(MOVE TOKEN)
        this._current = this._current.next;
        // MARK(MAKE NODE)
        return new Option<ast.Block>()..some = new ast.Block(indentToken, statements, outdentToken);
    }

    Option<ast.Statement> parseStatement() {
        return this.parseVariableDeclarationOrExpressionStatement();
    }

    Option<ast.Statement> parseVariableDeclarationOrExpressionStatement() {
        Token startToken = this._current;

        // first, we try to parse a type, without reporting error
        Option<ast.TypeAnnotation> typeResult = this.parseTypeName(false); // TODO: to parseTypeAnnotation
        if(typeResult.isSome()) {
            ast.TypeAnnotation type = typeResult.some;

            // if a type is parsed, we try to parse a name, without reporting error
            Option<ast.SimpleIdentifier> nameResult = this.parseSimpleIdentifier(false);
            if(nameResult.isSome()) {
                return this.parseVariableDeclarationStatement(type, nameResult.some);
            }
        }

        // MARK(MAKE NODE)
        this._current = startToken;
        // TODO: report manage error
        return this.parseExpressionStatement();
    }

    Option<ast.VariableDeclarationStatement> parseVariableDeclarationStatement(ast.TypeAnnotation type, ast.SimpleIdentifier name) {
        if(this._current != null && this._current.kind.kindOf(TokenKind.EQUALASSIGN)) {
            Token equal = this._current;
            // MARK(MOVE TOKEN)
            this._current = this._current.next;
            Option<ast.Expression> expressionResult = this.parseSimpleIdentifier(); // TODO: to parseExpression
            if(expressionResult.isNone()) {
                // TODO: report error
                return new Option<ast.VariableDeclarationStatement>();
            }
            return new Option<ast.VariableDeclarationStatement>()..some = new ast.VariableDeclarationStatement(type, name, equal, expressionResult.some);
        }
        return new Option<ast.VariableDeclarationStatement>()..some = new ast.VariableDeclarationStatement(type, name); 
    }

    Option<ast.ExpressionStatement> parseExpressionStatement() {
        Option<ast.Expression> result = this.parseSimpleIdentifier();
        if(result.isNone()) {

        }
        // MARK(MAKE NODE)
        return new Option()..some = new ast.ExpressionStatement(result.some);
    }

    Option<ast.TypeName> parseTypeName([bool reportError = true]) {
        Option<ast.SimpleIdentifier> result = this.parseSimpleIdentifier();
        if(result.isNone()) {
            // TODO: report error
            return new Option<ast.TypeName>();
        }
        // MARK(MAKE NODE)
        return new Option<ast.TypeName>()..some = new ast.TypeName(result.some);
    }

    Option<ast.SimpleIdentifier> parseSimpleIdentifier([bool reportError = true]) {
        Token token;
        if(!this._current.kind.kindOf(TokenKind.NAME)) {
            // TODO: report error
            return new Option<ast.SimpleIdentifier>();
        }
        // MARK(MAKE NODE)
        token = this._current;
        // MARK(MOVE TOKEN)
        this._current = this._current.next;
        return new Option<ast.SimpleIdentifier>()..some = new ast.SimpleIdentifier(token);
    }
}
