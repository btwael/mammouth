var sys = require('sys'),
    exec = require('child_process').exec,
    fs = require('fs'),
    child;

function removePhpFiles(callback) {
  exec("rm ./tests/*.php", function(error) {
    // if(error !== null) {
    //  sys.print('removePhpFiles error: ' + error + '\n');
    // }
    callback && callback();
  });
}

function compileMammouth(callback) {
  child = exec("node ./bin/mammouth --compile --output ./tests ./tests", function(error, stdout, stderr) {
    sys.print('stdout: ' + stdout);
    sys.print('stderr: ' + stderr);
    if (error === null) {
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
  console.log(ctn);
  sys.print('\n===TEST BEGIN===\n');

  (fileLoop = function(i) {
    if(ctn.length === i) {
      return callback && callback();;
    }
    if(ctn[i].substr(-9).toLowerCase() !== '.mammouth') {
      // ommit php files from list
      return fileLoop(i ? ++i : 1);
    }
    phpFileName = ctn[i].replace(/.mammouth$/, '') + '.php';
    if(ctn.indexOf(phpFileName) === -1) {
      sys.print('FAIL | ' + ctn[i] + ' | (not even compiled)\n');
      return fileLoop(i ? ++i : 1);
    } else {
      exec('php -f ' + path + phpFileName, function(error, stdout, stderr) {
        if(stderr) {
          sys.print('stderr: ' + stderr + '\n');
        }
        if (error === null) {
          if(typeof stdout == 'string' && stdout.trim() == 'pass') {
            sys.print('PASS | ' + ctn[i] + '\n');
          } else {
            sys.print('FAIL | ' + ctn[i] + ' | "pass" !== "' + stdout + '"\n');
          }
        } else {
          sys.print(phpFileName + ' execution error: ' + error + '\n');
        }
        return fileLoop(i ? ++i : 1);
      });
    }
  })(0);
}

function finishTest() {
  sys.print('===TEST END===\n');
};

removePhpFiles(function() {
  compileMammouth(function() {
    doTheTests(function() {
      removePhpFiles();
      finishTest();
    })
  });
});
