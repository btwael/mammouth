nodes = require './nodes'

exports.IdCounter = class IdCounter
	letter: ['i', 'j', 'k', 'c', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', 'a', 'b', 'c', 'd', 'e', 'f', 'j', 'h']
	_level: 1
	letterLevel: 0

	generateAtLevel: ->
		r = ''
		i = 0
		while i < @_level
			r += '_'
			i++
		return r
		
	next: ->
		if (@letterLevel + 1) is @letter.length
			@_level++
			@letterLevel = 0
		else
			@letterLevel++

	get: ->
		r = @generateAtLevel() + @letter[@letterLevel]
		@next()
		return new nodes.Identifier(r)