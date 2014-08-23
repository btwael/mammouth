function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
v = heredoc(function() {
/*
{{
class A
    func foo() ->
        if this?
            echo '$this is defined ('
            echo get_class(this)
            echo ")\n"
        else
            echo "\$this is not defined.\n"

class B
    func bar() ->
    	#sdfsd
        A.foo()
a = new A()
a.foo()

# Note: the next line will issue a warning if E_STRICT is enabled.
A.foo()
b = new B()
b.bar()

# Note: the next line will issue a warning if E_STRICT is enabled.
B.bar()
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