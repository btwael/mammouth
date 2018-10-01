library mammouth.language.mammouth.type.implementation;

import 'package:mammouth/src/language/mammouth/element/element.dart';
import 'package:mammouth/src/language/mammouth/type/type.dart';

class FunctionTypeImpl extends FunctionType {
  final List<ClassMemberElement> members = [];
  MammouthType returnType;
  List<MammouthType> parametersType;

  FunctionTypeImpl(this.returnType, this.parametersType);

  bool isAssignableTo(MammouthType type) {
    if(type == this || type is DynamicType) {
      return true;
    }
    if(type is FunctionType) {
      if(!this.returnType.isAssignableTo(type.returnType)) return false;
      if(this.parametersType.length != type.parametersType.length)
        return false;
      for(int i = 0; i < this.parametersType.length; i++) {
        if(!this.parametersType[i].isAssignableTo(parametersType[i]))
          return false;
      }
      return true;
    }
    return false;
  }

  int assignabilityTo(MammouthType type) {
    if(type == this || type is DynamicType) {
      return 0;
    }
    if(type is FunctionType) {
      if(!this.returnType.isAssignableTo(type.returnType)) return 100;
      if(this.parametersType.length != type.parametersType.length)
        return 100;
      for(int i = 0; i < this.parametersType.length; i++) {
        if(!this.parametersType[i].isAssignableTo(parametersType[i]))
          return 100;
      }
      return 0;
    }
    return 100;
  }
}

class InterfaceTypeImpl extends InterfaceType {
  final List<ClassMemberElement> members;

  InterfaceType superclass;

  List<InterfaceType> interfaces = [];

  InterfaceTypeImpl(this.members);

  void addMember(List<ClassMemberElement> members) {
    this.members.addAll(members);
  }
}

class NativeTypeImpl extends NativeType {
  final String name;
  List<ClassMemberElement> members = new List<ClassMemberElement>();

  InterfaceType superclass;

  List<InterfaceType> interfaces = [];

  NativeTypeImpl(this.name);
}

class DynamicTypeImpl extends DynamicType {
  List<ClassMemberElement> members = [];

  DynamicTypeImpl();
}
