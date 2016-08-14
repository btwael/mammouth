// Position object describe a specific point in a text code (lsemiliar to cursor in text editor)
// a Position is defined with a file name, offset (the number of characters from code start, from 0),
// line (start from 1), and column (start from 0);
function Position(filename, offset, line, column) {
    this.filename = filename === undefined ? null : filename;
    this.offset = offset === undefined ? 0 : offset;
    this.line = line === undefined ? 1 : line;
    this.column = column === undefined ? 0 : column;
}

// Get a clone of this object
Position.prototype.clone = function() {
    return new Position(this.filename, this.offset, this.line, this.column);
};

/*-- For dynamic and tracking position --*/
// Increment a position with number of columns
Position.prototype.colAdvance = function(num) {
    num = num === undefined ? 1 : num;
    this.offset += num;
    this.column += num;
};

// Increment a position with number of line breaks
Position.prototype.rowAdvance = function(num) {
    num = num === undefined ? 1 : num;
    this.offset += num;
    this.line += num;
    this.column = 0;
};

// exports
module.exports = Position;