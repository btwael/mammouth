fs = require('fs');
yy = require('./lib/nodes');
parser = require('./lib/grammar');
parser.lexer = require('./lib/lexer');
parser.yy = yy;
// Generate for the browser
function generateBrowser() {
    code = ''
    // add lex
    code += 'require["lex"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync("./node_modules/lex/lexer.js", 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    // add parser.js
    code += 'require["./parser"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync("./lib/parser.js", 'utf8')
    code += 'return exports;'
    code += '})();\n'
    // add context.js
    code += 'require["./context"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync("./lib/context.js", 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    // add lexer.js
    code += 'require["./lexer"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync("./lib/lexer.js", 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    // add nodes.js
    code += 'require["./nodes"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync("./lib/nodes.js", 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    // add helpers.js
    code += 'require["./helpers"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync("./lib/helpers.js", 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    // add rewriter.js
    code += 'require["./rewriter"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync("./lib/rewriter.js", 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    // add mammouth.js
    code += 'require["./mammouth"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync("./lib/mammouth.js", 'utf8')
    code += 'return module.exports;'
    code += '})();'
    code = '(function(root) {\n' + 'function require(path){ return require[path]; }\n' + code + '\nmammouth = require["./mammouth"];\nreturn require["./mammouth"]' + ';\n' + '}(this));'
    fs.writeFile('./extras/mammouth.js', code, function(err) {
        if(err) {
            console.log(err);
        } else {
            console.log("The browser file was saved!");
            var compressor = require('node-minify');
            // Using Google Closure
            new compressor.minify({
                type: 'uglifyjs',
                fileIn: './extras/mammouth.js',
                fileOut: './extras/mammouth.min.js',
                callback: function(err, min){
                    if(err) {
                        console.log(err);
                    } else {
                        console.log("The minified browser file was saved!");
                        addHeader();
                    }
                }
            });
        }
    });
}
header = "/**\n * Mammouth Compiler v" + require('./lib/mammouth').VERSION +"\n * http://mammouth.wamalaka.com\n *\n * Copyright 2014, Wael Amine Boutglay\n * Released under the MIT License\n */\n"
function addHeader() {
    fs.writeFile('./extras/mammouth.js', header + fs.readFileSync('./extras/mammouth.js'), function(err) {
        if(err) {
            console.log(err);
        }
    });
    fs.writeFile('./extras/mammouth.min.js', header + fs.readFileSync('./extras/mammouth.min.js'), function(err) {
        if(err) {
            console.log(err);
        }
    });
}
// Generate the stand-alone parser
fs.writeFile('./lib/parser.js', parser.generate(), function(err) {
    if(err) {
        console.log(err);
    } else {
        console.log("The parser was saved!");
        generateBrowser()
    }
});