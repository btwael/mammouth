# Grammar of Mammouth v4

## Precedence

| Name           | Operators                                                                | Ordinal  |
|:--------------:|:------------------------------------------------------------------------:|:--------:|
| Zero           | (default)                                                                | 0        |
| Assign         | `=`, `+=`, `-=`, `*=`, `**=`, `/=`, `%=`, `<<=`, `>>=`, `|=`, `&=`, `^=` | 1        |
| LogicalOr      | `||`                                                                     | 2        |
| LogicalAnd     | `&&`                                                                     | 3        |
| BitwiseOr      | `|`                                                                      | 4        |
| BitwiseAnd     | `&`                                                                      | 5        |
| BitwiseXor     | `^`                                                                      | 6        |
| Equality       | `==`, `!=`                                                               | 7        |
| Relational     | `<`, `>`, `<=`, `>=`                                                     | 8        |
| Shift          | `<<`, `>>`                                                               | 9        |
| Additive       | `+`, `-`                                                                 | 10       |
| Multiplicative | `*`, `**`, `/`, `%`                                                      | 11       |
| Membership     | `in`                                                                     | 12       |
| Conversion     | `to`, `as`                                                               | 13       |


## Syntax

    Document := DocumentEntry* EOS

    DocumentEntry := (InlineEntry | Script)

    InlineEntry := INLINE_ENTRY

    Script := START_TAG (Block)? END_TAG

    Block := INDENT Statement (MINDENT Statement)* OUTDENT
           | Statement

    Statement := Block
               | ImportDirective
               | InterfaceDeclaration
               | VariableDeclarationOrExpressionStatement
               | MaybeControlledStatement
               
    ImportDirective := IMPORT StringLiteral
               
    MaybeControlledStatement := SimpleStatement (ControlSource)? // TODO: think about break in for?
    
    SimpleStatement := BreakStatement
                     | ContinueStatement
                     | ReturnStatement
                     | ThrowStatement
                     
    BreakStatement := BREAK
    
    ContinueStatement := CONTINUE
    
    ReturnStatement := RETURN (Expression)?
    
    ThrowStatement := THROW Expression
               
    InterfaceDeclaration := INTERFACE SimpleIdentifier (ImplementsClause)? InterfaceBody
    
    ImplementsClause := IMPLEMENTS TypeName (COMMA TypeName)*
    
    InterfaceBody := INDENT ClassMember (MINDENT ClassMember)* OUTDENT
    
    VariableDeclarationOrExpressionStatement := VariableDeclarationStatement
                                              | ExpressionStatament

    VariableDeclarationStatement := TypeAnnotation SimpleIdentifier (ASSIGN_EQUAL Expression)?

    ExpressionStatement := Expression (ControlSource)?

    Expression := ClassExpression
                | FunctionExpression
                | IfExpression
                | RepetitionExpression
                | ForExpression
                | TryExpression
                | SwitchExpression
                | MaybeControlledExpresssion
                
    ClassExpression := CLASS (SimpleIdentifier)? (ExtendsClause)? (ImplementsClause)? ClassBody
    
    ExtendsClause := EXTENDS TypeName
    
    ClassBody := INDENT ClassMember (MINDENT ClassMember)* OUTDENT
    
    ClassMember := (Visibility)? ConstructorDeclaration
                 | (Visibility)? FieldDeclaration
                 | (ABSTRACT)? (Visibility)? (STATIC)? MethodDeclaration
                 | (ABSTRACT)? (Visibility)? OperatorDeclaration
                 | (ABSTRACT)? (Visibility)? ConverterDeclaration
                 
    Visibility := PRIVATE
                | PROTECTED
                | PUBLIC
                 
    ConstructorDeclaration := CONSTRUCTOR (ParameterList)? (INLINE)? (RIGHT_ARROW Block)?
                 
    FieldDeclaration := (TypeAnnotation)? SimpleIdentifier (ASSIGN_EQUAL Expression)?
                 
    MethodDeclaration := TypeAnnotation (GET|SET)? SimpleIdentifier (ParameterList)? (INLINE)? (RIGHT_ARROW Block)?

    OperatorDeclaration := OPERATOR BinaryOperator (ParameterList)? (INLINE)? (RIGHT_ARROW Block)?
                         | PREFIX (UnaryOperator|UpdateOperator) (ParameterList)? (INLINE)? (RIGHT_ARROW Block)?
                         | POSTFIX UpdateOperator (ParameterList)? (INLINE)? (RIGHT_ARROW Block)?
                     
                    // TODO: operators: []
                         
    ConverterDeclaration := TypeAnnotation TO RIGHT_ARROW (INLINE)? (RIGHT_ARROW Block)?

    FunctionExpression := TypeAnnotation (SimpleIdentifier)? (ParameterList)? (INLINE)? RIGHT_ARROW Block
    
    IfExpression := IfSource (THEN)? Statement (ELSE Statement)?
    
    IfSource := (IF|UNLESS) Expression
    
    RepetitionExpression := RepetitionSource Statement
    
    RepetitionSource := (WHILE | UNTIL) Expression (GuardSource)?
                      | LOOP (GuardSource)?
                      
    ForExpression := ForSource Statement
                      
    ForSource := FOR RangeLiteral (AS ForVariable)? (BY Expression)? (GuardSource)?
               | FOR RangeLiteral (BY Expression) (AS ForVariable) (GuardSource)?
               | FOR ForVariables (IN|OF) Expression (BY Expression)? (GuardSource)?
               
    ForVariables := ForVariable (COMMA ForVariable)?
    
    ForVariable := (TypeAnnotation)? SimpleIdentifier
    
    TryExpression := TRY Statement (MINDENT CATCH (TypeAnnotation)? SimpleIdentifier)? (MINDENT FINALLY Statement)?
    
    SwitchExpression := SWITCH Expression INDENT SwitchCase (MIDENT SwitchCase)* (SwitchDefult)? OUTDNET
    
    SwitchCase := (CASE|WHEN) Expression Statement
    
    SwitchDefault := DEFAULT Statement

    MaybeControlledExpresssion := SimpleExpression (ControlSource)?

    ControlSource := ForSource
                   | IfSource
                   | RepetitionSource
    
    GuardSource := (WHEN Expression)?

    SimpleExpression := EchoExpression
                      | MaybeAssignmentExpression
                      
    EchoExpression := ECHO Expression

    MaybeAssignmentExpression := MaybeBinaryExpression (AssignementOperator Expression)?

    MaybeBinaryExpression := MaybeInExpression (BinaryOperator MaybeBinaryExpression)?
                                                    // respecting operators precedence
                                                    
    MaybeInExpression := MaybePrefixExpression (IN MaybeNewExpression)?
    
    MaybeAsOrToExpression := MaybePrefixExpression ((AS|TO) TypeAnnotation)?

    MaybePrefixExpression := UpdateOperator MaybePrefixExpression
                           | UnaryOperator MaybePrefixExpression
                           | MaybePostfixExpression

    MaybePostfixExpression := MaybeNewExpression (UpdateOperator)?
    
    MaybeNewExpression := NEW TypeAnnotation (LEFT_PAREN ArgumentList RIGHT_PAREN)?
                        | MaybeMemberExpression
    
    MaybeMemberExpression := MaybeMemberExpression LEFT_PAREN ArgumentList RIGHT_PAREN
                           | MaybeMemberExpression LEFT_BRACKET Expression RIGHT_BRACKET
                           | MaybeMemberExpression RangeLiteral
                           | MaybeMemberExpression DOT SimpleIdentifier
                           | MaybeMemberExpression QUESTIONMARK
                           | PrimaryExpression

    PrimaryExpression := SimpleIdentifier
                       | NativeExpression
                       | AtExpression
                       | ArrayLiteral
                       | RangeLiteral
                       | MapLiteral
                       | ParenthesisExpression
                       | Literal
                       
    NativeExpression := NATIVE LEFT_PAREN ArgumentList RIGHT_PAREN
                       
    AtExpression := AT SimpleIdentifier
    
    ArrayLiteral := (LESS_THAN TypeAnnotation GREATER_THAN)? LEFT_BRACKET ArgumentList RIGHT_BRACKET
    
    RangeLiteral := LEFT_BRACKET (Expression)? (RANGE_DOUBLEDOT|RANGE_TRIPLEDOT) (Expression)? RIGHT_BRACKET
        // TODO: RangeOperator
    
    MapLiteral := (LESS_THAN TypeAnnotation COMMA TypeAnnotation GREATER_THAN)? LEFT_BRACE MapKeys RIGHT_BRACE
    
    MapBody := MapEntry (COMMA MapBody)?
             | INDENT (MapEntry ((COMMA)? (MINDENT)? MapEntry)?)? OUTDENT
    
    MapEntry := Expression COLON (Expression | (INDENT Expression OUTDENT))
    
    ParenthesisExpression := LEFT_PAREN Expression RIGHT_PAREN
                           | LEFT_PAREN INDENT Expression OUTDENT RIGHT_PAREN

    Literal := BooleanLiteral
             | StringLiteral
             | IntegerLiteral
             | FloatLiteral

    BooleanLiteral := BOOLEAN

    StringLiteral := STRING

    IntegerLiteral := INTEGER

    FloatLiteral := FLOAT

    SimpleIdentifier := NAME

    TypeAnnotation := TypeName

    TypeName := SimpleIdentifier (TypeArgumentList)?

    ParameterList := LEFT_PAREN (Parameter (COMMA Parameter)*)? RIGHT_PAREN
    
    Parameter := SimpleParameter
               | ClosureParameter

    SimpleParameter := (TypeAnnotation)? SimpleIdentifier
    
    ClosureParameter := TypeAnnotation SimpleIdentifier LEFT_PAREN (TypeAnnotation (COMMA TypeAnnotation)*)? RIGHT_PAREN
    
    ArgumentList := Expression (COMMA ArgumentList)?
                  | INDENT (Expression ((COMMA)? (MINDENT)? Expression)?)? OUTDENT
    
    TypeArgumentList := TypeAnnotation (COMMA TypeArgumentList)?
                      | INDENT (TypeAnnotation ((COMMA)? (MINDENT)? TypeAnnotation)?)? OUTDENT
    
    Argument := Expression
              | IndentedArguments
    
    IndentedArguments := INDENT (Expression ((COMMA)? (MINDENT)? Expression)?)? OUTDENT

    AssignementOperator := ASSIGN
    
    BinaryOperator := BINARY
    
    UpdateOperator := UPDATE
    
    UnaryOperator := UNARY | PLUS | MINUS
