// imports
var Position = require("./position");

// A location describe the start and the end of a code sequence (ex. Token)
function Location(start, end) {
    this.start = start === undefined ? new Position() : start;
    this.end = end === undefined ? new Position() : end;
}

// Get a clone of this object
Location.prototype.clone = function() {
    return new Location(this.start.clone(), this.end.clone());
};

// Set filename
Location.prototype.setFilename = function(filename) {
    this.start.filename = this.end.filename = filename;
};

// exports
module.exports = Location;