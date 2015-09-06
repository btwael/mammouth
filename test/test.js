var mammouth = require('../lib/mammouth.js');

function heredoc (f) {
    return f.toString().match(/\/\*\s*([\s\S]*?)\s*\*\//m)[1];
};
code = heredoc(function() {
/*
fsdfsdfsdf{{
eat(food) for food in ['toast', 'cheese', 'wine']

courses = ['greens', 'caviar', 'truffles', 'roast', 'cake']
menu(i + 1, dish) for dish, i in courses

foods = ['broccoli', 'spinach', 'chocolate']
eat(food) for food in foods when food isnt 'chocolate'
}}
*/
})

//console.log(mammouth.parse(code).sections[1].body.body[1])

console.log(mammouth.compile(code))

var lexer = require('../lib/lexer');
lexer.setInput(code);

//console.log(lexer.tokenize())