# Documents
exports.PlainBlock = class PlainBlock
	constructor: (@text) ->
		@type = 'PlainBlock'

	toPHP: ->
		return @text

exports.MammouthBlock = class MammouthBlock
	constructor: (@body) ->
		@type = 'MammouthBlock'

# Blocks
exports.Block = class Block
	constructor: (@nodes) ->
		@type = 'Block'

exports.Expression = class Expression
	constructor: (@expression) ->
		@type = 'Expression'

# Values, types and variables
exports.Value = class Value
	constructor: (@value, @properties = []) ->
		@type = 'Value'

	add: (prop) ->
		@properties.push(prop)

exports.Access = class Access
	constructor: (@value, @method = ".") ->
		@type = 'Access'

exports.Parens = class Parens
	constructor: (@expression) ->
		@type = 'Parens'

exports.Identifier = class Identifier
	constructor: (@name, @as_arguments = false, @passing = false) ->
		@type = 'Identifier'

exports.Literal = class Literal
	constructor: (@value) ->
		@type = 'Literal'

exports.Bool = class Bool
	constructor: (@value) ->
		@type = 'Bool'

exports.Array = class Array
	constructor: (@elements = []) ->
		@type = 'Array'

exports.ArrayKey = class ArrayKey
	constructor: (@key, @value) ->
		@type = 'ArrayKey'

exports.Call = class Call
	constructor: (@variable, @arguments = []) ->
		@type = 'Call'

exports.Code = class Code
	constructor: (@parameters, @body, @normal = false, @name = null) ->
		@type = 'Code'

# Operations
exports.Assign = class Assign
	constructor: (@operator, @left, @right) ->
		@type = 'Assign'

exports.Constant = class Constant
	constructor: (@left, @right) ->
		@type = 'Constant'

exports.Unary = class Unary
	constructor: (@operator, @expression) ->
		@type = 'Unary'

exports.Update = class Update
	constructor: (@operator, @expression, @prefix = true) ->
		@type = 'Update'

exports.Existence = class Existence
	constructor: (@expression) ->
		@type = 'Existence'

exports.Operation = class Operation
	constructor: (@operator, @left, @right) ->
		@type = 'Operation'

exports.In = class In
	constructor: (@left, @right) ->
		@type = 'In'

# If
exports.If = class If
	constructor: (@condition, @body) ->
		@type = 'If'
		@Elses = []

	addElse: (element) ->
		@Elses.push(element)

exports.ElseIf = class ElseIf
	constructor: (@condition, @body) ->
		@type = 'ElseIf'

exports.Else = class Else
	constructor: (@body) ->
		@type = 'Else'

# While
exports.While = class While
	constructor: (@test, @body) ->
		@type = 'While'

# Try
exports.Try = class Try
	constructor: (@TryBody, @CatchIdentifier, @CatchBody, @Finally = false) ->
		@type = 'Try'

	addFinally: (body) ->
		@Finally = true
		@FinallyBody = body

# Switch
exports.Switch = class Switch
	constructor: (@variable, @cases) ->
		@type = 'Switch'

exports.When = class When
	constructor: (@condition, @body) ->
		@type = 'When'

exports.SwitchElse = class SwitchElse
	constructor: (@body) ->
		@type = 'SwitchElse'