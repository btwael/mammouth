library mammouth.language.mammouth.element.implementation;

import "package:mammouth/src/language/common/ast/visibility.dart";
import "package:mammouth/src/language/mammouth/ast/ast.dart" as mammouth;
import "package:mammouth/src/language/mammouth/element/element.dart";
import "package:mammouth/src/language/mammouth/type/type.dart";
import "package:mammouth/src/language/mammouth/type/implementation.dart";
import 'package:mammouth/src/language/php/ast/ast.dart' as php;
import "package:mammouth/src/semantic/elementBuilder.dart";
import "package:mammouth/src/semantic/parentResolver.dart";
import "package:mammouth/src/semantic/typeChecker.dart";
import "./Cloner.dart";

class ClassElementImpl extends ClassElement {
  final String name;
  MammouthType type;

  Map<String, List<ClassMemberElement>> _members =
  <String, List<ClassMemberElement>>{};

  ClassElementImpl(this.name);

  @override
  List<ClassMemberElement> get members {
    List<ClassMemberElement> members = <ClassMemberElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        members.add(element);
      });
    });
    return members;
  }

  @override
  List<String> get memberNames {
    List<String> names = <String>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      if(elements.where((ClassMemberElement element) {
        return !(element is ConstructorElement);
      }).length >
          0) {
        names.add(name);
      }
      ;
    });
    return names;
  }

  @override
  List<ConstructorElement> get constructors {
    List<ConstructorElement> constructors = <ConstructorElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        if(element is ConstructorElement) {
          constructors.add(element);
        }
      });
    });
    return constructors;
  }

  @override
  List<FieldElement> get fields {
    List<FieldElement> fields = <FieldElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        if(element is FieldElement) {
          fields.add(element);
        }
      });
    });
    return fields;
  }

  @override
  List<MethodElement> get methods {
    List<MethodElement> methods = <MethodElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        if(element is MethodElement) {
          methods.add(element);
        }
      });
    });
    return methods;
  }

  @override
  List<OperatorElement> get operators {
    List<OperatorElement> operators = <OperatorElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        if(element is OperatorElement) {
          operators.add(element);
        }
      });
    });
    return operators;
  }

  @override
  List<ConverterElement> get converters {
    List<ConverterElement> operators = <ConverterElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        if(element is ConverterElement) {
          operators.add(element);
        }
      });
    });
    return operators;
  }

  @override
  void addMember(ClassMemberElement member) {
    if(!this._members.containsKey(member.name)) {
      this._members[member.name] = <ClassMemberElement>[];
    }
    this._members[member.name].add(member);
  }

  @override
  void setup() {
    this._members.forEach((String name, List<ClassMemberElement> members) {
      for(int i = 0; i < members.length; i++) {
        ClassMemberElement member = members[i];
        if(members.length > 1 && member is ExecutableClassMemberElement) {
          member.isOverloaded = true;
        }
      }
    });
  }

  @override
  List<ClassMemberElement> getElementsOf(String name) {
    if(this._members.containsKey(name)) {
      return this._members[name];
    }
    return [];
  }

  Map<List<MammouthType>, MammouthType> _cache = {};

  @override
  MammouthType instantiate(
      [List<MammouthType> typeArguments, TypeChecker tc, MammouthType dynamicType]) {
    if(node.typeParameters != null) {
      int parameterLength = node.typeParameters.parameters.length;
      if(typeArguments.length == 0) {
        List<MammouthType> types = [];
        for(int i = 0; i < parameterLength; i++) {
          types.add(dynamicType);
        }
        typeArguments = types;
      } else if(typeArguments.length != parameterLength) {
        // TODO: report error
        throw "";
      }
    }
    if(typeArguments.length > 0) {
      casee: for(int i = 0; i< _cache.length; i++) {
        List<MammouthType> key = _cache.keys.elementAt(i);
        for(int j = 0; j < key.length; j++) {
          if(key.elementAt(j) != typeArguments.elementAt(j)) {
            continue casee;
          }
        }
        return _cache.values.elementAt(i);
      }
    }
    if(node.typeParameters != null) {
      mammouth.ClassExpression nnode = this.node.accept(
          new Cloner()) as mammouth.ClassExpression;
      int parameterLength = node.typeParameters.parameters.length;
      tc.pushScope();
      for(int i = 0; i < parameterLength; i++) {
        tc.scopeStack.last.define(
            new TypeDefiningElementImpl(
                node.typeParameters.parameters.elementAt(i).name.name,
                typeArguments.elementAt(i)));
      }
      InterfaceType type = new InterfaceTypeImpl([]);
      _cache[typeArguments] = type;
      nnode.accept(new ParentResolver());
      nnode.accept(new ElementBuilder());
      nnode.accept(tc, type: type);
      tc.popScope();
      return nnode.element.type;
    } else {
      return this.type;
    }
  }
}

class ConstructorElementImpl extends ConstructorElement {
  Visibility visibility;
  TypeDefiningElement enclosingElement;
  MammouthType enclosingType;
  bool isOverloaded = false;
  ConstructorElementImpl _overrided;
  List<ParameterElement> parameters;

  ConstructorElementImpl(this.enclosingElement, this.enclosingType,
      this.parameters);

  FunctionType get type {
    return new FunctionTypeImpl(
        this.returnType,
        this.parameters.map((ParameterElement parameterElement) {
          return parameterElement.type;
        }).toList());
  }

  String get name {
    return "";
  }

  MammouthType get returnType {
    // TODO: return void type
    return null;
  }

  void set returnType(Object other) {
    // nothing to do
  }

  @override
  ConstructorElement get overrided => _overrided;

  @override
  void set overrided(Element element) {
    if(element == null || element is ConstructorElement) {
      _overrided = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

class FieldElementImpl extends FieldElement {
  Visibility visibility;
  String name;
  ClassElement _enclosingElement;
  MammouthType type;
  ClassMemberElement _overrided;

  FieldElementImpl(this._enclosingElement, this.name);

  @override
  ClassMemberElement get overrided => _overrided;

  @override
  void set overrided(Element element) {
    if(element == null || element is ClassMemberElement) {
      _overrided = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }

  ClassElement get enclosingElement => _enclosingElement;

  void set enclosingElement(TypeDefiningElement element) {
    if(element is ClassElement) {
      _enclosingElement = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

class FunctionElementImpl extends FunctionElement {
  String name;
  MammouthType returnType;
  List<ParameterElement> parameters;

  FunctionElementImpl(this.name, this.returnType, this.parameters);

  FunctionType get type {
    return new FunctionTypeImpl(
        this.returnType,
        this.parameters.map((ParameterElement parameterElement) {
          return parameterElement.type;
        }).toList());
  }
}

class InterfaceElementImpl extends InterfaceElement {
  final String name;
  MammouthType type;

  Map<String, List<ClassMemberElement>> _members =
  <String, List<ClassMemberElement>>{};

  InterfaceElementImpl(this.name);

  @override
  List<ClassMemberElement> get members {
    List<ClassMemberElement> members = <ClassMemberElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        members.add(element);
      });
    });
    return members;
  }

  @override
  List<String> get memberNames {
    List<String> names = <String>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      if(elements.where((ClassMemberElement element) {
        return !(element is ConstructorElement);
      }).length >
          0) {
        names.add(name);
      }
      ;
    });
    return names;
  }

  @override
  List<ConstructorElement> get constructors {
    List<ConstructorElement> constructors = <ConstructorElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        if(element is ConstructorElement) {
          constructors.add(element);
        }
      });
    });
    return constructors;
  }

  @override
  List<MethodElement> get methods {
    List<MethodElement> methods = <MethodElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        if(element is MethodElement) {
          methods.add(element);
        }
      });
    });
    return methods;
  }

  @override
  List<OperatorElement> get operators {
    List<OperatorElement> operators = <OperatorElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        if(element is OperatorElement) {
          operators.add(element);
        }
      });
    });
    return operators;
  }

  @override
  List<ConverterElement> get converters {
    List<ConverterElement> operators = <ConverterElement>[];
    this._members.forEach((String name, List<ClassMemberElement> elements) {
      elements.forEach((ClassMemberElement element) {
        if(element is ConverterElement) {
          operators.add(element);
        }
      });
    });
    return operators;
  }

  @override
  void addMember(ClassMemberElement member) {
    if(!this._members.containsKey(member.name)) {
      this._members[member.name] = <ClassMemberElement>[];
    }
    this._members[member.name].add(member);
  }

  @override
  void setup() {
    this._members.forEach((String name, List<ClassMemberElement> members) {
      for(int i = 0; i < members.length; i++) {
        ClassMemberElement member = members[i];
        if(members.length > 1 && member is ExecutableClassMemberElement) {
          member.isOverloaded = true;
        }
      }
    });
  }

  @override
  List<ClassMemberElement> getElementsOf(String name) {
    if(this._members.containsKey(name)) {
      return this._members[name];
    }
    return [];
  }
}

class MethodElementImpl extends MethodElement {
  Visibility visibility;
  String name;
  bool isOverloaded = false;
  TypeDefiningElement enclosingElement;
  MammouthType returnType;
  List<ParameterElement> parameters;
  MethodElement _overrided;

  MethodElementImpl(this.enclosingElement, this.name, this.returnType,
      this.parameters);

  FunctionType get type {
    return new FunctionTypeImpl(
        this.returnType,
        this.parameters.map((ParameterElement parameterElement) {
          return parameterElement.type;
        }).toList());
  }

  @override
  MethodElement get overrided => _overrided;

  @override
  void set overrided(Element element) {
    if(element == null || element is MethodElement) {
      _overrided = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

class OperatorElementImpl extends OperatorElement {
  Visibility visibility;
  String name;
  TypeDefiningElement enclosingElement;
  MammouthType returnType;
  bool isOverloaded = false;
  List<ParameterElement> parameters;
  OperatorElement _overrided;

  OperatorElementImpl(this.enclosingElement, this.name, this.returnType,
      this.parameters);

  FunctionType get type {
    return new FunctionTypeImpl(
        this.returnType,
        this.parameters.map((ParameterElement parameterElement) {
          return parameterElement.type;
        }).toList());
  }

  @override
  OperatorElement get overrided => _overrided;

  @override
  void set overrided(Element element) {
    if(element is OperatorElement) {
      _overrided = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

class ConverterElementImpl extends ConverterElement {
  bool isOverloaded = false;
  Visibility visibility;
  TypeDefiningElement enclosingElement;
  MammouthType returnType;
  ConverterElement _overrided;

  ConverterElementImpl(this.enclosingElement, this.returnType);

  FunctionType get type {
    return new FunctionTypeImpl(
        this.returnType,
        this.parameters.map((ParameterElement parameterElement) {
          return parameterElement.type;
        }).toList());
  }

  @override
  ConverterElement get overrided => _overrided;

  @override
  void set overrided(Element element) {
    if(element is ConverterElement) {
      _overrided = element;
    } else {
      // MARK(UNREACHABLE ZONE)
      throw "Unreachable Zone!";
      // MARK(STOP PROCESSING)
    }
  }
}

class ParameterElementImpl extends ParameterElement {
  String name;
  MammouthType type;
  php.AstNode effectiveValue;
  bool isOptional;

  ParameterElementImpl(this.name, this.isOptional);
}

class TypeDefiningElementImpl extends TypeDefiningElement {
  String name;

  MammouthType type;

  TypeDefiningElementImpl(this.name, this.type);

  TypeDefiningElementImpl.native(this.name, this.type);

  TypeDefiningElementImpl.dynamic(DynamicType type)
      : this.name = type.name,
        this.type = type;
}

class TypeParameterElementImpl extends TypeParameterElement {
  String name;

  MammouthType type = new InterfaceTypeImpl([]);

  TypeParameterElementImpl(this.name);
}

class VariableElementImpl extends VariableElement {
  String name;
  MammouthType type;

  VariableElementImpl(this.name);
}
