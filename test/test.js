var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
{{
func mammouth() ->
    arguments = func_get_args()
    switch arguments[0]
        when '+'
            if (is_string(arguments[1]) and is_numeric(arguments[2])) or (is_string(arguments[1]) and is_numeric(arguments[1]))
                arguments[1] ~~ arguments[2]
            else
                'strict mode'
                arguments[1] + arguments[2]
        when 'length'
            if is_array(arguments[1])
                count(arguments[1])
            else if is_string(arguments[1])
                strlen(arguments[1])
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
}}
*/
})


//console.log(mammouth.parse(code).sections)

console.log(mammouth.compile(code))

var lexer = require('../lib/lexer');
lexer.setInput(code);

//console.log(lexer.tokenize())