//*-- Precedence
/**
 * Precedence defines the order in wihch tokens are
 * treated by the parser. 
 */
function Precedence(/*String*/ name,
                    /*int*/ ordinal) /*implements Comparable<Precedence>*/ {
    this._name = name;
    this._ordinal = ordinal;
}

/**
 * Returns the representative name of this Precedence. 
 */
Precedence.prototype.getName = /*String*/ function() {
    return this._name;
}

/**
 * Returns the ordinal of this Precedence. 
 */
Precedence.prototype.getOrdinal = /*int*/ function() {
    return this._ordinal;
}

/**
 * Compares two Precedence.
 */
Precedence.prototype.compareTo = /*int*/ function(/*Precedence*/ other) {
    return this._ordinal - other._ordinal;
};

// Predefined precedences
/*Precedence*/ Precedence.Expression = new Precedence("expression", -100);
/*Precedence*/ Precedence.Zero = new Precedence("zero", 0);
/*Precedence*/ Precedence.Assign = new Precedence("assign", 1);
/*Precedence*/ Precedence.LogicalOr = new Precedence("logicalOr", 2);
/*Precedence*/ Precedence.LogicalAnd = new Precedence("logicalAnd", 3);
/*Precedence*/ Precedence.BitwiseOr = new Precedence("bitwiseOr", 4);
/*Precedence*/ Precedence.BitwiseAnd = new Precedence("bitwiseAnd", 5);
/*Precedence*/ Precedence.BitwiseXor = new Precedence("bitwiseXor", 6);
/*Precedence*/ Precedence.Equality = new Precedence("equality", 7);
/*Precedence*/ Precedence.Relational = new Precedence("relational", 8);
/*Precedence*/ Precedence.Shift = new Precedence("shift", 9);
/*Precedence*/ Precedence.Additive = new Precedence("additive", 10);
/*Precedence*/ Precedence.Multiplicative = new Precedence("multiplicative", 11);

// export
module.exports = Precedence;
