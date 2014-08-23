v = "sdf{{\ninterface iTemplate extends wael, moha\n public func setVariable(name, var)\n cte wael = 12}}"
mammouth = require('./lib/mammouth')
console.log(mammouth.compile(v))
/*lexer = require('./lib/lexer.js'),
lexer.setInput(v)
m= 0
while(m!=undefined) {
	m=lexer.lex()
	console.log(m)
}*/