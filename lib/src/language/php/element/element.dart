import "package:mammouth/src/codegen/namePicker.dart";

class Scope {
  NamePicker namePicker = new NamePicker();
  Scope parentScope;
  Set<NameElement> _names = new Set<NameElement>();

  Scope([this.parentScope = null]);

  void add(String name) {
    this._names.add(new StaticName(name));
  }

  void addLateName(LateName name) {
    this._names.add(name);
  }

  Set<String> get names {
    Set<String> names = new Set<String>();
    _names.forEach((NameElement variable) {
      if(variable is LateName && variable._name == null) {
        return;
      }
      names.add(variable.name);
    });
    return names;
  }
}

abstract class NameElement {
  String get name;

  Set<Scope> scopes = new Set<Scope>();
}

class StaticName extends NameElement {
  @override
  final String name;

  @override
  Set<Scope> scopes = new Set<Scope>();

  StaticName(this.name);
}

class LateName extends NameElement {
  final String basename;

  String _name;

  @override
  Set<Scope> scopes = new Set<Scope>();

  LateName(this.basename);

  @override
  String get name {
    if(_name != null) {
      return _name;
    }
    Set<String> names = new Set<String>();
    scopes.forEach((Scope scope) {
      names.addAll(scope.names);
    });
    if(basename.endsWith("_")) {
      names.add(basename);
    }
    _name = (new NamePicker()).pick(basename, names);
    return _name;
  }
}
