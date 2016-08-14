var fs = require('fs');
var files = {
        'position': 'module.exports',
        'location': 'module.exports',
        'token': 'module.exports',
        'utils': 'exports',
        'error': 'module.exports',
        'consts': 'exports',
        'rewriter': 'module.exports',
        'lexer': 'module.exports',
        'nodes': 'exports',
        'parser': 'module.exports',
        'mammouth' : 'module.exports'
    },
    TAB = '  ';

function addTab(source, number) {
    var res = '';
    var splited = source.split('\n');
    for(var i = 0; i < splited.length; i++) {
        for(var j = 0; j < number; j++) {
            res += TAB;
        }
        res += splited[i];
        res += '\n';
    }
    return res;
}

function main() {
    var code = 'var require = function(path) {return require[path]};\n';
    for(file in files) {
        code +='require["./' + file + '"] = (function() {\n'
        code += addTab('var exports = {}, module = {exports: exports};\n', 1);
        code += addTab(fs.readFileSync('./src/' + file + '.js', 'utf8') + '\n', 1)
        code += addTab('return ' + files[file] + ';\n', 1);
        code += '})();\n\n'
    }
    code = 'var mammouth = (function(root) {\n' + addTab(code, 1) + addTab('return require("./mammouth");', 1) + '})(this);'
    fs.writeFileSync('./lib/mammouth.js', code);
}

main();