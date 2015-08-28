Document = class exports.Document
    constructor: (sections) ->
        @type = 'Document'
        @sections = sections

RawText = class exports.RawText
    constructor: (text = '') ->
        @type = 'RawText'
        @text = text

Script = class exports.Script
    constructor: (block) ->
        @type = 'Script'
        @body = block

Block = class exports.Block
    constructor: (instructions = []) ->
        @type = 'Block'
        @body = instructions

Expression = class exports.Expression
    constructor: (expression) ->
        @type = 'Expression'
        @expression = expression

Value = class exports.Value
    constructor: (value, properties = []) ->
        @type = 'Value'
        @value = value
        @properties = properties

    add: (prop) ->
        @properties.push(prop) 

Identifier = class exports.Identifier
    constructor: (name) ->
        @type = 'Identifier'
        @name = name

Literal = class exports.Literal
    constructor: (raw) ->
        @type = 'Literal'
        @value = eval raw
        @raw = raw

Access = class exports.Access
    constructor: (value, method = ".") ->
        @type = 'Access'
        @value = value
        @method = method

Array = class exports.Array
    constructor: (elements = []) ->
        @type = 'Array'
        @elements = elements

ArrayKey = class exports.ArrayKey
    constructor: (key, value) ->
        @type = 'ArrayKey'
        @key = key
        @value = value

Parens = class exports.Parens
    constructor: (expression) ->
        @type = 'Parens'
        @expression = expression

typeCasting = class exports.typeCasting
    constructor: (expression, ctype) ->
        @type = 'typeCasting'
        @expression = expression
        @ctype = ctype

Clone = class exports.Clone
    constructor: (expression) ->
        @type = 'Clone'
        @expression = expression

Call = class exports.Call
    constructor: (callee, args = []) ->
        @type = 'Call'
        @callee = callee
        @arguments = args

NewExpression = class exports.NewExpression
    constructor: (callee, args = []) ->
        @type = 'NewExpression'
        @callee = callee
        @arguments = args

Existence = class exports.Existence
    constructor: (value) ->
        @type = 'Existence'
        @value = value

Range = class exports.Range
    constructor: (from, to, tag) ->
        @type = 'Range'
        @from = from
        @to = to
        @exclusive = tag is 'exclusive'

Slice = class exports.Slice
    constructor: (range) ->
        @type = 'Slice'
        @range = range

QualifiedName = class exports.QualifiedName
    constructor: (path) ->
        @type = 'QualifiedName'
        @path = path

# Operations
Assign = class exports.Assign
    constructor: (operator, left, right) ->
        @type = 'Assign'
        @operator = operator
        @left = left
        @right = right

GetKeyAssign = class exports.GetKeyAssign
    constructor: (keys, source) ->
        @type = 'GetKeyAssign'
        @keys = keys
        @source = source

Constant = class exports.Constant
    constructor: (left, right) ->
        @type = 'Constant'
        @left = left
        @right = right

Unary = class exports.Unary
    constructor: (operator, expression) ->
        @type = 'Unary'
        @operator = operator
        @expression = expression

Update = class exports.Update
    constructor: (operator, expression, prefix = true) ->
        @type = 'Update'
        @operator = operator
        @expression = expression
        @prefix = prefix

Operation = class exports.Operation
    constructor: (operator, left, right) ->
        @type = 'Operation'
        @operator = operator
        @left = left
        @right = right

Code = class exports.Code
    constructor: (parameters, body, asStatement = false, name = null) ->
        @type = 'Code'
        @parameters = parameters
        @body = body
        @asStatement = asStatement
        @name = name

Param = class exports.Param
    constructor: (name, passing = false, hasDefault = false, def = null) ->
        @type = 'Param'
        @name = name
        @passing = passing
        @hasDefault = hasDefault
        @default = def

# If
If = class exports.If
    constructor: (condition, body, invert = off) ->
        @type = 'If'
        @condition = if invert then new Unary("!", condition) else condition
        @body = body
        @elses = []

    addElse: (element) ->
        @elses.push(element)
        return @

ElseIf = class exports.ElseIf
    constructor: (condition, body) ->
        @type = 'ElseIf'
        @condition = condition
        @body = body

Else = class exports.Else
    constructor: (body) ->
        @type = 'Else'
        @body = body

# While
While = class exports.While
    constructor: (test, invert = off, guard = null, block = null) ->
        @type = 'While'
        @test = if invert then new Unary("!", test) else test
        @guard = guard
        @body = block
        if block isnt null
            delete @guard

    addBody: (block) ->
        @body = if @guard isnt null then new Block([new If(@guard, block.body)]) else block
        delete @guard
        return @

# Try
Try = class exports.Try
    constructor: (TryBody, CatchBody = new Block, CatchIdentifier = false, FinallyBody = false) ->
        @type = 'Try'
        @TryBody = TryBody
        @CatchBody = CatchBody
        @CatchIdentifier = CatchIdentifier
        @FinallyBody = FinallyBody

# For
For = class exports.For
    constructor: (properties, block) ->
        @type = 'For'
        @properties = properties
        @body = block

# For
Switch = class exports.Switch
    constructor: (subject, whens, otherwise = null) ->
        @type = 'Switch'
        @subject = subject
        @whens = whens
        @otherwise = otherwise

# Declare
Declare = class exports.Declare
    constructor: (expression, script = false) ->
        @type = 'Declare'
        @expression = expression
        @script = script

# Section
Section = class exports.Section
    constructor: (name) ->
        @type = 'Section'
        @name = name

# Jump Statement
Goto = class exports.Goto
    constructor: (section) ->
        @type = 'Goto'
        @section = section

Break = class exports.Break
    constructor: (arg = false) ->
        @type = 'Break'
        @arg = arg

Continue = class exports.Continue
    constructor: (arg = false) ->
        @type = 'Continue'
        @arg = arg

Return = class exports.Return
    constructor: (value = false) ->
        @type = 'Return'
        @value = value

Throw = class exports.Throw
    constructor: (expression) ->
        @type = 'Throw'
        @expression = expression

Echo = class exports.Echo
    constructor: (value) ->
        @type = 'Echo'
        @value = value

Delete = class exports.Delete
    constructor: (value) ->
        @type = 'Delete'
        @value = value

# Class
Class = class exports.Class
    constructor: (name, body, extendable = false, implement = false, modifier = false) ->
        @type = "Class"
        @name = name
        @body = body
        @extendable = extendable
        @implement = implement
        @modifier = modifier

ClassLine = class exports.ClassLine
    constructor: (visibility, statically, element) ->
        @type = 'ClassLine'
        @abstract = false
        @visibility = visibility
        @statically = statically
        @element = element

# Interface
Interface = class exports.Interface
    constructor: (name, body, extendable = false) ->
        @type = "Interface"
        @name = name
        @body = body
        @extendable = extendable

# Namespace
Namespace = class exports.Namespace
    constructor: (name, body = false) ->
        @type = 'Namespace'
        @name = Namespace
        @body = body