class exports.Document
    constructor: (sections) ->
        @type = 'Document'
        @sections = sections

class exports.RawText
    constructor: (text = '') ->
        @type = 'RawText'
        @text = text

class exports.Script
    constructor: (block) ->
        @type = 'Script'
        @body = block

class exports.Block
    constructor: (instructions = []) ->
        @type = 'Block'
        @body = instructions

class exports.Value
    constructor: (value, properties = []) ->
        @type = 'Value'
        @value = value
        @properties = properties

    add: (prop) ->
        @properties.push(prop) 

class exports.Identifier
    constructor: (name) ->
        @type = 'Identifier'
        @name = name

class exports.Literal
    constructor: (raw) ->
        @type = 'Literal'
        @value = eval raw
        @raw = raw

class exports.Access
    constructor: (value, method = ".") ->
        @type = 'Access'
        @value = value
        @method = method

class exports.Array
    constructor: (elements = []) ->
        @type = 'Array'
        @elements = elements

class exports.ArrayKey
    constructor: (key, value) ->
        @type = 'ArrayKey'
        @key = key
        @value = value

class exports.Parens
    constructor: (expression) ->
        @type = 'Parens'
        @expression = expression

class exports.typeCasting
    constructor: (expression, ctype) ->
        @type = 'typeCasting'
        @expression = expression
        @ctype = ctype

class exports.Clone
    constructor: (expression) ->
        @type = 'Clone'
        @expression = expression