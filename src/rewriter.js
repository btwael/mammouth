// Rewriter takes from lexer a token stream, and improve the ouput for better parsing and error handling
function Rewriter() {
    // Nothing go here
}

Rewriter.prototype.setInput = function(tokens) {
    this.input = tokens;
};

Rewriter.prototype.rewrite = function() {
    // Remove meaning-less token
    this.removeUnnecessary();
    // Token that meaning changes when they are in a special sequence (ex. between '[' & ']')
    this.landlockedToken();
    // Replace tokens reference with their indexes (avoiding circular references)
    this.referencesIndex();
    //return final tokens list
    return this.input;
};

Rewriter.prototype.removeUnnecessary = function() {
    for (var i = 0; i < this.input.length - 1; i++) {
        var firstToken = this.input[i];
        var secondToken = this.input[i + 1];
        // LINETERMINATOR + OUTDENT => delete LINETERMINATOR
        if(firstToken.type == 'LINETERMINATOR' && secondToken.type == 'OUTDENT') {
            this.input.splice(i, 1);
            i--; continue;
        }
        // CASE => SWITCH_WHEN
        if(firstToken.type == 'CASE') {
            firstToken.type == 'SWITCH_WHEN';
            i--; continue;
        }
        // INDENT or MINDENT or OUTDENT + WHEN => rename WHEN to SWITCH_WHEN
        if(['INDENT', 'MINDENT', 'OUTDENT'].indexOf(firstToken.type) > -1 && secondToken.type == 'WHEN') {
            secondToken.type = 'SWITCH_WHEN';
            i--; continue;
        }
        // MINDENT + CATCH => delete MINDENT
        if(firstToken.type == 'MINDENT' && secondToken.type == 'CATCH') {
            this.input.splice(i, 1);
            i--; continue;
        }
        // MINDENT + ELSE => delete MINDENT
        if(firstToken.type == 'MINDENT' && secondToken.type == 'ELSE') {
            this.input.splice(i, 1);
            i--; continue;
        }
        // MINDENT + FINALLY => delete MINDENT
        if(firstToken.type == 'MINDENT' && secondToken.type == 'FINALLY') {
            this.input.splice(i, 1);
            i--; continue;
        }
        // FINAL or ABSTARCT + CLASS => rename first to CLASSMODIFIER
        if(['FINAL', 'ABSTRACT'].indexOf(firstToken.type) > -1 && secondToken.type == 'CLASS') {
            firstToken.type = 'CLASSMODIFIER';
            i--; continue;
        }
        // FUNC + IDENTIFIER + CALL_START => FUNC + IDENTIFIER + (
        if(firstToken.type == 'FUNC' && secondToken.type == 'IDENTIFIER'
                                     && i + 2 < this.input.length
                                     && this.input[i + 2].type == 'CALL_START') {
            var thirdToken = this.input[i + 2];
            thirdToken.type = '(';
            thirdToken._.closedIn.type = ')';
        }
    }
};

Rewriter.prototype.landlockedToken = function() {
    for(var i = 0; i < this.input.length; i++) {
        var startToken = this.input[i];
        if(startToken.type == 'INDEX_START' && this.checkLandlocked(i, startToken, 'RANGE')) {
            startToken.type = 'SLICE_START';
            startToken._.closedIn.type = 'SLICE_END';
        }
        if(startToken.type == '[' && this.checkLandlocked(i, startToken, 'RANGE')) {
            startToken.type = 'RANGE_START';
            startToken._.closedIn.type = 'RANGE_END';
        }
    }
};

Rewriter.prototype.referencesIndex = function() {
    for(var i = 0; i < this.input.length; i++) {
        var startToken = this.input[i];
        for(var j = 0; j < this.input.length; j++) {
            if(j == i) continue;
            var endToken = this.input[j];
            switch(startToken.type) {
                case 'MINDENT':
                    if(startToken._.startedIn == endToken) {
                        startToken._.startedIn = j;
                    }
                    break;
                case 'OUTDENT':
                    if(startToken._.openedIn == endToken) {
                        startToken._.openedIn = j;
                        endToken._.closedIn = i;
                    }
                    break;
                case 'INDEX_START':
                case 'START_TAG':
                case '{':
                case 'CALL_START':
                case 'RANGE_START':
                    if(startToken._.closedIn == endToken) {
                        startToken._.closedIn = j;
                        endToken._.openedIn = i;
                    }
                    break;
            }
        }
    }
};

Rewriter.prototype.checkLandlocked = function(startIndex, startToken, landlockedType) {
    var found = false;
    for(var i = startIndex + 1; i < this.input.length; i++) {
        var endToken = this.input[i];
        if(endToken.type == landlockedType) {
            found = true;
            break;
        }
        if(endToken == startToken._.closedIn) {
            break;
        }
    }
    return found;
};

// exports
module.exports = Rewriter;