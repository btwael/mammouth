function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
v = heredoc(function() {
/*
{{
namespace my\name

class MyClass
 cte w = "wael"
func myfunction ->
  somevar
cte MYCONST = 1
MYCONST
a = new MyClass
c = new \my\name\MyClass
$d = __NAMESPACE__ <-> '\MYCONST'
}}
*/
})
mammouth = require('./lib/mammouth')
console.log(mammouth.compile(v))
lexer = require('./lib/lexer.js'),
lexer.setInput(v)
m= 0
while(m!=undefined) {
	m=lexer.lex()
	console.log(m)
}