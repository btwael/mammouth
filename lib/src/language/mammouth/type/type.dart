library mammouth.language.mammouth.type.type;

import "package:mammouth/src/basic/option.dart" show Option;
import 'package:mammouth/src/language/mammouth/element/element.dart';

///*-- FunctionType
/**
 * The type of an invokable element: function, constructor and method.
 */
abstract class FunctionType extends MammouthType {
  /**
   * The type of object returned by this type of function.
   */
  MammouthType get returnType;

  /**
   * the types of arguments taken by this type of function.
   */
  List<MammouthType> get parametersType;
}

//*-- Type
/**
 * Base structure to represents a type, semantically.
 */
abstract class MammouthType {
  /**
   * Members defind for object of this type.
   */
  List<ClassMemberElement> get members;

  /**
   * Methods defined for object of this type.
   */
  List<MethodElement> get methods {
    List<MethodElement> result = <MethodElement>[];
    this.members.forEach((ClassMemberElement member) {
      if(member is MethodElement) {
        result.add(member);
      }
    });
    return result;
  }

  List<OperatorElement> get operators {
    List<OperatorElement> result = <OperatorElement>[];
    this.members.forEach((ClassMemberElement member) {
      if(member is OperatorElement) {
        result.add(member);
      }
    });
    return result;
  }

  List<ConverterElement> get converters {
    List<ConverterElement> result = <ConverterElement>[];
    this.members.forEach((ClassMemberElement member) {
      if(member is ConverterElement) {
        result.add(member);
      }
    });
    return result;
  }

  /**
   * Return `true` if this type is assignable to [other].
   */
  bool isAssignableTo(MammouthType type);

  int assignabilityTo(MammouthType type);
}

//*-- InterfaceType
/**
 * A type defined by a class.
 */
abstract class InterfaceType extends MammouthType {
  InterfaceType get superclass;

  void set superclass(InterfaceType type);

  List<InterfaceType> get interfaces;

  @override
  bool isAssignableTo(MammouthType type) {
    if(this == type || type is DynamicType) {
      return true;
    }
    if(type is InterfaceType && this.isSubtypeOf(type)) {
      return true;
    }
    if(this
        .converters
        .where((ConverterElement method) {
      return method.returnType == type && method.name == "->";
    })
        .toList()
        .length >
        0) {
      return true;
    }
    return false;
  }

  int assignabilityTo(MammouthType type) {
    if(this == type || type is DynamicType) {
      return 0;
    }
    if(type is InterfaceType && this.isSubtypeOf(type)) {
      return 0;
    }
    if(this
        .converters
        .where((ConverterElement method) {
      return method.returnType == type && method.name == "->";
    })
        .toList()
        .length >
        0) {
      return 1;
    }
    return 100;
  }

  bool isSubtypeOf(InterfaceType type) {
    List<MammouthType> types = [this];
    while(types.isNotEmpty) {
      InterfaceType typei = types.removeLast();
      if(typei == type) {
        return true;
      } else {
        if(typei.superclass != null) {
          types.add(typei.superclass);
        }
        types.addAll(typei.interfaces);
      }
    }
    return false;
  }

  List<FieldElement> get fields {
    List<FieldElement> result = <FieldElement>[];
    this.members.forEach((ClassMemberElement member) {
      if(member is FieldElement) {
        result.add(member);
      }
    });
    return result;
  }

  /**
   * Constructors defined for this interface.
   */
  List<ConstructorElement> get constructors {
    List<ConstructorElement> result = <ConstructorElement>[];
    this.members.forEach((ClassMemberElement member) {
      if(member is ConstructorElement) {
        result.add(member);
      }
    });
    return result;
  }

  /**
   * Lookups for a member in this interface with given [name].
   */
  List<ClassMemberElement> lookup(String name) {
    List<ClassMemberElement> members = [];
    List<MammouthType> types = [this];
    while(types.isNotEmpty) {
      InterfaceType typei = types.removeLast();
      members.addAll(typei.members);
      if(typei.superclass != null) {
        types.add(typei.superclass);
      }
    }
    for(int i = 0; i < members.length; i++) {
      ClassMemberElement member = members[i];
      if(member.isOverride) {
        for(int j = i + 1; j < members.length; j++) {
          if(members[j] == member.overrided) {
            members.removeAt(j);
            j--;
          }
        }
      }
    }
    members = members.where((ClassMemberElement member) {
      if(member is ConstructorElement) {
        return false;
      }
      return member.name == name;
    }).toList();
    return members;
  }

  Option<ConstructorElement> hasDefaultConstructor() {
    for(int i = 0; i < this.members.length; i++) {
      if(this.members[i] is ConstructorElement) {
        ConstructorElement constructor = this.members[i];
        // TODO: precise class definition null or empty
        if(constructor.parameters == null || constructor.parameters.isEmpty) {
          return new Option<ConstructorElement>.Some(constructor);
        }
      }
    }
    return new Option<ConstructorElement>();
  }

  Option<ConstructorElement> getConstructorFor(List<MammouthType> argTypes) {
    List<ConstructorElement> constructors = [];
    constuctorLoop:
    for(int i = 0; i < this.members.length; i++) {
      if(this.members[i] is ConstructorElement) {
        ConstructorElement constructor = this.members[i];
        // TODO: precise class definition null or empty
        if(constructor.parameters.length == argTypes.length) {
          for(int j = 0; j < argTypes.length; j++) {
            if(!argTypes[j].isAssignableTo(constructor.parameters[j].type)) {
              continue constuctorLoop;
            }
          }
          constructors.add(constructor);
        }
      }
    }
    if(constructors.length >= 1) {
      // TODO: rate and choose best constructor
      return new Option<ConstructorElement>.Some(constructors.first);
    }
    return new Option<ConstructorElement>();
  }

  Option<MethodElement> getMethodFor(String name, List<MammouthType> argTypes) {
    List<MethodElement> methods = [];
    methodLoop:
    for(int i = 0; i < this.members.length; i++) {
      if(this.members[i] is MethodElement) {
        MethodElement method = this.members[i];
        if(method.parameters.length == argTypes.length) {
          for(int j = 0; j < argTypes.length; j++) {
            if(!argTypes[j].isAssignableTo(method.parameters[j].type)) {
              continue methodLoop;
            }
          }
          if(method.name == name) {
            methods.add(method);
          }
        }
      }
    }
    if(methods.length >= 1) {
      // TODO: rate and choose best method
      return new Option<MethodElement>.Some(methods.first);
    }
    return new Option<MethodElement>();
  }

  Option<FieldElement> getField(String name) {
    for(int i = 0; i < this.fields.length; i++) {
      FieldElement field = this.fields[i];
      if(field.name == name) {
        return new Option<FieldElement>.Some(field);
      }
    }
    return new Option<FieldElement>();
  }

  Option<ConverterElement> getConverterTo(MammouthType type) {
    for(int i = 0; i < this.converters.length; i++) {
      ConverterElement converter = this.converters[i];
      if(converter.returnType == type) {
        return new Option<ConverterElement>.Some(converter);
      }
    }
    return new Option<ConverterElement>();
  }

  void addMember(List<ClassMemberElement> members) {}
}

//*-- NativeType
/**
 * Represents a built-in type.
 */
abstract class NativeType extends InterfaceType {
  /**
   * The name of the built-in native type.
   */
  String get name;
}

//*-- DynamicType
/**
 * Represents the dynamic type used for weak typing.
 */
abstract class DynamicType extends MammouthType {
  String get name => "dynamic";

  bool isAssignableTo(MammouthType type) {
    return true;
  }

  int assignabilityTo(MammouthType type) {
    return 0;
  }
}
