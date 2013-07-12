start
= b:((!LineTerminator .)* LineTerminator)*
n:((!LineTerminator .)* LineTerminator?)
{
var line = [];
for(var i = 0; i < b.length;i++) {
var m =[];
for(var o = 0; o < b[i][0].length; o++) {
m.push(b[i][0][o][1]);
}
line.push(m.join(''))
}
var m =[];
for(var o = 0; o < n[0].length; o++) {
m.push(n[0][o][1]);
}
line.push(m.join(''))
return line;
}

LineTerminator
= ([\n\v\r\u2028\u2029] / LineTerminatorSequence)

LineTerminatorSequence "end of line"
= "\n"
/ "\r\n"
/ "\r"
/ "\u2028" // line separator
/ "\u2029" // paragraph separator