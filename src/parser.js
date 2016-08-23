// imports
var Position = require("./position");
var Nodes = require("./nodes");
var consts = require("./consts");

// Parser takes an input tokens stream/list, and generates an AST
function Parser() {
    // nothing go here
}

Parser.prototype.setInput = function(tokens, errorM, filename) {
    this.input = tokens;
    this._i = 0;
    this.errorM = errorM;
    this.filename = filename === undefined ? null : filename;
    this.endPosition = new Position(filename);
};

// Tokens
// Check if we have anymore token
Parser.prototype.hasNextToken = function() {
    return this._i < this.input.length;
};

// Get the current token
Parser.prototype.currentToken = function() {
    return this.input[this._i];
};

// Go to the next token
Parser.prototype.next = function() {
    var token = this.currentToken();
    this._i++;
    this.endPosition = token.location.end === null ? token.location.start.clone() : token.location.start.clone();
    return token;
};

// Consume a token of type or throw error
Parser.prototype.consume = function(type) {
    if(this.currentToken().type != type) {
        this.fail({expected: type});
    }
    return this.next();
};

// Error handling
Parser.prototype.fail = function(arg) {
    var token = null, expected = null, message = null;
    if(arg === undefined) arg = {};
    if(arg.hasOwnProperty('token')) token = arg.token;
    if(arg.hasOwnProperty('expected')) expected = arg.expected;
    if(arg.hasOwnProperty('message')) message = arg.message;
    if(token === null) {
        token = this.currentToken();
    }
    if(message === null){
        if(expected === null) {
            var what;
            if(token.type == 'IDENTIFIER') {
                what = 'identifier ' + token.value;
            } else {
                what = token.value;
            }
            this.errorM.let(100, {
                what: what,
                pos: token.location.start
            });
            return;
        } else {
            message = 'Expected ' + expected  + ' but found ' + token;
            this.errorM.let(101, {
                expected: expected,
                found: token.type,
                pos: token.location.start
            });
        }
    } else {

    }
    // TODO: error : throw better error
    throw message;
};

// Parsing

// Parse Document (root)
//      Document := DocumentSections
//      DocumentSections := DocumentSection
//                        | DocumentSections DocumentSection
//      DocumentSection := RAWSection
//                       | Script
Parser.prototype.parseDocument = function() {
    var node = new Nodes.Document();
    if(this.hasNextToken()) {
        node.location.start = this.currentToken().location.start.clone();
        while(this.hasNextToken()) {
            switch(this.currentToken().type) {
                case 'RAW':
                    node.sections.push(this.parseRAW());
                    break;
                case 'START_TAG':
                    node.sections.push(this.parseScript());
                    break;
                case 'INTERPOLATION_START_TAG':
                    node.sections.push(this.parseInterpolation())
                default:
                    // TODO: error
            }
        }
        node.location.end = this.endPosition.clone();
    }
    return node;
};

// Parse RAW text setion
//      RAWSection := RAW
Parser.prototype.parseRAW = function() {
    var token = this.consume('RAW');
    var node = new Nodes.RAW(token.value);
    node.location = token.location.clone();
    return node;
};

// Parse mammouth script
//      Script := START_TAG Block END_TAG
Parser.prototype.parseScript = function() {
    var startPos = this.consume('START_TAG').location.start.clone();
    var node = new Nodes.Script(this.parseBlock(true));
    var endPos = this.consume('END_TAG').location.end.clone();
    node.location.start = startPos;
    node.location.end = endPos;
    return node;
};

// Parse mammouth interpolation
//      Script := INTERPOLATION_START_TAG Expression INTERPOLATION_END_TAG
Parser.prototype.parseInterpolation = function() {
    var startPos = this.consume('INTERPOLATION_START_TAG').location.start.clone();
    var node = new Nodes.Script(new Nodes.Block([new Nodes.Echo(this.parseExpression())]));
    node.body.statements[0].location = node.body.statements[0].argument.location.clone();
    node.body.location = node.body.statements[0].location.clone();
    var endPos = this.consume('INTERPOLATION_END_TAG').location.end.clone();
    node.location.start = startPos;
    node.location.end = endPos;
    return node;
};

// Parse block of code
//      Block := INDENT Statements OUTDENT
//             | Statement
//      Statements := Statement
//                  | Statements MINDENT Statement                 

Parser.prototype.parseBlock = function(allowInline) {
    var node, startPos;
    allowInline = allowInline === undefined ? false : allowInline;
    // look for inline block
    if(allowInline && this.currentToken().type != 'INDENT') {
        node = this.parseStatement();
        node = new Nodes.Block([node]);
        node.location = node.statements[0].location.clone();
        return node;
    }
    // parse a no-inline block
    startPos = this.consume('INDENT').location.start.clone();
    node = new Nodes.Block();
    while(this.currentToken().type != 'OUTDENT') {
        node.statements.push(this.parseStatement());
        if(this.currentToken().type != 'OUTDENT') {
            this.consume('MINDENT');
        }
    }
    node.location.start = startPos;
    node.location.end = this.consume('OUTDENT').location.start.clone();
    return node;
};

// Parse statement
//      Statement := SimpleStatement IfHeader IfElses
//                 | SimpleStatement IfHeader
//                 | SimpleStatement ForSource
//                 | SimpleStatement WhileSource
//                 | Namespace
//                 | Class
//                 | Interface
//                 | Use
//                 | Comment
//      SimpleStatement := ExpressionStatement
//                       | Include
//                       | Require
//                       | Section
//                       | Break
//                       | Constant
//                       | Continue
//                       | Delete
//                       | Global
//                       | Goto
//                       | Return
//                       | Throw
Parser.prototype.parseStatement = function() {
    var statement, block;
    if(this.currentToken().type == 'IDENTIFIER' && this.input[this._i + 1] !== undefined && this.input[this._i + 1].type == ':') {
        statement = this.parseSection();
    }
    else switch(this.currentToken().type) {
        case 'INCLUDE':
            statement = this.parseInclude();
            break;
        case 'REQUIRE':
            statement = this.parseRequire();
            break;
        case 'BREAK':
            statement = this.parseBreak();
            break;
        case 'CONST':
            statement = this.parseConstant();
            break;
        case 'CONTINUE':
            statement = this.parseContinue();
            break;
        case 'DELETE':
            statement = this.parseDelete();
            break;
        case 'GLOBAL':
            statement = this.parseGlobal();
            break;
        case 'GOTO':
            statement = this.parseGoto();
            break;
        case 'RETURN':
            statement = this.parseReturn();
            break;
        case 'THROW':
            statement = this.parseThrow();
            break;
        case 'NAMESPACE':
            return this.parseNamespace();
        case 'CLASS':
            return this.parseClass();
        case 'INTERFACE':
            return this.parseInterface();
        case 'USE':
            return this.parseUse();
        case 'COMMENT':
            return this.parseComment();
        default:
            statement = this.parseExpressionStatement();
    }
    switch(this.currentToken().type) {
        case 'IF':
            var ifHeader = this.parseIfHeader();
            block = new Nodes.Block([statement]);
            block.location = statement.location.clone();
            ifHeader.body = block;
            ifHeader.location.start = statement.location.start.clone();
            ifHeader.location.end = ifHeader.condition.location.end.clone();
            if(this.currentToken().type == 'ELSE') {
                ifHeader.elses = this.parseIfElses();
                ifHeader.location.end = ifHeader.elses[ifHeader.elses.length - 1].location.end.clone();
            }
            statement = ifHeader;
            break;
        case 'FOR':
            var forSource = this.parseForSource();
            block = new Nodes.Block([statement]);
            block.location = statement.location.clone();
            statement = new Nodes.For(forSource, block);
            statement.location.start = block.location.start.clone();
            statement.location.end = forSource.endPos.clone();
            break;
        case 'UNTIL':
        case 'WHILE':
            var whileSource = this.parseWhileSource();
            whileSource.body = new Nodes.Block([statement]);
            whileSource.body.location = statement.location.end.clone();
            statement = whileSource;
            break;
    }
    return statement;
};

// Parse comment
//      Comment := COMMENT
Parser.prototype.parseComment = function() {
    var node = new Nodes.Comment();
    var token = this.consume('COMMENT');
    node.value = token.value;
    node.location = token.location.clone();
    return node;
};

// Parse include statement
//      Include := INCLUDE ONCE Expression
//               | INCLUDE Expression
Parser.prototype.parseInclude = function() {
    var node = new Nodes.Include();
    node.location.start = this.consume('INCLUDE').location.start.clone();
    if(this.currentToken().type == 'ONCE') {
        this.consume('ONCE');
        node.isOnce = true;
    }
    node.path = this.parseExpression(false);
    node.location.end = node.path.location.end.clone();
    return node;
};

// Parse require statement
//      Require := REQUIRE ONCE Expression
//               | REQUIRE Expression
Parser.prototype.parseRequire = function() {
    var node = new Nodes.Require();
    node.location.start = this.consume('REQUIRE').location.start.clone();
    if(this.currentToken().type == 'ONCE') {
        this.consume('ONCE');
        node.isOnce = true;
    }
    node.path = this.parseExpression(false);
    node.location.end = node.path.location.end.clone();
    return node;
};

// Parse section statament
//      Section := IDENTIFIER :
Parser.prototype.parseSection = function() {
    var node = new Nodes.Section();
    var token = this.consume('IDENTIFIER');
    node.name = token.value;
    node.location.start = token.location.start.clone();
    node.location.end = this.consume(':').location.end.clone();
    return node;
};

// Parse break statement
//      Break := BREAK Number
//             | BREAK
Parser.prototype.parseBreak = function() {
    var node = new Nodes.Break();
    node.location = this.consume('BREAK').location.clone();
    if(this.currentToken().type == 'NUMBER') {
        node.argument = this.parseNumber();
        node.location.end = node.argument.location.end.clone();
    }
    return node;
};

// Parse constant statement
//      Constant := CONST IDENTIFIER = INDENT Expression OUTDENT
//                | CONST IDENTIFIER = Expression
Parser.prototype.parseConstant = function() {
    var node = new Nodes.Constant();
    node.location.start = this.consume('CONST').location.start.clone();
    node.name = this.consume('IDENTIFIER').value;
    var needOutdent = false;
    var operator = this.parseAssignOperator();
    if(this.currentToken().type == 'INDENT') {
        needOutdent = true;
        this.consume('INDENT');
    }
    var right = this.parseExpression();
    node.value = right;
    node.location.end = right.location.end.clone();
    if(needOutdent === true) {
        this.consume('OUTDENT');
    }
    return node;
};

// Parse continue statement
//      Continue := CONTINUE Number
//                | CONTINUE
Parser.prototype.parseContinue = function() {
    var node = new Nodes.Continue();
    node.location = this.consume('CONTINUE').location.clone();
    if(this.currentToken().type == 'NUMBER') {
        node.argument = this.parseNumber();
        node.location.end = node.argument.location.end.clone();
    }
    return node;
};

// Parse delete statement
//      Delete := DELETE Expression
Parser.prototype.parseDelete = function() {
    var node = new Nodes.Delete();
    node.location.start = this.consume('DELETE').location.start.clone();
    node.argument = this.parseExpression(false);
    node.location.end = node.argument.location.end.clone();
    return node;
};

// Parse global statement
//      Global := GLOBAL Arguments
Parser.prototype.parseGlobal = function() {
    var node = new Nodes.Global();
    node.location.start = this.consume('GLOBAL').location.start.clone();
    node.arguments = this.parseArguments(['INDENT', 'MINDENT', 'OUTDENT'], false);
    if(node.arguments.length === 0) {
        // TODO: error
        throw 'error';
    } else {
        node.location.end = node.arguments[node.arguments.length - 1].location.end.clone();
    }
    return node;
};

// Parse goto statement
//      Goto := GOTO IDENTIFIER
Parser.prototype.parseGoto = function() {
    var token;
    var node = new Nodes.Goto();
    node.location.start = this.consume('GOTO').location.start.clone();
    token = this.consume('IDENTIFIER');
    node.section = token.value;
    node.location.end = token.location.end.clone();
    return node;
};

// Parse return statement
//      Return := RETURN Expression
//              | RETURN
Parser.prototype.parseReturn = function() {
    var node = new Nodes.Return();
    node.location = this.consume('RETURN').location.clone();
    if(consts.tokenInterpretation.notExpression.indexOf(this.currentToken().type) == - 1) {
        node.argument = this.parseExpression(false);
        node.location.end = node.argument.location.end.clone();
    }
    return node;
};

// Parse throw statement
//      Throw := THROW Expression
Parser.prototype.parseThrow = function() {
    var node = new Nodes.Throw();
    node.location.start = this.consume('THROW').location.start.clone();
    node.argument = this.parseExpression(false);
    node.location.end = node.argument.location.end.clone();
    return node;
};

// Parse expression statement
//      ExpressionStatement := Expression
Parser.prototype.parseExpressionStatement = function() {
    var expression = this.parseExpression();
    var node = new Nodes.ExpressionStatement(expression);
    node.location = expression.location.clone();
    return node;
};

// Parse expression
//      Expression := SimpleExpression IFHeader IfElses
//                  | SimpleExpression IFHeader
//                  | SimpleExpression ForSource
//                  | SimpleExpression WhileSource
//                  | SimpleExpression
//      SimpleExpression := Assignement
//                        | Echo
//                        | If
//                        | For
//                        | While
//                        | Try
//                        | Switch
Parser.prototype.parseExpression = function(allowControl) {
    var expression, block;
    allowControl = allowControl === undefined ? true : allowControl;
    switch(this.currentToken().type) {
        case 'ECHO':
            expression = this.parseEcho();
            break;
        case 'IF':
            expression = this.parseIf();
            break;
        case 'FOR':
            expression = this.parseFor();
            break;
        case 'LOOP':
        case 'UNTIL':
        case 'WHILE':
            expression = this.parseWhile();
            break;
        case 'TRY':
            expression = this.parseTry();
            break;
        case 'SWITCH':
            expression = this.parseSwitch();
            break;
        default:
            expression = this.parseAssignement();
    }
    if(allowControl) {
        switch(this.currentToken().type) {
            case 'IF':
                var ifHeader = this.parseIfHeader();
                block = new Nodes.Block([expression]);
                block.location = expression.location.clone();
                ifHeader.body = block;
                ifHeader.location.start = expression.location.start.clone();
                ifHeader.location.end = ifHeader.condition.location.end.clone();
                if(this.currentToken().type == 'ELSE') {
                    ifHeader.elses = this.parseIfElses();
                    ifHeader.location.end = ifHeader.elses[ifHeader.elses.length - 1].location.end.clone();
                }
                expression = ifHeader;
                break;
            case 'FOR':
                var forSource = this.parseForSource();
                block = new Nodes.Block([expression]);
                block.location = expression.location.clone();
                expression = new Nodes.For(forSource, block);
                expression.location.start = block.location.start.clone();
                expression.location.end = forSource.endPos.clone();
                break;
            case 'UNTIL':
            case 'WHILE':
                var whileSource = this.parseWhileSource();
                whileSource.body = new Nodes.Block([expression]);
                whileSource.body.location = expression.location.end.clone();
                expression = whileSource;
                break;
        }
    }
    return expression;
};

// Parse echo expression
Parser.prototype.parseEcho = function() {
    var node = new Nodes.Echo();
    node.location.start = this.consume('ECHO').location.start.clone();
    node.argument = this.parseExpression();
    node.location.end = node.argument.location.end.clone();
    return node;
};

// Parse if expression
//      If := IfHeader Block IfElses
//  (Other if expression, see Statement and Expression sections)
Parser.prototype.parseIf = function() {
    var node = this.parseIfHeader();
    node.body = this.parseBlock(true);
    node.location.end = node.body.location.end.clone();
    if(this.currentToken().type == 'ELSE') {
        node.elses = this.parseIfElses();
        node.location.end = node.elses[node.elses.length - 1].location.end.clone();
    }
    return node;
};

// Parse if condition/header
//      IfHeader := IF Expression
Parser.prototype.parseIfHeader = function() {
    var node = new Nodes.If();
    node.location.start = this.consume('IF').location.start.clone();
    node.condition = this.parseExpression();
    return node;
};

// Parse if elses
//      IfElses := ElseIfs ELSE Block
//               | ElseIfs
//               | ELSE Block
//               |
//      ElseIfs := ElseIfs ELSE IF Expression Block
//               | ELSE IF Expression Block
Parser.prototype.parseIfElses = function() {
    var elses = [];
    while(this.currentToken().type == 'ELSE') {
        var node;
        var startPos = this.consume('ELSE').location.start.clone();
        if(this.currentToken().type == 'IF') {
            this.consume('IF');
            node = new Nodes.ElseIf();
            node.condition = this.parseExpression();
            node.body = this.parseBlock(true);
            node.location.start = startPos;
            node.location.end = node.body.location.end.clone();
            elses.push(node);
            continue;
        } else {
            node = new Nodes.Else();
            node.body = this.parseBlock(true);
            node.location.start = startPos;
            node.location.end = node.body.location.end.clone();
            elses.push(node);
            break;
        }
    }
    return elses;
};

// Parse for expression
//      For := ForSource Block      
//  (Other for expression, see Statement and Expression sections)
Parser.prototype.parseFor = function() {
    var node = new Nodes.For();
    node.source = this.parseForSource();
    node.body = this.parseBlock(true);
    node.location.start = node.source.startPos.clone();
    node.location.end = node.body.location.end.clone();
    return node;
};

// Parse for source/header
//      ForSource := 
//                 | FOR Range BY Expression AS Identifier WHEN Expression
//                 | FOR Range AS Identifier BY Expression WHEN Expression
//                 | FOR Range AS Identifier BY Expression
//                 | FOR Range BY Expression AS Identifier
//                 | FOR Range BY Expression WHEN Expression
//                 | FOR Range AS Identifier WHEN Expression
//                 | FOR Range BY Expression
//                 | FOR Range AS Identifier
//                 | FOR Range
//                 | FOR ForVariables FORIN Expression BY Expression WHEN Expression
//                 | FOR ForVariables FOROF Expression BY Expression WHEN Expressio 
//                 | FOR ForVariables FORIN Expression WHEN Expression
//                 | FOR ForVariables FOROF Expression WHEN Expressio 
//                 | FOR ForVariables FORIN Expression BY Expression
//                 | FOR ForVariables FOROF Expression BY Expression
//                 | FOR ForVariables FORIN Expression
//                 | FOR ForVariables FOROF Expression
//      ForVariables := ForValue , ForValue
//                    | ForValue
Parser.prototype.parseForSource = function() {
    var token;
    var source = {source: null, name: null, index: null, step: null, guard: null, isRange: false, isForIn: false, isForOf: false, startPos: null, endPos: null};
    token = this.consume('FOR');
    source.startPos = token.location.start.clone();
    source.endPos = token.location.end.clone();
    if(this.currentToken().type == 'RANGE_START') {
        var range = this.parseRange();
        source.isRange = true;
        source.source = range;
        source.endPos = range.location.end.clone();
        var asParsed = false, byParsed = false, whenParsed = false;
        var i = 0;
        while(i < 3) {
            if(asParsed === false && this.currentToken().type == 'AS') {
                asParsed = true;
                this.consume('AS');
                source.index = this.parseIdentifier();
                source.endPos = source.index.location.end.clone(); 
            } else if(byParsed === false && this.currentToken().type == 'BY') {
                byParsed = true;
                this.consume('BY');
                source.step = this.parseExpression();
                source.endPos = source.step.location.end.clone(); 
            } else if(whenParsed === false && this.currentToken().type == 'WHEN') {
                whenParsed = true;
                this.consume('WHEN');
                source.guard = this.parseExpression();
                source.endPos = source.guard.location.end.clone(); 
            }
            i++;
        }
    } else {
        source.name = this.parseForValue();
        if(this.currentToken().type == ',') {
            this.consume(',');
            source.index = this.parseForValue();
        }
        if(this.currentToken().type == 'FORIN') {
            this.consume('FORIN');
            source.isForIn = true;
        } else if(this.currentToken().type == 'FOROF') {
            this.consume('FOROF');
            source.isForOf = true;
        } else {
            // TODO : error
            throw 'error';
        }
        var expression = this.parseExpression();
        source.source = expression;
        source.endPos = expression.location.end.clone();
        var byParsed = false, whenParsed = false;
        var i = 0;
        while(i < 2) {
            if(byParsed === false && this.currentToken().type == 'BY') {
                byParsed = true;
                this.consume('BY');
                source.step = this.parseExpression();
                source.endPos = source.step.location.end.clone(); 
            } else if(whenParsed === false && this.currentToken().type == 'WHEN') {
                whenParsed = true;
                this.consume('WHEN');
                source.guard = this.parseExpression();
                source.endPos = source.guard.location.end.clone(); 
            }
            i++;
        }
    }
    return source;
};

// Parse a for valable value
//      ForValue := Identifier
//                | Array
Parser.prototype.parseForValue = function() {
    if(this.currentToken().type == 'IDENTIFIER') {
        return this.parseIdentifier();
    } else if(this.currentToken().type == '[') {
        return this.parseArray();
    }
    // TODO : error
    throw 'error';
};

// Parse while expression
//      While := WhileSource Block
//             | Loop
//  (Other while expression, see Statement and Expression sections)
Parser.prototype.parseWhile = function() {
    var node;
    if(this.currentToken().type == 'WHILE' || this.currentToken().type == 'UNTIL') {
        node = this.parseWhileSource();
        var block = this.parseBlock(true);
        node.body = block;
        node.location.end = block.location.end.clone();
    } else if(this.currentToken().type == 'LOOP') {
        return this.parseLoop();
    }
    return node;
};

// Parse a while source/header
//      WhileSource := WHILE Expression
//                   | WHILE Expression WHEN Expression
//                   | UNTIL Expression
//                   | UNTIL Expression WHEN Expression
Parser.prototype.parseWhileSource = function() {
    var token, expression;
    var node = new Nodes.While();
    switch(this.currentToken().type) {
        case 'UNTIL':
        case 'WHILE':
            token = this.consume(this.currentToken().type);
            if(token.type == 'WHILE') {
                node.invert = false;
            } else if(token.type == 'UNTIL') {
                node.invert = true;
            }
            node.location.start = token.location.start.clone();
            break;
        default:
            // TODO: error
    }
    expression = this.parseExpression();
    node.test = expression;
    if(this.currentToken().type == 'WHEN') {
        this.consume('WHEN');
        expression = this.parseExpression();
        node.guard = expression;
        node.location.end = expression.location.end.clone();
    } else {
        node.location.end = expression.location.end.clone();
    }
    return node;
};

// Parse loop
//      Loop := LOOP Block
//            | LOOP Expression
Parser.prototype.parseLoop = function() {
    var node = new Nodes.While();
    var token = this.consume('LOOP');
    node.location.start = token.location.start.clone();
    node.test = new Nodes.Literal('true', 'bool');
    node.test.location = token.location.clone();
    if(this.currentToken().type == 'INDENT') {
        var block = this.parseBlock();
        node.body = block;
        node.location.end = block.location.end.clone();
    } else {
        var expression = this.parseExpression();
        node.body = new Nodes.Block([expression]);
        node.body.location = expression.location.clone();
    }
    return node;
};

// Parse try expression
//      Try := TRY Block CATCH Identifier Block FINALLY Block
//           | TRY Block CATCH Block FINALLY Block
//           | TRY Block FINALLY Block
//           | TRY Block CATCH Identifier Block
//           | TRY Block CATCH Block
//           | TRY BLOCK
Parser.prototype.parseTry = function() {
    var node = new Nodes.Try();
    node.location.start = this.consume('TRY').location.start.clone();
    node.tryBody = this.parseBlock(true);
    node.location.end = node.tryBody.location.end.clone();
    if(this.currentToken().type == 'CATCH') {
        this.consume('CATCH');
        if(this.currentToken().type == 'IDENTIFIER') {
            node.catchIdentifier = this.parseIdentifier();
        }
        node.catchBody = this.parseBlock();
        node.location.end = node.catchBody.location.end.clone();
    }
    if(this.currentToken().type == 'FINALLY') {
        this.consume('FINALLY');
        node.finallyBody = this.parseBlock(true);
        node.location.end = node.finallyBody.location.end.clone();
    }
    return node;
};

// Parse switch expression
//      Switch := SWITCH Expression INDENT Whens OUTDENT
//              | SWITCH Expression INDENT Whens ELSE Block OUTDENT
//              | SWITCH INDENT Whens OUTDENT
//              | SWITCH INDENT Whens ELSE Block OUTDENT
//      Whens := Whens MINDENT When
//             | When
//      When := SWITCH_WHEN SimpleArgs Block
Parser.prototype.parseSwitch = function() {
    var node = new Nodes.Switch();
    node.location.start = this.consume('SWITCH').location.start.clone();
    if(this.currentToken().type != 'INDENT') {
        node.subject = this.parseExpression();
    }
    this.consume('INDENT');
    isFirstCase = true;
    while(isFirstCase || this.currentToken().type == 'SWITCH_WHEN') {
        isFirstCase = false;
        this.consume('SWITCH_WHEN');
        node.whens.push([this.parseSimpleArgs(), this.parseBlock(true)]);
    }
    if(this.currentToken().type == 'ELSE') {
        this.consume('ELSE');
        node.otherwise = this.parseBlock(true);
    }
    node.location.end = this.consume('OUTDENT').location.start.clone();
    return node;
};

// Parse SimpleArgs
//      SimpleArgs := SimpleArgs , Expression
//                  | Expression
Parser.prototype.parseSimpleArgs = function() {
    var args = [this.parseExpression()];
    while(this.currentToken().type == ',') {
        args.push(this.parseExpression());
    }
    return args;
};

// Parse assignement expression
//      Assignement := Operation AssignOperator Expression
//                   | Operation AssignOperator INDENT Expression OUTDENT
//                   | Operation
//                   | KeyAssignement
Parser.prototype.parseAssignement = function() {
    if(this.currentToken().type == '{') {
        return this.parseKeysAssignement();
    }
    var node = this.parseOperation(consts.Precedence.expression);
    if(this.currentToken().type == 'ASSIGN') {
        var needOutdent = false;
        var startPos = node.location.start.clone();
        var operator = this.parseAssignOperator();
        if(this.currentToken().type == 'INDENT') {
            needOutdent = true;
            this.consume('INDENT');
        }
        var right = this.parseExpression();
        node = new Nodes.Assignement(operator, node, right);
        node.location.start = startPos;
        node.location.end = right.location.end.clone();
        if(needOutdent === true) {
            this.consume('OUTDENT');
        }
    }
    return node;
};

// Parse keys assignement expression
//      KeyAssignement := { KeysList } = INDENT Expression OUTDENT
//                      | { KeysList } = Expression
Parser.prototype.parseKeysAssignement = function() {
    var startPos = this.consume('{').location.start.clone();
    var node = new Nodes.KeysAssignement(this.parseKeysList());
    this.consume('}');
    var needOutdent = false;
    var operator = this.parseAssignOperator();
    if(this.currentToken().type == 'INDENT') {
        needOutdent = true;
        this.consume('INDENT');
    }
    var right = this.parseExpression();
    node.right = right;
    node.location.end = right.location.end.clone();
    if(needOutdent === true) {
        this.consume('OUTDENT');
    }
    return node;
};

// Parse a keys list
//      KeysList := INDENT KeysList , Identifier OUTDENT
//                | INDENT KeysList MINDENT Identifier OUTDENT
//                | INDENT OUTDENT
//                | Identifier
//                |                        (possibly empty)
Parser.prototype.parseKeysList = function() {
    var args = [];
    if(this.currentToken().type == 'INDENT') {
        this.consume('INDENT');
        var loopInside = function() {
            args.push(this.parseIdentifier());
            if(this.currentToken().type == ',') {
                this.consume(',');
            }
            if(this.currentToken().type != 'OUTDENT') {
                if(this.currentToken().type != 'MINDENT') {
                    loopInside.call(this);
                } else {
                    this.consume('MINDENT');
                }
            }
        };
        while(this.currentToken().type != 'OUTDENT') {
            loopInside.call(this);
        }
        this.consume('OUTDENT');
    } else {
        while(this.currentToken().type != '}') {
            if(args.length > 0) {
                var commaConsumed = false;
                if(this.currentToken().type == ',') {
                    this.consume(',');
                    commaConsumed = true;
                }
                if(this.currentToken().type == 'INDENT') {
                    args = args.concat(this.parseKeysList());
                    continue;
                } else {
                    if(commaConsumed === false) {
                        this.consume(',');
                    }
                }
            }
            args.push(this.parseIdentifier());
        }
    }
    return args;
};

// Parse binary operation
//      Operation := CastExpression BinaryOperator operation (BinaryOperator with precedence rule)
//                 | CastExpression
Parser.prototype.parseOperation = function(minPrecedence) {
    var node = this.parseCastExpression();
    while(this.currentToken().precedence >= minPrecedence) {
        var precedence = this.currentToken().precedence;
        var operator = this.parseBinaryOperator();
        var startPos = node.location.start.clone();
        var right = this.parseOperation(precedence + 1);
        node = new Nodes.Operation(operator, node, right);
        node.location.start = startPos;
        node.location.end = right.location.end.clone();
    }
    return node;
};

// Parse cast expression
//      CastExpression := Unary => CASTTYPE
//                      | Unary
Parser.prototype.parseCastExpression = function() {
    var node = this.parsePrefix();
    if(this.currentToken().type == '=>') {
        var startPos = node.location.start.clone();
        // Cast operator
        var operator = new Nodes.Operator('=>', 'cast');
        operator.location = this.consume('=>').location.clone();
        // Cast type
        var token = this.consume('CASTTYPE');
        var castType = new Nodes.CastType();
        castType.location = token.location.clone();
        // final node
        node = new Nodes.CastTyping(node, castType);
        node.location.start = startPos;
        node.location.end = castType.location.end.clone();
    }
    return node;
};

// Parse expression with prefix
//      Posfix := CLONE Expression
//              | UNARY Expression
//              | Update Expression
//              | + Expression
//              | - Expression
//              | Posfix
Parser.prototype.parsePrefix = function() {
    if(consts.tokenInterpretation.prefixOperator.indexOf(this.currentToken().type) > -1) {
        var operator, node, argument;
        switch(this.currentToken().type) {
            case 'CLONE':
                operator = new Nodes.Operator('clone', 'clone');
                operator.location = this.consume('CLONE').location.clone();
                argument = this.parseExpression();
                node = new Nodes.Clone(operator, argument);
                node.location.start = operator.location.start.clone();
                node.location.end = argument.location.end.clone();
                return node;
            case 'UNARY':
            case '+':
            case '-':
                operator = this.parseUnaryOperator();
                argument = this.parseExpression();
                node = new Nodes.Unary(operator, argument);
                node.location.start = operator.location.start.clone();
                node.location.end = argument.location.end.clone();
                return node;
            case 'UPDATE':
                operator = this.parseUpdateOperator();
                argument = this.parseExpression();
                node = new Nodes.Update(operator, argument, true);
                node.location.start = operator.location.start.clone();
                node.location.end = argument.location.end.clone();
                return node;
        }
    }
    return this.parsePostfix();
};

// Parse postfix expression
//      Postfix := UPDATE LeftHand
//               | LeftHand
Parser.prototype.parsePostfix = function() {
    var expression = this.parseLeftHand();
    if(this.currentToken().type == 'UPDATE') {
        var startPos = expression.location.start.clone();
        var operator = this.parseUpdateOperator();
        expression = new Nodes.Update(operator, expression, false);
        expression.location.start = startPos;
        expression.location.end = operator.location.end.clone();
    }
    return expression;
};

// Parse left hand side
//      LeftHand := NEW Expression
//                | Member
Parser.prototype.parseLeftHand = function() {
    if(this.currentToken().type == 'NEW') {
        var operator = new Nodes.Operator('new', 'new');
        operator.location = this.consume('NEW').location.clone();
        var argument = this.parseExpression();
        var node = new Nodes.New(operator, argument);
        node.location.start = operator.location.start.clone();
        node.location.end = argument.location.end.clone();
        return node;
    } else {
        return this.parseMember();
    }
};

// Parse member/index/invocation
//      Member := Member MemberOperator Identifier
//              | Member INDEX_START Expression INDEX_END
//              | Member SLICE_START Slice SLICE_END
//              | Member CALL_START ArgumentsList CALL_END
//              | Member ?
//              | Primary
Parser.prototype.parseMember = function() {
    var node = this.parsePrimary();
    loop: while(true) {
        var startPos = node.location.start.clone();
        switch(this.currentToken().type) {
            case 'MEMBER':
                var operator = this.parseMemberOperator();
                var member = this.parseIdentifier();
                node = new Nodes.Member(operator, node, member);
                node.location.start = startPos;
                node.location.end = member.location.end.clone();
                break;
            case 'CALL_START':
                this.consume('CALL_START');
                args = this.parseArguments('CALL_END', false);
                node = new Nodes.Call(node, args);
                node.location.start = startPos;
                node.location.end = this.consume('CALL_END').location.end.clone();
                break;
            case 'INDEX_START':
                this.consume('INDEX_START');
                var index = this.parseExpression();
                node = new Nodes.Index(node, index);
                node.location.start = startPos;
                node.location.end = this.consume('INDEX_END').location.end.clone();
                break;
            case 'SLICE_START':
                this.consume('SLICE_START');
                var slicingRange = this.parseSlice();
                node = new Nodes.Slice(node, slicingRange);
                node.location.start = startPos;
                node.location.end = this.consume('SLICE_END').location.end.clone();
                break;
            case '?':
                node = new Nodes.Existance(node);
                node.location.start = startPos;
                node.location.end = this.consume('?').location.end.clone();
                break;
            default:
                break loop;
        }
    }
    return node;
};

// Parse slice range
//      Slice := Expression RANGE Expression
//             | Expression RANGE
//             | RANGE Expression
//             | RANGE
Parser.prototype.parseSlice = function() {
    var node;
    if(this.currentToken().type == 'RANGE') {
        var token = this.consume('RANGE');
        var operator = new Nodes.Operator(token.value, 'range');
        operator.location = token.location.clone();
        if(this.currentToken().type == 'SLICE_END') {
            node = new Nodes.Range(null, null, operator);
        } else {
            node = new Nodes.Range(null, this.parseExpression(), operator);
        }
    } else {
        var from = this.parseExpression();
        var token = this.consume('RANGE');
        var operator = new Nodes.Operator(token.value, 'range');
        operator.location = token.location.clone();
        if(this.currentToken().type == 'SLICE_END') {
            node = new Nodes.Range(from, null, operator);
        } else {
            node = new Nodes.Range(from, this.parseExpression(), operator);
        }
    }
    return node;
};

// Parse primary value
//      Primary := Boolean
//               | Identifier
//               | Number
//               | Null
//               | String
//               | QualifiedString
//               | HereDoc
//               | Array
//               | Range
//               | Parenthetical
//               | Code
//               | At
//               | QualifiedNamespaceName
Parser.prototype.parsePrimary = function() {
    switch(this.currentToken().type) {
        case 'BOOL':
            return this.parseBoolean();
        case 'IDENTIFIER':
            if(this.input[this._i + 1] !== undefined && this.input[this._i + 1].type == '\\') {
                return this.parseQualifiedNamespaceName();
            }
            return this.parseIdentifier();
        case 'NUMBER':
            return this.parseNumber();
        case 'NULL':
            return this.parseNull();
        case 'STRING':
            return this.parseString();
        case 'QUALIFIEDSTRING':
            return this.parseQualifiedString();
        case 'HEREDOC':
            return this.parseHereDoc();
        case '[':
            return this.parseArray();
        case 'RANGE_START':
            return this.parseRange();
        case '(':
            return this.parseParenthetical();
        case 'FUNC':
            return this.parseCode();
        case '@':
            return this.parseAtOperator();
        case '\\':
            return this.parseQualifiedNamespaceName();
        default:
            this.fail();
    }
};

// Parse array
//      Array := [ ArgumentsList ]
Parser.prototype.parseArray = function() {
    var startPos = this.consume('[').location.start.clone();
    var node = new Nodes.Array(this.parseArguments(']', true));
    node.location.start = startPos;
    node.location.end = this.consume(']').location.end.clone();
    return node;
};

// Parse arguments list for invocation/call or array declaration
//      ArgumentsList := INDENT ArgumentsList , Argument OUTDENT
//                     | INDENT ArgumentsList MINDENT Argument OUTDENT
//                     | INDENT OUTDENT
//                     | Argument
//                     |                        (possibly empty)
Parser.prototype.parseArguments = function(endTokenType, allowKey) {
    var args = [];
    var checkisEnd = function(tokenType) {
        if(endTokenType instanceof Array) {
            return endTokenType.indexOf(tokenType) > -1;
        } else {
            return endTokenType == tokenType;
        }
    };
    if(this.currentToken().type == 'INDENT') {
        this.consume('INDENT');
        var loopInside = function() {
            args.push(this.parseArgument(allowKey));
            if(this.currentToken().type == ',') {
                this.consume(',');
            }
            if(this.currentToken().type != 'OUTDENT') {
                if(this.currentToken().type != 'MINDENT') {
                    loopInside.call(this);
                } else {
                    this.consume('MINDENT');
                }
            }
        };
        while(this.currentToken().type != 'OUTDENT') {
            loopInside.call(this);
        }
        this.consume('OUTDENT');
    } else {
        while(!checkisEnd(this.currentToken().type)) {
            if(args.length > 0) {
                var commaConsumed = false;
                if(this.currentToken().type == ',') {
                    this.consume(',');
                    commaConsumed = true;
                }
                if(this.currentToken().type == 'INDENT') {
                    args = args.concat(this.parseArguments());
                    continue;
                } else {
                    if(commaConsumed === false) {
                        this.consume(',');
                    }
                }
            }
            args.push(this.parseArgument(allowKey));
        }
    }
    return args;
};

// Parse signle argument for invocation/call or array keyed arg
//      Argument := Expression
//                | Expression : Expression     (if array declaration)
Parser.prototype.parseArgument = function(allowKey) {
    var node  = this.parseExpression();
    if(allowKey && this.currentToken().type == ':') {
        this.consume(':');
        var startPos = node.location.start.clone();
        var value = this.parseExpression();
        node = new Nodes.ArrayKey(node, value);
        node.location.start = startPos;
        node.location.end = value.location.end.clone();
    }
    return node;
};

// Parse range
//      Range := RANGE_START Expression RANGE Expression RANGE_END
Parser.prototype.parseRange = function() {
    var startPos = this.consume('RANGE_START').location.start.clone();
    var from = this.parseExpression();
    var token = this.consume('RANGE');
    var operator = new Nodes.Operator(token.type, 'range');
    operator.location = token.location.clone();
    var to = this.parseExpression();
    var node = new Nodes.Range(from, to, operator);
    node.location.start = startPos;
    node.location.end = this.consume('RANGE_END').location.end.clone();
    return node;
};

// Parse parenthetical
//      Parenthetical := ( Expression )
//                     | ( INDENT Expression OUTDENT )
Parser.prototype.parseParenthetical = function() {
    var expression;
    var startPos = this.consume('(').location.start.clone();
    if(this.currentToken().type == 'INDENT') {
        this.consume('INDENT');
        expression = this.parseExpression();
        this.consume('OUTDENT');
    } else {
        expression = this.parseExpression();
    }
    var node = new Nodes.Parenthetical(expression);
    node.location.start = startPos;
    node.location.end = this.consume(')').location.end.clone();
    return node;
};

// Parse identifier
//      Identifier := IDENTIFIER
Parser.prototype.parseIdentifier = function() {
    var token = this.consume('IDENTIFIER');
    var node = new Nodes.Identifier(token.value);
    node.location = token.location.clone();
    return node;
};

// Parse number
//      Number := NUMBER
Parser.prototype.parseNumber = function() {
    var token = this.consume('NUMBER');
    var node = new Nodes.Literal(token.value, 'number');
    node.location = token.location.clone();
    return node;
};

// Parse string
//      String := STRING
Parser.prototype.parseString = function() {
    var token = this.consume('STRING');
    var node = new Nodes.Literal(token.value, 'string');
    node.location = token.location.clone();
    return node;
};

// Parse qualified string
//      QualifiedString := QUALIFIEDSTRING
Parser.prototype.parseQualifiedString = function() {
    var token = this.consume('QUALIFIEDSTRING');
    var node = new Nodes.Literal(token.value, 'qualifiedString');
    node.location = token.location.clone();
    return node;
};

// Parse Heredoc
//      HereDoc := HEREDOC
Parser.prototype.parseHereDoc = function() {
    var token = this.consume('HEREDOC');
    var node = new Nodes.Literal(token.value, 'herDoc');
    node.location = token.location.clone();
    return node;
};

// Parse boolean
//      Boolean := BOOL
Parser.prototype.parseBoolean = function() {
    var token = this.consume('BOOL');
    var node = new Nodes.Literal(token.value, 'bool');
    node.location = token.location.clone();
    return node;
};

// Parse null
//      Null := NULL
Parser.prototype.parseNull = function() {
    var token = this.consume('NULL');
    var node = new Nodes.Literal(token.value, 'null');
    node.location = token.location.clone();
    return node;
};

// Parse anonymous function
//      Code := FUNC ( ParametersList ) CALL_START ParametersList CALL_END  -> Block
//            | FUNC ( ParametersList ) -> Block
//            | FUNC ( ParametersList ) CALL_START ParametersList CALL_END
//            | FUNC ( ParametersList )
//            | FUNC -> Block
//            | FUNC IDENTIFIER ( ParametersList ) CALL_START ParametersList CALL_END -> Block
//            | FUNC IDENTIFIER ( ParametersList ) -> Block
//            | FUNC IDENTIFIER ( ParametersList ) CALL_START ParametersList CALL_END
//            | FUNC IDENTIFIER ( ParametersList )
//            | FUNC IDENTIFIER -> Block
Parser.prototype.parseCode = function() {
    var node = new Nodes.Code();
    node.location.start = this.consume('FUNC').location.start.clone();
    if(this.currentToken().type == 'IDENTIFIER') {
        node.isAnonymous = false;
        node.name = this.parseIdentifier();
    } else {
        node.isAnonymous = true;
        node.hasBody = true;
        node.body = new Nodes.Block();
        node.location.start = node.location.start.clone();
        node.location.end = node.location.start.clone();
    }
    if(this.currentToken().type == '(') {
        this.consume('(');
        node.parameters = this.parseParametersList(')');
        this.consume(')');
    }
    if(this.currentToken().type == 'CALL_START') {
        this.consume('CALL_START');
        node.withUses = true;
        node.uses = this.parseParametersList('CALL_END');
        this.consume('CALL_END');
    }
    if(this.currentToken().type == '->') {
        this.consume('->');
        node.hasBody = true;
        node.body = this.parseBlock(true);
    }
    node.location.end = this.endPosition.clone();
    return node;
};

// Parse parameters list
//      ParametersList := ParametersList , Param
//                      | Param
Parser.prototype.parseParametersList = function(tokenCloseType) {
    var list = [];
    while(this.currentToken().type != tokenCloseType) {
        list.push(this.parseParam());
    }
    return list;
};

// Parse parameter
//      Param := USE ParamIdentifier
//             | ParamIdentifier = Expression
//             | ParamIdentifier
Parser.prototype.parseParam = function() {
    var param;
    if(this.currentToken().type == 'USE') {
        this.consume('USE');
        param = this.parseParamIdentifier();
        param.isPassing = true;
    } else {
        param = this.parseParamIdentifier();
        if(this.currentToken().type == '=') {
            this.consume('=');
            param.hasDefault = true;
            param.default = this.parseExpression();
        }
    }
    return param;
};

// Parse ParamIdentifier
//      ParamIdentifier := & IDENTIFIER
//                       | IDENTIFIER
Parser.prototype.parseParamIdentifier = function() {
    var node = new Nodes.Parameter();
    node.location.start = this.currentToken().location.start.clone();
    if(this.currentToken().type == '&') {
        this.consume('&');
        node.isPassing = true;
    }
    var token = this.consume('IDENTIFIER');
    node.name = token.value;
    node.location.end = token.location.end.clone();
    return node;
};

// Parse @ operator
//      At := @ Identifier
//          | @
Parser.prototype.parseAtOperator = function() {
    var node;
    var token = this.consume('@');
    if(this.currentToken().type == 'IDENTIFIER') {
        // property
        var identifier = this.parseIdentifier();
        // base
        var base = new Nodes.Identifier('this');
        base.isAt = true;
        base.location = token.location.clone();
        // operator
        var operator = new Nodes.Operator('.', 'member');
        operator.location = null; // cause don't exist in code
        // final member node
        node = new Nodes.Member(operator, base, identifier);
        node.location.start = token.location.start.clone();
        node.location.end = identifier.location.end.clone();
    } else {
        node = new Nodes.Identifier('this');
        node.isAt = true;
        node.location = token.location.clone();
    }
    return node;
};

// Parse assignement operator
//      AssignementOperator := ASSIGN
Parser.prototype.parseAssignOperator = function() {
    var token = this.consume('ASSIGN');
    var node = new Nodes.Operator(token.value, 'assign');
    node.location = token.location.clone();
    return node;
};

// Parse binary operator
//      BinaryOperator := BITWISE
//                      | COMPARE
//                      | CONCAT
//                      | LOGIC
//                      | MATH
//                      | SHIFT
//                      | IN
//                      | INSTANCEOF
//                      | +
//                      | -
Parser.prototype.parseBinaryOperator = function() {
    var token;
    switch(this.currentToken().type) {
        case 'BITWISE':
        case 'COMPARE':
        case 'CONCAT':
        case 'LOGIC':
        case 'MATH':
        case 'SHIFT':
        case 'IN':
        case 'INSTANCEOF':
        case '+':
        case '-':
            token = this.consume(this.currentToken().type);
            break;
        default:
            // TODO: error
            throw 'error';
    }
    var node = new Nodes.Operator(token.value, 'binary');
    node.precedence = token.precedence;
    node.location = token.location.clone();
    return node;
};

// Parse update operator
//      UpdateOperator := UPDATE
Parser.prototype.parseUpdateOperator = function() {
    var token = this.consume('UPDATE');
    var node = new Nodes.Operator(token.value, 'update');
    node.location = token.location.clone();
    return node;
};

// Parse unary operator
//      UnaryOperator := UNARY
//                     | +
//                     | -
Parser.prototype.parseUnaryOperator = function() {
    var token;
    switch(this.currentToken().type) {
        case 'UNARY':
        case '+':
        case '-':
            token = this.consume(this.currentToken().type);
            break;
        default:
            // TODO: erreor
            throw 'error';
    }
    var node = new Nodes.Operator(token.value, 'unary');
    node.location = token.location.clone();
    return node;
};

// Parse member operator
//      MemberOperator := MEMBER
Parser.prototype.parseMemberOperator = function() {
    var token = this.consume('MEMBER');
    var node = new Nodes.Operator(token.value, 'member');
    node.location = token.location.clone();
    return node;
};

// Parse a namespace definition
//      Namespace := NAMESPACE Block
//                 | NAMESPACE NamespaceName Block
//                 | NAMESPACE NamespaceName
Parser.prototype.parseNamespace = function() {
    var node = new Nodes.Namespace();
    node.location.start = this.consume('NAMESPACE').location.start.clone();
    if(this.currentToken().type != 'INDENT') {
        node.name = this.parseNamespaceName();
        node.location.end = node.name.location.end.clone();
    }
    if(this.currentToken().type == 'INDENT') {
        node.body = this.parseBlock();
        node.location.end = node.location.end.clone();
        return node;
    }
    return node;
};

// Parse namespace name
//      NamespaceName := NamespaceName \ IDENTIFIER
//                     | IDENTIFIER
Parser.prototype.parseNamespaceName = function() {
    var node = new Nodes.NamespaceName();
    var token = this.consume('IDENTIFIER');
    node.location = token.location.clone();
    node.nameSequence.push(token.value);
    while(this.currentToken().type == '\\') {
        this.consume('\\');
        token = this.consume('IDENTIFIER');
        node.location.end = token.location.end.clone();
        node.nameSequence.push(token.value);
    }
    return node;
};

// Parse qualified namespace name
//      QualifiedNamespaceName := \ NamespaceName
//                              | NamespaceName
Parser.prototype.parseQualifiedNamespaceName = function() {
    var node;
    if(this.currentToken().type == '\\') {
        var startPos = this.consume('\\').location.start.clone();
        node = this.parseNamespaceName();
        node.startWithBackSlash = true;
        node.location.start = startPos;
    } else if(this.currentToken().type == 'QUALIFIEDSTRING') {
        node = this.parseQualifiedString();
    } else {
        node = this.parseNamespaceName();
    }
    return node;
};


// Parse class declatarion statement
//      Class := ClassModifier CLASS IDENTIFIER Extends ImplementsOpt INDENT ClassMembers OUTDENT
//      ClassModifier := CLASSMODIFIER
//                     | 
//      Extends := EXTENDS QualifiedNamespaceName
//               |
//      ImplementsOpt := Implements
//                     | 
//      Implements := Implements , QualifiedNamespaceName
//                  | IMPLEMENTS QualifiedNamespaceName
//      ClassMembers := ClassMembers MINDENT ClassMember
//                    | ClassMember
//      ClassMember := Abstractity FINAL Visiblility Statically Code
//                   | Abstractity Visiblility Statically Assignement
//      Abstractity := ABSTRACT
//                   | 
//      Visiblility := PUBLIC
//                   | PROTECTED
//                   | PUBLIC
//                   |
//      Statically := STATIC
//                  |
Parser.prototype.parseClass = function() {
    var node = new Nodes.Class(), token;
    if(this.currentToken().type == 'CLASSMODIFIER') {
        token = this.consume('CLASSMODIFIER');
        node.modifier = token.value;
        node.location.start = token.location.start.clone();
        this.consume('CLASS');
    } else {
        node.location.start = this.consume('CLASS').location.start.clone();
    }
    token = this.consume('IDENTIFIER');
    node.name = token.value;
    if(this.currentToken().type == 'EXTENDS') {
        this.consume('EXTENDS');
        node.extends = this.parseQualifiedNamespaceName();
    }
    if(this.currentToken().type == 'IMPLEMENTS') {
        node.implements = [];
        this.consume('IMPLEMENTS');
        node.implements.push(this.parseQualifiedNamespaceName());
        while(this.currentToken().type == ',') {
            node.implements.push(this.parseQualifiedNamespaceName());
        }
    }
    if(this.currentToken().type == 'INDENT') {
        node.members = [];
        this.consume('INDENT');
        while(this.currentToken().type != 'OUTDENT') {
            var startPos = null;
            var member = new Nodes.ClassMember();
            if(this.currentToken().type == 'ABSTRACT') {
                token = this.consume('ABSTRACT');
                member.isAbstract = true;
                if(startPos == null) {
                    startPos = token.location.start.clone();
                }
            }
            if(this.currentToken().type == 'FINAL') {
                token = this.consume('FINAL');
                member.isFinal = true;
                if(startPos == null) {
                    startPos = token.location.start.clone();
                }
            }
            if(['PUBLIC', 'PROTECTED', 'PUBLIC'].indexOf(this.currentToken().type) > -1) {
                token = this.consume(this.currentToken().type);
                member.visibility = token.value;
                if(startPos == null) {
                    startPos = token.location.start.clone();
                }
            }
            if(this.currentToken().type == 'STATIC') {
                token = this.consume('STATIC');
                member.isStatic = true;
                if(startPos == null) {
                    startPos = token.location.start.clone();
                }
            }
            if(member.isFinal) {
                member.member = this.parseCode();
            } else {
                member.member = this.parseAssignement();
            }
            member.location.start = startPos;
            member.location.end = member.location.end.clone();
            node.location.end = member.location.end.clone();
            node.members.push(member);
            if(this.currentToken().type == 'MINDENT') {
                this.consume('MINDENT');
            }
        }
        this.consume('OUTDENT');
    }
    return node;
};

// Parse interface declaration statement
//      Interface := INTERFACE IDENTIFIER Extends INDENT InterfaceMembers OUTDENT
//      Extends := EXTENDS QualifiedNamespaceName
//               |
//      InterfaceMembers := InterfaceMembers MINDENT InterfaceMember
//                    | InterfaceMember
//      InterfaceMember := FINAL Visiblility Statically Code
//                   | Visiblility Statically Assignement
//      Visiblility := PUBLIC
//                   | PROTECTED
//                   | PUBLIC
//                   |
//      Statically := STATIC
//                  |
Parser.prototype.parseInterface = function() {
    var node = new Nodes.Interface(), token;
    node.location.start = this.consume('INTERFACE').location.start.clone();
    token = this.consume('IDENTIFIER');
    node.name = token.value;
    if(this.currentToken().type == 'EXTENDS') {
        this.consume('EXTENDS');
        node.extends = this.parseQualifiedNamespaceName();
    }
    if(this.currentToken().type == 'INDENT') {
        node.members = [];
        this.consume('INDENT');
        while(this.currentToken().type != 'OUTDENT') {
            var startPos = null;
            var member = new Nodes.ClassMember();
            if(this.currentToken().type == 'FINAL') {
                token = this.consume('FINAL');
                member.isFinal = true;
                if(startPos == null) {
                    startPos = token.location.start.clone();
                }
            }
            if(['PUBLIC', 'PROTECTED', 'PUBLIC'].indexOf(this.currentToken().type) > -1) {
                token = this.consume(this.currentToken().type);
                member.visibility = token.value;
                if(startPos == null) {
                    startPos = token.location.start.clone();
                }
            }
            if(this.currentToken().type == 'STATIC') {
                token = this.consume('STATIC');
                member.isStatic = true;
                if(startPos == null) {
                    startPos = token.location.start.clone();
                }
            }
            if(member.isFinal) {
                member.member = this.parseCode();
            } else {
                member.member = this.parseAssignement();
            }
            member.location.start = startPos;
            member.location.end = member.location.end.clone();
            node.location.end = member.location.end.clone();
            node.members.push(member);
            if(this.currentToken().type == 'MINDENT') {
                this.consume('MINDENT');
            }
        }
        this.consume('OUTDENT');
    }
    return node;
};

// Parse a use statement
//      Use := USE UseType UseClauses
//      UseType := CONST
//               | FUNC
//               |
//      UseClauses := UseClauses , UseClause
Parser.prototype.parseUse = function() {
    var node = new Nodes.Use();
    node.location.start = this.consume('USE').location.start.clone();
    if(this.currentToken().type == 'CONST') {
        this.consume('CONST');
        node.isConstFunc = 'const';
    } else if(this.currentToken().type == 'FUNC') {
        this.consume('FUNC');
        node.isConstFunc = 'function';
    }
    node.clauses.push(this.parseUseClause());
    while(this.currentToken().type == ',') {
        node.clauses.push(this.parseUseClause());
    }
    node.location.end = node.clauses[node.clauses.length - 1][node.clauses[node.clauses.length - 1].length - 1].location.end.clone();
    return node;
};

// Parse use clause
//      UseClause := QualifiedNamespaceName AS IDENTIFIER
//                 | QualifiedNamespaceName
Parser.prototype.parseUseClause = function() {
    var clause = [this.parseQualifiedNamespaceName()];
    if(this.currentToken().type == 'AS') {
        this.consume('AS');
        clause.push(this.parseIdentifier());
    }
    return clause;
};

// exports
module.exports = Parser;