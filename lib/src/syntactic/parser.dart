import "package:mammouth/src/basic/option.dart" show Option;
import "package:mammouth/src/basic/source.dart" show Source;
import "package:mammouth/src/diagnostic/diagnosticEngine.dart"
    show DiagnosticEngine;
import "package:mammouth/src/diagnostic/error.dart" show AnalysisError;
import "package:mammouth/src/language/common/ast/ast.dart" as common;
import "package:mammouth/src/language/common/ast/implementation.dart" as common;
import "package:mammouth/src/language/common/ast/precedence.dart"
    show Precedence;
import "package:mammouth/src/language/common/ast/token.dart"
    show TokenKind, Token, SimpleToken;
import "package:mammouth/src/language/mammouth/ast/ast.dart" as mammouth;
import "package:mammouth/src/language/mammouth/ast/implementation.dart"
as mammouth;
import "package:mammouth/src/syntactic/errors.dart" show ParserErrorCode;

class Parser {
  Token _current;
  Source _source;

  DiagnosticEngine _diagnosticEngine;

  Parser(_diagnosticEngine);

  void setInput(Source source, Token input) {
    _source = source;
    _current = input;
  }

  /**
   *      Document := DocumentEntry* EOS
   */
  Option<common.Document> parseDocument({bool reportError = true}) {
    List<common.DocumentEntry> elements = new List<common.DocumentEntry>();
    // the end of the document is determined with an EOS token.
    while(!_isCurrentOfKind(TokenKind.EOS)) {
      // parse a DocumentElement
      Option<common.DocumentEntry> result =
      this.parseDocumentElement(reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // MARK(ERROR ALREADY REPORTED)
        }
        return new Option<common.Document>();
        // MARK(STOP PARSING)
      }
      elements.add(result.some);
    }
    // MARK(MAKE NODE)
    return new Option<common.Document>.Some(
        new common.DocumentImpl(elements, _current));
  }

  /**
   *      DocumentElement := (InlineEntry | Script)
   */
  Option<common.DocumentEntry> parseDocumentElement({bool reportError = true}) {
    if(_isCurrentOfKind(TokenKind.INLINE_ENTRY)) {
      // an InlineEntry consists always of one INLINE_ENTRY token.
      // parse InlineEntry
      return this.parseInlineEntry(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.START_TAG)) {
      // a Script starts always with a START_TAG
      // parse Script
      return this.parseScript(reportError: reportError);
    } else {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
    }
    return new Option<common.DocumentEntry>();
    // MARK(STOP PARSING)
  }

  /**
   *      InlineEntry := INLINE
   */
  Option<common.InlineEntry> parseInlineEntry({bool reportError = true}) {
    Token token;
    // consume INLINE
    if(!_isCurrentOfKind(TokenKind.INLINE_ENTRY)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<common.InlineEntry>();
      // MARK(STOP PARSING)
    }
    token = _current; // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<common.InlineEntry>.Some(
        new common.InlineEntryImpl(token));
  }

  /**
   *      Script := START_TAG (Block)? END_TAG
   */
  Option<mammouth.Script> parseScript({bool reportError = true}) {
    mammouth.Block block;
    Token startTag, endTag;
    // consume START_TAG
    if(!_isCurrentOfKind(TokenKind.START_TAG)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.Script>();
      // MARK(STOP PARSING)
    }
    startTag = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    if(!_isCurrentOfKind(TokenKind.END_TAG)) {
      // parse Block
      Option<mammouth.Block> result = this.parseBlock(
          allowInline: true, reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // MARK(ERROR ALREADY REPORTED)
        }
        return new Option<mammouth.Script>();
        // MARK(STOP PARSING)
      }
      block = result.some;
    } else {
      block = new mammouth.BlockImpl([]);
    }
    // consume END_TAG
    if(!_isCurrentOfKind(TokenKind.END_TAG)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        _reportExpected(TokenKind.END_TAG);
      }
      return new Option<mammouth.Script>();
      // MARK(STOP PARSING)
    }
    endTag = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.Script>.Some(
        new mammouth.ScriptImpl(startTag, block, endTag));
  }

  /**
   *      Block := INDENT Statement [MIDENT Statement]*  OUTDENT
   *             | Statement
   */
  Option<mammouth.Block> parseBlock(
      {bool allowInline = false, bool reportError = true}) {
    List<mammouth.Statement> statements = new List<mammouth.Statement>();
    if(allowInline && !_isCurrentOfKind(TokenKind.INDENT)) {
      Option<mammouth.ExpressionStatement> result =
      this.parseExpressionStatement(reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // MARK(ERROR ALREADY REPORTED)
        }
        return new Option<mammouth.Block>();
        // MARK(STOP PARSING)
      }
      // MARK(MAKE NODE)
      return new Option<mammouth.Block>.Some(
          new mammouth.BlockImpl([result.some]));
    }
    // consume INDENT
    if(!_isCurrentOfKind(TokenKind.INDENT)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        _reportExpected(TokenKind.INDENT);
      }
      return new Option<mammouth.Block>();
      // MARK(STOP PARSING)
    }
    _current = _current.next;
    // parse Statements := Statement [MIDENT Statement]*
    while(!_isCurrentOfKind(TokenKind.OUTDENT)) {
      Option<mammouth.Statement> result = this.parseStatement();
      if(result.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // MARK(ERROR ALREADY REPORTED)
        }
        // TODO: continuation
        return new Option<mammouth.Block>();
        // MARK(STOP PARSING)
      }
      statements.add(result.some);
      if(!_isCurrentOfKind(TokenKind.OUTDENT)) {
        if(!_isCurrentOfKind(TokenKind.MINDENT)) {
          if(reportError) {
            // MARK(REPORT ERROR)
            _reportExpected(TokenKind.MINDENT);
          }
          return new Option<mammouth.Block>();
          // MARK(STOP PARSING)
        }
        _current = _current.next; // MARK(MOVE TOKEN)
      }
    }
    // consume OUTDENT
    if(!_isCurrentOfKind(TokenKind.OUTDENT)) {
      // MARK(REPORT ERROR)
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable zone!";
      // MARK(STOP PARSING)
    }
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.Block>.Some(new mammouth.BlockImpl(statements));
  }

  /**
   *        Statement := Block
   *                   | ImportDirective
   *                   | InterfaceDeclaration
   *                   | VariableDeclarationOrExpressionStatement
   *                   | MaybeControlledStatement
   */
  Option<mammouth.Statement> parseStatement({bool reportError = true}) {
    // a block always starts with an INDENT
    if(_isCurrentOfKind(TokenKind.INDENT)) {
      // parse Block
      return this.parseBlock();
    } else if(_isCurrentOfKind(TokenKind.IMPORT)) {
      // parse Block
      return this.parseImportDirective(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.INTERFACE)) {
      // parse Block
      return this.parseInterfaceDeclaration();
    } else if(_isCurrentOfKind(TokenKind.BREAK) ||
        _isCurrentOfKind(TokenKind.CONTINUE) ||
        _isCurrentOfKind(TokenKind.RETURN) ||
        _isCurrentOfKind(TokenKind.THROW)) {
      return this.parseMaybeControlledStatement(reportError: reportError);
    }
    // parse VariableDeclarationOrExpressionStatement
    return this.parseVariableDeclarationOrExpressionStatement();
  }

  /**
   *        ImportDirective := IMPORT StringLiteral
   */
  Option<mammouth.ImportDirective> parseImportDirective(
      {bool reportError = true}) {
    Token importKeyword;
    if(!_isCurrentOfKind(TokenKind.IMPORT)) {
      // TODO: report error
      // MAYBE THIS IS UNREACHABLE
      return new Option<mammouth.ImportDirective>();
    }
    importKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.Expression> uriResult =
    this.parseStringLiteral(reportError: reportError);
    if(uriResult.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.ImportDirective>();
      // MARK(STOP PARSING)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.ImportDirective>.Some(
        new mammouth.ImportDirectiveImpl.syntactic(
            importKeyword, uriResult.some));
  }

  /**
   *        MaybeControlledStatement := SimpleStatement (ControlSource)?
   */
  Option<mammouth.Statement> parseMaybeControlledStatement(
      {bool reportError = true}) {
    Option<mammouth.Statement> statementResult =
    this.parseSimpleStatement(reportError: reportError);
    if(statementResult.isNone) {
      // TODO: report error
      return new Option<mammouth.Statement>();
    }
    if(_isCurrentOfKind(TokenKind.IF) || _isCurrentOfKind(TokenKind.UNLESS)) {
      Token elseKeyword;
      mammouth.Statement alternate;
      Option<mammouth.IfSource> sourceResult =
      parseIfSource(reportError: reportError);
      if(sourceResult.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // MARK(ERROR ALREADY REPORTED)
        }
        return new Option<mammouth.ExpressionStatement>();
        // MARK(STOP PARSING)
      }
      if(_isCurrentOfKind(TokenKind.ELSE)) {
        // consume ELSE
        elseKeyword = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        Option<mammouth.Statement> alternateResult =
        this.parseBlock(allowInline: true, reportError: reportError);
        if(alternateResult.isNone) {
          // TODO: report error
          return new Option<mammouth.ExpressionStatement>();
          // MARK(STOP PARSING)
        }
        alternate = alternateResult.some;
      }
      // MARK(MAKE NODE)
      statementResult = new Option.Some(new mammouth.ExpressionStatementImpl(
          new mammouth.IfExpressionImpl.syntactic(
              sourceResult.some, statementResult.some, elseKeyword,
              alternate)));
    } else if(_isCurrentOfKind(TokenKind.WHILE) ||
        _isCurrentOfKind(TokenKind.UNTIL)) {
      Option<mammouth.RepetitionSource> sourceResult =
      this.parseRepetitionSource(reportError: reportError);
      // MARK(MAKE NODE)
      statementResult = new Option.Some(new mammouth.ExpressionStatementImpl(
          new mammouth.RepetitionExpressionImpl(
              sourceResult.some, statementResult.some)));
    } else if(_isCurrentOfKind(TokenKind.FOR)) {
      Option<mammouth.ForSource> sourceResult =
      this.parseForSource(reportError: reportError);
      // MARK(MAKE NODE)
      statementResult = new Option.Some(new mammouth.ExpressionStatementImpl(
          new mammouth.ForExpressionImpl(
              sourceResult.some, statementResult.some)));
    }
    return statementResult;
  }

  /**
   *        SimpleStatement := BreakStatement
   *                         | ContinueStatement
   *                         | ReturnStatement
   */
  Option<mammouth.Statement> parseSimpleStatement({bool reportError = true}) {
    if(_isCurrentOfKind(TokenKind.BREAK)) {
      return this.parseBreakStatement(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.CONTINUE)) {
      return this.parseContinueStatement(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.RETURN)) {
      return this.parseReturnStatement(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.THROW)) {
      return this.parseThrowStatement(reportError: reportError);
    }
    // TODO: report error
    return new Option<mammouth.Statement>();
  }

  /**
   *        BreakStatement := BREAK
   */
  Option<mammouth.BreakStatement> parseBreakStatement(
      {bool reportError = true}) {
    if(!_isCurrentOfKind(TokenKind.BREAK)) {
      // TODO: report error
      // MAYBE THIS IS UNREACHABLE
      return new Option<mammouth.BreakStatement>();
    }
    Token breakKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.BreakStatement>.Some(
        new mammouth.BreakStatementImpl.syntactic(breakKeyword));
  }

  /**
   *        ContinueStatement := CONTINUE
   */
  Option<mammouth.ContinueStatement> parseContinueStatement(
      {bool reportError = true}) {
    if(!_isCurrentOfKind(TokenKind.CONTINUE)) {
      // TODO: report error
      // MAYBE THIS IS UNREACHABLE
      return new Option<mammouth.ContinueStatement>();
    }
    Token continueKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.ContinueStatement>.Some(
        new mammouth.ContinueStatementImpl.syntactic(continueKeyword));
  }

  /**
   *        ReturnStatement := RETURN (Expression)?
   */
  Option<mammouth.ReturnStatement> parseReturnStatement(
      {bool reportError = true}) {
    Token returnKeyword;
    mammouth.Expression expression;
    if(!_isCurrentOfKind(TokenKind.RETURN)) {
      // TODO: report error
      // MAYBE THIS IS UNREACHABLE
      return new Option<mammouth.ReturnStatement>();
    }
    returnKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    if(!_isCurrentOfKind(TokenKind.INDENTATION)) {
      Option<mammouth.Expression> initializerResult =
      this.parseExpression(reportError: true);
      if(initializerResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.ReturnStatement>();
        // MARK(STOP PARSING)
      }
      expression = initializerResult.some;
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.ReturnStatement>.Some(
        new mammouth.ReturnStatementImpl.syntactic(returnKeyword, expression));
  }

  /**
   *        ThrowStatement := THROW Expression
   */
  Option<mammouth.ThrowStatement> parseThrowStatement(
      {bool reportError = true}) {
    Token throwKeyword;
    if(!_isCurrentOfKind(TokenKind.THROW)) {
      // TODO: report error
      // MAYBE THIS IS UNREACHABLE
      return new Option<mammouth.ThrowStatement>();
    }
    throwKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.Expression> expressionResult =
    this.parseExpression(reportError: true);
    if(expressionResult.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.ThrowStatement>();
      // MARK(STOP PARSING)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.ThrowStatement>.Some(
        new mammouth.ThrowStatementImpl.syntactic(
            throwKeyword, expressionResult.some));
  }

  /**
   *          InterfaceDeclaration := INTERFACE SimpleIdentifier InterfaceBody
   *
   *          InterfaceBody := INDENT ClassMember (MINDENT ClassMember)* OUTDENT
   */
  Option<mammouth.InterfaceDeclaration> parseInterfaceDeclaration(
      {bool reportError = true}) {
    Token interfaceKeyword;
    mammouth.SimpleIdentifier name;
    mammouth.ImplementsClause implementsClause;
    List<mammouth.ClassMember> members = new List<mammouth.ClassMember>();
    // consume INTERFACE
    if(!_isCurrentOfKind(TokenKind.INTERFACE)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.InterfaceDeclaration>();
      // MARK(STOP PARSING)
    }
    interfaceKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.Expression> result =
    this.parseSimpleIdentifier(reportError: true);
    if(result.isNone) {
      if(reportError) {
        // MARK(REPORT ERROR)
        _reportErrorCode(
            ParserErrorCode.INVALID_CLASS_NAME, _current.offset, 0);
        // TODO: invalid interface name
      }
      return new Option<mammouth.InterfaceDeclaration>();
      // MARK(STOP PARSING)
    }
    name = result.some;
    if(_isCurrentOfKind(TokenKind.IMPLEMENTS)) {
      Option<mammouth.ImplementsClause> implementsResult =
      this.parseImplementsClause(reportError: reportError);
      if(implementsResult.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // TODO: report error
        }
        return new Option<mammouth.InterfaceDeclaration>();
        // MARK(STOP PARSING)
      }
      implementsClause = implementsResult.some;
    }
    // parse INDENT
    if(!_isCurrentOfKind(TokenKind.INDENT)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        _reportErrorCode(
            ParserErrorCode.INVALID_CLASS_NAME, _current.offset, 0);
      }
      return new Option<mammouth.InterfaceDeclaration>();
      // MARK(STOP PARSING)
    }
    _current = _current.next; // MARK(MOVE TOKEN)
    // parse interface members := ClassMember (MINDENT ClassMember)*
    while(!_isCurrentOfKind(TokenKind.OUTDENT)) {
      // parse ClassMember
      Option<mammouth.ClassMember> result =
      this.parseClassMember(reportError: reportError);
      if(result.isNone) {
        // MARK(REPORT ERROR)
        // MARK(ERROR ALREADY REPORTED)
        return new Option<mammouth.InterfaceDeclaration>();
        // MARK(STOP PARSING)
      }
      members.add(result.some);
      if(!_isCurrentOfKind(TokenKind.OUTDENT)) {
        if(!_isCurrentOfKind(TokenKind.MINDENT)) {
          if(reportError) {
            // MARK(REPORT ERROR)
            _reportExpected(TokenKind.MINDENT);
          }
          return new Option<mammouth.InterfaceDeclaration>();
          // MARK(STOP PARSING)
        }
        _current = _current.next; // MARK(MOVE TOKEN)
      }
    }
    // parse OUTDENT
    if(!_isCurrentOfKind(TokenKind.OUTDENT)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        _reportExpected(TokenKind.MINDENT);
      }
      return new Option<mammouth.InterfaceDeclaration>();
      // MARK(STOP PARSING)
    }
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.InterfaceDeclaration>.Some(
        new mammouth.InterfaceDeclarationImpl.syntactic(
            interfaceKeyword, name, implementsClause, members));
  }

  /**
   *      ImplementsClause := IMPLEMENTS TypeName (COMMA TypeName)*
   */
  Option<mammouth.ImplementsClause> parseImplementsClause(
      {bool reportError = true}) {
    Token implementsKeyword;
    List<mammouth.TypeName> interfaces = <mammouth.TypeName>[];
    // consume EXTENDS
    if(!_isCurrentOfKind(TokenKind.IMPLEMENTS)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.ImplementsClause>();
      // MARK(STOP PARSING)
    }
    implementsKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    do {
      Option<mammouth.TypeName> interfaceResult =
      this.parseTypeName(reportError: reportError);
      if(interfaceResult.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // TODO: report error
        }
        return new Option<mammouth.ImplementsClause>();
        // MARK(STOP PARSING)
      }
      interfaces.add(interfaceResult.some);
    } while(_isCurrentOfKind(TokenKind.COMMA));
    // MARK(MAKE NODE)
    return new Option<mammouth.ImplementsClause>.Some(
        new mammouth.ImplementsClauseImpl.syntactic(
            implementsKeyword, interfaces));
  }

  /**
   *      VariableDeclarationOrExpressionStatement := VariableDeclarationStatement
   *                                                | ExpressionStatement
   */
  Option<mammouth.Statement> parseVariableDeclarationOrExpressionStatement(
      {bool reportError = true}) {
    // keeps the start state, so if we fail to parse a VariableDeclarationStatement,
    // we return to the start state and try to parse an ExpressionStatement
    Token startToken = _current;

    // Try to parse the type of the variable in the VariableDeclarationStatement
    Option<mammouth.TypeAnnotation> typeResult =
    this.parseTypeAnnotation(reportError: false);
    if(typeResult.isSome) {
      mammouth.TypeAnnotation type = typeResult.some;

      // if this is a VariableDeclarationStatement, we should be able to
      // parse the name of the declared variable
      Option<mammouth.SimpleIdentifier> nameResult =
      this.parseSimpleIdentifier(reportError: false);
      if(nameResult.isSome) {
        if(_isCurrentOfKind(TokenKind.LEFT_PAREN) ||
            _isCurrentOfKind(TokenKind.RIGHT_ARROW)) {
          Option<mammouth.Expression> expressionResult = this
              .parseFunctionExpression(
              returnType: typeResult.some,
              name: nameResult.some,
              reportError: false);
          if(expressionResult.isSome) {
            // MARK(MAKE NODE)
            return new Option<mammouth.Statement>.Some(
                new mammouth.ExpressionStatementImpl(expressionResult.some));
          }
        }
        // finalize the parse of the VariableDeclarationStatement
        return this.parseVariableDeclarationStatement(type, nameResult.some);
      }
    }

    // Returns to the start state, and parse an ExpressionStatement
    _current = startToken;
    return this.parseExpressionStatement();
  }

  /**
   *      VariableDeclarationStatement := TypeAnnotation SimpleIdentifier (ASSIGN_EQUAL Expression)?
   */
  Option<mammouth.VariableDeclarationStatement>
  parseVariableDeclarationStatement(mammouth.TypeAnnotation type,
      mammouth.SimpleIdentifier name,
      {bool reportError = true}) {
    Token equal;
    mammouth.Expression initializer;
    // if we reach an ASSIGN_EQUAL at this point, then this variable declaration
    // is initialized with an expression value
    if(_isCurrentOfKind(TokenKind.ASSIGN_EQUAL)) {
      //  consume ASSIGN_EQUAL
      equal = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
      // parse Expression
      Option<mammouth.Expression> initializerResult =
      this.parseExpression(reportError: false);
      if(initializerResult.isNone) {
        if(reportError) {
          // it's illegal to not be able to parse an initializing
          // expression after ASSIGN_EQUAL
          // MARK(REPORT ERROR)
          _reportErrorCode(ParserErrorCode.EXPECTED_EXPRESSION_AFTER_EQUAL,
              equal.endOffset, 0);
        }
        return new Option<mammouth.VariableDeclarationStatement>();
        // MARK(STOP PARSING)
      }
      initializer = initializerResult.some;
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.VariableDeclarationStatement>.Some(
        new mammouth.VariableDeclarationStatementImpl.syntactic(
            type, name, equal, initializer));
  }

  /**
   *      ExpressionStatement := Expression (ControlSource)?
   */
  Option<mammouth.ExpressionStatement> parseExpressionStatement(
      {bool reportError = true}) {
    mammouth.Expression expression;
    // parse Expression
    Option<mammouth.Expression> result =
    this.parseExpression(allowControl: false, reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(ERROR ALREADY REPORTED)
      }
      return new Option<mammouth.ExpressionStatement>();
      // MARK(STOP PARSING)
    }
    expression = result.some;
    if(_isCurrentOfKind(TokenKind.IF) || _isCurrentOfKind(TokenKind.UNLESS)) {
      Token elseKeyword;
      mammouth.Statement alternate;
      Option<mammouth.IfSource> sourceResult =
      parseIfSource(reportError: reportError);
      if(sourceResult.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // MARK(ERROR ALREADY REPORTED)
        }
        return new Option<mammouth.ExpressionStatement>();
        // MARK(STOP PARSING)
      }
      if(_isCurrentOfKind(TokenKind.ELSE)) {
        // consume ELSE
        elseKeyword = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        Option<mammouth.Statement> alternateResult =
        this.parseBlock(allowInline: true, reportError: reportError);
        if(alternateResult.isNone) {
          // TODO: report error
          return new Option<mammouth.ExpressionStatement>();
          // MARK(STOP PARSING)
        }
        alternate = alternateResult.some;
      }
      // MARK(MAKE NODE)
      expression = new mammouth.IfExpressionImpl.syntactic(
          sourceResult.some,
          new mammouth.ExpressionStatementImpl(expression),
          elseKeyword,
          alternate);
    } else if(_isCurrentOfKind(TokenKind.WHILE) ||
        _isCurrentOfKind(TokenKind.UNTIL)) {
      Option<mammouth.RepetitionSource> sourceResult =
      this.parseRepetitionSource(reportError: reportError);
      // MARK(MAKE NODE)
      expression = new mammouth.RepetitionExpressionImpl(
          sourceResult.some, new mammouth.ExpressionStatementImpl(expression));
    } else if(_isCurrentOfKind(TokenKind.FOR)) {
      Option<mammouth.ForSource> sourceResult =
      this.parseForSource(reportError: reportError);
      // MARK(MAKE NODE)
      expression = new mammouth.ForExpressionImpl(
          sourceResult.some, new mammouth.ExpressionStatementImpl(expression));
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.ExpressionStatement>.Some(
        new mammouth.ExpressionStatementImpl(expression));
  }

  /**
   *      Expression := ClassExpression
   *                  | FunctionExpression
   *                  | IfExpression
   *                  | RepetitionExpression
   *                  | ForExpression
   *                  | TryExpression
   *                  | MaybeControlledExpresssion
   */
  Option<mammouth.Expression> parseExpression(
      {bool allowControl = true, bool reportError = true}) {
    if(_isCurrentOfKind(TokenKind.CLASS)) {
      // Only class declaration expression starts with CLASS.
      // parse ClassExpression
      return this.parseClassExpression(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.IF) ||
        _isCurrentOfKind(TokenKind.UNLESS)) {
      // Only an if expression starts with IF.
      // parse IfExpression
      return this.parseIfExpression(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.WHILE) ||
        _isCurrentOfKind(TokenKind.UNTIL) ||
        _isCurrentOfKind(TokenKind.LOOP)) {
      // Only an repetition expression starts with WHILE, UNTIL or LOOP.
      // parse RepetitionExpression
      return this.parseRepetitionExpression(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.FOR)) {
      // Only an for expression starts with FOR.
      // parse ForExpression
      return this.parseForExpression(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.TRY)) {
      // Only a try expression starts with TRY.
      // parse TryExpression
      return this.parseTryExpression(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.SWITCH)) {
      // Only a switch expression starts with SWITCH.
      // parse SwitchExpression
      return this.parseSwitchExpression(reportError: reportError);
    }

    // keeps the start state, so if we fail to parse a FunctionExpression
    // that starts with a return type declaration, we return to the start
    // state and try to parse a MaybeControlledExpresssion
    Token startToken = _current;

    // Try to parse the return type of the FunctionExpression
    Option<mammouth.TypeAnnotation> typeResult =
    this.parseTypeAnnotation(reportError: false);
    if(typeResult.isSome) {
      mammouth.TypeAnnotation type = typeResult.some;

      // if this is a FunctionExpression, we may be able to parse the
      // optional name of the declared function
      Option<mammouth.SimpleIdentifier> nameResult =
      this.parseSimpleIdentifier(reportError: false);
      if(nameResult.isSome) {
        // if this is a FunctionExpression, after the name, only LEFT_PAREN
        // and RIGHT_ARROW maybe found.
        if(_isCurrentOfKind(TokenKind.LEFT_PAREN) ||
            _isCurrentOfKind(TokenKind.RIGHT_ARROW)) {
          return this.parseFunctionExpression(
              returnType: type, name: nameResult.some, reportError: false);
        }
      } else if(_isCurrentOfKind(TokenKind.LEFT_PAREN) ||
          _isCurrentOfKind(TokenKind.RIGHT_ARROW)) {
        // some function are anonymous, so after return type, only
        // LEFT_PAREN and RIGHT_ARROW maybe found.
        Option<mammouth.FunctionExpression> funcResult =
        this.parseFunctionExpression(returnType: type, reportError: false);
        if(funcResult.isSome) {
          return funcResult;
        }
      }
    }

    // Returns to the start state, and parse an MaybeControlledExpresssion
    _current = startToken;
    return this.parseMaybeControlledExpresssion(
        allowControl: allowControl, reportError: reportError);
  }

  /**
   * ClassExpression := CLASS (SimpleIdentifier)? ClassBody
   *
   * ClassBody := INDENT ClassMember (MINDENT ClassMember)* OUTDENT
   */
  Option<mammouth.ClassExpression> parseClassExpression(
      {bool reportError = true}) {
    Token classKeyword;
    mammouth.SimpleIdentifier name;
    mammouth.TypeParameterList typeParameters;
    mammouth.ExtendsClause extendsClause;
    mammouth.ImplementsClause implementsClause;
    List<mammouth.ClassMember> members = new List<mammouth.ClassMember>();
    // consume CLASS
    if(!_isCurrentOfKind(TokenKind.CLASS)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.ClassExpression>();
      // MARK(STOP PARSING)
    }
    classKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // Anonymous class are allowed, so class names are optional.
    if(_isCurrentOfKind(TokenKind.NAME)) {
      // parse the class name = SimpleIdentifier
      Option<mammouth.Expression> result =
      this.parseSimpleIdentifier(reportError: false);
      if(result.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          _reportErrorCode(
              ParserErrorCode.INVALID_CLASS_NAME, _current.offset, 0);
        }
        return new Option<mammouth.ClassExpression>();
        // MARK(STOP PARSING)
      }
      name = result.some;
      if(_isCurrentOfKind(TokenKind.LESS_THAN)) {
        Option<mammouth.TypeParameterList> typeParameterResult = this
            .parseTypeParameterList(reportError: reportError);
        if(typeParameterResult.isNone) {
          if(reportError) {
            // TODO: report error
          }
        }
        typeParameters = typeParameterResult.some;
      }
    }
    if(_isCurrentOfKind(TokenKind.EXTENDS)) {
      Option<mammouth.ExtendsClause> extendsResult =
      this.parseExtendsClause(reportError: reportError);
      if(extendsResult.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // TODO: report error
        }
        return new Option<mammouth.ClassExpression>();
        // MARK(STOP PARSING)
      }
      extendsClause = extendsResult.some;
    }
    if(_isCurrentOfKind(TokenKind.IMPLEMENTS)) {
      Option<mammouth.ImplementsClause> implementsResult =
      this.parseImplementsClause(reportError: reportError);
      if(implementsResult.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // TODO: report error
        }
        return new Option<mammouth.ClassExpression>();
        // MARK(STOP PARSING)
      }
      implementsClause = implementsResult.some;
    }
    // parse INDENT
    if(!_isCurrentOfKind(TokenKind.INDENT)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        _reportErrorCode(
            ParserErrorCode.INVALID_CLASS_NAME, _current.offset, 0);
      }
      return new Option<mammouth.ClassExpression>();
      // MARK(STOP PARSING)
    }
    _current = _current.next; // MARK(MOVE TOKEN)
    // parse class members := ClassMember (MINDENT ClassMember)*
    while(!_isCurrentOfKind(TokenKind.OUTDENT)) {
      // parse ClassMember
      Option<mammouth.ClassMember> result =
      this.parseClassMember(reportError: reportError);
      if(result.isNone) {
        // MARK(REPORT ERROR)
        // MARK(ERROR ALREADY REPORTED)
        return new Option<mammouth.ClassExpression>();
        // MARK(STOP PARSING)
      }
      members.add(result.some);
      if(!_isCurrentOfKind(TokenKind.OUTDENT)) {
        if(!_isCurrentOfKind(TokenKind.MINDENT)) {
          if(reportError) {
            // MARK(REPORT ERROR)
            _reportExpected(TokenKind.MINDENT);
          }
          return new Option<mammouth.ClassExpression>();
          // MARK(STOP PARSING)
        }
        _current = _current.next; // MARK(MOVE TOKEN)
      }
    }
    // parse OUTDENT
    if(!_isCurrentOfKind(TokenKind.OUTDENT)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        _reportExpected(TokenKind.MINDENT);
      }
      return new Option<mammouth.ClassExpression>();
      // MARK(STOP PARSING)
    }
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.ClassExpression>.Some(
        new mammouth.ClassExpressionImpl.syntactic(
            classKeyword, name, typeParameters, extendsClause, implementsClause,
            members));
  }

  /**
   *      ExtendsClause := EXTENDS TypeName
   */
  Option<mammouth.ExtendsClause> parseExtendsClause({bool reportError = true}) {
    Token extendsKeyword;
    // consume EXTENDS
    if(!_isCurrentOfKind(TokenKind.EXTENDS)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.ExtendsClause>();
      // MARK(STOP PARSING)
    }
    extendsKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.TypeName> superclassResult = this.parseTypeName(
        reportError: reportError);
    if(superclassResult.isNone) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // TODO: report error
      }
      return new Option<mammouth.ExtendsClause>();
      // MARK(STOP PARSING)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.ExtendsClause>.Some(
        new mammouth.ExtendsClauseImpl.syntactic(
            extendsKeyword, superclassResult.some));
  }

  /**
   *      ClassMember := (Visibility)? ConstructorDeclaration
   *                   | (Visibility)? FieldDeclaration
   *                   | (Visibility)? MethodDeclaration
   */
  Option<mammouth.ClassMember> parseClassMember({bool reportError = true}) {
    Token abstractKeyword;
    Token visibility;
    Token staticToken;

    // Parse abstract if it's given
    if(_isCurrentOfKind(TokenKind.ABSTRACT)) {
      // consume visibility token
      abstractKeyword = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
    }

    // Parse visibility if it's given
    if(_isCurrentOfKind(TokenKind.PRIVATE) ||
        _isCurrentOfKind(TokenKind.PROTECTED) ||
        _isCurrentOfKind(TokenKind.PUBLIC)) {
      // consume visibility token
      visibility = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
    }

    // Parse static if it's given
    if(_isCurrentOfKind(TokenKind.STATIC)) {
      // consume STATIC
      staticToken = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
    }

    if(_isCurrentOfKind(TokenKind.CONSTRUCTOR)) {
      // Only an constructor declaration starts with CONSTRUCTOR.
      // parse ConstructorDeclaration
      return this.parseConstructorDeclaration(
          visibility: visibility, reportError: reportError);
    }

    // keeps the start state, so if we fail to parse a MethodDeclaration or
    // a FieldDeclaration that starts with a return type declaration, we
    // return to the start state and try to parse a FieldDeclaration
    Token startToken = _current;

    // Try to parse the return type of the MethodDeclaration that may also
    // be the type of a FieldDeclaration
    Option<mammouth.TypeAnnotation> typeResult = this.parseTypeAnnotation(
        reportError: false);
    if(typeResult.isSome) {
      mammouth.TypeAnnotation type = typeResult.some;

      if(_isCurrentOfKind(TokenKind.TO)) {
        Token toKeyword = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        return this.parseConverterDeclaration(
            abstractKeyword: abstractKeyword,
            visibility: visibility,
            returnType: type,
            toKeyword: toKeyword,
            reportError: true);
      }

      Token propertyKeyword, operatorKeyword;
      Option<mammouth.SimpleIdentifier> nameResult = this.parseSimpleIdentifier(
          reportError: false);
      if(nameResult.isSome &&
          (nameResult.some.name == "get" || nameResult.some.name == "set")) {
        if(_isCurrentOfKind(TokenKind.NAME)) {
          propertyKeyword = nameResult.some.token;
        }
      } else if(nameResult.isSome &&
          (nameResult.some.name == "operator" ||
              nameResult.some.name == "prefix" ||
              nameResult.some.name == "postfix")) {
        if(this.isBinaryOperator() ||
            this.isUnaryOperator() ||
            this.isUpdateOperator() ||
            _isCurrentOfKind(TokenKind.LEFT_BRACKET)) {
          operatorKeyword = nameResult.some.token;
          return this.parseMethodDeclaration(
              abstractKeyword: abstractKeyword,
              visibility: visibility,
              staticToken: staticToken,
              operatorKeyword: operatorKeyword,
              returnType: type,
              reportError: true);
        }
      }

      // if this is a MethodDelaration, we should be able to parse the name
      // of the declared method
      if(propertyKeyword != null) {
        nameResult = this.parseSimpleIdentifier(reportError: false);
      }
      if(nameResult.isSome) {
        if(_isCurrentOfKind(TokenKind.LEFT_PAREN) ||
            _isCurrentOfKind(TokenKind.RIGHT_ARROW) ||
            _isCurrentOfKind(TokenKind.INLINE)) {
          // if the name is followed with LEFT_PAREN or a RIGHT_ARROW
          // only a method declaration is expected
          return this.parseMethodDeclaration(
              abstractKeyword: abstractKeyword,
              visibility: visibility,
              staticToken: staticToken,
              returnType: type,
              propertyKeyword: propertyKeyword,
              name: nameResult.some,
              reportError: true);
        } else {
          // if the name is not followed with LEFT_PAREN or a RIGHT_ARROW
          // only a field declaration is expected
          return this.parseFieldDeclaration(
              visibility: visibility,
              staticToken: staticToken,
              type: type,
              name: nameResult.some,
              reportError: true);
        }
      }
    }

    // Returns to the start state, and parse an MaybeControlledExpresssion
    _current = startToken;
    return this.parseFieldDeclaration(
        visibility: visibility,
        staticToken: staticToken,
        reportError: reportError);
  }

  /**
   *      ConstructorDeclaration := CONSTRUCTOR (ParameterList)? RIGHT_ARROW Block
   */
  Option<mammouth.ConstructorDeclaration> parseConstructorDeclaration(
      {Token visibility = null, bool reportError = true}) {
    Token constructorKeyword = null;
    mammouth.ParameterList parameters;
    Token inlineKeyword;
    Token arrow;
    mammouth.Block body;
    // consume CONSTRUCTOR
    if(!_isCurrentOfKind(TokenKind.CONSTRUCTOR)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.ConstructorDeclaration>();
      // MARK(STOP PARSING)
    }
    constructorKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // a constructor can be declared without parameters
    if(_isCurrentOfKind(TokenKind.LEFT_PAREN)) {
      // if LEFT_PAREN is reached here, then a parameters list is expected
      // parse ParameterList
      Option<mammouth.ParameterList> result =
      this.parseParameterList(reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // MARK(ERROR ALREADY REPORTED)
        }
        return new Option<mammouth.ConstructorDeclaration>();
        // MARK(STOP PARSING)
      }
      parameters = result.some;
    }
    if(_isCurrentOfKind(TokenKind.INLINE)) {
      inlineKeyword = _current;
      // MARK(MOVE TOKEN)
      _current = _current.next;
    }
    // parse RIGHT_ARROW
    if(!_isCurrentOfKind(TokenKind.RIGHT_ARROW)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        _reportErrorCode(ParserErrorCode.EXPECTED_RIGHT_ARROW_CONSTRUCTOR,
            _current.offset, 0);
      }
      return new Option<mammouth.ConstructorDeclaration>();
      // MARK(STOP PARSING)
    }
    arrow = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // parse Block
    Option<mammouth.Block> result = this.parseBlock(reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(ERROR ALREADY REPORTED)
      }
      return new Option<mammouth.ConstructorDeclaration>();
      // MARK(STOP PARSING)
    }
    body = result.some;
    // MARK(MAKE NODE)
    return new Option<mammouth.ConstructorDeclaration>.Some(
        new mammouth.ConstructorDeclarationImpl.syntactic(
            visibility, constructorKeyword, parameters, inlineKeyword, arrow,
            body));
  }

  /**
   *      FieldDeclaration := (TypeAnnotation)? SimpleIdentifier (ASSIGN_EQUAL Expression)?
   */
  Option<mammouth.FieldDeclaration> parseFieldDeclaration(
      {Token visibility = null,
        mammouth.TypeAnnotation type = null,
        Token staticToken: null,
        mammouth.SimpleIdentifier name = null,
        bool reportError = true}) {
    Token equal;
    mammouth.Expression initializer;
    // The type may be already parsed and received via `type` parameter.
    if(type == null) {
      bool withType = false;
      Token startToken = _current;
      // Ok, the type is not given, let's try to parse one.
      // parse TypeAnnotation
      Option<mammouth.TypeAnnotation> typeResult = this.parseTypeAnnotation(
          reportError: false);
      if(typeResult.isSome) {
        // The type is parsed, let's parse name for the field.
        // parse SimpleIdentifier
        Option<mammouth.SimpleIdentifier> nameResult = this
            .parseSimpleIdentifier(reportError: false);
        if(nameResult.isSome) {
          type = typeResult.some;
          name = nameResult.some;
          withType = true;
        }
      }
      if(!withType) {
        _current = startToken;
        // The field is typeless, let's parse name for the field.
        // parse SimpleIdentifier
        Option<mammouth.SimpleIdentifier> nameResult =
        this.parseSimpleIdentifier(reportError: false);
        if(nameResult.isSome) {
          name = nameResult.some;
        } else {
          // TODO/: report error
          throw "rerro";
        }
      }
    }
    // A field may be initialized with an expression, so looks if we have an
    // assign operator at this stage.
    if(_isCurrentOfKind(TokenKind.ASSIGN_EQUAL)) {
      // parse ASSIGN_EQUAL
      equal = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
      // parse Expression
      Option<mammouth.Expression> initializerResult =
      this.parseExpression(reportError: reportError);
      if(initializerResult.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // MARK(ERROR ALREADY REPORTED)
        }
        return new Option<mammouth.FieldDeclaration>();
        // MARK(STOP PARSING)
      }
      initializer = initializerResult.some;
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.FieldDeclaration>.Some(
        new mammouth.FieldDeclarationImpl.syntactic(
            visibility, staticToken, type, name, equal, initializer));
  }

  /**
   *      MethodDeclaration := (FN|TypeAnnotation) (((GET|SET)? SimpleIdentifier)|(OPERATOR OverloadOperator)) (FormalParameterList)? (INLINE)? (RIGHT_ARROW Block)?
   */
  Option<mammouth.ClassMember> parseMethodDeclaration(
      {Token abstractKeyword = null,
        Token visibility = null,
        mammouth.TypeAnnotation returnType = null,
        Token toKeyword = null,
        Token staticToken = null,
        Token propertyKeyword = null,
        Token operatorKeyword = null,
        mammouth.SimpleIdentifier name = null,
        bool reportError = true}) {
    mammouth.Operator operator;
    mammouth.ParameterList parameters;
    Token inlineKeyword;
    Token arrow;
    mammouth.Block body;
    if(operatorKeyword == null) {
      if(name == null) {
        if(!_isCurrentOfKind(TokenKind.NAME)) {
          if(reportError) {
            // MARK(REPORT ERROR)
            _reportErrorCode(
                ParserErrorCode.METHOD_REQUIRES_NAME, _current.offset, 0);
          }
          return new Option<mammouth.ClassMember>();
          // MARK(STOP PARSING)
        }
        // parse SimpleIdentifier
        Option<mammouth.Expression> result =
        this.parseSimpleIdentifier(reportError: false);
        if(result.isNone) {
          if(reportError) {
            // MARK(REPORT ERROR)
            // MARK(UNREACHABLE ZONE)
            throw "Unreachable zone!";
            // MARK(STOP PARSING)
          }
          return new Option<mammouth.ClassMember>();
          // MARK(STOP PARSING)
        }
        name = result.some;
      }
    } else {
      Option<mammouth.Operator> opResult;
      if(this.isBinaryOperator()) {
        opResult = this.parseBinaryOperator(reportError: reportError);
      } else if(this.isUnaryOperator()) {
        opResult = this.parseUnaryOperator(reportError: reportError);
      } else if(this.isUpdateOperator()) {
        opResult = this.parseUpdateOperator(reportError: reportError);
      } else if(_isCurrentOfKind(TokenKind.LEFT_BRACKET)) {
        SimpleToken first = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        if(_isCurrentOfKind(TokenKind.RIGHT_BRACKET)) {
          first.kind = TokenKind.INDEX_OPERATOR;
          first.next = _current.next;
          _current = _current.next; // MARK(MOVE TOKEN)
          opResult = new Option<mammouth.Operator>.Some(
              new mammouth.BinaryOperatorImpl.syntactic(first));
        } else {
          // MARK(REPORT ERROR)
          // TODO: report error
        }
      } else {
        if(reportError) {
          // MARK(REPORT ERROR)
          // TODO: report error: operator needed
        }
        return new Option<mammouth.ClassMember>();
        // MARK(STOP PARSING)
      }
      operator = opResult.some;
    }
    // a method can be declared without parameters
    if(_isCurrentOfKind(TokenKind.LEFT_PAREN)) {
      Option<mammouth.ParameterList> result =
      this.parseParameterList(reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.ClassMember>();
        // MARK(STOP PARSING)
      }
      parameters = result.some;
    }

    if(_isCurrentOfKind(TokenKind.INLINE)) {
      inlineKeyword = _current;
      // MARK(MOVE TOKEN)
      _current = _current.next;
    }

    if(_isCurrentOfKind(TokenKind.RIGHT_ARROW)) {
      arrow = _current;
      _current = _current.next; // MARK(MOVE TOKEN)

      Option<mammouth.Block> result = this.parseBlock(allowInline: true);
      if(result.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.ClassMember>();
        // MARK(STOP PARSING)
      }
      body = result.some;
    }
    // MARK(MAKE NODE)
    if(operator == null) {
      return new Option<mammouth.ClassMember>.Some(
          new mammouth.MethodDeclarationImpl.syntactic(
              abstractKeyword,
              visibility,
              staticToken,
              returnType,
              propertyKeyword,
              name,
              parameters,
              inlineKeyword,
              arrow,
              body));
    } else {
      return new Option<mammouth.ClassMember>.Some(
          new mammouth.OperatorDeclarationImpl.syntactic(
              abstractKeyword,
              visibility,
              returnType,
              operatorKeyword,
              operator,
              parameters,
              inlineKeyword,
              arrow,
              body));
    }
  }

  /**
   *      ConverterDeclaration := TypeAnnotation TO RIGHT_ARROW (INLINE)? Block
   */
  Option<mammouth.ConverterDeclaration> parseConverterDeclaration(
      {Token abstractKeyword = null,
        Token visibility = null,
        mammouth.TypeAnnotation returnType = null,
        Token toKeyword = null,
        bool reportError = true}) {
    Token inlineKeyword;
    Token arrow;
    mammouth.Block body;
    if(_isCurrentOfKind(TokenKind.INLINE)) {
      inlineKeyword = _current;
      // MARK(MOVE TOKEN)
      _current = _current.next;
    }

    if(!_isCurrentOfKind(TokenKind.RIGHT_ARROW)) {
      // TODO: throw an error
      return new Option<mammouth.ConverterDeclaration>();
      // MARK(STOP PARSING)
    }
    arrow = _current;
    _current = _current.next; // MARK(MOVE TOKEN)

    Option<mammouth.Block> result = this.parseBlock(allowInline: true);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.ConverterDeclaration>();
      // MARK(STOP PARSING)
    }
    body = result.some;
    // MARK(MAKE NODE)
    return new Option<mammouth.ConverterDeclaration>.Some(
        new mammouth.ConverterDeclarationImpl.syntactic(
            abstractKeyword,
            visibility,
            returnType,
            toKeyword,
            inlineKeyword,
            arrow,
            body));
  }

  /**
   *      FunctionExpression := TypeAnnotation (SimpleIdentifier)? (ParameterList)? RIGHT_ARROW Block
   */
  Option<mammouth.FunctionExpression> parseFunctionExpression(
      {mammouth.TypeAnnotation returnType = null,
        mammouth.SimpleIdentifier name = null,
        bool reportError = true}) {
    mammouth.ParameterList parameters;
    Token inlineKeyword;
    Token arrow;
    mammouth.Block body;
    if(name == null) {
      if(_isCurrentOfKind(TokenKind.NAME)) {
        Option<mammouth.Expression> result =
        this.parseSimpleIdentifier(reportError: false);
        if(result.isNone) {
          if(reportError) {
            // TODO: report error
          }
          return new Option<mammouth.FunctionExpression>();
          // MARK(STOP PARSING)
        }
        name = result.some;
      }
    }
    if(_isCurrentOfKind(TokenKind.LEFT_PAREN)) {
      Option<mammouth.ParameterList> result =
      this.parseParameterList(reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.FunctionExpression>();
        // MARK(STOP PARSING)
      }
      parameters = result.some;
    }

    if(_isCurrentOfKind(TokenKind.INLINE)) {
      inlineKeyword = _current;
      // MARK(MOVE TOKEN)
      _current = _current.next;
    }

    if(!_isCurrentOfKind(TokenKind.RIGHT_ARROW)) {
      // TODO: throw an error
      return new Option<mammouth.FunctionExpression>();
      // MARK(STOP PARSING)
    }
    arrow = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;

    Option<mammouth.Block> result = this.parseBlock(allowInline: true);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.FunctionExpression>();
      // MARK(STOP PARSING)
    }
    body = result.some;
    // MARK(MAKE NODE)
    return new Option<mammouth.FunctionExpression>.Some(
        new mammouth.FunctionExpressionImpl.syntactic(
            returnType,
            name,
            parameters,
            inlineKeyword,
            arrow,
            body));
  }

  /**
   *      IfExpression := IfSource Block (MIDENT ELSE Block)?
   */
  Option<mammouth.IfExpression> parseIfExpression({bool reportError = true}) {
    mammouth.Statement consequent;
    Token elseKeyword;
    mammouth.Statement alternate;
    Option<mammouth.IfSource> sourceResult =
    parseIfSource(reportError: reportError);
    // TODO: report if source problem
    if(_isCurrentOfKind(TokenKind.THEN)) {
      _current = _current.next; // consume THEN
    }
    Option<mammouth.Statement> consequentResult = this.parseStatement();
    if(consequentResult.isNone) {
      // TODO: report error
      return new Option<mammouth.IfExpression>();
      // MARK(STOP PARSING)
    }
    consequent = consequentResult.some;
    if(_isCurrentOfKind(TokenKind.ELSE) ||
        (consequent is mammouth.Block &&
            _isCurrentOfKind(TokenKind.MINDENT) &&
            _current.next.kind == TokenKind.ELSE)) {
      if(_isCurrentOfKind(TokenKind.MINDENT)) {
        _current = _current.next; // consume MIDENT
      }
      elseKeyword = _current;
      // MARK(MOVE TOKEN)
      _current = _current.next;
      Option<mammouth.Statement> alternateResult = this.parseStatement();
      if(alternateResult.isNone) {
        // TODO: report error
        return new Option<mammouth.IfExpression>();
        // MARK(STOP PARSING)
      }
      alternate = alternateResult.some;
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.IfExpression>.Some(
        new mammouth.IfExpressionImpl.syntactic(
            sourceResult.some, consequent, elseKeyword, alternate));
  }

  /**
   *      IfSource := (IF|UNLESS) Expression
   */
  Option<mammouth.IfSource> parseIfSource({bool reportError = true}) {
    Token ifKeyword;
    if(!(_isCurrentOfKind(TokenKind.IF) ||
        _isCurrentOfKind(TokenKind.UNLESS))) {
      // TODO: throw an error
      return new Option<mammouth.IfSource>();
      // MARK(STOP PARSING)
    }
    ifKeyword = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    Option<mammouth.Expression> conditionResult =
    this.parseExpression(reportError: reportError);
    if(conditionResult.isNone) {
      // TODO: throw an error
      return new Option<mammouth.IfSource>();
      // MARK(STOP PARSING)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.IfSource>.Some(
        new mammouth.IfSourceImpl.syntactic(ifKeyword, conditionResult.some));
  }

  /**
   *      RepetitionExpression := RepetitionSource Statement
   */
  Option<mammouth.RepetitionExpression> parseRepetitionExpression(
      {bool reportError = true}) {
    Option<mammouth.RepetitionSource> sourceResult =
    parseRepetitionSource(reportError: reportError);
    Option<mammouth.Statement> bodyResult = this.parseStatement();
    if(bodyResult.isNone) {
      // TODO: report error
      return new Option<mammouth.RepetitionExpression>();
      // MARK(STOP PARSING)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.RepetitionExpression>.Some(
        new mammouth.RepetitionExpressionImpl(
            sourceResult.some, bodyResult.some));
  }

  /**
   *      RepetitionSource := (WHILE | UNTIL) Expression Guard
   *                        | LOOP
   *      TODO: when
   */
  Option<mammouth.RepetitionSource> parseRepetitionSource(
      {bool reportError = true}) {
    Token keyword;
    mammouth.Expression test;
    mammouth.GuardSource guard;
    if(!_isCurrentOfKind(TokenKind.WHILE) &&
        !_isCurrentOfKind(TokenKind.UNTIL) &&
        !_isCurrentOfKind(TokenKind.LOOP)) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.RepetitionSource>();
      // MARK(STOP PARSING)
    }
    keyword = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    if(keyword.kind != TokenKind.LOOP) {
      Option<mammouth.Expression> testResult =
      this.parseExpression(reportError: reportError);
      if(testResult.isNone) {
        if(reportError) {
          // TODO: throw an error
        }
        return new Option<mammouth.RepetitionSource>();
        // MARK(STOP PARSING)
      }
      test = testResult.some;
    }
    if(_isCurrentOfKind(TokenKind.WHEN)) {
      Option<mammouth.GuardSource> guardResult =
      this.parseGuardSource(reportError: reportError);
      if(guardResult.isNone) {
        if(reportError) {
          // TODO: throw an error
        }
        return new Option<mammouth.RepetitionSource>();
        // MARK(STOP PARSING)
      }
      guard = guardResult.some;
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.RepetitionSource>.Some(
        new mammouth.RepetitionSourceImpl(keyword, test, guard));
  }

  /**
   *      ForExpression := RepetitionSource Statement
   */
  Option<mammouth.ForExpression> parseForExpression({bool reportError = true}) {
    Option<mammouth.ForSource> sourceResult =
    parseForSource(reportError: reportError);
    Option<mammouth.Statement> bodyResult = this.parseStatement();
    if(bodyResult.isNone) {
      // TODO: report error
      return new Option<mammouth.ForExpression>();
      // MARK(STOP PARSING)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.ForExpression>.Some(
        new mammouth.ForExpressionImpl(sourceResult.some, bodyResult.some));
  }

  /**
   *       ForSource := FOR RangeLiteral (AS SimpleIdentifier)? (BY Expression)? (Guard)?
   *                  | FOR RangeLiteral (BY Expression) (AS SimpleIdentifier) (Guard)?
   *                  | FOR ForVariables (IN|OF) Expression (BY Expression)? (WHEN Expression)?
   *
   *       ForVariables := ForVariable (COMMA ForVariable)?
   */
  Option<mammouth.ForSource> parseForSource({bool reportError = true}) {
    Token forKeyword;

    if(!_isCurrentOfKind(TokenKind.FOR)) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.ForSource>();
      // MARK(STOP PARSING)
    }
    forKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)

    if(_isCurrentOfKind(TokenKind.LEFT_BRACKET)) {
      mammouth.RangeLiteral source;
      Token asKeyword;
      mammouth.ForVariable name;
      Token byKeyword;
      mammouth.Expression step;
      mammouth.GuardSource guard;

      Option<mammouth.RangeLiteral> sourceResult =
      this.parseRangeLiteral(reportError: reportError);
      if(sourceResult.isNone) {
        if(reportError) {
          // TODO: throw an error
        }
        return new Option<mammouth.ForSource>();
        // MARK(STOP PARSING)
      }
      source = sourceResult.some;

      bool allowAS = true,
          allowBY = true;

      for(int i = 0; i < 2; i++) {
        if(allowAS && _isCurrentOfKind(TokenKind.AS)) {
          allowAS = false;
          if(!_isCurrentOfKind(TokenKind.AS)) {
            if(reportError) {
              // TODO: throw an error
            }
            return new Option<mammouth.ForSource>();
            // MARK(STOP PARSING)
          }
          asKeyword = _current;
          _current = _current.next; // MARK(MOVE TOKEN)

          Option<mammouth.ForVariable> nameResult =
          this.parseForVariable(reportError: reportError);
          if(nameResult.isNone) {
            if(reportError) {
              // TODO: throw an error
            }
            return new Option<mammouth.ForSource>();
            // MARK(STOP PARSING)
          }
          name = nameResult.some;
        } else if(allowBY && _isCurrentOfKind(TokenKind.BY)) {
          allowBY = false;
          if(!_isCurrentOfKind(TokenKind.BY)) {
            if(reportError) {
              // TODO: throw an error
            }
            return new Option<mammouth.ForSource>();
            // MARK(STOP PARSING)
          }
          byKeyword = _current;
          _current = _current.next; // MARK(MOVE TOKEN)

          Option<mammouth.Expression> stepResult =
          this.parseExpression(reportError: reportError);
          if(stepResult.isNone) {
            if(reportError) {
              // TODO: throw an error
            }
            return new Option<mammouth.ForSource>();
            // MARK(STOP PARSING)
          }
          step = stepResult.some;
        }
      }

      if(_isCurrentOfKind(TokenKind.WHEN)) {
        Option<mammouth.GuardSource> guardResult =
        this.parseGuardSource(reportError: reportError);
        if(guardResult.isNone) {
          if(reportError) {
            // TODO: throw an error
          }
          return new Option<mammouth.ForSource>();
          // MARK(STOP PARSING)
        }
        guard = guardResult.some;
      }

      // MARK(MAKE NODE)
      return new Option<mammouth.ForSource>.Some(
          new mammouth.ForRangeSourceImpl.syntactic(
              forKeyword,
              source,
              asKeyword,
              name,
              byKeyword,
              step,
              guard));
    } else {
      mammouth.ForVariable firstVariable;
      mammouth.ForVariable secondVariable;
      Token inKeyword;
      Token ofKeyword;
      mammouth.Expression source;
      Token byKeyword;
      mammouth.Expression step;
      mammouth.GuardSource guard;

      Option<mammouth.ForVariable> variableResult =
      this.parseForVariable(reportError: reportError);
      if(variableResult.isNone) {
        if(reportError) {
          // TODO: throw an error
        }
        return new Option<mammouth.ForSource>();
        // MARK(STOP PARSING)
      }
      firstVariable = variableResult.some;

      if(_isCurrentOfKind(TokenKind.COMMA)) {
        _current = _current.next; // MARK(MOVE TOKEN)
        variableResult = this.parseForVariable(reportError: reportError);
        if(variableResult.isNone) {
          if(reportError) {
            // TODO: throw an error
          }
          return new Option<mammouth.ForSource>();
          // MARK(STOP PARSING)
        }
        secondVariable = variableResult.some;
      }

      if(_isCurrentOfKind(TokenKind.IN)) {
        inKeyword = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
      } else if(_isCurrentOfKind(TokenKind.OF)) {
        ofKeyword = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
      } else {
        if(reportError) {
          // TODO: throw an error
        }
        return new Option<mammouth.ForSource>();
        // MARK(STOP PARSING)
      }

      Option<mammouth.Expression> sourceResult =
      this.parseExpression(reportError: reportError);
      if(sourceResult.isNone) {
        if(reportError) {
          // TODO: throw an error
        }
        return new Option<mammouth.ForSource>();
        // MARK(STOP PARSING)
      }
      source = sourceResult.some;

      if(_isCurrentOfKind(TokenKind.BY)) {
        byKeyword = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        Option<mammouth.Expression> stepResult =
        this.parseExpression(reportError: reportError);
        if(stepResult.isNone) {
          if(reportError) {
            // TODO: throw an error
          }
          return new Option<mammouth.ForSource>();
          // MARK(STOP PARSING)
        }
        step = stepResult.some;
      }

      if(_isCurrentOfKind(TokenKind.WHEN)) {
        Option<mammouth.GuardSource> guardResult =
        this.parseGuardSource(reportError: reportError);
        if(guardResult.isNone) {
          if(reportError) {
            // TODO: throw an error
          }
          return new Option<mammouth.ForSource>();
          // MARK(STOP PARSING)
        }
        guard = guardResult.some;
      }

      // MARK(MAKE NODE)
      return new Option<mammouth.ForSource>.Some(
          new mammouth.ForVariableSourceImpl.syntactic(
              forKeyword,
              firstVariable,
              secondVariable,
              inKeyword,
              ofKeyword,
              source,
              byKeyword,
              step,
              guard));
    }
  }

  /**
   *       ForVariable := (TypeAnnotation)? SimpleIdentifier
   */
  Option<mammouth.ForVariable> parseForVariable({bool reportError = true}) {
    mammouth.TypeAnnotation type;
    mammouth.SimpleIdentifier name;

    bool isTyped = false;
    Token startToken = _current;
    Option<mammouth.TypeAnnotation> typeResult =
    this.parseTypeAnnotation(reportError: false);
    if(typeResult.isSome) {
      Option<mammouth.SimpleIdentifier> nameResult =
      this.parseSimpleIdentifier(reportError: false);
      if(nameResult.isSome) {
        isTyped = true;
        type = typeResult.some;
        name = nameResult.some;
      }
    }

    if(!isTyped) {
      _current = startToken;
      Option<mammouth.SimpleIdentifier> nameResult =
      this.parseSimpleIdentifier(reportError: reportError);
      if(nameResult.isNone) {
        if(reportError) {
          // TODO: throw an error
        }
        return new Option<mammouth.ForVariable>();
        // MARK(STOP PARSING)
      }
      name = nameResult.some;
    }

    return new Option<mammouth.ForVariable>.Some(
        new mammouth.ForVariableImpl(type, name));
  }

  /**
   *       GuardSource := WHEN Expression
   */
  Option<mammouth.GuardSource> parseGuardSource({bool reportError = true}) {
    Token whenKeyword;
    if(!_isCurrentOfKind(TokenKind.WHEN)) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.GuardSource>();
      // MARK(STOP PARSING)
    }
    whenKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.Expression> consitionResult =
    this.parseExpression(reportError: reportError);
    if(consitionResult.isNone) {
      // TODO: throw an error
      return new Option<mammouth.GuardSource>();
      // MARK(STOP PARSING)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.GuardSource>.Some(
        new mammouth.GuardSourceImpl.syntactic(
            whenKeyword, consitionResult.some));
  }

  /**
   *       TryExpression := TRY Statement (MINDENT CATCH (TypeAnnotation)? SimpleIdentifier)? (MINDENT FINALLY Statement)?
   */
  Option<mammouth.TryExpression> parseTryExpression({bool reportError = true}) {
    Token tryKeyword, catchKeyword, finallyKeyword;
    mammouth.Statement tryStatement, catchStatement, finallyStatement;
    mammouth.SimpleParameter catchVariable;
    if(!_isCurrentOfKind(TokenKind.TRY)) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.TryExpression>();
      // MARK(STOP PARSING)
    }
    tryKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.Statement> statementResult = this.parseStatement();
    if(statementResult.isNone) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.TryExpression>();
      // MARK(STOP PARSING)
    }
    tryStatement = statementResult.some;
    if(_isCurrentOfKind(TokenKind.MINDENT)) {
      _current = _current.next; // MARK(MOVE TOKEN)
      bool hasCatch = false;
      if(_isCurrentOfKind(TokenKind.CATCH)) {
        hasCatch = true;
        catchKeyword = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        Option<mammouth.SimpleParameter> varResult = this.parseParameter(
            reportError: reportError);
        if(varResult.isNone) {
          if(reportError) {
            // TODO: throw an error
          }
          return new Option<mammouth.TryExpression>();
          // MARK(STOP PARSING)
        }
        catchVariable = varResult.some;
        statementResult = this.parseStatement(reportError: reportError);
        if(statementResult.isNone) {
          if(reportError) {
            // TODO: throw an error
          }
          return new Option<mammouth.TryExpression>();
          // MARK(STOP PARSING)
        }
        catchStatement = statementResult.some;
      }
      bool expectFinally = false;
      if(hasCatch) {
        if(_isCurrentOfKind(TokenKind.MINDENT)) {
          expectFinally = true;
          _current = _current.next;
        }
      } else {
        expectFinally = true;
      }
      if(expectFinally) {
        if(!_isCurrentOfKind(TokenKind.FINALLY)) {
          if(reportError) {
            // TODO: throw an error
          }
          return new Option<mammouth.TryExpression>();
          // MARK(STOP PARSING)
        }
        finallyKeyword = _current;
        _current = _current.next;
        statementResult = this.parseStatement(reportError: reportError);
        if(statementResult.isNone) {
          if(reportError) {
            // TODO: throw an error
          }
          return new Option<mammouth.TryExpression>();
          // MARK(STOP PARSING)
        }
        finallyStatement = statementResult.some;
      }
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.TryExpression>.Some(
        new mammouth.TryExpressionImpl.syntactic(
            tryKeyword,
            tryStatement,
            catchKeyword,
            catchVariable,
            catchStatement,
            finallyKeyword,
            finallyStatement));
  }

  /**
   *       SwitchExpression := SWITCH Expression INDENT SwitchCase (MIDENT SwitchCase)* OUTDNET
   */
  Option<mammouth.SwitchExpression> parseSwitchExpression(
      {bool reportError = true}) {
    Token switchKeyword;
    mammouth.Expression discriminant;
    List<mammouth.SwitchCase> cases = [];
    mammouth.SwitchDefault defaultCase;
    if(!_isCurrentOfKind(TokenKind.SWITCH)) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.SwitchExpression>();
      // MARK(STOP PARSING)
    }
    switchKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.Expression> expressionResult =
    this.parseExpression(reportError: reportError);
    if(expressionResult.isNone) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.SwitchExpression>();
      // MARK(STOP PARSING)
    }
    discriminant = expressionResult.some;
    if(!_isCurrentOfKind(TokenKind.INDENT)) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.SwitchExpression>();
      // MARK(STOP PARSING)
    }
    _current = _current.next; // MARK(MOVE TOKEN)
    while(
    _isCurrentOfKind(TokenKind.CASE) || _isCurrentOfKind(TokenKind.WHEN)) {
      Option<mammouth.SwitchCase> caseResult =
      this.parseSwitchCase(reportError: reportError);
      if(caseResult.isNone) {
        if(reportError) {
          // TODO: throw an error
        }
        return new Option<mammouth.SwitchExpression>();
        // MARK(STOP PARSING)
      }
      cases.add(caseResult.some);
      if(_isCurrentOfKind(TokenKind.MINDENT)) {
        _current = _current.next; // MARK(MOVE TOKEN)
      }
    }
    if(_isCurrentOfKind(TokenKind.DEFAULT)) {
      Option<mammouth.SwitchDefault> caseResult =
      this.parseSwitchDefault(reportError: reportError);
      if(caseResult.isNone) {
        if(reportError) {
          // TODO: throw an error
        }
        return new Option<mammouth.SwitchExpression>();
        // MARK(STOP PARSING)
      }
      defaultCase = caseResult.some;
    }
    if(!_isCurrentOfKind(TokenKind.OUTDENT)) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.SwitchExpression>();
      // MARK(STOP PARSING)
    }
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.SwitchExpression>.Some(
        new mammouth.SwitchExpressionImpl.syntactic(
            switchKeyword, discriminant, cases, defaultCase));
  }

  /**
   *      SwitchCase := (CASE|WHEN) Expression Statement
   */
  Option<mammouth.SwitchCase> parseSwitchCase({bool reportError = true}) {
    Token keyword;
    mammouth.Expression test;
    mammouth.Statement consequent;
    if(!_isCurrentOfKind(TokenKind.CASE) &&
        !_isCurrentOfKind(TokenKind.WHEN)) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.SwitchCase>();
      // MARK(STOP PARSING)
    }
    keyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.Expression> testResult =
    this.parseExpression(reportError: reportError);
    if(testResult.isNone) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.SwitchCase>();
      // MARK(STOP PARSING)
    }
    test = testResult.some;
    Option<mammouth.Statement> consequentResult =
    this.parseStatement(reportError: reportError);
    if(consequentResult.isNone) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.SwitchCase>();
      // MARK(STOP PARSING)
    }
    consequent = consequentResult.some;
    // MARK(MAKE NODE)
    return new Option<mammouth.SwitchCase>.Some(
        new mammouth.SwitchCaseImpl.syntactic(keyword, test, consequent));
  }

  /**
   *      SwitchDefault := DEFAULT Statement
   */
  Option<mammouth.SwitchDefault> parseSwitchDefault({bool reportError = true}) {
    Token defaultKeyword;
    mammouth.Statement consequent;
    if(!_isCurrentOfKind(TokenKind.DEFAULT)) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.SwitchDefault>();
      // MARK(STOP PARSING)
    }
    defaultKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.Statement> consequentResult =
    this.parseStatement(reportError: reportError);
    if(consequentResult.isNone) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.SwitchDefault>();
      // MARK(STOP PARSING)
    }
    consequent = consequentResult.some;
    // MARK(MAKE NODE)
    return new Option<mammouth.SwitchDefault>.Some(
        new mammouth.SwitchDefaultImpl.syntactic(defaultKeyword, consequent));
  }

  /**
   *       MaybeControlledExpresssion := SimpleExpression (ControlSource)?
   *
   *       ControlSource := ForSource
   *                      | IfSource
   *                      | RepetitionSource
   */
  Option<mammouth.Expression> parseMaybeControlledExpresssion(
      {bool allowControl = true, bool reportError = true}) {
    Option<mammouth.Expression> expressionResult = this
        .parseSimpleExpression(allowControl: false, reportError: reportError);
    if(expressionResult.isNone) {
      // TODO: report error
      return expressionResult;
    }
    if(allowControl) {
      if(_isCurrentOfKind(TokenKind.IF)) {
        Token elseKeyword;
        mammouth.Statement alternate;
        Option<mammouth.IfSource> sourceResult =
        parseIfSource(reportError: reportError);
        if(sourceResult.isNone) {
          // TODO: report error
          return new Option<mammouth.Expression>();
          // MARK(STOP PARSING)
        }
        if(_isCurrentOfKind(TokenKind.ELSE)) {
          // consume ELSE
          elseKeyword = _current;
          _current = _current.next; // MARK(MOVE TOKEN)
          Option<mammouth.Statement> alternateResult = this.parseStatement();
          if(alternateResult.isNone) {
            // TODO: report error
            return new Option<mammouth.IfExpression>();
            // MARK(STOP PARSING)
          }
          alternate = alternateResult.some;
        }
        // MARK(MAKE NODE)
        return new Option<mammouth.Expression>.Some(
            new mammouth.IfExpressionImpl.syntactic(
                sourceResult.some,
                new mammouth.ExpressionStatementImpl(expressionResult.some),
                elseKeyword,
                alternate));
      } else if(_isCurrentOfKind(TokenKind.WHILE) ||
          _isCurrentOfKind(TokenKind.UNTIL)) {
        Option<mammouth.RepetitionSource> sourceResult =
        parseRepetitionSource(reportError: reportError);
        // MARK(MAKE NODE)
        return new Option<mammouth.RepetitionExpression>.Some(
            new mammouth.RepetitionExpressionImpl(sourceResult.some,
                new mammouth.ExpressionStatementImpl(expressionResult.some)));
      } else if(_isCurrentOfKind(TokenKind.FOR)) {
        Option<mammouth.ForSource> sourceResult =
        parseForSource(reportError: reportError);
        // MARK(MAKE NODE)
        return new Option<mammouth.ForExpression>.Some(
            new mammouth.ForExpressionImpl(sourceResult.some,
                new mammouth.ExpressionStatementImpl(expressionResult.some)));
      }
    }
    return expressionResult;
  }

  /**
   *      SimpleExpression := EchoExpression
   *                        | MaybeAssignmentExpression
   */
  Option<mammouth.Expression> parseSimpleExpression(
      {bool allowControl: true, bool reportError = true}) {
    if(_isCurrentOfKind(TokenKind.ECHO)) {
      // Only an echo expression starts with ECHO.
      // parse EchoExpression
      return this.parseEchoExpression(
          allowControl: allowControl, reportError: reportError);
    }

    // parse MaybeAssignmentExpression
    return this.parseMaybeAssignmentExpression(
        allowControl: allowControl, reportError: reportError);
  }

  /**
   *      ECHO Expression
   */
  Option<mammouth.EchoExpression> parseEchoExpression(
      {bool allowControl = true, bool reportError = true}) {
    Token echoKeyword;
    // consume ECHO
    if(!_isCurrentOfKind(TokenKind.ECHO)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.EchoExpression>();
      // MARK(STOP PARSING)
    }
    echoKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // parse Expression
    Option<mammouth.Expression> exprResult = this
        .parseExpression(allowControl: allowControl, reportError: reportError);
    if(exprResult.isNone) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(ERROR ALREADY REPORTED)
      }
      return new Option<mammouth.EchoExpression>();
      // MARK(STOP PARSING)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.EchoExpression>.Some(
        new mammouth.EchoExpressionImpl.syntactic(
            echoKeyword, exprResult.some));
  }

  /**
   *      MaybeAssignmentExpression := MaybeBinaryExpression (AssignementOperator Expression)?
   */
  Option<mammouth.Expression> parseMaybeAssignmentExpression(
      {bool allowControl = true, bool reportError = true}) {
    mammouth.Expression left, right;
    Option<mammouth.Expression> result =
    this.parseMaybeBinaryExpression(reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.Expression>();
      // MARK(STOP PARSING)
    }
    left = result.some;
    if(!this.isAssignmentOperator()) {
      return result;
    }
    Option<mammouth.AssignmentOperator> opResult =
    this.parseAssignementOperator();
    result = this
        .parseExpression(allowControl: allowControl, reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.Expression>();
      // MARK(STOP PARSING)
    }
    right = result.some;
    // MARK(MAKE NODE)
    return new Option<mammouth.Expression>.Some(
        new mammouth.AssignmentExpressionImpl(left, opResult.some, right));
  }

  /**
   *      MaybeBinaryExpression := MaybeInExpression (BinaryOperator MaybeBinaryExpression)?
   *          // respecting operators precedence
   */
  Option<mammouth.Expression> parseMaybeBinaryExpression(
      {Precedence minPrecedence = Precedence.Zero, bool reportError = true}) {
    mammouth.Expression node;
    Option<mammouth.Expression> result = this.parseMaybeInExpression(
        reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.Expression>();
      // MARK(STOP PARSING)
    }
    node = result.some;
    // TODO: test precedence
    while(this.isBinaryOperator() &&
        _current.precedence >= minPrecedence) {
      Option<mammouth.BinaryOperator> operat0rResult =
      this.parseBinaryOperator(reportError: reportError);
      if(operat0rResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      mammouth.BinaryOperator operat0r = operat0rResult.some;
      result = this.parseMaybeBinaryExpression(
          minPrecedence: operat0rResult.some.precedence + 1);
      if(result.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      // MARK(MAKE NODE)
      node = new mammouth.BinaryExpressionImpl(node, operat0r, result.some);
    }
    return new Option<mammouth.Expression>.Some(node);
  }

  /**
   *      MaybeInExpression := MaybeAsOrToExpression (IN MaybeNewExpression)?
   */
  Option<mammouth.Expression> parseMaybeInExpression(
      {bool reportError = true}) {
    Option<mammouth.Expression> result = this.parseMaybeAsOrToExpression(
        reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.Expression>();
      // MARK(STOP PARSING)
    }
    if(_isCurrentOfKind(TokenKind.IN)) {
      Token inKeyword = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
      Option<mammouth.Expression> containerResult = this
          .parseMaybeNewExpression(reportError: reportError);
      if(containerResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.Expression>.Some(
          new mammouth.InExpressionImpl.syntactic(
              result.some, inKeyword, containerResult.some));
    }
    return result;
  }

  /**
   *      MaybeAsOrToExpression := MaybePrefixExpression ((AS|TO) TypeAnnotation)?
   */
  Option<mammouth.Expression> parseMaybeAsOrToExpression(
      {bool reportError = true}) {
    Option<mammouth.Expression> result = this.parseMaybePrefixExpression(
        reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.Expression>();
      // MARK(STOP PARSING)
    }
    if(_isCurrentOfKind(TokenKind.TO)) {
      Token toKeyword = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
      Option<mammouth.TypeAnnotation> typeResult = this.parseTypeAnnotation(
          reportError: reportError);
      if(typeResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.Expression>.Some(
          new mammouth.ToExpressionImpl.syntactic(
              result.some, toKeyword, typeResult.some));
    } else if(_isCurrentOfKind(TokenKind.AS)) {
      Token asKeyword = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
      Option<mammouth.TypeAnnotation> typeResult = this.parseTypeAnnotation(
          reportError: reportError);
      if(typeResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.Expression>.Some(
          new mammouth.AsExpressionImpl.syntactic(
              result.some, asKeyword, typeResult.some));
    }
    return result;
  }

  /**
   *      MaybePrefixExpression := UpdateOperator MaybePrefixExpression
   *                             | UnaryOperator MaybePrefixExpression
   *                             | MaybePostfixExpression
   */
  Option<mammouth.Expression> parseMaybePrefixExpression(
      {bool reportError = true}) {
    if(this.isUpdateOperator()) {
      Option<mammouth.UpdateOperator> operat0rResult =
      this.parseUpdateOperator(reportError: reportError);
      if(operat0rResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      Option<mammouth.Expression> result =
      this.parseMaybePrefixExpression(reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      // MARK(MAKE NODE)
      return new Option<mammouth.Expression>.Some(
          new mammouth.UpdateExpressionImpl(
              true, operat0rResult.some, result.some));
    } else if(this.isUnaryOperator()) {
      Option<mammouth.UnaryOperator> operat0rResult =
      this.parseUnaryOperator(reportError: reportError);
      if(operat0rResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      Option<mammouth.Expression> result =
      this.parseMaybePrefixExpression(reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      // MARK(MAKE NODE)
      return new Option<mammouth.Expression>.Some(
          new mammouth.UnaryExpressionImpl(operat0rResult.some, result.some));
    }
    return this.parseMaybePostfixExpression(reportError: reportError);
  }

  /**
   *      MaybePostfixExpression := MaybeNewExpression (UpdateOperator)?
   */
  Option<mammouth.Expression> parseMaybePostfixExpression(
      {bool reportError = true}) {
    mammouth.Expression expression;
    Option<mammouth.Expression> result =
    this.parseMaybeNewExpression(reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.Expression>();
      // MARK(STOP PARSING)
    }
    expression = result.some;
    if(this.isUpdateOperator()) {
      Option<mammouth.UpdateOperator> operat0rResult =
      this.parseUpdateOperator(reportError: reportError);
      if(operat0rResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      // MARK(MAKE NODE)
      expression = new mammouth.UpdateExpressionImpl(
          false, operat0rResult.some, expression);
    }
    return new Option<mammouth.Expression>.Some(expression);
  }

  /**
   *      MaybeNewExpression := NEW MaybeMemberExpression (LEFT_PAREN ArgumentList RIGHT_PAREN)?*
   *                          | MaybeMemberExpression
   */
  Option<mammouth.Expression> parseMaybeNewExpression(
      {bool reportError = true}) {
    if(_isCurrentOfKind(TokenKind.NEW)) {
      // TODO: new without parenthesis
      Token newKeyword;
      mammouth.TypeAnnotation callee;
      Token leftParen, rightParen;
      // consume NEW
      newKeyword = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
      Option<mammouth.TypeAnnotation> result = this.parseTypeAnnotation(
          reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      callee = result.some;
      // consume LEFT_PAREN
      leftParen = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
      Option<mammouth.ArgumentList> argResult = this
          .parseArgumentList(TokenKind.RIGHT_PAREN, reportError: reportError);
      if(argResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      // consume RIGHT_PAREN
      if(!_isCurrentOfKind(TokenKind.RIGHT_PAREN)) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
      }
      rightParen = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
      // MARK(MAKE NODE)
      return new Option<mammouth.Expression>.Some(
          new mammouth.NewExpressionImpl.syntactic(
              newKeyword, callee, leftParen, argResult.some, rightParen));
    }
    return this.parseMaybeMemberExpression(reportError: reportError);
  }

  /**
   *      MaybeMemberExpression := MaybeMemberExpression LEFT_PAREN ArgumentList RIGHT_PAREN
   *                             | MaybeMemberExpression LEFT_BRACKET Expression RIGHT_BRACKET
   *                             | MaybeMemberExpression RangeLiteral
   *                             | MaybeMemberExpression DOT SimpleIdentifier
   *                             | MaybeMemberExpression QUESTIONMARK
   *                             | PrimaryExpression
   */
  Option<mammouth.Expression> parseMaybeMemberExpression(
      {bool allowInvocation = true, bool reportError = true}) {
    mammouth.Expression expression;
    Option<mammouth.Expression> result =
    this.parsePrimaryExpression(reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.Expression>();
      // MARK(STOP PARSING)
    }
    expression = result.some;
    while(true) {
      if(allowInvocation && _isCurrentOfKind(TokenKind.LEFT_PAREN)) {
        Token leftParen, rightParen;
        // consume LEFT_PAREN
        leftParen = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        Option<mammouth.ArgumentList> argResult = this
            .parseArgumentList(TokenKind.RIGHT_PAREN, reportError: reportError);
        if(argResult.isNone) {
          if(reportError) {
            // TODO: report error
          }
          return new Option<mammouth.Expression>();
          // MARK(STOP PARSING)
        }
        // consume RIGHT_PAREN
        if(!_isCurrentOfKind(TokenKind.RIGHT_PAREN)) {
          if(reportError) {
            // TODO: report error
          }
          return new Option<mammouth.Expression>();
          // MARK(STOP PARSING)
        }
        rightParen = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        expression = new mammouth.InvocationExpressionImpl.syntactic(
            expression, leftParen, argResult.some, rightParen);
      } else if(_isCurrentOfKind(TokenKind.LEFT_BRACKET)) {
        Token leftBracket, rightBracket;
        Token startToken = _current;

        Option<mammouth.RangeLiteral> slicingRange = this.parseRangeLiteral(
            allowOptionalRightLimit: true, reportError: reportError);
        if(slicingRange.isSome) {
          expression =
          new mammouth.SliceExpressionImpl(expression, slicingRange.some);
        } else {
          _current = startToken;
          // consume LEFT_BRACKET
          leftBracket = _current;
          _current = _current.next; // MARK(MOVE TOKEN)
          Option<mammouth.Expression> indexResult =
          this.parseExpression(reportError: reportError);
          if(indexResult.isNone) {
            if(reportError) {
              // TODO: report error
            }
            return new Option<mammouth.Expression>();
            // MARK(STOP PARSING)
          }
          // consume RIGHT_BRACKET
          if(!_isCurrentOfKind(TokenKind.RIGHT_BRACKET)) {
            if(reportError) {
              // TODO: report error
            }
            return new Option<mammouth.Expression>();
            // MARK(STOP PARSING)
          }
          rightBracket = _current;
          _current = _current.next; // MARK(MOVE TOKEN)
          expression = new mammouth.IndexExpressionImpl.syntactic(
              expression, leftBracket, indexResult.some, rightBracket);
        }
      } else if(_isCurrentOfKind(TokenKind.DOT)) {
        Token dot;
        // consume DOT
        dot = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        Option<mammouth.Expression> propertyResult =
        this.parseSimpleIdentifier(reportError: reportError);
        if(propertyResult.isNone) {
          if(reportError) {
            // TODO: report error
          }
          return new Option<mammouth.Expression>();
          // MARK(STOP PARSING)
        }
        expression = new mammouth.MemberExpressionImpl.syntactic(
            expression, dot, propertyResult.some);
      } else if(_isCurrentOfKind(TokenKind.QUESTIONMARK)) {
        Token questionMark;
        // consume QUESTIONMARK
        questionMark = _current;
        _current = _current.next; // MARK(MOVE TOKEN)
        expression =
        new mammouth.ExistenceExpressionImpl.syntactic(
            expression, questionMark);
      } else {
        break;
      }
    }
    return new Option<mammouth.Expression>.Some(expression);
  }

  /**
   *      PrimaryExpression := SimpleIdentifier
   *                         | NativeExpression
   *                         | AtExpression
   *                         | ArrayLiteral
   *                         | ParenthesisExpression
   *                         | Literal
   */
  Option<mammouth.Expression> parsePrimaryExpression(
      {bool reportError = true}) {
    if(_isCurrentOfKind(TokenKind.NAME)) {
      return this.parseSimpleIdentifier(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.NATIVE)) {
      return this.parseNativeExpression(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.AT)) {
      return this.parseAtExpression(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.LEFT_BRACKET)) {
      return this.parseArrayLiteralOrRangeLiteral(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.LEFT_BRACE)) {
      return this.parseMapLiteral(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.LEFT_PAREN)) {
      return this.parseParenthesisExpression(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.LESS_THAN)) {
      Option<mammouth.TypeArgumentList> typeArgumentResult =
      this.parseTypeArgumentList(reportError: reportError);
      if(typeArgumentResult.isNone) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
      if(typeArgumentResult.some.arguments.length == 2) {
        return this.parseMapLiteral(
            typeArguments: typeArgumentResult.some, reportError: reportError);
      } else if(typeArgumentResult.some.arguments.length == 1) {
        return this.parseArrayLiteral(
            typeArguments: typeArgumentResult.some, reportError: reportError);
      } else {
        if(reportError) {
          // MARK(REPORT ERROR)
          // TODO: report error
        }
        return new Option<mammouth.Expression>();
        // MARK(STOP PARSING)
      }
    }
    return this.parseLiteral();
  }

  /**
   *      NativeExpression := NATIVE LEFT_PAREN ArgumentList RIGHT_PAREN
   */
  Option<mammouth.NativeExpression> parseNativeExpression(
      {bool reportError = true}) {
    Token nativeKeyword, leftParen, rightParen;
    // consume NATIVE
    if(!_isCurrentOfKind(TokenKind.NATIVE)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.NativeExpression>();
      // MARK(STOP PARSING)
    }
    nativeKeyword = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // consume LEFT_PAREN
    leftParen = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.ArgumentList> argResult =
    this.parseArgumentList(TokenKind.RIGHT_PAREN, reportError: reportError);
    if(argResult.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.NativeExpression>();
      // MARK(STOP PARSING)
    }
    // consume RIGHT_PAREN
    if(!_isCurrentOfKind(TokenKind.RIGHT_PAREN)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.NativeExpression>();
      // MARK(STOP PARSING)
    }
    rightParen = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.NativeExpression>.Some(
        new mammouth.NativeExpressionImpl.syntactic(
            nativeKeyword, leftParen, argResult.some, rightParen));
  }

  /**
   *      AtExpression := AT SimpleIdentifier
   */
  Option<mammouth.AtExpression> parseAtExpression({bool reportError = true}) {
    Token atToken;
    // consume AT
    if(!_isCurrentOfKind(TokenKind.AT)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.AtExpression>();
      // MARK(STOP PARSING)
    }
    atToken = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // parse property := SimpleIdentifier
    Option<mammouth.Expression> propertyResult =
    this.parseSimpleIdentifier(reportError: reportError);
    if(propertyResult.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.AtExpression>();
      // MARK(STOP PARSING)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.AtExpression>.Some(
        new mammouth.AtExpressionImpl.syntactic(atToken, propertyResult.some));
  }

  Option<mammouth.Expression> parseArrayLiteralOrRangeLiteral(
      {bool reportError = true}) {
    Token startToken = _current;

    Option<mammouth.Expression> result =
    this.parseRangeLiteral(reportError: false);
    if(result.isSome) {
      return result;
    }
    _current = startToken;
    return this.parseArrayLiteral(reportError: reportError);
  }

  /**
   *      ArrayLiteral := (LESS_THAN TypeAnnotation GREATER_THAN)? LEFT_BRACKET ArgumentList RIGHT_BRACKET
   */
  Option<mammouth.ArrayLiteral> parseArrayLiteral(
      {mammouth.TypeArgumentList typeArguments = null,
        bool reportError = true}) {
    Token leftBracket, rightBracket;
    // consume LEFT_BRACKET
    if(!_isCurrentOfKind(TokenKind.LEFT_BRACKET)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
        // TODO: report error here if start with type generic
      }
      return new Option<mammouth.ArrayLiteral>();
      // MARK(STOP PARSING)
    }
    leftBracket = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Option<mammouth.ArgumentList> argResult = this
        .parseArgumentList(TokenKind.RIGHT_BRACKET, reportError: reportError);
    if(argResult.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.ArrayLiteral>();
      // MARK(STOP PARSING)
    }
    // consume RIGHT_BRACKET
    if(!_isCurrentOfKind(TokenKind.RIGHT_BRACKET)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // TODO: report error
      }
      return new Option<mammouth.ArrayLiteral>();
      // MARK(STOP PARSING)
    }
    leftBracket = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.ArrayLiteral>.Some(
        new mammouth.ArrayLiteralImpl.syntactic(
            typeArguments, leftBracket, argResult.some.arguments,
            rightBracket));
  }

  /**
   *      RangeLiteral := LEFT_BRACKET (Expression)? (RANGE_DOUBLEDOT|RANGE_TRIPLEDOT) (Expression)? RIGHT_BRACKET
   */
  Option<mammouth.RangeLiteral> parseRangeLiteral(
      {bool allowOptionalRightLimit = false, bool reportError = true}) {
    Token leftBracket, rangeOperator, rightBracket;
    mammouth.Expression rangeStart, rangeEnd;
    // consume LEFT_BRACKET
    if(!_isCurrentOfKind(TokenKind.LEFT_BRACKET)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
      }
      return new Option<mammouth.RangeLiteral>();
      // MARK(STOP PARSING)
    }
    leftBracket = _current;
    _current = _current.next; // MARK(MOVE TOKEN)

    Option<mammouth.Expression> result;
    if(!_isCurrentOfKind(TokenKind.RANGE_DOUBLEDOT) &&
        !_isCurrentOfKind(TokenKind.RANGE_TRIPLEDOT)) {
      result = this.parseExpression(reportError: reportError);
      if(result.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.RangeLiteral>();
        // MARK(STOP PARSING)
      }
      rangeStart = result.some;
    }
    // consume RANGE_DOUBLEDOT or RANGE_TRIPLEDOT
    if(!(_isCurrentOfKind(TokenKind.RANGE_DOUBLEDOT) ||
        _isCurrentOfKind(TokenKind.RANGE_TRIPLEDOT))) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // TODO: report error
      }
      return new Option<mammouth.RangeLiteral>();
      // MARK(STOP PARSING)
    }
    rangeOperator = _current;
    _current = _current.next; // MARK(MOVE TOKEN)

    Token startToken = _current;
    result = this.parseExpression(reportError: reportError);
    if(result.isNone && !allowOptionalRightLimit) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.RangeLiteral>();
      // MARK(STOP PARSING)
    } else if(result.isSome) {
      rangeEnd = result.some;
    } else {
      _current = startToken;
    }
    // consume RIGHT_BRACKET
    if(!_isCurrentOfKind(TokenKind.RIGHT_BRACKET)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // TODO: report error
      }
      return new Option<mammouth.RangeLiteral>();
      // MARK(STOP PARSING)
    }
    leftBracket = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.RangeLiteral>.Some(
        new mammouth.RangeLiteralImpl.syntactic(
            leftBracket, rangeStart, rangeOperator, rangeEnd, rightBracket));
  }

  /**
   *      MapLiteral := (LESS_THAN TypeAnnotation COMMA TypeAnnotation GREATER_THAN)? LEFT_BRACE MapKeys RIGHT_BRACE
   *
   *      MapBody := MapEntry (COMMA MapBody)?
   *               | INDENT (MapEntry ((COMMA)? (MINDENT)? MapEntry)?)? OUTDENT
   */
  Option<mammouth.MapLiteral> parseMapLiteral(
      {mammouth.TypeArgumentList typeArguments = null,
        bool reportError = true}) {
    Token leftBrace, rightBrace;
    // consume LEFT_BRACE
    if(!_isCurrentOfKind(TokenKind.LEFT_BRACE)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
        // TODO: report error here if start with type generic
      }
      return new Option<mammouth.MapLiteral>();
      // MARK(STOP PARSING)
    }
    leftBrace = _current;
    _current = _current.next; // MARK(MOVE TOKEN)

    List<mammouth.MMapEntry> mapEntries = new List<mammouth.MMapEntry>();
    Function parseIndentedMapBody = () {
      // consume INDENT
      _current = _current.next; // MARK(MOVE TOKEN)
      // parse arguments
      while(!_isCurrentOfKind(TokenKind.OUTDENT)) {
        Option<mammouth.MMapEntry> entryResult =
        this.parseMapEntry(reportError: reportError);
        if(entryResult.isNone) {
          // TODO: throw an error
          return new Option<mammouth.ArgumentList>();
          // MARK(STOP PARSING)
        }
        mapEntries.add(entryResult.some);
        if(_isCurrentOfKind(TokenKind.COMMA)) {
          // consume COMMA
          _current = _current.next; // MARK(MOVE TOKEN)
        }
        if(_isCurrentOfKind(TokenKind.MINDENT)) {
          // consume MINDENT
          _current = _current.next; // MARK(MOVE TOKEN)
        }
      }
      // consume OUTDENT
      _current = _current.next; // MARK(MOVE TOKEN)
    };
    if(_isCurrentOfKind(TokenKind.INDENT)) {
      parseIndentedMapBody();
    } else {
      while(!_isCurrentOfKind(TokenKind.RIGHT_BRACE)) {
        Option<mammouth.MMapEntry> entryResult =
        this.parseMapEntry(reportError: reportError);
        if(entryResult.isNone) {
          // TODO: throw an error
          return new Option<mammouth.MapLiteral>();
          // MARK(STOP PARSING)
        }
        mapEntries.add(entryResult.some);
        if(_isCurrentOfKind(TokenKind.COMMA)) {
          // consume COMMA
          _current = _current.next; // MARK(MOVE TOKEN)
        }
        if(_isCurrentOfKind(TokenKind.INDENT)) {
          parseIndentedMapBody();
        }
      }
    }

    // consume RIGHT_BRACE
    if(!_isCurrentOfKind(TokenKind.RIGHT_BRACE)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // TODO: report error
      }
      return new Option<mammouth.MapLiteral>();
      // MARK(STOP PARSING)
    }
    rightBrace = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.MapLiteral>.Some(
        new mammouth.MapLiteralImpl.syntactic(
            typeArguments, leftBrace, mapEntries, rightBrace));
  }

  /**
   *      MapEntry := Expression COLON (Expression | (INDENT Expression OUTDENT))
   */
  Option<mammouth.MMapEntry> parseMapEntry({bool reportError = true}) {
    Token colon;
    Option<mammouth.Expression> keyResult =
    this.parseExpression(reportError: reportError);
    if(keyResult.isNone) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.MMapEntry>();
      // MARK(STOP PARSING)
    }
    // consume COLON
    if(!_isCurrentOfKind(TokenKind.COLON)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // TODO: report error
      }
      return new Option<mammouth.MMapEntry>();
      // MARK(STOP PARSING)
    }
    colon = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    bool expectOutdent = false;
    if(_isCurrentOfKind(TokenKind.INDENT)) {
      _current = _current.next; // MARK(MOVE TOKEN)
      expectOutdent = true;
    }
    // MARK(MAKE NODE)
    Option<mammouth.Expression> valueResult =
    this.parseExpression(reportError: reportError);
    if(valueResult.isNone) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.MMapEntry>();
      // MARK(STOP PARSING)
    }
    if(expectOutdent) {
      // consume RIGHT_BRACKET
      if(!_isCurrentOfKind(TokenKind.OUTDENT)) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // TODO: report error
        }
        return new Option<mammouth.MMapEntry>();
        // MARK(STOP PARSING)
      }
      _current = _current.next; // MARK(MOVE TOKEN)
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.MMapEntry>.Some(
        new mammouth.MMapEntryImpl.syntactic(
            keyResult.some, colon, valueResult.some));
  }

  /**
   *      ParenthesisExpression := LEFT_PAREN Expression RIGHT_PAREN
   *                              | LEFT_PAREN INDENT Expression OUTDENT RIGHT_PAREN
   */
  Option<mammouth.ParenthesisExpression> parseParenthesisExpression(
      {bool reportError = true}) {
    Token leftParen, rightParen;
    // consume LEFT_PAREN
    if(!_isCurrentOfKind(TokenKind.LEFT_PAREN)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // MARK(UNREACHABLE ZONE)
        throw "Unreachable zone!";
        // MARK(STOP PARSING)
        // TODO: report error here if start with type generic
      }
      return new Option<mammouth.ParenthesisExpression>();
      // MARK(STOP PARSING)
    }
    leftParen = _current;
    _current = _current.next; // MARK(MOVE TOKEN)

    Option<mammouth.Expression> expressionResult =
    this.parseExpression(reportError: reportError);
    if(expressionResult.isNone) {
      if(reportError) {
        // TODO: throw an error
      }
      return new Option<mammouth.ParenthesisExpression>();
      // MARK(STOP PARSING)
    }

    bool expectOutdent = false;
    if(_isCurrentOfKind(TokenKind.INDENT)) {
      expectOutdent = true;
      _current = _current.next; // MARK(MOVE TOKEN)
    }

    // consume RIGHT_PAREN
    if(!_isCurrentOfKind(TokenKind.RIGHT_PAREN)) {
      if(reportError) {
        // MARK(REPORT ERROR)
        // TODO: report error
      }
      return new Option<mammouth.ParenthesisExpression>();
      // MARK(STOP PARSING)
    }
    rightParen = _current;
    _current = _current.next; // MARK(MOVE TOKEN)

    if(expectOutdent) {
      if(!_isCurrentOfKind(TokenKind.OUTDENT)) {
        if(reportError) {
          // MARK(REPORT ERROR)
          // TODO: report error
        }
        return new Option<mammouth.ParenthesisExpression>();
        // MARK(STOP PARSING)
      }
    }

    // MARK(MAKE NODE)
    return new Option<mammouth.ParenthesisExpression>.Some(
        new mammouth.ParenthesisExpressionImpl.syntactic(
            leftParen, expressionResult.some, rightParen));
  }

  /**
   *      Literal := BooleanLiteral
   *               | StringLiteral
   *               | IntegerLiteral
   *               | FloatLiteral
   */
  Option<mammouth.Literal> parseLiteral({bool reportError = true}) {
    if(_isCurrentOfKind(TokenKind.BOOLEAN)) {
      return this.parseBooleanLiteral(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.STRING)) {
      return this.parseStringLiteral(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.INTEGER)) {
      return this.parseIntegerLiteral(reportError: reportError);
    } else if(_isCurrentOfKind(TokenKind.FLOAT)) {
      return this.parseFloatLiteral(reportError: reportError);
    }
    // TODO: report error
    return new Option<mammouth.Literal>();
    // MARK(STOP PARSING)
  }

  /**
   *      BooleanLiteral := BOOLEAN
   */
  Option<mammouth.BooleanLiteral> parseBooleanLiteral(
      {bool reportError = true}) {
    Token token;
    if(!_isCurrentOfKind(TokenKind.BOOLEAN)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.BooleanLiteral>();
      // MARK(STOP PARSING)
    }
    token = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.BooleanLiteral>.Some(
        new mammouth.BooleanLiteralImpl.syntactic(token));
  }

  /**
   *      StringLiteral := STRING
   */
  Option<mammouth.StringLiteral> parseStringLiteral({bool reportError = true}) {
    Token token;
    if(!_isCurrentOfKind(TokenKind.STRING)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.StringLiteral>();
      // MARK(STOP PARSING)
    }
    token = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.StringLiteral>.Some(
        new mammouth.StringLiteralImpl.syntactic(token));
  }

  /**
   *      IntegerLiteral := INTEGER
   */
  Option<mammouth.IntegerLiteral> parseIntegerLiteral(
      {bool reportError = true}) {
    Token token;
    if(!_isCurrentOfKind(TokenKind.INTEGER)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.IntegerLiteral>();
      // MARK(STOP PARSING)
    }
    token = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.IntegerLiteral>.Some(
        new mammouth.IntegerLiteralImpl.syntactic(token));
  }

  /**
   *      FloatLiteral := FLOAT
   */
  Option<mammouth.FloatLiteral> parseFloatLiteral({bool reportError = true}) {
    Token token;
    if(!_isCurrentOfKind(TokenKind.FLOAT)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.FloatLiteral>();
      // MARK(STOP PARSING)
    }
    token = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.FloatLiteral>.Some(
        new mammouth.FloatLiteralImpl.syntactic(token));
  }

  /**
   *      SimpleIdentifier := NAME
   */
  Option<mammouth.SimpleIdentifier> parseSimpleIdentifier(
      {bool reportError = true}) {
    Token token;
    if(!_isCurrentOfKind(TokenKind.NAME)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.SimpleIdentifier>();
      // MARK(STOP PARSING)
    }
    token = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.SimpleIdentifier>.Some(
        new mammouth.SimpleIdentifierImpl.syntactic(token));
  }

  /**
   *      TypeAnnotation := TypeName
   */
  Option<mammouth.TypeAnnotation> parseTypeAnnotation(
      {bool reportError = true}) {
    return this.parseTypeName();
  }

  /**
   *      TypeName := SimpleIdentifier
   */
  Option<mammouth.TypeName> parseTypeName({bool reportError = true}) {
    mammouth.TypeArgumentList typeArguments;
    Option<mammouth.SimpleIdentifier> result =
    this.parseSimpleIdentifier(reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.TypeName>();
      // MARK(STOP PARSING)
    }
    if(_isCurrentOfKind(TokenKind.LESS_THAN)) {
      Option<mammouth.TypeArgumentList> typeArgsResult =
      this.parseTypeArgumentList(reportError: reportError);
      if(typeArgsResult.isNone) {
        if(reportError) {
          // TODO: report error
        }
        return new Option<mammouth.TypeName>();
        // MARK(STOP PARSING)
      }
      typeArguments = typeArgsResult.some;
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.TypeName>.Some(
        new mammouth.TypeNameImpl(result.some, typeArguments));
  }

  /**
   *      ParameterList := LEFT_PAREN (Parameter (COMMA Parameter)*)? RIGHT_PAREN
   */
  Option<mammouth.ParameterList> parseParameterList({bool reportError = true}) {
    Token leftParen, rightParen;
    List<Token> commas = new List<Token>();
    List<mammouth.Parameter> parameters = new List<mammouth.Parameter>();
    if(!_isCurrentOfKind(TokenKind.LEFT_PAREN)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.ParameterList>();
      // MARK(STOP PARSING)
    }
    leftParen = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    bool isOptional = false;
    while(!_isCurrentOfKind(TokenKind.RIGHT_PAREN)) {
      if(_isCurrentOfKind(TokenKind.LEFT_BRACKET)) {
        isOptional = true;
        _current = _current.next; // MARK(MOVE TOKEN)
      }
      Option<mammouth.Parameter> result = this.parseParameter(
          isOptional: isOptional);
      if(result.isNone) {
        // TODO: throw an error
        return new Option<mammouth.ParameterList>();
        // MARK(STOP PARSING)
      }
      parameters.add(result.some);
      if(isOptional && _isCurrentOfKind(TokenKind.RIGHT_BRACKET)) {
        _current = _current.next; // MARK(MOVE TOKEN)
        break;
      }
      if(!_isCurrentOfKind(TokenKind.RIGHT_PAREN)) {
        if(!_isCurrentOfKind(TokenKind.COMMA)) {
          if(reportError) {
            // TODO: report error
          }
          return new Option<mammouth.ParameterList>();
          // MARK(STOP PARSING)
        }
        commas.add(_current);
        // MARK(MOVE TOKEN)
        _current = _current.next;
      }
    }
    if(!_isCurrentOfKind(TokenKind.RIGHT_PAREN)) {
      // TODO: throw an error
      return new Option<mammouth.ParameterList>();
      // MARK(STOP PARSING)
    }
    rightParen = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.ParameterList>.Some(
        new mammouth.ParameterListImpl.syntactic(
            leftParen, parameters, rightParen));
  }

  /**
   *      SimpleParameter := (TypeAnnotation)? SimpleIdentifier
   */
  Option<mammouth.Parameter> parseParameter(
      {bool isOptional = false, bool reportError = true}) {
    mammouth.TypeAnnotation type;
    mammouth.SimpleIdentifier name;
    Token equal;
    mammouth.Expression initializer;

    bool isTyped = true;
    Token startToken = _current;

    // first, we try to parse a type, without reporting error
    // TODO: or FN
    Option<mammouth.TypeAnnotation> typeResult = this.parseTypeAnnotation(
        reportError: false);
    if(typeResult.isSome) {
      type = typeResult.some;

      // if a type is parsed, we try to parse a name, without reporting error
      Option<mammouth.SimpleIdentifier> nameResult = this.parseSimpleIdentifier(
          reportError: false);
      if(nameResult.isSome) {
        name = nameResult.some;
        if(_isCurrentOfKind(TokenKind.LEFT_PAREN)) {
          Token leftParen = _current;
          List<mammouth.TypeAnnotation> types = [];
          _current = _current.next; // MARK(MOVE TOKEN)
          while(!_isCurrentOfKind(TokenKind.RIGHT_PAREN)) {
            Option<mammouth.TypeAnnotation> paraType = this.parseTypeAnnotation(
                reportError: false);
            if(paraType.isNone) {
              // TODO: report error
              return new Option<mammouth.Parameter>();
            }
            types.add(paraType.some);
            if(_isCurrentOfKind(TokenKind.COMMA)) {
              _current = _current.next; // MARK(MOVE TOKEN)
            }
          }
          if(!_isCurrentOfKind(TokenKind.RIGHT_PAREN)) {
            // TODO: throw an error
            return new Option<mammouth.Parameter>();
            // MARK(STOP PARSING)
          }
          Token rightParen = _current;
          _current = _current.next; // MARK(MOVE TOKEN)
          return new Option<mammouth.Parameter>.Some(
              new mammouth.ClosureParameterImpl.syntactic(
                  type, name, leftParen, types, rightParen, isOptional));
        }
      } else {
        isTyped = false;
        type = null;
      }
    }

    if(!isTyped) {
      // MARK(MAKE NODE)
      _current = startToken;
      Option<mammouth.SimpleIdentifier> nameResult = this.parseSimpleIdentifier(
          reportError: false);
      if(nameResult.isNone) {
        // TODO: throw an error
        return new Option<mammouth.SimpleParameter>();
        // MARK(STOP PARSING)
      }
      name = nameResult.some;
    }

    if(isOptional && _isCurrentOfKind(TokenKind.ASSIGN_EQUAL)) {
      equal = _current;
      _current = _current.next; // MARK(MOVE TOKEN)
      Option<mammouth.Expression> initializerResult =
      this.parseExpression(reportError: false);
      if(initializerResult.isNone) {
        // TODO: throw an error
        return new Option<mammouth.SimpleParameter>();
        // MARK(STOP PARSING)
      }
      initializer = initializerResult.some;
    }

    // MARK(MAKE NODE)
    return new Option<mammouth.SimpleParameter>.Some(
        new mammouth.SimpleParameterImpl.syntactic(
            type, name, equal, initializer, isOptional));
  }

  /**
   *      ArgumentList := Expression (COMMA ArgumentList)?
   *                    | INDENT (Expression ((COMMA)? (MINDENT)? Expression)?)? OUTDENT
   */
  Option<mammouth.ArgumentList> parseArgumentList(TokenKind endToken,
      {bool reportError: true}) {
    List<mammouth.Expression> arguments = new List<mammouth.Expression>();
    Function parseIndentedArguments = () {
      // consume INDENT
      _current = _current.next; // MARK(MOVE TOKEN)
      // parse arguments
      while(!_isCurrentOfKind(TokenKind.OUTDENT)) {
        Option<mammouth.Expression> argumentResult =
        this.parseExpression(reportError: reportError);
        if(argumentResult.isNone) {
          // TODO: throw an error
          return new Option<mammouth.ArgumentList>();
          // MARK(STOP PARSING)
        }
        arguments.add(argumentResult.some);
        if(_isCurrentOfKind(TokenKind.COMMA)) {
          // consume COMMA
          _current = _current.next; // MARK(MOVE TOKEN)
        }
        if(_isCurrentOfKind(TokenKind.MINDENT)) {
          // consume MINDENT
          _current = _current.next; // MARK(MOVE TOKEN)
        }
      }
      // consume OUTDENT
      _current = _current.next; // MARK(MOVE TOKEN)
    };
    if(_isCurrentOfKind(TokenKind.INDENT)) {
      parseIndentedArguments();
    } else {
      while(!_isCurrentOfKind(endToken)) {
        Option<mammouth.Expression> argumentResult =
        this.parseExpression(reportError: reportError);
        if(argumentResult.isNone) {
          // TODO: throw an error
          return new Option<mammouth.ArgumentList>();
          // MARK(STOP PARSING)
        }
        arguments.add(argumentResult.some);
        if(_isCurrentOfKind(TokenKind.COMMA)) {
          // consume COMMA
          _current = _current.next; // MARK(MOVE TOKEN)
        }
        if(_isCurrentOfKind(TokenKind.INDENT)) {
          parseIndentedArguments();
        }
      }
    }
    // MARK(MAKE NODE)
    return new Option<mammouth.ArgumentList>.Some(
        new mammouth.ArgumentListImpl(arguments));
  }

  /**
   *      TypeArgumentList := TypeAnnotation (COMMA TypeArgumentList)?
   *                        | INDENT (TypeAnnotation ((COMMA)? (MINDENT)? TypeAnnotation)?)? OUTDENT
   */
  Option<mammouth.TypeArgumentList> parseTypeArgumentList(
      {bool reportError: true}) {
    Token leftAngle, rightAngle;
    List<mammouth.TypeAnnotation> typeArguments =
    new List<mammouth.TypeAnnotation>();
    if(!_isCurrentOfKind(TokenKind.LESS_THAN)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.TypeArgumentList>();
      // MARK(STOP PARSING)
    }
    leftAngle = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Function parseIndentedTypeArguments = () {
      // consume INDENT
      _current = _current.next; // MARK(MOVE TOKEN)
      // parse arguments
      while(!_isCurrentOfKind(TokenKind.OUTDENT)) {
        Option<mammouth.TypeAnnotation> argumentResult =
        this.parseTypeAnnotation(reportError: reportError);
        if(argumentResult.isNone) {
          // TODO: throw an error
          return new Option<mammouth.TypeArgumentList>();
          // MARK(STOP PARSING)
        }
        typeArguments.add(argumentResult.some);
        if(_isCurrentOfKind(TokenKind.COMMA)) {
          // consume COMMA
          _current = _current.next; // MARK(MOVE TOKEN)
        }
        if(_isCurrentOfKind(TokenKind.MINDENT)) {
          // consume MINDENT
          _current = _current.next; // MARK(MOVE TOKEN)
        }
      }
      // consume OUTDENT
      _current = _current.next; // MARK(MOVE TOKEN)
    };
    if(_isCurrentOfKind(TokenKind.INDENT)) {
      parseIndentedTypeArguments();
    } else {
      while(!_isCurrentOfKind(TokenKind.GREATER_THAN)) {
        Option<mammouth.TypeAnnotation> argumentResult =
        this.parseTypeAnnotation(reportError: reportError);
        if(argumentResult.isNone) {
          // TODO: throw an error
          return new Option<mammouth.TypeArgumentList>();
          // MARK(STOP PARSING)
        }
        typeArguments.add(argumentResult.some);
        if(_isCurrentOfKind(TokenKind.COMMA)) {
          // consume COMMA
          _current = _current.next; // MARK(MOVE TOKEN)
        }
        if(_isCurrentOfKind(TokenKind.INDENT)) {
          parseIndentedTypeArguments();
        }
      }
    }
    if(!_isCurrentOfKind(TokenKind.GREATER_THAN)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.TypeArgumentList>();
      // MARK(STOP PARSING)
    }
    rightAngle = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.TypeArgumentList>.Some(
        new mammouth.TypeArgumentListImpl(
            leftAngle, typeArguments, rightAngle));
  }

  /**
   *      TypeParameterList := TypeParameter (COMMA TypeParameterList)?
   *                         | INDENT (TypeParameter ((COMMA)? (MINDENT)? TypeParameter)?)? OUTDENT
   */
  Option<mammouth.TypeParameterList> parseTypeParameterList(
      {bool reportError: true}) {
    Token leftAngle, rightAngle;
    List<mammouth.TypeParameter> typeParameters = <mammouth.TypeParameter>[];
    if(!_isCurrentOfKind(TokenKind.LESS_THAN)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.TypeParameterList>();
      // MARK(STOP PARSING)
    }
    leftAngle = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    Function parseIndentedTypeParameters = () {
      // consume INDENT
      _current = _current.next; // MARK(MOVE TOKEN)
      // parse arguments
      while(!_isCurrentOfKind(TokenKind.OUTDENT)) {
        Option<mammouth.TypeParameter> parameterResult = this
            .parseTypeParameter(reportError: reportError);
        if(parameterResult.isNone) {
          // TODO: throw an error
          return new Option<mammouth.TypeParameterList>();
          // MARK(STOP PARSING)
        }
        typeParameters.add(parameterResult.some);
        if(_isCurrentOfKind(TokenKind.COMMA)) {
          // consume COMMA
          _current = _current.next; // MARK(MOVE TOKEN)
        }
        if(_isCurrentOfKind(TokenKind.MINDENT)) {
          // consume MINDENT
          _current = _current.next; // MARK(MOVE TOKEN)
        }
      }
      // consume OUTDENT
      _current = _current.next; // MARK(MOVE TOKEN)
    };
    if(_isCurrentOfKind(TokenKind.INDENT)) {
      parseIndentedTypeParameters();
    } else {
      while(!_isCurrentOfKind(TokenKind.GREATER_THAN)) {
        Option<mammouth.TypeParameter> parameterResult = this
            .parseTypeParameter(reportError: reportError);
        if(parameterResult.isNone) {
          // TODO: throw an error
          return new Option<mammouth.TypeParameterList>();
          // MARK(STOP PARSING)
        }
        typeParameters.add(parameterResult.some);
        if(_isCurrentOfKind(TokenKind.COMMA)) {
          // consume COMMA
          _current = _current.next; // MARK(MOVE TOKEN)
        }
        if(_isCurrentOfKind(TokenKind.INDENT)) {
          parseIndentedTypeParameters();
        }
      }
    }
    if(!_isCurrentOfKind(TokenKind.GREATER_THAN)) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.TypeParameterList>();
      // MARK(STOP PARSING)
    }
    rightAngle = _current;
    _current = _current.next; // MARK(MOVE TOKEN)
    // MARK(MAKE NODE)
    return new Option<mammouth.TypeParameterList>.Some(
        new mammouth.TypeParameterListImpl.syntactic(
            leftAngle, typeParameters, rightAngle));
  }

  /**
   *      TypeParameter := SimpleIdentifier
   */
  Option<mammouth.TypeParameter> parseTypeParameter({bool reportError = true}) {
    Option<mammouth.SimpleIdentifier> result = this.parseSimpleIdentifier(
        reportError: reportError);
    if(result.isNone) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.TypeParameter>();
    }
    return new Option<mammouth.TypeParameter>.Some(
        new mammouth.TypeParameterImpl(result.some));
  }

  /**
   *      AssignementOperator := ASSIGN
   */
  Option<mammouth.AssignmentOperator> parseAssignementOperator(
      {bool reportError = true}) {
    Token token;
    if(!this.isAssignmentOperator()) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.AssignmentOperator>();
      // MARK(STOP PARSING)
    }
    token = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.AssignmentOperator>.Some(
        new mammouth.AssignmentOperatorImpl.syntactic(token));
  }

  /**
   *      BinaryOperator := BINARY
   */
  Option<mammouth.BinaryOperator> parseBinaryOperator(
      {bool reportError = true}) {
    Token token;
    if(!this.isBinaryOperator()) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.BinaryOperator>();
      // MARK(STOP PARSING)
    }
    token = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.BinaryOperator>.Some(
        new mammouth.BinaryOperatorImpl.syntactic(token));
  }

  /**
   *      UpdateOperator := UPDATE
   */
  Option<mammouth.UpdateOperator> parseUpdateOperator(
      {bool reportError = true}) {
    Token token;
    if(!this.isUpdateOperator()) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.UpdateOperator>();
      // MARK(STOP PARSING)
    }
    token = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.UpdateOperator>.Some(
        new mammouth.UpdateOperatorImpl.syntactic(token));
  }

  /**
   *      UnaryOperator := UNARY | PLUS | MINUS
   */
  Option<mammouth.UnaryOperator> parseUnaryOperator({bool reportError = true}) {
    Token token;
    if(!this.isUnaryOperator()) {
      if(reportError) {
        // TODO: report error
      }
      return new Option<mammouth.UnaryOperator>();
      // MARK(STOP PARSING)
    }
    token = _current;
    // MARK(MOVE TOKEN)
    _current = _current.next;
    // MARK(MAKE NODE)
    return new Option<mammouth.UnaryOperator>.Some(
        new mammouth.UnaryOperatorImpl.syntactic(token));
  }

  bool isAssignmentOperator() {
    if(_current != null && _isCurrentOfKind(TokenKind.ASSIGN)) {
      return true;
    }
    return false;
  }

  bool isBinaryOperator() {
    if(_current != null && _isCurrentOfKind(TokenKind.BINARY)) {
      return true;
    }
    return false;
  }

  bool isUpdateOperator() {
    if(_current != null && _isCurrentOfKind(TokenKind.UPDATE)) {
      return true;
    }
    return false;
  }

  bool isUnaryOperator() {
    if(_current != null &&
        (_isCurrentOfKind(TokenKind.UNARY) ||
            _isCurrentOfKind(TokenKind.PLUS) ||
            _isCurrentOfKind(TokenKind.MINUS))) {
      return true;
    }
    return false;
  }

  bool _isOfKind(Token token, TokenKind kind) {
    return token != null && token.kind == kind;
  }

  bool _isCurrentOfKind(TokenKind kind) {
    return _isOfKind(_current, kind);
  }

  void _reportExpected(TokenKind kind) {
    int offset,
        length = 0;
    ParserErrorCode errorCode;
    List<String> arguments = <String>[];
    if(kind == TokenKind.END_TAG) {
      if(_current.kind == TokenKind.EOS) {
        offset = _source.content.length;
        arguments.add("end of file reached");
      } else {
        offset = _current.offset;
        length = _current.length;
        arguments.add("found ${_current.kind.name}");
      }
      errorCode = ParserErrorCode.EXPECTED_END_TAG;
    } else if(kind == TokenKind.MINDENT) {
      if(_current.kind == TokenKind.INDENT) {
        offset = _current.endOffset;
      }
      errorCode = ParserErrorCode.INDENTATION_LEVEL_IN_BETWEEN;
    } else if(kind == TokenKind.INDENT) {
      offset = _current.endOffset;
      errorCode = ParserErrorCode.EXPECTED_INDENT_BLOCK;
    }
    _report(
        new AnalysisError(_source, offset, length, errorCode, arguments));
  }

  _reportErrorCode(ParserErrorCode errorCode, int offset, int length,
      [List<String> arguments = null]) {
    _report(new AnalysisError(_source, offset, length, errorCode,
        arguments == null ? [] : arguments));
  }

  void _report(AnalysisError error) {
    _diagnosticEngine.report(_source, error);
  }
}
