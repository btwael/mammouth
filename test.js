function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
v = heredoc(function() {
/*
{{
'123'+123
}}
*/
})
mammouth = require('./lib/mammouth')
console.log(mammouth.compile(v))
/*lexer = require('./lib/lexer.js'),
lexer.setInput(v)
m= 0
while(m!=undefined) {
	m=lexer.lex()
	console.log(m)
}*/