abstract class Source {
    bool get exist;

    String get content;
}

class BasicSource extends Source {
    final String _content;

    BasicSource(this._content);

    @override
    bool get exist {
        return true;
    }

    @override
    String get content {
        return this._content;
    }
}
