function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
v = heredoc(function() {
/*
{{
number   = 42
opposite = true

square = func (x) ->
 return x * x

square()

list = [1, 2, 3, 4, 5]

if elvis
 alert("I knew it!") 

func Hello() ->
 echo('Hello Mammouth')

Hello()
class wael
  cte love = "thouraya baarabcxvxc"
  public func kiss ->
    return true
  protected func fuck ->
    return 'yes'
}}
*/
})
mammouth = require('./lib/mammouth')
console.log(mammouth.compile(v))
console.log(mammouth.compile(v))
/*lexer = require('./lib/lexer.js'),
lexer.setInput(v)
m= 0
while(m!=undefined) {
	m=lexer.lex()
	console.log(m)
}*/