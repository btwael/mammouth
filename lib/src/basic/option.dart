class Option<T> {
  bool _set = false;
  T _value = null;

  Option();

  Option.Some(T value) {
    this.some = value;
  }

  bool get isSome => this._set == true;

  bool get isNone => this._set == false;

  T get some {
    return this._value;
  }

  void set some(T value) {
    this._set = true;
    this._value = value;
  }

  void setNone() {
    this._set = false;
    this._value = null;
  }
}
