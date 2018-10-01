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
      else
        throw "error"
    else
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