//*-- Precedence
/**
 * Precedence defines the priority in which tokens are treated by parser.
 */
class Precedence implements Comparable<Precedence> {
    final int _ordinal;

    const Precedence(this._ordinal);

    /**
     * Returns the ordinal of this precedence.
     */
    int get ordinal {
        return this._ordinal;
    }

    @override
    int compareTo(Precedence other) {
        return this.ordinal - other.ordinal;
    }

    static const Precedence Zero = const Precedence(0);
}
