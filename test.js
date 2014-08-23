v = "sdf{{\ndelete variable}}sdf{{\ndelete variable}}"
mammouth = require('./lib/mammouth')
mammouth.parse(v)
/*lexer = require('./lib/lexer.js'),
lexer.setInput(v)
m= 0
while(m!=undefined) {
	m=lexer.lex()
	console.log(m)
}*/