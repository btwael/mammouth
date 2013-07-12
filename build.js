var fs = require('fs'),
	PEG = require('pegjs');
var rmDir = function(dirPath) {
	try { var files = fs.readdirSync(dirPath); }
	catch(e) { return; }
	if (files.length > 0)
		for (var i = 0; i < files.length; i++) {
			var filePath = dirPath + '/' + files[i];
			if (fs.statSync(filePath).isFile())
				fs.unlinkSync(filePath);
			else
				rmDir(filePath);
		}
	fs.rmdirSync(dirPath);
};
try {
	fs.unlinkSync('src/parser.js');
	fs.unlinkSync('src/LineTerminator.js');
	fs.unlinkSync('extras/mammouth.js');
	fs.unlinkSync('extras/mammouth-nodejs.js');
} catch(e) {

}
try {
	var data = '';
	data += 'var mammouth = {};' + "\n";
	rf = fs.readFileSync('src/parser.pegjs', 'utf8')
	r = PEG.buildParser(rf, {})._source;
	fs.writeFile('src/parser.js', 'mammouth.parser' + " = " + r + ';', function () {
	});
	data += 'mammouth.parser' + " = " + r + ';';
	rf = fs.readFileSync('src/LineTerminator.pegjs', 'utf8')
	r = PEG.buildParser(rf, {})._source;
	fs.writeFile('src/LineTerminator.js', 'mammouth.LineTerminatorParser' + " = " + r + ';', function () {
	});
	data += 'mammouth.LineTerminatorParser' + " = " + r + ';';
	data += fs.readFileSync('src/tokens.js').toString() + '\n';
	data += fs.readFileSync('src/compiler.js').toString() + '\n';
	fs.appendFileSync("extras/mammouth.js", data + "\n");
} catch(err) {
	console.log(err);
}
try {
	var data = '';
	data += fs.readFileSync('extras/mammouth.js').toString() + '\n';
	data += 'module.exports = mammouth;' + "\n"; 
	fs.appendFileSync("extras/mammouth-nodejs.js", data);
} catch(err) {
	console.log(err);
}