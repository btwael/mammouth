v = 'sdf{{\ndef call(id)->\n dsfds\nsd=12\nvall()}}'
mammouth = require('./lib/mammouth')
//console.log(mammouth.parse(v)[1])
console.log(mammouth.compile(v))
/*lexer = require('./lib/lexer.js'),
lexer.setInput(v)
m= 0
while(m!=undefined) {
	m=lexer.lex()
	console.log(m)
}*/