exports.rewrite = (tree, context) ->
	UseSuperMammouth = false
	php = ''
	ADD = (string) ->
		php += string

	compile = (element)->
		switch element.type
			when 'Block'
				if element.nodes[element.nodes.length - 1].type is 'BlankLine'
					element.nodes.pop()
				if element.nodes.length == 1 and element.nodes[0].type is 'Expression'
					r = ' ' + compile(element.nodes[0]) + ' '
					return r
				else
					r = ''
					for node, i in element.nodes
						r += compile(node)
						if i != element.nodes.length - 1
							r += '\n'
					return '\n' + r + '\n'
			when 'Expression' then return compile(element.expression) + ';'
			when 'BlankLine' then return ''

			# Values
			when 'Value'
				if element.properties.length > 0
					r = compile element.value
					for propertie in element.properties
						switch propertie.method
							when '->', '.'
								r += "->" + propertie.value.name
							when '::', '..'
								r += '::' + propertie.value.name
							when '[]'
								r += '[' + compile(propertie.value) + ']'
					return r
				else 
					return compile element.value
			when 'Parens' then return '(' + compile(element.expression) + ')'
			when 'Identifier'
				if element.as_arguments
					return '$' + element.name
				else
					return context.Identify(element.name)
			when 'PassingIdentifier'
				return '&' + context.Identify(element.name)
			when 'Literal'
				if typeof element.value is 'number'
					return element.value
				else
					return '"' + element.value + '"'
			when 'Bool'
				if element.value
					return 'true'
				else
					return 'false'
			when 'Array'
				r = 'array('
				for elem, i in element.elements
					if elem.type is 'ArrayKey'
						r += compile(elem.key) + ' => ' + compile(elem.value)
					else
						r += compile elem
					if i != element.elements.length - 1
						r += ', '
				r += ')'
				return r;
			when 'Call'
				r = compile(element.variable) + '('
				for arg, i in element.arguments
					r += compile arg
					if i != element.arguments.length - 1
						r += ', '
				r += ')'
				return r;
			when 'Code'
				if element.normal
					r = 'function ' + element.name + '('
					context.elements[element.name] = {
						'type': 'function'
					}
				else
					r = 'function('
				for parameter, i in element.parameters
					if parameter.and is true
						r += '&' + compile parameter
					else
						r += compile parameter
					if i != element.parameters.length - 1
						r += ', '
				r += ') {'
				r += compile element.body
				r += '}'
				return r;

			# Operations
			when 'Operation'
				if element.operator is '**'
					r = 'pow(' + compile(element.left) + ', ' + compile(element.right) + ')'
				else if element.operator is 'and'
					r = compile(element.left) + ' & ' + compile(element.right)
				else if element.operator is 'or'
					r = compile(element.left) + ' or ' + compile(element.right)
				else if element.operator is '<->'
					r = compile(element.left) + '.' + compile(element.right)
				else if element.operator is '+'
					UseSuperMammouth = true
					r = '$Mammouth("+", ' + compile(element.left) + ', ' + compile(element.right) + ')'
				else if element.operator is 'IN'
					r = '$Mammouth("in_array",' + compile(element.left) + ', ' + compile(element.right) + ')'
				else
					r = compile(element.left) + ' ' + element.operator + ' ' + compile(element.right)
				return r
			when 'Assign'
				if element.operator is '='
					context.Assign(element.left, element.right)
				r = compile(element.left) + ' ' + element.operator + ' ' + compile(element.right)
				return r
			when 'Constant'
				cte = context.Add(element.left)
				cte.type = 'cte'
				return 'define("' + compile(element.left) + '", ' + compile(element.right) + ')'
			when 'Unary'
				r = element.operator
				r += compile element.expression
				return r
			when 'Update'
				r = compile element.expression
				r = if not element.prefix then r + element.operator else element.operator + r
				return r
			when 'Existence'
				r = 'isset(' + compile(element.expression) + ')'
				return r

			# Statements
			when 'EchoStatement'
				return 'echo ' + compile(element.expression) + ';'
			when 'ReturnStatement'
				if element.expression is null
					return 'return;'
				else
					return 'return ' + compile(element.expression) + ';'
			when 'BreakStatement'
				if element.expression is null
					return 'break;'
				else
					return 'break ' + compile(element.expression) + ';'
			when 'ContinueStatement'
				if element.expression is null
					return 'continue;'
				else
					return 'continue ' + compile(element.expression) + ';'
			when 'IncludeStatement'
				r = 'include'
				r += '_once' if element.once
				r += ' ' + compile(element.expression) + ';'
				return r
			when 'RequireStatement'
				r = 'require'
				r += '_once' if element.once
				r += ' ' + compile(element.expression) + ';'
				return r
			# IF
			when 'If'
				if element.expression
					r = compile(element.condition) + ' ? ' + compile(element.body) + ' : ' 
					r += compile(element.Elses)
				else
					r = 'if(' + compile(element.condition) + ') {'
					r += compile(element.body)
					r += '}'
					for elsei in element.Elses
						if elsei.type is 'Else'
							r += ' else {'
							r += compile(elsei.body)
							r += '}'
						else if elsei.type is 'ElseIf'
							r += ' elseif(' + compile(elsei.condition) + ') {'
							r += compile(elsei.body)
							r += '}'
				return r
			# While
			when 'While'
				r = 'while(' + compile(element.condition) + ') {'
				r += compile(element.body)
				r += '}'
				return r
			# Try
			when 'Try'
				r = 'try {'
				r += compile(element.TryBody)
				r += '}'
				r += ' catch(Exception ' + compile(element.CatchIdentifier) + ') {'
				r += compile(element.CatchBody)
				r += '}'
				if element.Finally
					r += ' finally {'
					r += compile(element.FinallyBody)
					r += '}'
				return r

	for doc in tree
		switch doc.type
			when 'PlainBlock' then ADD doc.toPHP()
			when 'MammouthBlock' then ADD '<?php' + compile(doc.body) + '?>'
	return php