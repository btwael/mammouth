library mammouth.semantic.typeProvider;

import "package:mammouth/src/basic/option.dart" show Option;
import "package:mammouth/src/language/mammouth/element/element.dart";
import "package:mammouth/src/language/mammouth/element/implementation.dart";
import "package:mammouth/src/language/mammouth/type/type.dart";
import "package:mammouth/src/language/mammouth/type/implementation.dart";
import "package:mammouth/src/semantic/scope.dart";

//*-- TypeProvider
/**
 * Provides built-in type defined by the language to the type checker and code
 * generator...
 */
class TypeProvider extends Scope {
  final NativeType arrayType = new NativeTypeImpl("Array");
  final NativeType boolType = new NativeTypeImpl("bool");
  final MammouthType stringType = new InterfaceTypeImpl([]);
  final MammouthType intType = new InterfaceTypeImpl([]);
  final MammouthType floatType = new InterfaceTypeImpl([]);
  final NativeType mapType = new NativeTypeImpl("Map");

  final DynamicType dynamicType = new DynamicTypeImpl();

  TypeProvider() : super(null) {
    this.definedElements["String"] =
    new TypeDefiningElementImpl.native("String", this.stringType);
    this.definedElements["float"] =
    new TypeDefiningElementImpl.native("float", this.floatType);
    this.definedElements["int"] =
    new TypeDefiningElementImpl.native("int", this.intType);

    this.definedElements["dynamic"] =
    new TypeDefiningElementImpl.dynamic(this.dynamicType);
  }
}

//*-- TypeSystem
abstract class TypeSystem {
  TypeProvider get typeProvider;

  Option<OperatorElement> operateBinary(String operator, MammouthType leftType,
      MammouthType rightType);

  Option<OperatorElement> operateUnary(String operator,
      MammouthType argumentType, bool isPrefix);

  Option<OperatorElement> operateIndex(MammouthType targetType,
      MammouthType indexType);
}

//*-- StrongTypeSystem
class StrongTypeSystem implements TypeSystem {
  @override
  final TypeProvider typeProvider;

  StrongTypeSystem(this.typeProvider);

  @override
  Option<OperatorElement> operateBinary(String operator, MammouthType leftType,
      MammouthType rightType) {
    if(leftType is DynamicType) {
      return new Option<OperatorElement>.Some(null);
    }
    if(leftType is InterfaceType) {
      List<OperatorElement> valableMethods =
      leftType.lookup("operator" + operator).where((ClassMemberElement method) {
        return method is OperatorElement && method.parameters.length == 1 &&
            rightType.isAssignableTo(method.parameters.first.type);
      }).whereType<OperatorElement>().toList();
      if(valableMethods.isNotEmpty) {
        // TODO: if > 1 report error
        return new Option<OperatorElement>.Some(valableMethods.first);
      }
    }
    return new Option<OperatorElement>();
  }

  @override
  Option<OperatorElement> operateUnary(String operator,
      MammouthType argumentType, bool isPrefix) {
    if(argumentType is DynamicType) {
      return new Option<OperatorElement>.Some(null);
    }
    if(argumentType is InterfaceType) {
      List<OperatorElement> valableMethods =
      argumentType.lookup(((isPrefix ? "prefix" : "postfix") + operator))
          .where((ClassMemberElement method) {
        return method is OperatorElement && method.parameters.length == 0;
      }).whereType<OperatorElement>().toList();
      if(valableMethods.isNotEmpty) {
        // TODO: if > 1 report error
        return new Option<OperatorElement>.Some(valableMethods.first);
      }
    }
    return new Option<OperatorElement>();
  }

  @override
  Option<OperatorElement> operateIndex(MammouthType targetType,
      MammouthType indexType) {
    if(targetType is DynamicType) {
      return new Option<OperatorElement>.Some(null);
    }
    if(targetType is InterfaceType) {
      List<OperatorElement> valableMethods = targetType.operators.where((
          OperatorElement method) {
        return method.name == "operator[]" && method.parameters.length == 1 &&
            indexType.isAssignableTo(method.parameters.first.type);
      }).toList();
      if(valableMethods.isNotEmpty) {
        // TODO: if > 1 report error
        return new Option<OperatorElement>.Some(valableMethods.first);
      }
    }
    return new Option<OperatorElement>();
  }
}
