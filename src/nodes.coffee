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

exports.Null = class
	constructor: ->
		@type = 'Null'

exports.Array = class Array
	constructor: (@elements = []) ->
		@type = 'Array'

exports.ArrayKey = class ArrayKey
	constructor: (@key, @value) ->
		@type = 'ArrayKey'

exports.Call = class Call
	constructor: (@variable, @arguments = []) ->
		@type = 'Call'

exports.NewCall = class NewCall
	constructor: (@variable, @arguments = false) ->
		@type = 'NewCall'

exports.Code = class Code
	constructor: (@parameters, @body, @normal = false, @name = null) ->
		@type = 'Code'

exports.Casting = class Casting
	constructor: (@variable, @typec) ->
		@type = 'Casting'

exports.Exec = class Exec
	constructor: (code) ->
		@type = 'Exec'
		if code[0] is "'"
			@code = code.replace(/\'/g, '')
		else if code[0] is '"'
			@code = code.replace(/\"/, '') 

exports.HereDoc = class HereDoc
	constructor: (@doc) ->
		@type = 'HereDoc'

exports.Clone = class Clone
	constructor: (@value) ->
		@type = 'Clone'


# Operations
exports.Assign = class Assign
	constructor: (@operator, @left, @right) ->
		@type = 'Assign'

exports.GetKeyAssign = class GetKeyAssign
	constructor: (@keys, @source) ->
		@type = 'GetKeyAssign'

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

# Simple Statements
exports.Echo = class Echo
	constructor: (@value) ->
		@type = 'Echo'

exports.Delete = class Delete
	constructor: (@value) ->
		@type = 'Delete'

exports.Include = class Include
	constructor: (@path, @once) ->
		@type = 'Include'

exports.Require = class Require
	constructor: (@path, @once) ->
		@type = 'Require'

exports.Break = class Break
	constructor: (@arg = false) ->
		@type = 'Break'

exports.Continue = class Continue
	constructor: (@arg = false) ->
		@type = 'Continue'

exports.Return = class Return
	constructor: (@value) ->
		@type = 'Return'

exports.Declare = class Declare
	constructor: (@expression, @script = false) ->
		@type = 'Declare'

exports.Goto = class Goto
	constructor: (@section) ->
		@type = 'Goto'

# If
exports.If = class If
	constructor: (@condition, @body, @as_expression = false) ->
		@type = 'If'
		if not @as_expression
			@Elses = []
		else
			@Elses = false

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

# Do While
exports.DoWhile = class DoWhile
	constructor: (@test, @body) ->
		@type = 'DoWhile'

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

# For
exports.For = class For
	constructor: ->
		@type = 'For'
		if arguments[0] is 'normal'
			@method = 'normal'
			@expressions = arguments[1]
			@body = arguments[2]
		else if arguments[0] is 'foreach'
			@method = 'foreach'
			@left = arguments[1]
			@right = arguments[2]
			@body = arguments[3]

# Section
exports.Section = class Section
	constructor: (@name) ->
		@type = 'Section'

# Classe
exports.Class = class Class
	constructor: (@name, @body, @extendable = false, @implement = false, @abstract = false) ->
		@type = "Class"

exports.ClassLine = class ClassLine
	constructor: (@visibility, @statically, @element) ->
		@type = 'ClassLine'
		@abstract = false

# Interface
exports.Interface = class Interface
	constructor: (@name, @body, @extendable = false) ->
		@type = "Interface"

# Namespace
exports.Namespace = class Namespace
	constructor: (@name, @body = false) ->
		@type = 'Namespace'

exports.NamespaceRef = class NamespaceRef
	constructor: (@path) ->
		@type = 'NamespaceRef'