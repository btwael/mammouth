exports.reverseArray = function(array) {
    var reversed = [];
    for(var i = 0; i < array.length; i++) {
        reversed.unshift(array[i]);
    }
    return reversed;
};

exports.extends = function(base, extension) {
    var constructed = function() {
        extension.apply(this, arguments);
        delete this.location;
        base.apply(this, arguments);
    };
    for(var key in extension.prototype) {
        base.prototype[key] = extension.prototype[key];
    }
    return constructed;
};