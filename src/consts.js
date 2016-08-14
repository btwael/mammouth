var RegularExpressions = {
    'IDENTIFIER': /((^[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*)( [^\n\S]* : (?!:) )?)/,
    'HEREDOC': /^`(((?!(\`|{{|}}))([\n\r\u2028\u2029]|.))*)`/,
    'NUMBER': /^(0b[01]+|0o[0-7]+|0(x|X)[\da-fA-F]+|\d*\.?\d+(?:(e|E)[+-]?\d+)?)/,
    'STRING': /^('[^\\']*(?:\\[\s\S][^\\']*)*'|\u0022[^\\\u0022]*(?:\\[\s\S][^\\\u0022]*)*\u0022)/,
    'QUALIFIEDSTRING': /^q('[^\\']*(?:\\[\s\S][^\\']*)*'|\u0022[^\\\u0022]*(?:\\[\s\S][^\\\u0022]*)*\u0022)/,

    'INDENTATION': /(^[ \t]*)/,

    'START_TAG': /^{{/,
    'END_TAG': /^}}/,
    'INTERPOLATION_START_TAG': /^{{>/
};

var Precedence = {
    expression: 0,
    logicalOR: 2,
    logicalAND: 3,
    bitwiseOR: 4,
    bitwiseXOR: 5,
    bitwiseAND: 6,
    equality: 7,
    relationel: 8,
    shift: 9,
    additive: 10,
    multiplicative: 11,
};

var Keywords = {
    bool: ['true', 'false'],
    compare: ['is', 'isnt'],
    logic: ['and', 'or', 'xor'],
    castType: ['array', 'binary', 'bool', 'boolean', 'double', 'int', 'integer', 'float', 'object', 'real', 'string', 'unset'],
    reserved: [
        'abstract', 'as',
        'break', 'by',
        'case', 'catch', 'class', 'clone', 'const', 'continue',
        'delete',
        'echo', 'else', 'extends',
        'final', 'finally', 'for', 'func',
        'global', 'goto',
        'if', 'implements', 'in', 'include', 'instanceof', 'interface',
        'loop',
        'namespace', 'new', 'null',
        'of', 'once',
        'private', 'protected', 'public',
        'require', 'return',
        'static', 'switch',
        'throw', 'try',
        'until', 'use',
        'while', 'when'
    ]
};

// TODO: fill indexable and callable
var CALLABLE = ['CALL_END', 'IDENTIFIER', 'INDEX_END', 'QUALIFIEDSTRING', ')', ']', '?'];

var INDEXABLE = ['SLICE_END', 'RANGE_END'].concat(CALLABLE);

var tokenInterpretation = {
    callable: CALLABLE,
    indexable: INDEXABLE,
    notExpression: ['INDENT', 'MINDENT', 'OUTDENT'].concat(Keywords.compare).concat(Keywords.logic).concat(Keywords.reserved),
    prefixOperator: ['CLONE', 'NEW', 'UNARY', 'UPDATE', '+', '-']
}

// exports
exports.RegularExpressions = RegularExpressions;
exports.Precedence = Precedence;
exports.Keywords = Keywords;
exports.tokenInterpretation = tokenInterpretation;