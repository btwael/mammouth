// imports
var Location = require("./location");
var utils = require("./utils");

// Base node
var Base = function() {};

// Document Node
var Document = function(sections) {
    this.type = 'Document';
    this.sections = sections === undefined ? [] : sections; // List of DocumentSection
    this.location = new Location();
};

Document = utils.extends(Document, Base);

// DocumentSection node
var DocumentSection = function() {
    this.type = 'DocumentSection';
    this.location = new Location();
};

DocumentSection = utils.extends(DocumentSection, Base);

// RAW node
var RAW = function(text) {
    this.type = 'RAW';
    this.text = text === undefined ? '' : text;
    this.location = new Location();
};

RAW = utils.extends(RAW, DocumentSection);

// Script node
var Script = function(body) {
    this.type = 'Script';
    this.body = body === undefined ? new Block() : body;
    this.location = new Location();
};

Script = utils.extends(Script, DocumentSection);

// Block node
var Block = function(statements) {
    this.type = 'Block';
    this.statements = statements === undefined ? [] : statements; // List of Statement
    this.location = new Location();
};

Block = utils.extends(Block, Base);

// Statement node
var Statement = function() {
    this.type = 'Statement';
    this.location = new Location();
};

Statement = utils.extends(Statement, Base);

// Include node
var Include = function(path, isOnce) {
    this.type = 'Include';
    this.path = path === undefined ? null : path;
    this.isOnce = isOnce === undefined ? false : isOnce;
    this.location = new Location();
}

Include = utils.extends(Include, Statement);

// Require node
var Require = function(path, isOnce) {
    this.type = 'Require';
    this.path = path === undefined ? null : path;
    this.isOnce = isOnce === undefined ? false : isOnce;
    this.location = new Location();
}

Require = utils.extends(Require, Statement);

// Section node
var Section = function(name) {
    this.type = 'Section';
    this.name = name === undefined ? null : name;
    this.location = new Location();
};

Section = utils.extends(Section, Statement);

// Delete node
var Delete = function(argument) {
    this.type = 'Delete';
    this.argument = argument;
    this.location = new Location();
};

Delete = utils.extends(Delete, Statement);

// Global node
var Global = function(args) {
    this.type = 'Global';
    this.arguments = args;
    this.location = new Location();
};

Global = utils.extends(Global, Statement);

// Break node
var Break = function(argument) {
    this.type = 'Break';
    this.argument = argument === undefined ? null : argument;
    this.location = new Location();
};

Break = utils.extends(Break, Statement);

// Continue node
var Continue = function(argument) {
    this.type = 'Continue';
    this.argument = argument === undefined ? null : argument;
    this.location = new Location();
};

Continue = utils.extends(Continue, Statement);

// Return node
var Return = function(argument) {
    this.type = 'Return';
    this.argument = argument === undefined ? null : argument;
    this.location = new Location();
};

Return = utils.extends(Return, Statement);

// Throw node
var Throw = function(argument) {
    this.type = 'Throw';
    this.argument = argument === undefined ? null : argument;
    this.location = new Location();
};

Throw = utils.extends(Throw, Statement);

// Goto node
var Goto = function(section) {
    this.type = 'Goto';
    this.section = section === undefined ? null : section;
    this.location = new Location();
};

Goto = utils.extends(Goto, Statement);

// Constant node
var Constant = function(name, value) {
    this.type = 'Constant';
    this.name = name;
    this.value = value;
    this.location = new Location();
};

Constant = utils.extends(Constant, Statement);

// ExpressionStatement node
var ExpressionStatement = function(expression) {
    this.type = 'ExpressionStatement';
    this.expression = expression;
    this.location = new Location();
};

ExpressionStatement = utils.extends(ExpressionStatement, Statement);

// Expression node
var Expression = function() {
    this.type = 'Expression';
    this.location = new Location();
};

Expression = utils.extends(Expression, Base);

// For node
var If = function(condition, body) {
    this.type = 'If';
    this.condition = condition;
    this.body = body === undefined ? null : body;
    this.elses = [];  
    this.location = new Location();
};

If = utils.extends(If, Expression);

var ElseIf = function(condition, body) {
    this.type = 'ElseIf';
    this.condition = condition;
    this.body = body === undefined ? null : body;    
    this.location = new Location();
};

ElseIf = utils.extends(ElseIf, Expression);

var Else = function(body) {
    this.type = 'Else';
    this.body = body === undefined ? null : body;    
    this.location = new Location();
};

Else = utils.extends(Else, Expression);

// For node
var For = function(source, body) {
    this.type = 'For';
    this.source = source;
    this.body = body === undefined ? null : body;    
    this.location = new Location();
};

For = utils.extends(For, Expression);

// While node
var While = function(test, invert, guard, body) {
    this.type = 'While';
    this.test = test;
    this.invert = invert === undefined ? false : invert;
    this.guard = guard === undefined ? null : guard;
    this.body = body === undefined ? null : body;    
    this.location = new Location();
};

While = utils.extends(While, Expression);

// Try node
var Try = function() {
    this.type = 'Try';
    this.tryBody = null;
    this.catchIdentifier = null;
    this.catchBody = null;
    this.finallyBody = null;
    this.location = new Location();
};

Try = utils.extends(Try, Expression);

// Switch node
var Switch = function() {
    this.type = 'Switch';
    this.subject = null;
    this.whens = [];
    this.otherwise = null;
    this.location = new Location();
};

Switch = utils.extends(Switch, Expression);

// Assignement node
var Assignement = function(operator, left, right) {
    this.type = 'Assignement';
    this.operator = operator;
    this.left = left;
    this.right = right;
    this.location = new Location();
};

Assignement = utils.extends(Assignement, Expression);

// Keys Assignement node
var KeysAssignement = function(keys, right) {
    this.type = 'KeysAssignement';
    this.keys = keys === undefined ? [] : keys;
    this.right = right === undefined ? null : right;
    this.location = new Location();
};

KeysAssignement = utils.extends(KeysAssignement, Expression);

// Operation node
var Operation = function(operator, left, right) {
    this.type = 'Operation';
    this.operator = operator;
    this.left = left;
    this.right = right;
    this.location = new Location();
};

Operation = utils.extends(Operation, Expression);

// Operation node
var CastTyping = function(argument, castType) {
    this.type = 'CastTyping';
    this.argument = argument;
    this.castType = castType;
    this.location = new Location();
};

CastTyping = utils.extends(CastTyping, Expression);

// Unary node
var Unary = function(operator, argument) {
    this.type = 'Unary';
    this.operator = operator;
    this.argument = argument;
    this.location = new Location();
};

Unary = utils.extends(Unary, Expression);

// Update node
var Update = function(operator, argument, prefix) {
    this.type = 'Update';
    this.operator = operator;
    this.argument = argument;
    this.prefix = prefix;
    this.location = new Location();
};

Update = utils.extends(Update, Expression);

// Clone node
var Clone = function(operator, argument) {
    this.type = 'Clone';
    this.operator = operator;
    this.argument = argument;
    this.location = new Location();
};

Clone = utils.extends(Clone, Expression);

// Echo node
var Echo = function(argument) {
    this.type = 'Echo';
    this.argument = argument;
    this.location = new Location();
};

Echo = utils.extends(Echo, Expression);

// Value node
var Value = function() {
    this.type = 'Value';
    this.location = new Location();
};

Value = utils.extends(Value, Base);

// New node
var New = function(operator, argument) {
    this.type = 'New';
    this.operator = operator;
    this.argument = argument;
    this.location = new Location();
};

New = utils.extends(New, Base);

// Member node
var Member = function(operator, base, property) {
    this.type = 'Member';
    this.base = base;
    this.property = property;
    this.operator = operator === undefined ? '.' : operator;
    this.location = new Location();
};

Member = utils.extends(Member, Value);

// Call node
var Call = function(callee, args) {
    this.type = 'Call';
    this.callee = callee;
    this.args = args;
    this.location = new Location();
};

Call = utils.extends(Call, Value);

// Index node
var Index = function(base, property) {
    this.type = 'Index';
    this.base = base;
    this.property = property;
    this.location = new Location();
};

Index = utils.extends(Index, Value);

// Slice node
var Slice = function(base, range) {
    this.type = 'Slice';
    this.base = base;
    this.range = range;
    this.location = new Location();
};

Slice = utils.extends(Slice, Value);

// Existance node
var Existance = function(value) {
    this.type = 'Existance';
    this.value = value;
    this.location = new Location();
};

Existance = utils.extends(Existance, Value);

// Array node
var ArrayNode = function(elements) {
    this.type = 'Array';
    this.elements = elements === undefined ? [] : elements;
    this.location = new Location();
};

ArrayNode = utils.extends(ArrayNode, Value);

// Array key node
var ArrayKey = function(key, value) {
    this.type = 'ArrayKey';
    this.key = key;
    this.value = value;
    this.location = new Location();
};

ArrayKey = utils.extends(ArrayKey, Base);

// Range node
var Range = function(from, to, rangeOperator) {
    this.type = 'Range';
    this.from = from;
    this.to = to;
    this.rangeOperator = rangeOperator;
    this.location = new Location();
};

Range = utils.extends(Range, Value);

// Parenthetical node
var Parenthetical = function(expression) {
    this.type = 'Parenthetical';
    this.expression = expression;
    this.location = new Location();
};

Parenthetical = utils.extends(Parenthetical, Value);

// Identifier node
var Identifier = function(name) {
    this.type = 'Identifier';
    this.name = name;
    this.isThis = false;
    if(this.name == 'this') {
        this.isThis = true;
        this.isAt = false;
    }
    this.location = new Location();
};

Identifier = utils.extends(Identifier, Value);

// Literal node
var Literal = function(value, subtype) {
    this.type = 'Literal';
    this.subtype = subtype;
    this.value = value;
    this.location = new Location();
};

Literal = utils.extends(Literal, Value);

// Code (functions) node
var Code = function() {
    this.type = 'Code';
    this.parameters = [];
    this.isAnonymous = true;
    this.name = null;
    this.hasBody = false;
    this.body = null;
    this.withUses = false;
    this.uses = [];
    this.location = new Location();
};

Code = utils.extends(Code, Value);

// Parameter node
var Parameter = function(name, isPassing) {
    this.type = 'Parameter';
    this.name = name === undefined ? null : name;
    this.isPassing = isPassing === undefined ? false : isPassing;
    this.hasDefault = false;
    this.default = null;
    this.location = new Location();
};

Parameter = utils.extends(Parameter, Base);

// Casting type node
var CastType = function(name) {
    this.type = 'CastType';
    this.name = name;
    this.location = new Location();
};

CastType = utils.extends(CastType, Value);

// Operator node
var Operator = function(symbol, subtype) {
    this.type = 'Operator';
    this.subtype = subtype === undefined ? null : subtype;
    this.symbol = symbol;
    this.precedence = 1;
    this.location = new Location();
};

Operator = utils.extends(Operator, Base);

// Namespace node
var Namespace = function(name, body) {
    this.type = 'Namespace';
    this.name = name === undefined ? null : name;
    this.body = body === undefined ? null : body;
    this.location = new Location();
};

Namespace = utils.extends(Namespace, Statement);

// Namespace name node
var NamespaceName = function() {
    this.type = 'NamespaceName';
    this.nameSequence = [];
    this.startWithBackSlash = false;
    this.location = new Location();
};

NamespaceName = utils.extends(NamespaceName, Value);

// Class node
var Class = function() {
    this.type = 'Class';
    this.modifier = null;
    this.name = null;
    this.extends = null;
    this.implements = null;
    this.members = null;
    this.location = new Location();
};

Class = utils.extends(Class, Statement);

// Class member node
var ClassMember = function() {
    this.type = 'ClassMember';
    this.isAbstract = false;
    this.isFinal = false;
    this.visibility = null;
    this.isStatic = false;
    this.member = null;
    this.location = new Location();
};

ClassMember = utils.extends(ClassMember, Base);

// Interface node
var Interface = function() {
    this.type = 'Interface';
    this.name = null;
    this.extends = null;
    this.members = null;
    this.location = new Location();
};

Interface = utils.extends(Interface, Statement);

// Use statement node
var Use = function() {
    this.type = 'Use';
    this.isConstFunc = null;
    this.clauses = [];
    this.location = new Location();
};

Use = utils.extends(Use, Statement);


// exports
exports.Base = Base;

exports.Document = Document;
exports.DocumentSection = DocumentSection;
exports.RAW = RAW;
exports.Script = Script;

exports.Block = Block;
exports.Statement = Statement;
exports.Include = Include;
exports.Require = Require;
exports.Section = Section;
exports.Delete = Delete;
exports.Global = Global;
exports.Break = Break;
exports.Continue = Continue;
exports.Return = Return;
exports.Throw = Throw;
exports.Goto = Goto;
exports.Constant = Constant;
exports.ExpressionStatement = ExpressionStatement;

exports.Expression = Expression;
exports.If = If;
exports.ElseIf = ElseIf;
exports.Else = Else;
exports.For = For;
exports.While = While;
exports.Try = Try;
exports.Switch = Switch;
exports.Assignement = Assignement;
exports.KeysAssignement = KeysAssignement;
exports.Operation = Operation;
exports.CastTyping = CastTyping;
exports.Unary = Unary;
exports.Update = Update;
exports.Clone = Clone;
exports.Echo = Echo;

exports.Value = Value;
exports.New = New;
exports.Member = Member;
exports.Call = Call;
exports.Index = Index;
exports.Slice = Slice;
exports.Existance = Existance;
exports.Array = ArrayNode;
exports.ArrayKey = ArrayKey;
exports.Range = Range;
exports.Parenthetical = Parenthetical;
exports.Identifier = Identifier;
exports.Literal = Literal;
exports.Code = Code;
exports.Parameter = Parameter;

exports.CastType = CastType;
exports.Operator = Operator;

exports.Namespace = Namespace;
exports.NamespaceName = NamespaceName;
exports.Class = Class;
exports.ClassMember = ClassMember;
exports.Interface = Interface;
exports.Use = Use;