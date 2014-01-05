mammouth.VERSION = '0.2.0';
mammouth.compile = function(code) {
	Tokens = mammouth.Tokens;
	var Use_Slice_Function = false;
	var Added_Slice_Function = false;
	var Use_Len_Function = false;
	var Added_Len_Function = false;
	FunctionInAssignment = function(seq) {
		var r = Tokens.FunctionToken;
		var arguments = '(';
		for (var i = 0; i < seq.right.params.length; i++) {
			if( i != 0 ) {
				arguments += ', '
			}
			arguments += evalStatement(seq.right.params[i]);
		};
		arguments += ')';
		r += arguments;
		r += ' {';
		if(seq.right.body != null) {
			var body = '';
			for(var j = 0; j < seq.right.body.length; j++) {
				if(typeof seq.right.body[j] == 'undefined') {
					body += '\n';
				} else {
					seq.right.body[j].only = true;
					if(typeof seq.right.body[j] == 'string') {
						body += evalStatement(seq.right.body[j]);
					} else {
						body += evalStatement(seq.right.body[j]) + '\n';
					}
				}
			}
			var pars = mammouth.LineTerminatorParser.parse(body);
			for(var x = 0; x < pars.length; x++) {
				if(pars[x] != '' || x == 0) {
					if(x == (pars.length - 1)) {
						r += '\t' + pars[x];
					} else {
						if(seq.right.body.length == 1) {
							r += '\t' + pars[x];
						} else {
							r += '\t' + pars[x] + '\n';
						}
					}
				} else if(typeof pars[x] == 'undefined') {
					r += '\n';
				} else {
					r += pars[x];
				}
			}
		}
		r += '}';
		return r;
	};
	evalStatement = function(seq) {
		if(typeof seq == 'string') {
			return seq;
		}
		if(seq == null) {
			return '';
		}
		switch(seq.type) {
			case 'embed':
				return seq.content;
			case 'block':
				var r = '';
				for(var i = 0; i < seq.elements.length; i++) {
					if(typeof seq.elements[i] == 'undefined') {
						
					} else {
						seq.elements[i].only = true;
						if(typeof seq.elements[i] == 'string') {
							r += evalStatement(seq.elements[i]);
						} else {
							r += evalStatement(seq.elements[i]) + '\n';
						}
					}
				}
				if(Use_Slice_Function == true && Added_Slice_Function == false) {
					r = mammouth.helpers.slice_php_function + '\n' + r;
					Added_Slice_Function = true;
				}
				if(Use_Len_Function == true && Added_Len_Function == false) {
					r = mammouth.helpers.len_php_function + '\n' + r;
					Added_Len_Function = true;
				}
				r = '<?php \n' + r;
				return r + '?>';
			case 'blockwithoutbra':
				var r = '';
				for(var i = 0; i < seq.elements.length; i++) {
					if(typeof seq.elements[i] == 'undefined') {
						r += '\n';
					} else {
						seq.elements[i].only = true;
						if(typeof seq.elements[i] == 'string') {
							r += evalStatement(seq.elements[i]);
						} else {
							r += evalStatement(seq.elements[i]) + '\n';
						}
					}
				}
				return r;
			case 'NumericLiteral':
				var r = seq.value;
				if(seq.only==true) {
					r += ';';
				}
				return r;
			case 'BooleanLiteral':
				var r = seq.value;
				if(seq.only==true) {
					r += ';';
				}
				return r;
			case 'StringLiteral':
				var r = "'" + seq.value + "'";
				if(seq.only==true) {
					r += ';';
				}
				return r;
			case 'ArrayLiteral':
				var r = 'array(';
				var elements = '';
				if(seq.elements != '') {
					for (var i = 0; i < seq.elements.length; i++) {
						if( i != 0 ) {
							elements += ', '
						}
						elements += evalStatement(seq.elements[i]);
					};
				}
				r += elements + ')'; 
				if(seq.only==true) {
					r += ';';
				}
				return r;
			case 'EODLiteral':
				r = '<<<EOD' + '\n';
				r += seq.value +'\n';
				r += 'EOD';
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'EOTLiteral':
				r = '<<<EOT' + '\n';
				r += seq.value +'\n';
				r += 'EOT';
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'Variable':
				var r = '$' + evalStatement(seq.name);
				if(seq.only==true) {
					r += ';';
				}
				return r;
			case 'This':
				var r = '$this';
				if(seq.only==true) {
					r += ';';
				}
				return r;
			case 'NullLiteral':
				var r = 'NULL';
				if(seq.only==true) {
					r += ';';
				}
				return r;
			case 'VariableConst':
				var r = '$' + '__' + evalStatement(seq.name) + '__';
				if(seq.only==true) {
					r += ';';
				}
				return r;
			case 'ReferenceVariable':
				var r = '&$' + evalStatement(seq.name);
				return r;
			case 'PropertyAccess':
				var b = evalStatement(seq.base);
				var n, r;
				if(typeof seq.name == 'object') {
					n = seq.name;
					r = b + '::' + n[0];
				} else if(typeof seq.name == 'string') {
					n = seq.name;
					r = b + '->' + n;
				} else {
					n = '[' + evalStatement(seq.name) + ']'
					r = b + n;
				} 
				if(seq.only==true) {
					r += ';';
				}
				return r;
			case 'NewOperator':
				var r = Tokens.NewToken;
				var constructor = evalStatement(seq.constructor);
				var arguments = '(';
				for (var i = 0; i < seq.arguments.length; i++) {
					if( i != 0 ) {
						arguments += ', '
					}
					arguments += evalStatement(seq.arguments[i]);
				};
				arguments += ')';
				r += ' ' + constructor + arguments;
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'BinaryExpression':
				if(seq.left.type == 'BinaryExpression') {
					if(seq.left.operator != '.') {
						seq.left.Parentheses = true;
					}
				}
				var left = evalStatement(seq.left);
				if(seq.right.type == 'BinaryExpression') {
					if(seq.right.operator != '.') {
						seq.right.Parentheses = true;
					}
				}
				var right = evalStatement(seq.right);
				if(seq.operator != '.') {
					var operator = ' ' + seq.operator + ' ';
				} else {
					var operator = seq.operator;
				}
				var r = left + operator + right;
				if(seq.Parentheses == true) {
					r = '(' + r;
					r += ')';
				}
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'PostfixExpression':
				if(seq.expression.type == 'BinaryExpression') {
					seq.expression.Parentheses = true;
				}
				var expression = evalStatement(seq.expression);
				var operator = seq.operator;
				var r = expression + operator;
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'UnaryExpression':
				if(seq.expression.type == 'BinaryExpression') {
					seq.expression.Parentheses = true;
				}
				var expression = evalStatement(seq.expression);
				var operator = seq.operator;
				var r = operator + expression;
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'AssignmentExpression':
				var left = evalStatement(seq.left);
				var right;
				if(seq.right.type == 'Function') {
					right = FunctionInAssignment(seq);
				} else {
					right = evalStatement(seq.right);
				}
				var operator = ' ' + seq.operator + ' ';
				var r = left + operator + right;
				if(seq.Parentheses == true) {
					r = '(' + r;
					r += ')';
				}
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'AssignmentExpressionOfFunction':
				var left = evalStatement(seq.left);
				var right = evalStatement(seq.right);
				var operator = ' ' + seq.operator + ' ';
				var r = left + operator + right;
				if(seq.Parentheses == true) {
					r = '(' + r;
					r += ')';
				}
				return r;
			case 'ConditionalExpression':
				if(seq.condition.type == 'BinaryExpression') {
					seq.condition.Parentheses = true;
				}
				var condition = evalStatement(seq.condition);
				var trueExpression = evalStatement(seq.trueExpression);
				var falseExpression = evalStatement(seq.falseExpression);
				var r = condition + ' ? ' + trueExpression + ' : ' + falseExpression; 
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'break':
				var r = 'break'
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'FunctionCall':
				var name;
				if(seq.name.type == 'PropertyAccess') {
					name = evalStatement(seq.name);
				} else {
					name = evalStatement(seq.name.name);
				}
				var arguments = '(';
				for (var i = 0; i < seq.arguments.length; i++) {
					if( i != 0 ) {
						arguments += ', '
					}
					arguments += evalStatement(seq.arguments[i]);
				};
				arguments += ')';
				r = name + arguments;
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'SliceExpression':
				var r = '';
				Use_Slice_Function = true;
				var end = evalStatement(seq.end);
				var start = evalStatement(seq.start);
				if(seq.end == null) {
					Use_Len_Function = true;
					end = '_m_len(' + evalStatement(seq.slicer) + ')';
				}
				if(seq.start == 0) {
					start = 0;
				}
				r += '_m_slice(' + evalStatement(seq.slicer) + ', ' + start + ', ' + end + ')';
				if(seq.only == true) {
					r += ';';
				}
				return r;
			case 'IfStatement':
				var r = Tokens.IfToken;
				var condition = '(';
				condition += evalStatement(seq.condition);
				condition += ')';
				r += condition;
				r += ' {';
				var body = '';
				if(seq.ifStatement != null) {
					for(var j = 0; j < seq.ifStatement.length; j++) {
						if(typeof seq.ifStatement[j] == 'undefined') {
							body += '\n';
						} else {
							seq.ifStatement[j].only = true;
							if(typeof seq.ifStatement[j] == 'string') {
								body += evalStatement(seq.ifStatement[j]);
							} else {
								body += evalStatement(seq.ifStatement[j]) + '\n';
							}
						}
					}
					r += '\n';
					var pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '') {
							if(seq.ifStatement.length == 1) {
								r += '\t' + pars[x] + '\n';
							} else {
								r += '\t' + pars[x] + '\n';
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							r += pars[x];
						}
					}
				} else {
					r += '\n'
				}
				r += '}';
				if(seq.elseifStatement != null) {
					for (var i = 0; i < seq.elseifStatement.length; i++) {
						r += ' ' + Tokens.ElseToken + Tokens.IfToken;
						condition = '(';
						condition += evalStatement(seq.elseifStatement[i].condition);
						condition += ')';
						r += condition;
						r += ' {';
						body = '';
						for(var j = 0; j < seq.elseifStatement[i].statement.length; j++) {
							if(typeof seq.elseifStatement[i].statement[j] == 'undefined') {
								body += '\n';
							} else {
								seq.elseifStatement[i].statement[j].only = true;
								if(typeof seq.elseifStatement[i][j] == 'string') {
									body += evalStatement(seq.elseifStatement[i].statement[j]);
								} else {
									body += evalStatement(seq.elseifStatement[i].statement[j]) + '\n';
								}
							}
						}
						r += '\n';
						var pars = mammouth.LineTerminatorParser.parse(body);
						for(var x = 0; x < pars.length; x++) {
							if(pars[x] != '') {
								if(seq.elseifStatement[i].length == 1) {
									r += '\t' + pars[x] + '\n';
								} else {
									r += '\t' + pars[x] + '\n';
								}
							} else if(typeof pars[x] == 'undefined') {
								r += '\n';
							} else {
								r += pars[x];
							}
						}
						r += '}';
					};
				}
				if(seq.elseStatement != null) {
					body = '';
					for(var j = 0; j < seq.elseStatement.length; j++) {
						if(typeof seq.elseStatement[j] == 'undefined') {
							body += '\n';
						} else {
							seq.elseStatement[j].only = true;
							if(typeof seq.elseStatement[j] == 'string') {
								body += evalStatement(seq.elseStatement[j]);
							} else {
								body += evalStatement(seq.elseStatement[j]) + '\n';
							}
						}
					}
					r += ' ' + Tokens.ElseToken;
					r += ' {';
					r += '\n';
					var pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '') {
							if(seq.elseStatement.length == 1) {
								r += '\t' + pars[x] + '\n';
							} else {
								r += '\t' + pars[x] + '\n';
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							r += pars[x];
						}
					}
					r += '}';
				}
				return r;
			case 'ForStatement':
				var r = Tokens.ForToken + '(';
				if(seq.initializer.type == 'BinaryExpression') {
					if(seq.initializer.operator == 'of') {
						seq.test = {
							"type": "BinaryExpression",
							"operator": "<",
							"left": seq.initializer.left,
							"right": {
								"type": "FunctionCall",
								"name": {
									"type": "Variable",
									"name": "count"
								},
								"arguments": [
									seq.initializer.right
								]
							}
						};
						seq.counter = {
							"type": "PostfixExpression",
							"operator": "++",
							"expression": {
								"type": "Variable",
								"name": "i"
							}
						};
						if(seq.statement !== null) {
							seq.statement.splice(0, 0, {
								"type": "AssignmentExpression",
								"operator": "=",
								"left": seq.initializer.left,
								"right": {
									"type": "PropertyAccess",
									"base": seq.initializer.right,
									"name": {
										"type": "Variable",
										"name": "i"
									}
								}
							});
						}
						seq.initializer = {
							"type": "AssignmentExpression",
							"operator": "=",
							"left": {
									"type": "Variable",
									"name": "i"
								},
							"right": {
								"type": "NumericLiteral",
								"value": 0
							}
						};
					}
				}
				r += evalStatement(seq.initializer) + '; ';
				r += evalStatement(seq.test) + '; ';
				r += evalStatement(seq.counter);
				r += ')';
				r += ' {';
				var body = '';
				if(seq.statement !== null) {
					for(var j = 0; j < seq.statement.length; j++) {
						if(typeof seq.statement[j] == 'undefined') {
							body += '\n';
						} else {
							seq.statement[j].only = true;
							if(typeof seq.statement[j] == 'string') {
								body += evalStatement(seq.statement[j]);
							} else {
								body += evalStatement(seq.statement[j]) + '\n';
							}
						}
					}
					r += '\n';
					var pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '') {
							if(seq.statement.length == 1) {
								r += '\t' + pars[x] + '\n';
							} else {
								r += '\t' + pars[x] + '\n';
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							r += pars[x];
						}
					}
				} else {
					r += '\n';
				}
				r += '}';
				return r;
			case 'WhileStatement':
				var r = Tokens.WhileToken + '(';
				r += evalStatement(seq.condition);
				r += ')';
				r += ' {';
				var body = '';
				for(var j = 0; j < seq.statement.length; j++) {
					if(typeof seq.statement[j] == 'undefined') {
						body += '\n';
					} else {
						seq.statement[j].only = true;
						if(typeof seq.statement[j] == 'string') {
							body += evalStatement(seq.statement[j]);
						} else {
							body += evalStatement(seq.statement[j]) + '\n';
						}
					}
				}
				if(seq.statement != "") {
					body = '';
					for(var j = 0; j < seq.statement.length; j++) {
						if(typeof seq.statement[j] == 'undefined') {
							body += '\n';
						} else {
							seq.statement[j].only = true;
							if(typeof seq.statement[j] == 'string') {
								body += evalStatement(seq.statement[j]);
							} else {
								body += evalStatement(seq.statement[j]) + '\n';
							}
						}
					}
					r += '\n';
					pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '' || x == 0) {
							if(x == (pars.length - 1)) {
								r += '\t' + pars[x];
							} else {
								if(seq.statement.length == 1) {
									r += '\t' + pars[x];
								} else {
									r += '\t' + pars[x] + '\n';
								}
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							if(x == 1) {
								r += pars[x];
							}
						}
					}
				}
				r += '\n}';
				return r;
			case 'SwitchStatement':
				var r = Tokens.SwitchToken + '(';
				r += evalStatement(seq.variable);
				r += ')';
				r += ' {\n';
				var CasesBlock = '';
				for(var i = 0; i < seq.cases.length; i++) {
					if(typeof seq.cases[i] != 'undefined') {
						if(seq.cases[i].type == 'case') {
							CasesBlock += Tokens.CaseToken + ' ' + evalStatement(seq.cases[i].value) + ':\n';
							if(seq.cases[i].statement != '') {
								seq.cases[i].statement.push({
									type: 'break'
								})
								var body = '';
								for(var j = 0; j < seq.cases[i].statement.length; j++) {
									if(typeof seq.cases[i].statement[j] == 'undefined') {
										body += '\n';
									} else {
										seq.cases[i].statement[j].only = true;
										if(typeof seq.cases[i].statement[j] == 'string') {
											body += evalStatement(seq.cases[i].statement[j]);
										} else {
											body += evalStatement(seq.cases[i].statement[j]) + '\n';
										}
									}
								}
								var pars = mammouth.LineTerminatorParser.parse(body);
								for(var x = 0; x < pars.length; x++) {
									if(pars[x] != '' || x == 0) {
										if(x == (pars.length - 1)) {
											CasesBlock += '\t' + pars[x];
										} else {
											if(seq.cases[i].statement.length == 1) {
												CasesBlock += '\t' + pars[x];
											} else {
												CasesBlock += '\t' + pars[x] + '\n';
											}
										}
									} else if(typeof pars[x] == 'undefined') {
										CasesBlock += '\n';
									} else {
										CasesBlock += pars[x];
									}
								}
							}
						}
					}
				}
				if(seq.elsed != '') {
					CasesBlock += Tokens.DefaultToken + ':';
					seq.elsed.unshift(undefined);
					var body = '';
					for(var j = 0; j < seq.elsed.length; j++) {
						if(typeof seq.elsed[j] == 'undefined') {
							body += '\n';
						} else {
							seq.elsed[j].only = true;
							if(typeof seq.elsed[j] == 'string') {
								body += evalStatement(seq.elsed[j]);
							} else {
								body += evalStatement(seq.elsed[j]) + '\n';
							}
						}
					}
					var pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '' || x == 0) {
							if(x == (pars.length - 1)) {
								CasesBlock += '\t' + pars[x];
							} else {
								if(seq.elsed.length == 1) {
									CasesBlock += '\t' + pars[x];
								} else {
									CasesBlock += '\t' + pars[x] + '\n';
								}
							}
						} else if(typeof pars[x] == 'undefined') {
							CasesBlock += '\n';
						} else {
							CasesBlock += pars[x];
						}
					}
				}
				var pars = mammouth.LineTerminatorParser.parse(CasesBlock);
				for(var x = 0; x < pars.length; x++) {
					if(pars[x] != '' || x == 0) {
						if(x == (pars.length - 1)) {
							r += '\t' + pars[x];
						} else {
							if(seq.cases.length == 1) {
								r += '\t' + pars[x];
							} else {
								r += '\t' + pars[x] + '\n';
							}
						}
					} else if(typeof pars[x] == 'undefined') {
						r += '\n';
					} else {
						r += pars[x];
					}
				}
				r += '}';
				return r;
			case 'TryStatement':
				var r = Tokens.TryToken;
				r += ' {\n';
				if(seq.TryStatement != null) {
					var body = '';
					for(var j = 0; j < seq.TryStatement.length; j++) {
						if(typeof seq.TryStatement[j] == 'undefined') {
							body += '\n';
						} else {
							seq.TryStatement[j].only = true;
							if(typeof seq.TryStatement[j] == 'string') {
								body += evalStatement(seq.TryStatement[j]);
							} else {
								body += evalStatement(seq.TryStatement[j]) + '\n';
							}
						}
					}
					var pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '' || x == 0) {
							if(x == (pars.length - 1)) {
								r += '\t' + pars[x];
							} else {
								if(seq.TryStatement.length == 1) {
									r += '\t' + pars[x];
								} else {
									r += '\t' + pars[x] + '\n';
								}
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							if(x == 1) {
								r += '\n';
							}
						}
					}
				}
				r += '}'
				r += ' ' + Tokens.CatchToken + '(';
				r += seq.CatchErrVar.vtype + ' ' + evalStatement(seq.CatchErrVar.name);
				r += ')';
				r += ' {\n';
				if(seq.CatchStatement != null) {
					body = '';
					for(var j = 0; j < seq.CatchStatement.length; j++) {
						if(typeof seq.CatchStatement[j] == 'undefined') {
							body += '\n';
						} else {
							seq.CatchStatement[j].only = true;
							if(typeof seq.CatchStatement[j] == 'string') {
								body += evalStatement(seq.CatchStatement[j]);
							} else {
								body += evalStatement(seq.CatchStatement[j]) + '\n';
							}
						}
					}
					pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '' || x == 0) {
							if(x == (pars.length - 1)) {
								r += '\t' + pars[x];
							} else {
								if(seq.CatchStatement.length == 1) {
									r += '\t' + pars[x];
								} else {
									r += '\t' + pars[x] + '\n';
								}
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							if(x == 1) {
								r += '\n';
							}
						}
					}
				}
				r += '}'
				if(seq.FinallyStatemnt != null) {
					r += ' ' + Tokens.FinallyToken;
					r += ' {\n';
					body = '';
					for(var j = 0; j < seq.FinallyStatemnt.length; j++) {
						if(typeof seq.FinallyStatemnt[j] == 'undefined') {
							body += '\n';
						} else {
							seq.FinallyStatemnt[j].only = true;
							if(typeof seq.FinallyStatemnt[j] == 'string') {
								body += evalStatement(seq.FinallyStatemnt[j]);
							} else {
								body += evalStatement(seq.FinallyStatemnt[j]) + '\n';
							}
						}
					}
					pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '' || x == 0) {
							if(x == (pars.length - 1)) {
								r += '\t' + pars[x];
							} else {
								if(seq.FinallyStatemnt.length == 1) {
									r += '\t' + pars[x];
								} else {
									r += '\t' + pars[x] + '\n';
								}
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							if(x == 1) {
								r += '\n';
							}
						}
					}
					r += '}'
				}
				return r;
			case 'FunctionDeclaration':
				var r = Tokens.FunctionToken;
				r += ' ' + evalStatement(seq.name);
				var arguments = '(';
				for (var i = 0; i < seq.params.length; i++) {
					if( i != 0 ) {
						arguments += ', '
					}
					arguments += evalStatement(seq.params[i]);
				};
				arguments += ')';
				r += arguments;
				r += ' {';
				if(seq.body != null) {
					var body = '';
					for(var j = 0; j < seq.body.length; j++) {
						if(typeof seq.body[j] == 'undefined') {
							body += '\n';
						} else {
							seq.body[j].only = true;
							if(typeof seq.body[j] == 'string') {
								body += evalStatement(seq.body[j]);
							} else {
								body += evalStatement(seq.body[j]) + '\n';
							}
						}
					}
					var pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '' || x == 0) {
							if(x == (pars.length - 1)) {
								r += '\t' + pars[x];
							} else {
								if(seq.body.length == 1) {
									r += '\t' + pars[x];
								} else {
									r += '\t' + pars[x] + '\n';
								}
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							r += pars[x];
						}
					}
				}
				r += '}';
				return r;
			case 'NamespaceDeclaration':
				var r = Tokens.NamespaceToken + ' ' + evalStatement(seq.name);
				if(seq.body != null) {
					r += ' {';
					var body = '';
					for(var j = 0; j < seq.body.length; j++) {
						if(typeof seq.body[j] == 'undefined') {
							body += '\n';
						} else {
							seq.body[j].only = true;
							if(typeof seq.body[j] == 'string') {
								body += evalStatement(seq.body[j]);
							} else {
								body += evalStatement(seq.body[j]) + '\n';
							}
						}
					}
					var pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '' || x == 0) {
							if(x == (pars.length - 1)) {
								r += '\t' + pars[x];
							} else {
								if(seq.body.length == 1) {
									r += '\t' + pars[x];
								} else {
									r += '\t' + pars[x] + '\n';
								}
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							r += pars[x];
						}
					}
					r += '}';
				} else {
					r += ';'
				}
				return r;
			case 'NamespaceIdentifier':
				var r = '';
				if(seq.start == true) {
					r += '\\';
				}
				for (var i = 0; i < seq.name.length; i++) {
					if(i!=0) {
						r += '\\'
					}
					r += seq.name[i];
				};
				return r;
			case 'ClassDeclaration':
				var r = Tokens.ClassToken + ' ' + evalStatement(seq.name);
				r += ' {';
				if(seq.body != null) {
					var body = '';
					for(var j = 0; j < seq.body.length; j++) {
						if(typeof seq.body[j] == 'undefined') {
							body += '\n';
						} else {
							seq.body[j].only = true;
							if(typeof seq.body[j] == 'string') {
								body += evalStatement(seq.body[j]);
							} else {
								body += evalStatement(seq.body[j]) + '\n';
							}
						}
					}
					var pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '' || x == 0) {
							if(x == (pars.length - 1)) {
								if(pars[x] == 'EOD;' || pars[x] == 'EOT;') {
									r += pars[x];
								} else {
									r += '\t' + pars[x];
								}
							} else {
								if(seq.body.length == 1) {
									if(pars[x] == 'EOD;' || pars[x] == 'EOT;') {
										r += pars[x];
									} else {
										r += '\t' + pars[x];
									}
								} else {
									if(pars[x] == 'EOD;' || pars[x] == 'EOT;') {
										r += pars[x] + '\n';
									} else {
										r += '\t' + pars[x] + '\n';
									}
								}
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							r += pars[x];
						}
					}
				}
				r += '}';
				return r;
			case 'ClassPropertyDeclaration':
				var r;
				if(seq.Visibility == false) {
					r = 'var '
				} else {
					r = seq.Visibility + ' ';
				}
				var left = evalStatement(seq.left);
				if(seq.operator !== false) {
					right = ' ' + seq.operator + ' ' + evalStatement(seq.right);
				} else {
					right = '';
				}
				r += left + right + ';';
				return r;
			case 'ClassConstPropertyDeclaration':
				var r = 'const ';
				var left = evalStatement(seq.left);
				if(seq.operator !== false) {
					right = ' ' + seq.operator + ' ' + evalStatement(seq.right);
				} else {
					right = '';
				}
				r += left + right + ';';
				return r;
			case 'ClassFunctionDeclaration':
				var r;
				if(seq.Visibility == false) {
					r = ''
				} else {
					r = seq.Visibility + ' ';
				}
				r += Tokens.FunctionToken;
				r += ' ' + evalStatement(seq.name);
				var arguments = '(';
				for (var i = 0; i < seq.params.length; i++) {
					if( i != 0 ) {
						arguments += ', '
					}
					arguments += evalStatement(seq.params[i]);
				};
				arguments += ')';
				r += arguments;
				r += ' {\n';
				if(seq.body != null) {
					var body = '';
					for(var j = 0; j < seq.body.length; j++) {
						if(typeof seq.body[j] == 'undefined') {
							body += '\n';
						} else {
							seq.body[j].only = true;
							if(typeof seq.body[j] == 'string') {
								body += evalStatement(seq.body[j]);
							} else {
								body += evalStatement(seq.body[j]) + '\n';
							}
						}
					}
					var pars = mammouth.LineTerminatorParser.parse(body);
					for(var x = 0; x < pars.length; x++) {
						if(pars[x] != '' || x == 0) {
							if(x == (pars.length - 1)) {
								r += '\t' + pars[x];
							} else {
								if(seq.body.length == 1) {
									r += '\t' + pars[x];
								} else {
									r += '\t' + pars[x] + '\n';
								}
							}
						} else if(typeof pars[x] == 'undefined') {
							r += '\n';
						} else {
							r += pars[x];
						}
					}
				}
				r += '}';
				return r;
		}
	};
	var interprete = function(code){
		var r = '';
		var seq = mammouth.parser.parse(code);
		console.log(seq);
		for(var i = 0; i < seq.length; i++) {
			r += evalStatement(seq[i]);
		}
		return r;
	};
	var codeout = interprete(code);
	return codeout;
}