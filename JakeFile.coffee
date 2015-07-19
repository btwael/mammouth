exec = require('child_process').exec
fs = require 'fs'

desc 'Compile all CoffeeScript files in /src to /lib.'
task 'compile', {async: on}, ->
    exec 'coffee --compile --output lib/ src/', (error) ->
        if error
            console.log 'Compiling: Error while compiling files :('
        else
            console.log 'Compiling: Files has succrssfully been compiled :)'
        complete()

desc('Generate parser');
task 'parsify', () ->
	parser = require './lib/grammar'
	fs.writeFile './lib/parser.js', parser.generate()
	fs.unlinkSync './lib/grammar.js'
	console.log 'Generating: Parser has succrssfully been generated :)'

desc 'Build the project.'
task 'build', ['compile', 'parsify'], -> # Do nothing