const String content = r"""
{{
class bool
  public bool prefix! inline ->
    native("!$1", this)
  public bool operator||(other) inline ->
    native("$1 || $2", this, other)
}}
{{
class float
  public float operator+(float other) inline ->
    native("$1 + $2", this, other)
  public float operator-(float other) inline ->
    native("$1 - $2", this, other)
  public float operator*(float other) inline ->
    native("$1 * $2", this, other)
  public float operator/(float other) inline ->
    native("$1 / $2", this, other)
  public float prefix- inline ->
    native("-$1", this)
}}
{{
class int
  public bool operator>(int other) inline ->
    native("$1 > $2", this, other)
  public bool operator<(int other) inline ->
      native("$1 < $2", this, other)
  public int operator+(int other) inline ->
    native("$1 + $2", this, other)
  public int operator-(int other) inline ->
    native("$1 - $2", this, other)
  public int operator*(int other) inline ->
    native("$1 * $2", this, other)
  public int operator/(int other) inline ->
    native("$1 / $2", this, other)
  public bool operator==(int other) inline ->
    native("$1 == $2", this, other)
  public bool operator!=(int other) inline ->
      native("$1 != $2", this, other)
  public int prefix- inline ->
    native("-$1", this)
  public float to inline ->
    native("((float) $1)", this)
  public String to inline ->
    native("((string) $1)", this)
}}
{{
interface Countable
  int count() inline
}}
{{
interface Sliceable
  Sliceable slice(int start, [int end = 12]) inline
}}
{{
class Array<T>
  constructor() inline ->
    native("array()")
  public fn add(T element) inline ->
    native("array_push($1, $2)", this, element)
  public fn addAll(Array<T> elements) inline ->
    this.add(element) for T element in elements
  public bool contains(T element) inline ->
    native("in_array($1, $2)", element, this)
  public fn removeLast() inline ->
    native("array_pop($1)", this)
  public int get length inline ->
    native("count($1)", this)
  public bool get isEmpty inline ->
    this.length == 0
  public bool get isNotEmpty inline ->
    this.length > 0
  public Array<T> get reverse inline ->
    native("array_reverse($1)", this)
  public Array<T> slice(int start, [int end]) inline ->
    native("array_slice($1, $2, $3)", this, start, end - start if end? else null)
  public T operator[](int index) inline ->
    native("$1[$2]", this, index)
}}
{{
class String
  public bool get isEmpty inline ->
    this.length == 0
  public bool get isNotEmpty inline ->
    this.length != 0
  public int get length inline ->
    native("strlen($1)", this)
  public String operator+(String other) inline ->
    native("$1.$2", this, other)
  public bool operator==(String other) inline ->
    native("$1 == $2", this, other)
  public bool operator!=(String other) inline ->
    native("$1 != $2", this, other)
}}
""";