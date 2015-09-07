var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
fsdfsdfsdf{{
func mammouth() ->
    arguments = func_get_args()
    switch arguments[0]
        when 'length'
            if is_array(arguments[1])
                count(arguments[1])
            else if is_string(arguments[1])
                strlen(strlen)
            else if is_numeric(arguments[1])
                strlen(arguments[1] => string)
        when 'slice'
            if is_array(arguments[1])
                if count(arguments) is 3
                    array_slice(arguments[1], arguments[2])
                else
                    array_slice(arguments[1], arguments[2], arguments[3] - arguments[2])
            else if is_string(arguments[1])
                if count(arguments) is 3
                    substr(arguments[1], arguments[2])
                else
                    substr(arguments[1], arguments[2], arguments[3] - arguments[2])
            else if is_numeric(arguments[1])
                if count(arguments) is 3
                    mammouth('slice', arguments[1] => string, arguments[2])
                else
                     mammouth('slice', arguments[1] => string, arguments[2], arguments[3] - arguments[2])
numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9]

start   = numbers[0...2]

middle  = numbers[3....-2]

end     = numbers[-2...]

copy    = numbers[...]
}}
*/
})

//console.log(mammouth.parse(code).sections[1].body.body[0].whens)

console.log(mammouth.compile(code))

var lexer = require('../lib/lexer');
lexer.setInput(code);

//console.log(lexer.tokenize())