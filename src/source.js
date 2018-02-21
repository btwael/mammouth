//*-- Source
/**
 * Source represents an input source code.
 */
function Source(/*String*/ path, /*String */ content) {
    this._path = path;
    this._content = content;
}

/**
 * Returns the path of the source code.
 */
Source.prototype.getPath = /*String*/ function() {
    return this._path;
};

/**
 * Returns the path of the source code.
 */
Source.prototype.getContent = /*String*/ function() {
    return this._content;
};

// exports
module.exports = Source;
