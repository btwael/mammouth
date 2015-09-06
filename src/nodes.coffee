Context = require './context'

class Base
    prepare: -> @

    compile: ->

Document = class exports.Document extends Base
    constructor: (sections) ->
        @type = 'Document'
        @sections = sections

    prepare: -> @

    compile: (system) ->
        code = ''
        for section in @sections
            code += section.prepare(system).compile(system)
        return code

RawText = class exports.RawText extends Base
    constructor: (text = '') ->
        @type = 'RawText'
        @text = text

    compile: ->
        return @text

Script = class exports.Script extends Base
    constructor: (block) ->
        @type = 'Script'
        @body = block

    prepare: ->
        @body.braces = off
        @

    compile: (system) ->
        code = '<?php '
        code += @body.prepare(system).compile(system);
        code += '?>'
        return code

Block = class exports.Block extends Base
    constructor: (instructions = []) ->
        @type = 'Block'
        @body = instructions
        @braces = on
        @expands = off

    activateReturn: (returnGen = Express) ->
        return if @body.length is 0
        lastIndex = @body.length - 1
        switch @body[lastIndex].type
            when 'For', 'If', 'Switch', 'Try', 'While'
                @body[lastIndex].activateReturn(returnGen)
            when 'Break', 'Declare', 'Echo', 'Goto', 'Interface', 'Namespace', 'Section', 'Throw'
                return
            when 'Return'
                if @body[lastIndex].value is false
                    @body.pop()
            else
                @body[lastIndex] = returnGen(@body[lastIndex])

    prepare: ->
        for instruction, i in @body
            switch instruction.type
                when 'Assign', 'Call', 'Clone', 'Code', 'Goto', 'Break', 'Constant', 'Continue', 'Declare', 'Delete', 'GetKeyAssign', 'Echo', 'Namespace', 'NewExpression', 'Operation', 'Return', 'Throw', 'typeCasting', 'Value'
                    if instruction.type is 'Code' and instruction.body isnt false
                        break
                    if instruction.type is 'Namespace' and instruction.body isnt false
                        break
                    if instruction.type is 'Declare' and instruction.script isnt false
                        break
                    if instruction.type is 'Value' and instruction.value.type is 'Parens' and instruction.properties.length is 0
                        instruction = instruction.value.expression
                    expression = new Expression instruction
                    expression.isStatement = on
                    @body[i] = expression
                else
                    instruction.isStatement = on
        @

    compile: (system) ->
        if @braces and @body.length is 0
            return '{}'
        code = ''
        code += '{' if @braces
        if @body.length is 1 and @body[0].type is 'Expression' and not @expands
            code += ' ' + @body[0].prepare(system).compile(system) + ' }'
        else
            system.indent.up()
            code += '\n'
            for instruction, i in @body
                code += system.indent.get() + instruction.prepare(system).compile(system)
                code += '\n'
            system.indent.down()
            code += system.indent.get() + '}' if @braces
        return code

Expression = class exports.Expression extends Base
    constructor: (expression) ->
        @type = 'Expression'
        @expression = expression

    compile: (system) ->
        return @expression.prepare(system).compile(system) + ';'

Value = class exports.Value extends Base
    constructor: (value, properties = []) ->
        @type = 'Value'
        @value = value
        @properties = properties

    add: (prop) ->
        @properties.push(prop)
        @

    compile: (system) ->
        code = @value.prepare(system).compile(system)
        for propertie in @properties
            code += propertie.prepare(system).compile(system)
        return code

Access = class exports.Access extends Base
    constructor: (value, method = ".") ->
        @type = 'Access'
        @value = value
        @method = method

    compile: (system) ->
        switch @method
            when '->', '.'
                code = "->" + @value.name
            when '::', '..'
                code = '::' + @value.name
            when '[]'
                code = '[' + @value.prepare(system).compile(system) + ']'
        return code;

Identifier = class exports.Identifier extends Base
    constructor: (name) ->
        @type = 'Identifier'
        @name = name

    compile: (system) ->
        if not system.context.has @name 
            system.context.push new Context.Name @name
        return system.context.Identify(@name)

HereDoc = class exports.HereDoc extends Base
    constructor: (heredoc) ->
        @type = 'HereDoc'
        @heredoc = heredoc

    compile: (system) ->
        return '<<<EOT\n' + @heredoc + '\nEOT'

Literal = class exports.Literal extends Base
    constructor: (raw) ->
        @type = 'Literal'
        @value = eval raw
        @raw = raw

    compile: (system) ->
        return @raw

Array = class exports.Array extends Base
    constructor: (elements = []) ->
        @type = 'Array'
        @elements = elements

    compile: (system) ->
        code = 'array('
        for element, i in @elements
                code += element.prepare(system).compile(system)
                if i isnt @elements.length - 1
                    code += ', '
        code += ')'
        return code

ArrayKey = class exports.ArrayKey extends Base
    constructor: (key, value) ->
        @type = 'ArrayKey'
        @key = key
        @value = value

    compile: (system) ->
        return @key.prepare(system).compile(system) + ' => ' + @value.prepare(system).compile(system)

Parens = class exports.Parens extends Base
    constructor: (expression) ->
        @type = 'Parens'
        @expression = expression

    compile: (system) ->
        return '(' + @expression.prepare(system).compile(system) + ')'

typeCasting = class exports.typeCasting extends Base
    constructor: (expression, ctype) ->
        @type = 'typeCasting'
        @expression = expression
        @ctype = ctype

    compile: (system) ->
        return '(' + @ctype + ') ' + @expression.prepare(system).compile(system) 

Clone = class exports.Clone extends Base
    constructor: (expression) ->
        @type = 'Clone'
        @expression = expression

    compile: (system) ->
        return 'clone ' + @expression.prepare(system).compile(system)

Call = class exports.Call extends Base
    constructor: (callee, args = []) ->
        @type = 'Call'
        @callee = callee
        @arguments = args

    prepare: ->
        for arg, i in @arguments
            if arg.type is 'Value' and arg.value.type is 'Parens'
                @arguments[i] = arg.value.expression
        @

    compile: (system) ->
        code = @callee.prepare(system).compile(system)
        code += '('
        for arg, i in @arguments
            code += arg.prepare(system).compile(system)
            if i isnt @arguments.length - 1
                    code += ', '
        code += ')'
        return code

NewExpression = class exports.NewExpression extends Base
    constructor: (callee, args = []) ->
        @type = 'NewExpression'
        @callee = callee
        @arguments = args

    compile: (system) ->
        code = 'new ' + @callee.prepare(system).compile(system)
        code += '('
        for arg, i in @arguments
            code += arg.prepare(system).compile(system)
            if i isnt @arguments.length - 1
                    code += ', '
        code += ')'
        return code

Existence = class exports.Existence extends Base
    constructor: (value) ->
        @type = 'Existence'
        @value = value

    compile: (system) ->
        # check fo properties
        return 'isset(' + @value.prepare(system).compile(system) + ')'

Range = class exports.Range extends Base
    constructor: (from, to, tag) ->
        @type = 'Range'
        @from = from
        @to = to
        @exclusive = tag is 'exclusive'

    prepare: () ->
        if @from instanceof Value and
                @from.value instanceof Literal and
                typeof @from.value.value is 'number'
            @from = @from.value.value
        if @to instanceof Value and
                @to.value instanceof Literal and
                typeof @to.value.value is 'number'
            @to = @to.value.value
        if typeof @from is 'number' and typeof @to is 'number' and Math.abs(@from - @to) <= 20
            @compileResult = 'Array'
        else
            @compileResult = 'function'
        @

    compile: (system) ->
        if @compileResult is 'Array'
            array = if @exclusive then [@from...@to] else [@from..@to]
            return (new Array(new Literal(i.toString()) for i in array)).prepare(system).compile()
        # to be continuous

Slice = class exports.Slice extends Base
    constructor: (range) ->
        @type = 'Slice'
        @range = range

    compile: (system) ->
        # to be continuous

QualifiedName = class exports.QualifiedName extends Base
    constructor: (path) ->
        @type = 'QualifiedName'
        @path = path

    compile: (system) ->
        return @path

# Operations
Assign = class exports.Assign extends Base
    constructor: (operator, left, right) ->
        @type = 'Assign'
        @operator = operator
        @left = left
        @right = right

    compile: (system) ->
        code = @left.prepare(system).compile(system)
        code += ' ' + @operator + ' ' 
        code += @right.prepare(system).compile(system)
        return code

GetKeyAssign = class exports.GetKeyAssign extends Base
    constructor: (keys, source) ->
        @type = 'GetKeyAssign'
        @keys = keys
        @source = source

    compile: (system) ->
        code = ''
        for key, i in @keys
            if i isnt 0
                code += system.indent.get()
            left = (new Value key)
            @source.properties = []
            @source.add(new Access (new Value new Literal '"' + key.name + '"'), '[]')
            code += (new Assign '=', left, @source).prepare(system).compile(system)
            if i isnt @keys.length - 1
                code += ';\n'
        return code

Constant = class exports.Constant extends Base
    constructor: (left, right) ->
        @type = 'Constant'
        @left = left
        @right = right

    compile: (system) ->
        system.context.push new Context.Name @left, 'const'
        return 'const ' + @left + ' = ' + @right.prepare(system).compile(system)

Unary = class exports.Unary extends Base
    constructor: (operator, expression) ->
        @type = 'Unary'
        @operator = operator
        @expression = expression

    compile: (system) ->
        return @operator + @expression.prepare(system).compile(system)

Update = class exports.Update extends Base
    constructor: (operator, expression, prefix = true) ->
        @type = 'Update'
        @operator = operator
        @expression = expression
        @prefix = prefix

    compile: (system) ->
        code = @expression.prepare(system).compile(system)
        if @prefix then code = @operator + code else code += @operator
        return code

Operation = class exports.Operation extends Base
    constructor: (operator, left, right) ->
        @type = 'Operation'
        @operator = operator
        @left = left
        @right = right

    compile: (system) ->
        if @operator is 'in'
            return (new Value(new Call(
                new Value(new Identifier 'in_array')
                [
                   @left
                   @right 
                ]
            ))).prepare(system).compile(system)
        # if concat look if strict mode
        code = @left.prepare(system).compile(system)
        space = if @operator isnt '~' then ' ' else ''
        if @operator is '~'
            @operator = '.'
        code += space + @operator + space
        # mammouth super + check
        code += @right.prepare(system).compile(system)
        return code

Code = class exports.Code extends Base
    constructor: (parameters, body = false, asStatement = false, name = null) ->
        @type = 'Code'
        @parameters = parameters
        @body = body
        @asStatement = asStatement
        @name = name

    prepare: ->
        if @body isnt false
            @body.activateReturn((exp) -> new Expression new Return exp)
        @

    compile: (system) ->
        code = "function" + (if @asStatement then ' ' + @name else '') + '('
        system.context.push new Context.Name @name, 'function'
        system.context.scopeStarts()
        for parameter, i in @parameters
            code += parameter.prepare(system).compile(system)
            if i isnt @parameters.length - 1
                code += ', '
        code += ')'
        if @body isnt null
            code += ' ' + @body.prepare(system).compile(system)
        system.context.scopeEnds()
        return code;
        
Param = class exports.Param extends Base
    constructor: (name, passing = false, hasDefault = false, def = null) ->
        @type = 'Param'
        @name = name
        @passing = passing
        @hasDefault = hasDefault
        @default = def

    compile: (system) ->
        system.context.push new Context.Name @name
        code = (if @passing then '&' else '')
        code += '$' + @name
        code += (if @hasDefault then ' = ' + @default.prepare(system).compile(system) else '')
        return code

# If
If = class exports.If extends Base
    constructor: (condition, body, invert = off) ->
        @type = 'If'
        @condition = if invert then new Unary("!", condition) else condition
        @body = body
        @elses = []
        @closed = off

    addElse: (element) ->
        @elses.push(element)
        return @

    activateReturn: (returnGen) ->
        @body.activateReturn(returnGen)
        for els in @elses
            els.activateReturn(returnGen)

    prepare: () ->
        @body.expands = on 
        for els in @elses
            els.parentIf = @
            if @isStatement
                els.isStatement = on
            els.body.expands = on
        if not @isStatement
            if @body.body.length is 1
                @body = @body.body[0]
        @

    compile: (system) ->
        if @isStatement
            code = 'if(' + @condition.prepare(system).compile(system) + ') '
            code += @body.prepare(system).compile(system)
            for els in @elses
                code += els.prepare(system).compile(system)
        else
            code = @condition.prepare(system).compile(system) + ' ? ' + @body.prepare(system).compile(system)
            for els in @elses
                code += ' : ' + els.prepare(system).compile(system)
            if not @closed
                code += ' : NULL';
        return code
        

ElseIf = class exports.ElseIf extends Base
    constructor: (condition, body) ->
        @type = 'ElseIf'
        @condition = condition
        @body = body

    activateReturn: (returnGen) ->
        @body.activateReturn(returnGen)

    prepare: ->
        if not @isStatement
            if @body.body.length is 1
                @body = @body.body[0]
        @

    compile: (system) ->
        if @isStatement
            code = ' elseif(' + @condition.prepare(system).compile(system) + ') '
            code += @body.prepare(system).compile(system)
        else
            code = @condition.prepare(system).compile(system) + ' ? ' + @body.prepare(system).compile(system)
        return code

Else = class exports.Else extends Base
    constructor: (body) ->
        @type = 'Else'
        @body = body

    activateReturn: (returnGen) ->
        @body.activateReturn(returnGen)

    prepare: ->
        if not @isStatement
            if @body.body.length is 1
                @body = @body.body[0]
        @

    compile: (system) ->
        if @isStatement
            code = ' else '
            code += @body.prepare(system).compile(system)
        else
            parentIf.closed = on
            code = @body.prepare(system).compile(system)
        return code

# While
While = class exports.While extends Base
    constructor: (test, invert = off, guard = null, block = null) ->
        @type = 'While'
        @test = if invert then new Unary("!", test) else test
        @guard = guard
        @body = block
        @returnactived = off
        if block isnt null
            delete @guard

    addBody: (block) ->
        @body = if @guard isnt null then new Block([new If(@guard, block)]) else block
        delete @guard
        return @

    activateReturn: (returnGen) ->
        @returnactived = on

    prepare: (system) ->
        @body.expands = on
        if @returnactived
            @cacheRes = cacheRes = system.context.free('result')
            funcgen = (exp) ->
                m = new Expression(new Call(
                    new Value(new Identifier('array_push')),
                    [new Value(cacheRes), exp]
                ))
                return m
            @body.activateReturn(funcgen);
        @

    compile: (system) ->
        code = ''
        if @isStatement
            if @returnactived
                init = new Expression new Assign '=', new Value(@cacheRes), new Value(new Array())
                code += init.prepare(system).compile(system)
                code += '\n' + system.indent.get()
            code += 'while(' + @test.prepare(system).compile(system) + ') '
            code += @body.prepare(system).compile(system)
            if @returnactived
                code += '\n' + system.indent.get()
                code += (new Expression new Return new Value @cacheRes).prepare(system).compile(system)
        else
            @isStatement = on
            code += (new Value(
                new Call(
                    new Code(
                        []
                        new Block [@]
                    )
                )
            )).prepare(system).compile(system)
        return code

# Try
Try = class exports.Try extends Base
    constructor: (TryBody, CatchBody = new Block, CatchIdentifier = false, FinallyBody = false) ->
        @type = 'Try'
        @TryBody = TryBody
        @CatchBody = CatchBody
        @CatchIdentifier = CatchIdentifier
        @FinallyBody = FinallyBody

    activateReturn: (returnGen) ->
        @TryBody.activateReturn(returnGen)
        @CatchBody.activateReturn(returnGen)
        if @FinallyBody isnt false
            @FinallyBody.activateReturn(returnGen)

    prepare: (system) ->
        @TryBody.expands = on
        @CatchBody.expands = on
        if @FinallyBody isnt false
            @FinallyBody.expands = on
        @

    compile: (system) ->
        code = ''
        if @isStatement
            code += 'try '
            code += @TryBody.prepare(system).compile(system)
            code += ' catch(Exception '
            if @CatchIdentifier is false
                code += system.context.free('error').prepare(system).compile(system)
            else
                code += @CatchIdentifier.prepare(system).compile(system)
            code += ') ' + @CatchBody.prepare(system).compile(system)
        else
            @isStatement = on
            code += (new Value(
                new Call(
                    new Code(
                        []
                        new Block [@]
                    )
                )
            )).prepare(system).compile(system)
        return code
l = 0
# For
For = class exports.For extends Base
    constructor: (source, block) ->
        @type = 'For'
        @source = source
        @body = block
        @returnactived = off
        @isPrepared = off

    activateReturn: (returnGen) ->
        @returnactived = on

    prepare: (system) ->
        @body.expands = on
        @object = !!@source.object
        if not(@source.range? and @source.range is true)
            if not @object
                @cacheIndex = system.context.free('i')
                @cacheLen = system.context.free('len')
                if @source.source.type is 'Value' and @source.source.value.type is 'Identifier'
                    @initRef = false
                    @cacheRef = @source.source.value
                else
                    @initRef = true
                    @cacheRef = system.context.free('ref')
                valfromRef = new Value(@cacheRef)
                valfromRef.add(new Access((if @source.index? then @source.index else @cacheIndex), '[]'))
                addTop = true
        if @source.guard? and not @isPrepared
            @body = new Block([new If(@source.guard, @body)])
        if addTop is true and not @isPrepared
            @body.body.unshift new Expression new Assign(
                '='
                @source.name
                valfromRef
            )
        if @returnactived
                @cacheRes = cacheRes = system.context.free('result')
                funcgen = (exp) ->
                    m = new Expression(new Call(
                        new Value(new Identifier('array_push')),
                        [new Value(cacheRes), exp]
                    ))
                    return m
                @body.activateReturn(funcgen);
        @

    compile: (system) ->
        code = ''
        if @isStatement
            if @returnactived
                init = new Expression new Assign '=', new Value(@cacheRes), new Value(new Array())
                code += init.prepare(system).compile(system)
                code += '\n' + system.indent.get()
            if @source.range? and @source.range is true
                index = system.context.free('i')
                code += 'for(' 
                code += (new Assign(
                    '='
                    index
                    @source.source.from
                )).prepare(system).compile(system)
                code += '; '
                code += (new Operation(
                    if @source.source.exclusive then '<' else '<='
                    index
                    @source.source.to
                )).prepare(system).compile(system)
                code += '; '
                if @source.step?
                    update = new Assign '+=', index, @source.step
                else
                    update = new Update '++', index, false
                code += (update).prepare(system).compile(system)
                code += ') '
                code += @body.prepare(system).compile(system)
            else
                if @object
                    code += 'foreach(' + @source.source.prepare(system).compile(system) + ' as '
                    code += @source.name.prepare(system).compile(system)
                    code += ' => '
                    if @source.index?
                        code += @source.index.prepare(system).compile(system)
                    else
                        code += system.context.free('value').prepare(system).compile(system)
                    code += ') '
                    code += @body.prepare(system).compile(system)
                else
                    index = @cacheIndex
                    len = @cacheLen
                    if @initRef
                        init = new Expression new Assign '=', new Value(@cacheRef), @source.source
                        code += init.prepare(system).compile(system)
                        code += '\n' + system.indent.get()
                    code += 'for(' 
                    if @source.index?
                        code += (new Assign(
                            '='
                            @source.index
                            new Value(new Assign('=', index, new Value(new Literal('0'))))
                        )).prepare(system).compile(system)
                    else
                        code += (new Assign(
                            '='
                            index
                            new Value new Literal '0'
                        )).prepare(system).compile(system)
                    code += ', '
                    code += (new Assign(
                        '='
                        len
                        new Value new Call(
                            new Identifier('mammouth')
                            [
                                new Value new Literal("'length'")
                                @cacheRef
                            ]
                        )
                    )).prepare(system).compile(system)
                    code += '; '
                    code += (new Operation(
                        '<'
                        index
                        len
                    )).prepare(system).compile(system)
                    code += '; '
                    if @source.step?
                        update = new Assign '+=', index, @source.step
                    else
                        update = new Update '++', index, false
                    if @source.index?
                        code += (new Assign(
                            '='
                            @source.index
                            new Value(update)
                        )).prepare(system).compile(system)
                    else
                        code += (update).prepare(system).compile(system)
                    code += ') '
                    code += @body.prepare(system).compile(system)
            if @returnactived
                code += '\n' + system.indent.get()
                code += (new Expression new Return new Value @cacheRes).prepare(system).compile(system)
        else
            @isStatement = on
            @isPrepared = on
            code += (new Value(
                new Call(
                    new Code(
                        []
                        new Block [@]
                    )
                )
            )).prepare(system).compile(system)
        return code


# For
Switch = class exports.Switch extends Base
    constructor: (subject, whens, otherwise = null) ->
        @type = 'Switch'
        @subject = subject
        @whens = whens
        @otherwise = otherwise

# Declare
Declare = class exports.Declare extends Base
    constructor: (expression, script = false) ->
        @type = 'Declare'
        @expression = expression
        @script = script

    prepare: (system) ->
        if @script isnt false
            @script.expands = on
        @

    compile: (system) ->
        if @expression.type is 'Assign' and @expression.left.type is 'Value' and @expression.left.value.type is 'Identifier'
            system.context.push new Context.Name @expression.left.value.name, 'const'
        code = 'declare(' + @expression.prepare(system).compile(system) + ')'
        if @script isnt false
            code += ' ' + @script.prepare(system).compile(system)
        return code

# Section
Section = class exports.Section extends Base
    constructor: (name) ->
        @type = 'Section'
        @name = name

    compile: (system) ->
        return @name + ':'

# Jump Statement
Goto = class exports.Goto extends Base
    constructor: (section) ->
        @type = 'Goto'
        @section = section

    compile: (system) ->
        return 'goto ' + @section

Break = class exports.Break extends Base
    constructor: (arg = false) ->
        @type = 'Break'
        @arg = arg

    compile: (system) ->
        return 'break' + (if @arg is false then '' else ' ' + @arg.prepare(system).compile(system))

Continue = class exports.Continue extends Base
    constructor: (arg = false) ->
        @type = 'Continue'
        @arg = arg

    compile: (system) ->
        return 'continue' + (if @arg is false then '' else ' ' + @arg.prepare(system).compile(system))

Return = class exports.Return extends Base
    constructor: (value = false) ->
        @type = 'Return'
        @value = value

    compile: (system) ->
        return 'return' + (if @value is false then '' else ' ' + @value.prepare(system).compile(system))

Throw = class exports.Throw extends Base
    constructor: (expression) ->
        @type = 'Throw'
        @expression = expression

    compile: (system) ->
        return 'throw ' + @expression.prepare(system).compile(system)

Echo = class exports.Echo extends Base
    constructor: (value) ->
        @type = 'Echo'
        @value = value

    compile: (system) ->
        return 'echo ' + @value.prepare(system).compile(system)

Delete = class exports.Delete extends Base
    constructor: (value) ->
        @type = 'Delete'
        @value = value

    compile: (system) ->
        return 'delete ' + @value.prepare(system).compile(system)

# Class
Class = class exports.Class extends Base
    constructor: (name, body, extendable = false, implement = false, modifier = false) ->
        @type = "Class"
        @name = name
        @body = body
        @extendable = extendable
        @implement = implement
        @modifier = modifier

ClassLine = class exports.ClassLine extends Base
    constructor: (visibility, statically, element) ->
        @type = 'ClassLine'
        @abstract = false
        @visibility = visibility
        @statically = statically
        @element = element

# Interface
Interface = class exports.Interface extends Base
    constructor: (name, body, extendable = false) ->
        @type = "Interface"
        @name = name
        @body = body
        @extendable = extendable

# Namespace
Namespace = class exports.Namespace extends Base
    constructor: (name, body = false) ->
        @type = 'Namespace'
        @name = name
        @body = body

    prepare: (system) ->
        if @body isnt false
            @body.expands = on
        @

    compile: (system) ->
        code = 'namespace ' + @name.prepare(system).compile(system)
        if @body isnt false
            system.context.scopeStarts()
            code += ' ' + @body.prepare(system).compile(system)
            system.context.scopeEnds()
        return code