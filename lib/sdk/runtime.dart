const String content = r"""
{{
String mammouth_get_type(object) ->
    return native("gettype($1)", object)
bool mammouth_is_assignableTo(String type1, String type2) ->
    type1 == type2 || native("is_subclass_of($1, $2)", type1, type2)
fn mammouth_call_method(object, String methodName) ->
    Array arguments = native("func_get_args()")
    Array argumentTypes = []
    for i in [2..arguments.length]
      argumentTypes.add(mammouth_get_type(arguments[i]))
    String result
    if native('property_exists($1, "__mmt_runtime_map")', object)
      for String method, Array types of native("$1::$__mmt_runtime_map", object)[methodName][arguments.length - 2]
        bool isValid = true
        for int i in [1..types.length]
          String type = types[i]
          if !mammouth_is_assignableTo(argumentTypes[i - 1], type)
            isValid = false
            break
        if isValid
          result = method
          break
      if result?
        native("call_user_func_array(array($1, $2), $3)", object, result, arguments[2...])
      else
        throw "error"
    else
      switch mammouth_get_type(object)
        when "array"
          switch methodName
            when "add"
              return (object as Array).add(arguments[2])
            when "addAll"
              return (object as Array).addAll(arguments[2])
            when "contains"
              return (object as Array).contains(arguments[2])
            when "removeLast"
              return (object as Array).removeLast()
            when "slice"
              if arguments.length == 4
                return (object as Array).slice(arguments[2], arguments[3])
              else
                return (object as Array).slice(arguments[2])
            when "operator[]"
              return (object as Array)[arguments[2]]
        when "float"
          switch methodName
            when "abs"
              return (object as float).abs()
            when "ceil"
              return (object as float).ceil()
            when "floor"
              return (object as float).floor()
            when "remainder"
              return (object as float).remainder(arguments[2])
            when "operator>"
              return (object as float) > arguments[2]
            when "operator<"
              return (object as float) < arguments[2]
            when "operator>="
              return (object as float) >= arguments[2]
            when "operator<="
              return (object as float) <= arguments[2]
            when "operator+"
              return (object as float) + arguments[2]
            when "operator-"
              return (object as float) - arguments[2]
            when "operator*"
              return (object as float) * arguments[2]
            when "operator/"
              return (object as float) / arguments[2]
            when "operator%"
              return (object as float) % arguments[2]
            when "operator=="
              return (object as float) == arguments[2]
            when "operator!="
              return (object as float) != arguments[2]
            when "prefix+"
              return +(object as float)
            when "prefix-"
              return -(object as float)
        when "int"
          switch methodName
            when "abs"
              return (object as int).abs()
            when "ceil"
              return (object as int).ceil()
            when "floor"
              return (object as int).floor()
            when "remainder"
              return (object as int).remainder(arguments[2])
            when "operator>"
              return (object as int) > arguments[2]
            when "operator<"
              return (object as int) < arguments[2]
            when "operator>="
              return (object as int) >= arguments[2]
            when "operator<="
              return (object as int) <= arguments[2]
            when "operator+"
              return (object as int) + arguments[2]
            when "operator-"
              return (object as int) - arguments[2]
            when "operator*"
              return (object as int) * arguments[2]
            when "operator/"
              return (object as int) / arguments[2]
            when "operator%"
              return (object as int) % arguments[2]
            when "operator=="
              return (object as int) == arguments[2]
            when "operator!="
              return (object as int) != arguments[2]
            when "prefix+"
              return +(object as int)
            when "prefix-"
              return -(object as int)
        when "string"
          switch methodName
            when "operator+"
              return (object as String) + arguments[2]
            when "operator=="
              return (object as String) == arguments[2]
            when "operator!="
              return (object as String) != arguments[2]
      throw "error"
fn mammouth_call_converter(object, String targetType) ->
    if native('property_exists($1, "__mmt_runtime_map")', object)
      String result
      for String method, Array types of native("$1::$__mmt_runtime_map", object)["->"][0]
        if mammouth_is_assignableTo(targetType, types[0])
          result = method
          break
      if result?
        native("call_user_func_array(array($1, $2), $3)", object, result, [])
      else
        throw "error"
    else
        throw "error"
fn mammouth_call_getter(object, String getterName) ->
    if native('property_exists($1, "__mmt_runtime_map")', object)
      String result
      for String method, Array types of native("$1::$__mmt_runtime_map", object)[getterName][0]
          result = method
          break
      if result?
        native("call_user_func_array(array($1, $2), $3)", object, result, [])
      throw "error"
    else
      switch mammouth_get_type(object)
        when "array"
          switch getterName
            when "length"
              return (object as Array).length
            when "isEmpty"
              return (object as Array).isEmpty
            when "isNotEmpty"
              return (object as Array).isNotEmpty
            when "reverse"
              return (object as Array).reverse
        when "float"
          switch getterName
            when "isFinite"
              return (object as float).isFinite
            when "isInfinite"
              return (object as float).isInfinite
            when "isNaN"
              return (object as float).isNaN
            when "isNegative"
              return (object as float).isNegative
        when "int"
          switch getterName
            when "isFinite"
              return (object as int).isFinite
            when "isInfinite"
              return (object as int).isInfinite
            when "isNaN"
              return (object as int).isNaN
            when "isNegative"
              return (object as int).isNegative
        when "string"
          switch getterName
            when "length"
              return (object as String).length
            when "isEmpty"
              return (object as String).isEmpty
            when "isNotEmpty"
              return (object as String).isNotEmpty
      throw "error"
fn mammouth_call_setter(object, String setterName, value) ->
    if native('property_exists($1, "__mmt_runtime_map")', object)
      String result
      for String method, Array types of native("$1::$__mmt_runtime_map", object)[setterName][1]
        if mammouth_is_assignableTo(mammouth_get_type(value), types[1])
          result = method
          break
      if result?
        native("call_user_func_array(array($1, $2), $3)", object, result, [value])
      else
        throw "error"
    else
        throw "error"
}}
""";