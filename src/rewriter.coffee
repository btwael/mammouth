nodes = require './nodes'
{IdCounter} = require './helpers'

exports.rewrite = (tree, context) ->
	IdCounter = new IdCounter
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
					r = '$' + element.name
				else
					r = context.Identify(element.name)
				if element.passing
					r = '&' + r
				return r
			when 'Literal'
				if typeof element.value is 'number'
					return element.value
				else
					return element.value
			when 'Bool'
				if element.value
					return 'TRUE'
				else
					return 'FALSE'
			when 'Null'
				return 'NULL'
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
			when 'NewCall'
				r = 'new ' + compile(element.variable)
				if element.arguments isnt false
					r += '('
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
				r += ')'
				if element.body isnt false
					r += ' {'
					r += compile element.body
					r += '}'
				else
					r += ';'
				return r;
			when 'Casting'
				 return '(' + element.typec + ') ' + compile(element.variable)
			when 'Exec'
				return '`' + element.code + '`'
			when 'HereDoc'
				return '<<<EOT\n' + element.doc + '\nEOT'
			when 'Clone'
				return 'clone ' + compile(element.value)

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
				else
					r = compile(element.left) + ' ' + element.operator + ' ' + compile(element.right)
				return r
			when 'Assign'
				if element.operator is '='
					context.Assign(element.left, element.right)
				r = compile(element.left) + ' ' + element.operator + ' ' + compile(element.right)
				return r
			when 'GetKeyAssign'
				r = ''
				for key, i in element.keys
					value = new nodes.Value(element.source.value)
					value.add(new nodes.Access(new nodes.Literal('"' + key.name + '"'), '[]'))
					if i isnt (element.keys.length - 1)
						r += compile(new nodes.Expression(new nodes.Assign("=", key, value))) 
						r += '\n'
					else
						r += compile(new nodes.Assign("=", key, value))
				return r
			when 'Constant'
				cte = context.Add(element.left)
				cte.type = 'cte'
				return 'const ' + compile(element.left) + ' = ' + compile(element.right)
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
			when 'In'
				r = '$Mammouth("in_array", ' + compile(element.left) + ', ' + compile(element.right) + ')'
				return r

			# Simple Statements
			when 'Echo'
				return 'echo ' + compile(element.value)
			when 'Delete'
				return 'unset(' + compile(element.value) + ')'
			when 'Include'
				if element.once
					r = 'include_once '
				else
					r = 'include '
				r += compile(element.path)
				return r
			when 'Require'
				if element.once
					r = 'require_once '
				else
					r = 'require '
				r += compile(element.path)
				return r
			when 'Break'
				r = 'break'
				if element.arg isnt false
					r += ' ' + compile(element.arg)
				return r
			when 'Continue'
				r = 'continue'
				if element.arg isnt false
					r += ' ' + compile(element.arg)
				return r
			when 'Return'
				return 'return ' + compile(element.value)
			when 'Declare'
				r = 'declare(' + compile(element.expression) + ')'
				if element.script isnt false
					r += ' {'
					r += compile(element.script)
					r += '}'
				return r
			when 'Goto'
				return 'goto ' + element.section

			# If
			when 'If'
				if element.as_expression
					r = compile(element.condition) + ' ? ' + compile(element.body)
					if element.Elses is false
						r += ' : NULL'
					else
						r += ' : ' + compile(element.Elses)
					return r
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
				r = 'while(' + compile(element.test) + ') {'
				r += compile(element.body)
				r += '}'
				return r

			# Do While
			when 'DoWhile'
				r = 'do {'
				r += compile(element.body)
				r += '} while (' + compile(element.test) + ');'
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

			# Switch
			when 'Switch'
				r = 'switch (' + compile(element.variable) + ') {\n'
				for Scase in element.cases
					if Scase.type is 'When'
						r += 'case ' + compile(Scase.condition) + ': {'
						r += compile(Scase.body)
						r += '}'
					else if Scase.type is 'SwitchElse'
						r += 'default: {'
						r += compile(Scase.body)
						r += '}'
					r += '\n'
				r += '}'
				return r

			# For
			when 'For'
				if element.method is 'normal' and element.expressions.length > 1
					r = 'for('
					for expression, i in element.expressions
						if expression.type is 'In'
							expression.each = true
						r += compile(expression)
						if i isnt element.expressions.length
							r += '; '
					r += ') {'
					r += compile(element.body)
					r += '}'
				else if element.method is 'normal' and element.expressions.length is 1 and element.expressions[0].type is 'In'
					InElement = element.expressions[0]
					r = 'for('
					ID = IdCounter.get()
					r += compile(ID) + ' = 0; '
					r += compile(ID) + ' < count(' + compile(InElement.right) + '); '
					r += compile(ID) + '++'
					r += ') {'
					element.body.nodes.unshift(new nodes.Expression(new nodes.Assign('=', InElement.left, new nodes.Value(InElement.right, [new nodes.Access(ID, '[]')]))))
					r += compile(element.body)
					r += '}'
				else if element.method is 'foreach'
					r = 'foreach('
					r += compile(element.left)
					r += ' as '
					r += compile(element.right)
					r += ') {'
					r +=  compile(element.body)
					r += '}'
				return r

			# Section
			when 'Section'
				return element.name + ':'

			# Classe
			when 'Class'
				r = 'class ' + element.name
				context.elements[element.name] = {
					'type': 'class'
				}
				if element.abstract is true
					r = 'abstract ' + r
				if element.extendable isnt false
					r += ' extends ' + element.extendable
				if element.implement isnt false
					r += ' implements ' + element.implement
				r += ' {\n'
				for line, i in element.body
					lr = ''
					if line.visibility isnt false
						lr += line.visibility + ' '
					if line.statically isnt false
						lr += line.statically + ' '
					lr += compile(line.element)
					if line.finaly is true
						lr = 'final ' + lr
					if line.abstract is true
						lr = 'abstract ' + lr
					r += lr
					if i isnt (element.body.length - 1)
						r += '\n'
				r += '\n}'
				return r

			# Interface
			when 'Interface'
				r = 'interface ' + element.name
				context.elements[element.name] = {
					'type': 'interface'
				}
				if element.extendable isnt false
					r += ' extends '
					for ext, i in element.extendable
						r += ext
						if i isnt (element.extendable.length - 1)
							r += ', '
				r += ' {\n'
				for line, i in element.body
					lr = ''
					if line.type is 'Code'
						lr += 'public ' + compile(line)
					else 
						lr += compile(line)
					r += lr
					if i isnt (element.body.length - 1)
						r += '\n'
				r += '\n}'

			# Namespace
			when 'Namespace'
				r = 'namespace ' + element.name
				if element.body isnt false
					r += ' {'
					r += compile(element.body)
					r += '}'
				return r
			when 'NamespaceRef'
				return element.path

	for doc in tree
		switch doc.type
			when 'PlainBlock' then ADD doc.toPHP()
			when 'MammouthBlock' then ADD '<?php' + compile(doc.body) + '?>'
	return php