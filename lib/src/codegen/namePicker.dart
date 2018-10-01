class NamePicker {
  final Map<String, String> operatorNames = const <String, String>{
    "|": "bitor",
    "||": "or",
    "&": "bitand",
    "&&": "and",
    "^": "bitxor",
    "==": "equal",
    // TODO: implement not equal as call for !(==)
    "<": "lessthan",
    "<=": "lessthanequal",
    ">": "greaterthan",
    ">=": "greaterthanequal",
    "<<": "shiftleft",
    ">>": "shiftright",
    "+": "plus",
    "-": "minus",
    "*": "mult",
    "**": "pow",
    "/": "div",
    "%": "mod",
    "++": "inc",
    "--": "dec"
  };

  final List<String> alphabets = const <String>[
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'j',
    'h'
  ];

  String pick(String baseName, Set<String> names) {
    int i = -1,
        level = 1;
    String name = baseName;
    if(baseName == "") {
      name = alphabets[0];
    }
    while(names.contains(name)) {
      i++;
      if(i + 1 == alphabets.length) {
        level++;
        i = 0;
      }
      name = baseName + (alphabets[i] * level);
    }
    return name;
  }
}
