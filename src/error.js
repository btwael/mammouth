var ErrorList = {
    100: function() {
        return "unexpected " + this.what;
    },
    101: function() {
        return "Expected " + this.expected + ' but found ' + this.found;
    }
};

function error(source, filename, option) {
    this.source = source;
    this.filename = filename === undefined ? null : filename;
    this.option = option === undefined ? {} : option;
    if(this.option.showWhere === undefined) this.option.showWhere = true;
    if(this.option.showInSource === undefined) this.option.showInSource = true;
}

error.prototype.process = function(message, option) {
    var premessage;
    if(this.option.showWhere == true && option.pos != undefined) {
        premessage = 'Error';
        if(this.filename != null) {
            premessage += ' on ' + this.filename;
        }
        premessage += ' on line ' + option.pos.line + (option.pos.column == 0 ? '' : ' on column ' + (option.pos.column + 1));
        premessage += ': ';
        message = premessage + message;
    }
    if(this.option.showInSource == true && option.pos != undefined) {
        postmessage = '\n' + this.source.split("\n")[option.pos.line - 1]
        postmessage += '\n'
        for(var i = 0; i < option.pos.column + 1; i++) {
            postmessage += '^'
        }
        message = message + postmessage;
    }
    throw message;
};

error.prototype.let = function(errorid, option) {
    this.process(ErrorList[errorid].call(option), option);
};

module.exports = error;