var sys = require('sys'),
    exec = require('child_process').exec,
    fs = require('fs'),
    child,
    color = {
      default: '\033[0m',
      red: '\033[0;31m',
      green: '\033[0;32m',
      brown: '\033[0;33m',
      blue: '\033[0;34m',
      magenta: '\033[0;35m',
      cyan: '\033[0;36m',
      lightgray: '\033[0;37m'
    };

function removePhpFiles(callback) {
  exec("rm ./tests/*.php", function(error) {
    callback && callback();
  });
}

function compileMammouth(callback) {
  sys.print(color.cyan + '\n===COMPILATION START===\n' + color.default);
  child = exec("node ./bin/mammouth --compile --output ./tests ./tests", function(error, stdout, stderr) {
    if(stdout) {
      sys.print('stdout: ' + stdout);
    }
    if(stderr) {
      sys.print('stderr: ' + stderr);
    }
    if (error === null) {
      sys.print(color.cyan + '===COMPILATION END===\n' + color.default);
      callback && callback();
    } else {
      sys.print('compileMammouth error: ' + error + '\n');
    }
  });
}

function doTheTests(callback) {
  var phpFileName,
      fileLoop,
      path = './tests/',
      ctn = fs.readdirSync(path);
  console.log('Files in ./test/ directory after compilation: \n', ctn);
  sys.print(color.cyan + '\n===TEST BEGIN===\n' + color.default);

  (fileLoop = function(i) {
    if(ctn.length === i) {
      return callback && callback();
    }
    if(ctn[i].substr(-9).toLowerCase() !== '.mammouth') {
      // ommit php files from list
      return fileLoop(++i);
    }
    phpFileName = ctn[i].replace(/.mammouth$/, '') + '.php';
    if(ctn.indexOf(phpFileName) === -1) {
      sys.print(color.red + 'FAIL'+ color.default +' | ' + ctn[i] + ' | (not even compiled)\n');
      return fileLoop(++i);
    } else {
      exec('php -f ' + path + phpFileName, function(error, stdout, stderr) {
        if(stderr) {
          sys.print('stderr: ' + stderr + '\n');
        }
        if (error === null) {
          var result = stdout.toString();
          if(result.toLowerCase() === 'pass') {
            sys.print(color.green + 'PASS'+ color.default +' | ' + ctn[i] + '\n');
          } else {
            sys.print(color.red + 'FAIL'+ color.default +' | ' + ctn[i] + ' | "pass" !== "' + result + '"\n');
          }
        } else {
          sys.print(phpFileName + ' execution error: ' + error + '\n');
        }
        return fileLoop(++i);
      });
    }
  })(0);
}

function finishTest() {
  sys.print(color.cyan + '===TEST END===\n' + color.default);
}

removePhpFiles(function() {
  compileMammouth(function() {
    doTheTests(function() {
      removePhpFiles();
      finishTest();
    });
  });
});
