import "package:mammouth/src/language/mammouth/element/element.dart";
import "package:mammouth/src/language/mammouth/type/type.dart";

/**
 * A name scope used by to determine which names are visible at any given point
 * in the code.
 */
class Scope {
  Map<String, Element> definedElements = <String, Element>{};

  final Scope parentScope;

  MammouthType localThisType;

  Scope(this.parentScope);

  MammouthType get thisType {
    Scope scope = this;
    while(scope != null) {
      if(scope.localThisType != null) {
        return scope.localThisType;
      }
      scope = scope.parentScope;
    }
    return null;
  }

  void define(Element element) {
    this.definedElements[element.name] = element;
  }

  void addName(String name) {
    this.definedElements[name] = null;
  }

  bool isLocal(String name) {
    if(this.definedElements.containsKey(name)) {
      return true;
    }
    return false;
  }

  Element lookup(String name) {
    Scope scope = this;
    bool checkThis = true;
    while(scope != null) {
      if(scope.definedElements.containsKey(name)) {
        return scope.definedElements[name];
      }
      scope = scope.parentScope;
    }
    if(thisType is InterfaceType) {
      List<ClassMemberElement> elements = (thisType as InterfaceType).lookup(
          name);
      if(elements.length == 1) {
        return elements.first;
      }
    }
    return null;
  }

  Set<String> getAllNames() {
    Set<String> names = new Set<String>();
    Scope scope = this;
    while(scope != null) {
      names.addAll(scope.definedElements.keys);
      scope = scope.parentScope;
    }
    return names;
  }
}
