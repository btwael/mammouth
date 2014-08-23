exports.Context = class Context
	constructor: (element) ->
		@scopes = []
		@scopes.unshift(element)

	push: (iden) ->
		@scopes[0][iden.name] = {}
		@scopes[0][iden.name].name = iden.name
		@scopes[0][iden.name].type = iden.type

	scopein: () ->
		@scopes.unshift({});

	scopeout: () ->
		@scopes.shift()

	Identify: (name) ->
		if @scopes[0][name] == undefined
			return '$' + name
		else
			if @scopes[0][name].type in ['function', 'cte', 'class', 'interface']
				return name
			else
				return '$' + name

PreContext = exports.PreContext = new Context({
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
})