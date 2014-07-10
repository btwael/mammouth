exports.Context = class Context
	constructor: (@elements = {}) ->

	Add: (element) ->
		switch element.type
			when 'Value'
				if element.properties.length > 0

				else
					return @Add element.value
			when 'Identifier'
				@elements[element.name] = {}
				@elements[element.name].name = element.name
				return @elements[element.name]
	Assign: (right, left) ->
		r = @Add right
		r.type = @Typefy(left)
		return 0
	Typefy: (element) ->
		switch element.type
			when 'Bool'
				return 'Bool'
			when 'Code'
				return 'variable-function'
	Identify: (name) ->
		if @elements[name] == undefined
			return '$' + name
		else
			if @elements[name].type is 'function' or @elements[name].type is 'cte'
				return name
			else
				return '$' + name

PreContext = exports.PreContext = new Context()
PreContext.elements =
	# Function handling Functions
	'call_​user_​func_​array':
		'type': 'function'
	'call_user_func':
		'type': 'function'
	'create_function':
		'type': 'function'
	'forward_static_call_array':
		'type': 'function'
	'forward_static_call':
		'type': 'function'
	'func_get_arg':
		'type': 'function'
	'func_get_args':
		'type': 'function'
	'func_num_args':
		'type': 'function'
	'function_exists':
		'type': 'function'
	'get_defined_functions':
		'type': 'function'
	'register_shutdown_function':
		'type': 'function'
	'register_tick_function':
		'type': 'function'
	'unregister_tick_function':
		'type': 'function'