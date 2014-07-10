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

exports.BlankLine = class BlankLine
	constructor: () ->
		@type = 'BlankLine'

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
	constructor: (@name, @as_arguments = false) ->
		@type = 'Identifier'

exports.PassingIdentifier = class PassingIdentifier
	constructor: (@name) ->
		@type = 'PassingIdentifier'

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

# Statements
exports.EchoStatement = class EchoStatement
	constructor: (@expression) ->
		@type = 'EchoStatement'

exports.ReturnStatement = class ReturnStatement
	constructor: (@expression = null) ->
		@type = 'ReturnStatement'

exports.BreakStatement = class BreakStatement
	constructor: (@expression = null) ->
		@type = 'BreakStatement'

exports.ContinueStatement = class ContinueStatement
	constructor: (@expression = null) ->
		@type = 'ContinueStatement'

exports.IncludeStatement = class IncludeStatement
	constructor: (@expression, @once = false) ->
		@type = 'IncludeStatement'

exports.RequireStatement = class RequireStatement
	constructor: (@expression, @once = false) ->
		@type = 'RequireStatement'

exports.If = class If
	constructor: (@condition, @body, @expression = false) ->
		@type = 'If'
		@Elses = []

	addElse: (body) ->
		@Elses.push {
			type: 'Else'
			body: body
		}

	addElseIf: (condition, body) ->
		@Elses.push {
			type: 'ElseIf'
			condition: condition
			body: body
		}

exports.While = class While
	constructor: (@condition, @body) ->
		@type = 'While'

exports.Try = class Try
	constructor: (@TryBody, @CatchIdentifier, @CatchBody, @Finally = false) ->
		@type = 'Try'
		@Elses = []

	addFinally: (body) ->
		@Finally = true
		@FinallyBody = body