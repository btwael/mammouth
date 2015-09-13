exec = require('child_process').exec
fs = require 'fs'

desc 'Compile all CoffeeScript files in /src to /lib.'
task 'compile', {async: on}, ->
    exec 'coffee --compile --output lib/ src/', (error) ->
        if error
            console.log 'Compiling: Error while compiling files :('
        else
            console.log 'Compiling: Files has successfully been compiled :)'
        complete()

desc('Generate mammouth parser');
task 'generateParser', () ->
	parser = require './lib/grammar'
	fs.writeFile './lib/parser.js', parser.generate()
	fs.unlinkSync './lib/grammar.js'
	console.log 'Generating: mammouth Pparser has successfully been generated :)'

desc('Generate mammouth for browser');
task 'generateBrowser', () ->
    code = ''
    # add parser.js
    code += 'require["./parser"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync('./lib/parser.js', 'utf8')
    code += 'return exports;'
    code += '})();\n'
    # add utils.js
    code += 'require["./utils"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync('./lib/utils.js', 'utf8')
    code += 'return exports;'
    code += '})();\n'
    # add lexer.js
    code += 'require["./lexer"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync('./lib/lexer.js', 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    # add context.js
    code += 'require["./context"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync('./lib/context.js', 'utf8')
    code += 'return exports;'
    code += '})();\n'
    # add predefined.js
    code += 'require["./predefined"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync('./lib/predefined.js', 'utf8')
    code += 'return exports;'
    code += '})();\n'
    # add nodes.js
    code += 'require["./nodes"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync('./lib/nodes.js', 'utf8')
    code += 'return exports;'
    code += '})();\n'
    # add phplexer.js
    code += 'require["./phplexer"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync('./lib/phplexer.js', 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    # add php.js
    code += 'require["./php"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync('./lib/php.js', 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    # add mammouth.js
    code += 'require["./mammouth"] = (function() {'
    code += 'var exports = {}, module = {exports: exports};'
    code += fs.readFileSync('./lib/mammouth.js', 'utf8')
    code += 'return module.exports;'
    code += '})();\n'
    code = '(function(root) {\n' + 'function require(path){ return require[path]; }\n' + code + '\nmammouth = require["./mammouth"];\nreturn require["./mammouth"]' + ';\n' + '}(this));'

    fs.writeFileSync('./extras/mammouth.js', code, 'utf8')

desc 'Build the project.'
task 'build', ['compile', 'generateParser', 'generateBrowser'], -> # Do nothing