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
		for scope in @scopes
			if scope[name] isnt undefined
				if scope[name].type in ['function', 'cte', 'class', 'interface']
					return name
				else
					return '$' + name
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


	# Arrays
	# Array Constants
	'CASE_LOWER':
		'type': 'cte'
	'CASE_UPPER':
		'type': 'cte'
	'SORT_ASC':
		'type': 'cte'
	'SORT_DESC':
		'type': 'cte'
	'SORT_REGULAR':
		'type': 'cte'
	'SORT_NUMERIC':
		'type': 'cte'
	'SORT_STRING':
		'type': 'cte'
	'SORT_LOCALE_STRING':
		'type': 'cte'
	'SORT_NATURAL':
		'type': 'cte'
	'SORT_FLAG_CASE':
		'type': 'cte'
	'COUNT_NORMAL':
		'type': 'cte'
	'COUNT_RECURSIVE':
		'type': 'cte'
	'EXTR_OVERWRITE':
		'type': 'cte'
	'EXTR_SKIP':
		'type': 'cte'
	'EXTR_PREFIX_SAME':
		'type': 'cte'
	'EXTR_PREFIX_ALL':
		'type': 'cte'
	'EXTR_PREFIX_INVALID':
		'type': 'cte'
	'EXTR_PREFIX_IF_EXISTS':
		'type': 'cte'
	'EXTR_IF_EXISTS':
		'type': 'cte'
	'EXTR_REFS':
		'type': 'cte'

	# Array functions
	'array_change_key_case':
		'type': 'function'
	'array_chunk':
		'type': 'function'
	'array_column':
		'type': 'function'
	'array_combine':
		'type': 'function'
	'array_count_values':
		'type': 'function'
	'array_diff_assoc':
		'type': 'function'
	'array_diff_key':
		'type': 'function'
	'array_diff_uassoc':
		'type': 'function'
	'array_diff_ukey':
		'type': 'function'
	'array_diff':
		'type': 'function'
	'array_fill_keys':
		'type': 'function'
	'array_fill':
		'type': 'function'
	'array_filter':
		'type': 'function'
	'array_flip':
		'type': 'function'
	'array_intersect_assoc':
		'type': 'function'
	'array_intersect_key':
		'type': 'function'
	'array_intersect_uassoc':
		'type': 'function'
	'array_intersect_ukey':
		'type': 'function'
	'array_intersect':
		'type': 'function'
	'array_key_exists':
		'type': 'function'
	'array_keys':
		'type': 'function'
	'array_map':
		'type': 'function'
	'array_merge_recursive':
		'type': 'function'
	'array_merge':
		'type': 'function'
	'array_multisort':
		'type': 'function'
	'array_pad':
		'type': 'function'
	'array_pop':
		'type': 'function'
	'array_product':
		'type': 'function'
	'array_push':
		'type': 'function'
	'array_rand':
		'type': 'function'
	'array_reduce':
		'type': 'function'
	'array_replace_recursive':
		'type': 'function'
	'array_replace':
		'type': 'function'
	'array_reverse':
		'type': 'function'
	'array_search':
		'type': 'function'
	'array_shift':
		'type': 'function'
	'array_slice':
		'type': 'function'
	'array_splice':
		'type': 'function'
	'array_sum':
		'type': 'function'
	'array_udiff_assoc':
		'type': 'function'
	'array_udiff_uassoc':
		'type': 'function'
	'array_udiff':
		'type': 'function'
	'array_uintersect_assoc':
		'type': 'function'
	'array_uintersect_uassoc':
		'type': 'function'
	'array_uintersect':
		'type': 'function'
	'array_unique':
		'type': 'function'
	'array_unshift':
		'type': 'function'
	'array_values':
		'type': 'function'
	'array_walk_recursive':
		'type': 'function'
	'array_walk':
		'type': 'function'
	'array':
		'type': 'function'
	'arsort':
		'type': 'function'
	'asort':
		'type': 'function'
	'compact':
		'type': 'function'
	'count':
		'type': 'function'
	'current':
		'type': 'function'
	'each':
		'type': 'function'
	'end':
		'type': 'function'
	'extract':
		'type': 'function'
	'in_array':
		'type': 'function'
	'key_exists':
		'type': 'function'
	'key':
		'type': 'function'
	'krsort':
		'type': 'function'
	'ksort':
		'type': 'function'
	'list':
		'type': 'function'
	'natcasesort':
		'type': 'function'
	'natsort':
		'type': 'function'
	'next':
		'type': 'function'
	'pos':
		'type': 'function'
	'prev':
		'type': 'function'
	'range':
		'type': 'function'
	'reset':
		'type': 'function'
	'rsort':
		'type': 'function'
	'shuffle':
		'type': 'function'
	'sizeof':
		'type': 'function'
	'sort':
		'type': 'function'
	'uasort':
		'type': 'function'
	'uksort':
		'type': 'function'
	'usort':
		'type': 'function'


	# Objects/classes
	# Objects function
	'__autoload':
		'type': 'function'
	'call_user_method_array':
		'type': 'function'
	'call_user_method':
		'type': 'function'
	'class_alias':
		'type': 'function'
	'class_exists':
		'type': 'function'
	'get_called_class':
		'type': 'function'
	'get_class_methods':
		'type': 'function'
	'get_class_vars':
		'type': 'function'
	'get_class':
		'type': 'function'
	'get_declared_classes':
		'type': 'function'
	'get_declared_interfaces':
		'type': 'function'
	'get_declared_traits':
		'type': 'function'
	'get_object_vars':
		'type': 'function'
	'get_parent_class':
		'type': 'function'
	'interface_exists':
		'type': 'function'
	'is_a':
		'type': 'function'
	'is_subclass_of':
		'type': 'function'
	'method_exists':
		'type': 'function'
	'property_exists':
		'type': 'function'
	'trait_exists':
		'type': 'function'


	# Classkit
	# Classkit Constants
	'CLASSKIT_ACC_PRIVATE':
		'type': 'cte'
	'CLASSKIT_ACC_PROTECTED':
		'type': 'cte'
	'CLASSKIT_ACC_PUBLIC':
		'type': 'cte'
	# Classkit Functions
	'classkit_import':
		'type': 'function'
	'classkit_method_add':
		'type': 'function'
	'classkit_method_copy':
		'type': 'function'
	'classkit_method_redefine':
		'type': 'function'
	'classkit_method_remove':
		'type': 'function'
	'classkit_method_rename':
		'type': 'function'
})