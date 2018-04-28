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

    Option<ast.Document> _parseDocument() {
        List<ast.DocumentEntity> elements = <ast.DocumentEntity>[];
        while(this._current != null) {
            if(this._current.kind.kindOf(TokenKind.INLINE)) {
                Option<ast.Inline> result = this._parseInline();
                if(result.isNone()) {
                    // TODO:: error already reported
                }
                elements.add(result.some);
            } else if(this._current.kind.kindOf(TokenKind.STARTTAG)) {
                Option<ast.MammouthScript> result = this._parseMammouthScript();
                if(result.isNone()) {
                    // TODO:: error already reported
                }
                elements.add(result.some);
            } else {
                // TODO: report error
            }
        }
        return new Option()..some = new ast.Document(elements);
    }

    Option<ast.Inline> _parseInline([bool reportError = true]) {
        Token token;
        if(!this._current.kind.kindOf(TokenKind.INLINE)) {
            // TODO: report error
        }
        token = this._current;
        // MARK(MOVE TOKEN)
        this._current = this._current.next;
        // MARK(MAKE NODE)
        return new Option()..some = new ast.Inline(token);
    }

    Option<ast.MammouthScript> _parseMammouthScript([bool reportError = true]) {
        
    }
}
