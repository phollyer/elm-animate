(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}




var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log = F2(function(tag, value)
{
	return value;
});

var _Debug_log_UNUSED = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString(value)
{
	return '<internals>';
}

function _Debug_toString_UNUSED(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash_UNUSED(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.aV.aQ === region.c.aQ)
	{
		return 'on line ' + region.aV.aQ;
	}
	return 'on lines ' + region.aV.aQ + ' through ' + region.c.aQ;
}



// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**_UNUSED/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**_UNUSED/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**/
	if (typeof x.$ === 'undefined')
	//*/
	/**_UNUSED/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0 = 0;
var _Utils_Tuple0_UNUSED = { $: '#0' };

function _Utils_Tuple2(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2_UNUSED(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3_UNUSED(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr(c) { return c; }
function _Utils_chr_UNUSED(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil = { $: 0 };
var _List_Nil_UNUSED = { $: '[]' };

function _List_Cons(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons_UNUSED(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**_UNUSED/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap_UNUSED(value) { return { $: 0, a: value }; }
function _Json_unwrap_UNUSED(value) { return value.a; }

function _Json_wrap(value) { return value; }
function _Json_unwrap(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.ee,
		impl.ft,
		impl.e2,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**_UNUSED/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**/
	var node = args['node'];
	//*/
	/**_UNUSED/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS
//
// For some reason, tabs can appear in href protocols and it still works.
// So '\tjava\tSCRIPT:alert("!!!")' and 'javascript:alert("!!!")' are the same
// in practice. That is why _VirtualDom_RE_js and _VirtualDom_RE_js_html look
// so freaky.
//
// Pulling the regular expressions out to the top level gives a slight speed
// boost in small benchmarks (4-10%) but hoisting values to reduce allocation
// can be unpredictable in large programs where JIT may have a harder time with
// functions are not fully self-contained. The benefit is more that the js and
// js_html ones are so weird that I prefer to see them near each other.


var _VirtualDom_RE_script = /^script$/i;
var _VirtualDom_RE_on_formAction = /^(on|formAction$)/i;
var _VirtualDom_RE_js = /^\s*j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/i;
var _VirtualDom_RE_js_html = /^\s*(j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:|d\s*a\s*t\s*a\s*:\s*t\s*e\s*x\s*t\s*\/\s*h\s*t\s*m\s*l\s*(,|;))/i;


function _VirtualDom_noScript(tag)
{
	return _VirtualDom_RE_script.test(tag) ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return _VirtualDom_RE_on_formAction.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return _VirtualDom_RE_js.test(value)
		? /**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return _VirtualDom_RE_js_html.test(value)
		? /**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlJson(value)
{
	return (typeof _Json_unwrap(value) === 'string' && _VirtualDom_RE_js_html.test(_Json_unwrap(value)))
		? _Json_wrap(
			/**/''//*//**_UNUSED/'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'//*/
		) : value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		ad: func(record.ad),
		bV: record.bV,
		bR: record.bR
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.ad;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.bV;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.bR) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.ee,
		impl.ft,
		impl.e2,
		function(sendToApp, initialModel) {
			var view = impl.fu;
			/**/
			var domNode = args['node'];
			//*/
			/**_UNUSED/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.ee,
		impl.ft,
		impl.e2,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.bU && impl.bU(sendToApp)
			var view = impl.fu;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.dm);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.fl) && (_VirtualDom_doc.title = title = doc.fl);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.ex;
	var onUrlRequest = impl.ey;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		bU: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.cL === next.cL
							&& curr.cm === next.cm
							&& curr.cI.a === next.cI.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		ee: function(flags)
		{
			return A3(impl.ee, flags, _Browser_getUrl(), key);
		},
		fu: impl.fu,
		ft: impl.ft,
		e2: impl.e2
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { d7: 'hidden', dx: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { d7: 'mozHidden', dx: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { d7: 'msHidden', dx: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { d7: 'webkitHidden', dx: 'webkitvisibilitychange' }
		: { d7: 'hidden', dx: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		cS: _Browser_getScene(),
		c_: {
			b_: _Browser_window.pageXOffset,
			b$: _Browser_window.pageYOffset,
			c$: _Browser_doc.documentElement.clientWidth,
			cj: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		c$: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		cj: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			cS: {
				c$: node.scrollWidth,
				cj: node.scrollHeight
			},
			c_: {
				b_: node.scrollLeft,
				b$: node.scrollTop,
				c$: node.clientWidth,
				cj: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			cS: _Browser_getScene(),
			c_: {
				b_: x,
				b$: y,
				c$: _Browser_doc.documentElement.clientWidth,
				cj: _Browser_doc.documentElement.clientHeight
			},
			dS: {
				b_: x + rect.left,
				b$: y + rect.top,
				c$: rect.width,
				cj: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}
var $elm$core$List$cons = _List_cons;
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (!node.$) {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === -2) {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Basics$EQ = 1;
var $elm$core$Basics$GT = 2;
var $elm$core$Basics$LT = 0;
var $elm$core$Result$Err = function (a) {
	return {$: 1, a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 3, a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 0, a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 2, a: a};
};
var $elm$core$Basics$False = 1;
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Maybe$Nothing = {$: 1};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 0:
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 1) {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 1:
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 2:
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 0, a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 1, a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.g) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.i),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.i);
		} else {
			var treeLen = builder.g * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.j) : builder.j;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.g);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.i) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.i);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{j: nodeList, g: (len / $elm$core$Array$branchFactor) | 0, i: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = 0;
var $elm$core$Result$isOk = function (result) {
	if (!result.$) {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$andThen = _Json_andThen;
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 0:
			return 0;
		case 1:
			return 1;
		case 2:
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 1, a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 0, a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = $elm$core$Basics$identity;
var $elm$url$Url$Http = 0;
var $elm$url$Url$Https = 1;
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {cf: fragment, cm: host, cG: path, cI: port_, cL: protocol, cM: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 1) {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		0,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		1,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = $elm$core$Basics$identity;
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return 0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0;
		return A2($elm$core$Task$map, tagger, task);
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			A2($elm$core$Task$map, toMessage, task));
	});
var $elm$browser$Browser$element = _Browser_element;
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$json$Json$Decode$float = _Json_decodeFloat;
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$animGroupName = 'movingBox';
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$boxWidth = 100;
var $author$project$Anim$Internal$Engine$Sub$AnimState = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$AnimBuilder = $elm$core$Basics$identity;
var $elm$core$Dict$RBEmpty_elm_builtin = {$: -2};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$AnimGroups = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$init = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Builder$initAnimation = {y: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, aC: $elm$core$Maybe$Nothing, ao: $elm$core$Dict$empty};
var $author$project$Anim$Internal$Builder$clearAnimData = function (_v0) {
	var data = _v0;
	var pb = data.f;
	return _Utils_update(
		data,
		{
			e: $author$project$Anim$Internal$Builder$initAnimation,
			f: _Utils_update(
				pb,
				{aD: $elm$core$Dict$empty, aE: $elm$core$Dict$empty})
		});
};
var $author$project$Anim$Internal$Builder$getAnimGroups = function (_v0) {
	var data = _v0;
	return data.e.y;
};
var $author$project$Anim$Internal$Builder$getDiscreteEntryProperties = function (_v0) {
	var data = _v0;
	return data.f.aD;
};
var $author$project$Anim$Internal$Builder$getDiscreteExitProperties = function (_v0) {
	var data = _v0;
	return data.f.aE;
};
var $author$project$Anim$Internal$Builder$initDefaults = {T: $elm$core$Maybe$Nothing, H: $elm$core$Maybe$Nothing, U: $elm$core$Maybe$Nothing, I: $elm$core$Maybe$Nothing, ab: $elm$core$Maybe$Nothing};
var $author$project$Anim$Internal$Builder$Normal = 0;
var $author$project$Anim$Internal$Builder$Once = {$: 0};
var $author$project$Anim$Internal$Builder$initPlayback = {ah: 0, aD: $elm$core$Dict$empty, aE: $elm$core$Dict$empty, aP: false, ac: $author$project$Anim$Internal$Builder$Once};
var $author$project$Anim$Internal$Builder$initScrollDrivenConfig = {a2: $elm$core$Maybe$Nothing, br: $elm$core$Maybe$Nothing, aX: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, bw: $elm$core$Maybe$Nothing, bx: $elm$core$Maybe$Nothing};
var $author$project$Anim$Internal$Builder$initState = {ay: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, az: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init, bo: $author$project$Anim$Internal$Engine$Shared$AnimGroups$init};
var $author$project$Anim$Internal$Builder$init = A2(
	$elm$core$List$foldl,
	F2(
		function (f, b) {
			return f(b);
		}),
	{e: $author$project$Anim$Internal$Builder$initAnimation, b: $author$project$Anim$Internal$Builder$initDefaults, f: $author$project$Anim$Internal$Builder$initPlayback, k: $author$project$Anim$Internal$Builder$initScrollDrivenConfig, A: $author$project$Anim$Internal$Builder$initState});
var $author$project$Anim$Internal$Engine$Shared$PlayState$Complete = 4;
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (!_v0.$) {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $author$project$Anim$Internal$Engine$Sub$Animations$Animations = $elm$core$Basics$identity;
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $elm$core$Dict$Black = 1;
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: -1, a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$Red = 0;
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === -1) && (!right.a)) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === -1) && (!left.a)) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === -1) && (!left.a)) && (left.d.$ === -1)) && (!left.d.a)) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					0,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 1, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === -2) {
			return A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1) {
				case 0:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 1:
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $author$project$Anim$Internal$Engine$Sub$Animations$fromList = A2($elm$core$Basics$composeR, $elm$core$Dict$fromList, $elm$core$Basics$identity);
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$AnimGroup = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Engine$Shared$PlayState$NotStarted = 0;
var $author$project$Anim$Extra$TransformOrder$Rotate = 1;
var $author$project$Anim$Extra$TransformOrder$Scale = 3;
var $author$project$Anim$Extra$TransformOrder$Skew = 2;
var $author$project$Anim$Extra$TransformOrder$Translate = 0;
var $author$project$Anim$Extra$TransformOrder$default = _List_fromArray(
	[0, 1, 2, 3]);
var $author$project$Anim$Internal$Engine$Sub$Animations$init = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$init = {ah: 0, aM: $author$project$Anim$Internal$Engine$Sub$Animations$init, bC: 0, bD: $elm$core$Dict$empty, bE: $elm$core$Dict$empty, ac: $author$project$Anim$Internal$Builder$Once, aR: 0, q: $author$project$Anim$Extra$TransformOrder$default};
var $author$project$Anim$Internal$Builder$ProcessedCustomColorPropertyConfig = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$ProcessedCustomPropertyConfig = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $author$project$Anim$Internal$Builder$ProcessedOpacityConfig = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedPerspectiveOriginConfig = function (a) {
	return {$: 3, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedRotateConfig = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedScaleConfig = function (a) {
	return {$: 5, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedSizeConfig = function (a) {
	return {$: 6, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedSkewConfig = function (a) {
	return {$: 7, a: a};
};
var $author$project$Anim$Internal$Builder$ProcessedTranslateConfig = function (a) {
	return {$: 8, a: a};
};
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $elm$core$Basics$abs = function (n) {
	return (n < 0) ? (-n) : n;
};
var $author$project$Anim$Internal$Property$PerspectiveOrigin$Percent = function (a) {
	return {$: 0, a: a};
};
var $author$project$Anim$Internal$Property$PerspectiveOrigin$default = $author$project$Anim$Internal$Property$PerspectiveOrigin$Percent(
	{b_: 50, b$: 50});
var $author$project$Anim$Internal$Property$Rotate$Rotate = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Rotate$default = {b_: 0, b$: 0, b0: 0};
var $author$project$Anim$Internal$Property$Scale$Scale = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Scale$default = {b_: 1.0, b$: 1.0, b0: 1.0};
var $author$project$Anim$Internal$Property$Size$Size = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Size$default = {ci: 0, t: 0};
var $author$project$Anim$Internal$Property$Skew$Skew = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Skew$default = {b_: 0, b$: 0};
var $author$project$Anim$Internal$Property$Translate$Translate = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Translate$default = {b_: 0, b$: 0, b0: 0};
var $elm$core$Basics$sqrt = _Basics_sqrt;
var $author$project$Anim$Internal$Extra$Color$cleanHex = function (hex_) {
	return A2($elm$core$String$startsWith, '#', hex_) ? A2($elm$core$String$dropLeft, 1, hex_) : hex_;
};
var $elm$core$Maybe$map2 = F3(
	function (func, ma, mb) {
		if (ma.$ === 1) {
			return $elm$core$Maybe$Nothing;
		} else {
			var a = ma.a;
			if (mb.$ === 1) {
				return $elm$core$Maybe$Nothing;
			} else {
				var b = mb.a;
				return $elm$core$Maybe$Just(
					A2(func, a, b));
			}
		}
	});
var $elm$core$String$foldr = _String_foldr;
var $elm$core$String$toList = function (string) {
	return A3($elm$core$String$foldr, $elm$core$List$cons, _List_Nil, string);
};
var $author$project$Anim$Internal$Extra$Color$hexToInt = function (str) {
	var hexCharToInt = function (_char) {
		switch (_char) {
			case '0':
				return $elm$core$Maybe$Just(0);
			case '1':
				return $elm$core$Maybe$Just(1);
			case '2':
				return $elm$core$Maybe$Just(2);
			case '3':
				return $elm$core$Maybe$Just(3);
			case '4':
				return $elm$core$Maybe$Just(4);
			case '5':
				return $elm$core$Maybe$Just(5);
			case '6':
				return $elm$core$Maybe$Just(6);
			case '7':
				return $elm$core$Maybe$Just(7);
			case '8':
				return $elm$core$Maybe$Just(8);
			case '9':
				return $elm$core$Maybe$Just(9);
			case 'A':
				return $elm$core$Maybe$Just(10);
			case 'a':
				return $elm$core$Maybe$Just(10);
			case 'B':
				return $elm$core$Maybe$Just(11);
			case 'b':
				return $elm$core$Maybe$Just(11);
			case 'C':
				return $elm$core$Maybe$Just(12);
			case 'c':
				return $elm$core$Maybe$Just(12);
			case 'D':
				return $elm$core$Maybe$Just(13);
			case 'd':
				return $elm$core$Maybe$Just(13);
			case 'E':
				return $elm$core$Maybe$Just(14);
			case 'e':
				return $elm$core$Maybe$Just(14);
			case 'F':
				return $elm$core$Maybe$Just(15);
			case 'f':
				return $elm$core$Maybe$Just(15);
			default:
				return $elm$core$Maybe$Nothing;
		}
	};
	var chars = $elm$core$String$toList(str);
	if ((chars.b && chars.b.b) && (!chars.b.b.b)) {
		var c1 = chars.a;
		var _v1 = chars.b;
		var c2 = _v1.a;
		return A3(
			$elm$core$Maybe$map2,
			F2(
				function (v1, v2) {
					return (v1 * 16) + v2;
				}),
			hexCharToInt(c1),
			hexCharToInt(c2));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$Anim$Internal$Extra$Color$hexByteAt = F3(
	function (start, _default, hex_) {
		return A2(
			$elm$core$Maybe$withDefault,
			_default,
			$author$project$Anim$Internal$Extra$Color$hexToInt(
				A3($elm$core$String$slice, start, start + 2, hex_)));
	});
var $author$project$Anim$Internal$Extra$Color$hexToRgb = function (hex_) {
	var cleanHex_ = $author$project$Anim$Internal$Extra$Color$cleanHex(hex_);
	var g = A3($author$project$Anim$Internal$Extra$Color$hexByteAt, 2, 0, cleanHex_);
	var r = A3($author$project$Anim$Internal$Extra$Color$hexByteAt, 0, 0, cleanHex_);
	var b = A3($author$project$Anim$Internal$Extra$Color$hexByteAt, 4, 0, cleanHex_);
	return {b5: b, ch: g, cN: r};
};
var $author$project$Anim$Internal$Extra$Color$floatMod = F2(
	function (a, b) {
		return a - ($elm$core$Basics$floor(a / b) * b);
	});
var $elm$core$Basics$round = _Basics_round;
var $author$project$Anim$Internal$Extra$Color$hslToRgb = function (hslValue) {
	var s = hslValue.cQ / 100;
	var l = hslValue.cr / 100;
	var c = (1 - $elm$core$Basics$abs((2 * l) - 1)) * s;
	var m = l - (c / 2);
	var x = c * (1 - $elm$core$Basics$abs(
		A2($author$project$Anim$Internal$Extra$Color$floatMod, hslValue.ci / 60, 2) - 1));
	var _v0 = (hslValue.ci < 60) ? _Utils_Tuple3(c, x, 0) : ((hslValue.ci < 120) ? _Utils_Tuple3(x, c, 0) : ((hslValue.ci < 180) ? _Utils_Tuple3(0, c, x) : ((hslValue.ci < 240) ? _Utils_Tuple3(0, x, c) : ((hslValue.ci < 300) ? _Utils_Tuple3(x, 0, c) : _Utils_Tuple3(c, 0, x)))));
	var r1 = _v0.a;
	var g1 = _v0.b;
	var b1 = _v0.c;
	var b = $elm$core$Basics$round((b1 + m) * 255);
	var g = $elm$core$Basics$round((g1 + m) * 255);
	var r = $elm$core$Basics$round((r1 + m) * 255);
	return {b5: b, ch: g, cN: r};
};
var $avh4$elm_color$Color$toRgba = function (_v0) {
	var r = _v0.a;
	var g = _v0.b;
	var b = _v0.c;
	var a = _v0.d;
	return {a1: a, bB: b, bI: g, bS: r};
};
var $author$project$Anim$Internal$Extra$Color$toRgb = function (color) {
	switch (color.$) {
		case 0:
			var hex_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hexToRgb(hex_);
		case 1:
			var rgb_ = color.a;
			return rgb_;
		case 2:
			var rgba_ = color.a;
			return {b5: rgba_.b5, ch: rgba_.ch, cN: rgba_.cN};
		case 3:
			var hsl_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hslToRgb(hsl_);
		case 4:
			var hsla_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hslToRgb(
				{ci: hsla_.ci, cr: hsla_.cr, cQ: hsla_.cQ});
		default:
			var elmColor_ = color.a;
			var rgba_ = $avh4$elm_color$Color$toRgba(elmColor_);
			return {
				b5: $elm$core$Basics$round(rgba_.bB * 255),
				ch: $elm$core$Basics$round(rgba_.bI * 255),
				cN: $elm$core$Basics$round(rgba_.bS * 255)
			};
	}
};
var $author$project$Anim$Internal$Extra$Color$distance = F2(
	function (color1, color2) {
		var rgb2 = $author$project$Anim$Internal$Extra$Color$toRgb(color2);
		var rgb1 = $author$project$Anim$Internal$Extra$Color$toRgb(color1);
		var dr = rgb2.cN - rgb1.cN;
		var dg = rgb2.ch - rgb1.ch;
		var db = rgb2.b5 - rgb1.b5;
		return $elm$core$Basics$sqrt(((dr * dr) + (dg * dg)) + (db * db));
	});
var $author$project$Anim$Internal$Property$Opacity$distance = F2(
	function (_v0, _v1) {
		var o1 = _v0;
		var o2 = _v1;
		return $elm$core$Basics$abs(o2 - o1);
	});
var $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple = function (origin) {
	if (!origin.$) {
		var x = origin.a.b_;
		var y = origin.a.b$;
		return _Utils_Tuple2(x, y);
	} else {
		var x = origin.a.b_;
		var y = origin.a.b$;
		return _Utils_Tuple2(x, y);
	}
};
var $author$project$Anim$Internal$Property$PerspectiveOrigin$distance = F2(
	function (start, end) {
		var _v0 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(start);
		var sx = _v0.a;
		var sy = _v0.b;
		var _v1 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(end);
		var ex = _v1.a;
		var ey = _v1.b;
		var dx = ex - sx;
		var dy = ey - sy;
		return $elm$core$Basics$sqrt((dx * dx) + (dy * dy));
	});
var $author$project$Anim$Internal$Property$Shared$Axis3$distance = F3(
	function (support, coord1, coord2) {
		var record2 = support.fm(coord2);
		var record1 = support.fm(coord1);
		var dz = $elm$core$Basics$abs(record2.b0 - record1.b0);
		var dy = $elm$core$Basics$abs(record2.b$ - record1.b$);
		var dx = $elm$core$Basics$abs(record2.b_ - record1.b_);
		return A2(
			$elm$core$Basics$max,
			dx,
			A2($elm$core$Basics$max, dy, dz));
	});
var $author$project$Anim$Internal$Property$Rotate$support = {
	c4: F2(
		function (_v0, _v1) {
			var a = _v0;
			var b = _v1;
			return {b_: a.b_ + b.b_, b$: a.b$ + b.b$, b0: a.b0 + b.b0};
		}),
	d3: $elm$core$Basics$identity,
	bp: F2(
		function (factor, _v2) {
			var angles = _v2;
			return {b_: angles.b_ * factor, b$: angles.b$ * factor, b0: angles.b0 * factor};
		}),
	e3: F2(
		function (_v3, _v4) {
			var a = _v3;
			var b = _v4;
			return {b_: a.b_ - b.b_, b$: a.b$ - b.b$, b0: a.b0 - b.b0};
		}),
	fm: function (_v5) {
		var angles = _v5;
		return angles;
	},
	fw: $author$project$Anim$Internal$Property$Rotate$default
};
var $author$project$Anim$Internal$Property$Rotate$distance = $author$project$Anim$Internal$Property$Shared$Axis3$distance($author$project$Anim$Internal$Property$Rotate$support);
var $author$project$Anim$Internal$Property$Scale$support = {
	c4: F2(
		function (_v0, _v1) {
			var a = _v0;
			var b = _v1;
			return {b_: a.b_ + b.b_, b$: a.b$ + b.b$, b0: a.b0 + b.b0};
		}),
	d3: $elm$core$Basics$identity,
	bp: F2(
		function (factor, _v2) {
			var coords = _v2;
			return {b_: coords.b_ * factor, b$: coords.b$ * factor, b0: coords.b0 * factor};
		}),
	e3: F2(
		function (_v3, _v4) {
			var a = _v3;
			var b = _v4;
			return {b_: a.b_ - b.b_, b$: a.b$ - b.b$, b0: a.b0 - b.b0};
		}),
	fm: function (_v5) {
		var coords = _v5;
		return coords;
	},
	fw: $author$project$Anim$Internal$Property$Scale$default
};
var $author$project$Anim$Internal$Property$Scale$distance = $author$project$Anim$Internal$Property$Shared$Axis3$distance($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Property$Size$distance = F2(
	function (_v0, _v1) {
		var start = _v0;
		var end = _v1;
		var dw = end.t - start.t;
		var dh = end.ci - start.ci;
		return $elm$core$Basics$sqrt((dw * dw) + (dh * dh));
	});
var $author$project$Anim$Internal$Property$Skew$toTuple = function (_v0) {
	var values = _v0;
	return _Utils_Tuple2(values.b_, values.b$);
};
var $author$project$Anim$Internal$Property$Skew$distance = F2(
	function (start, end) {
		var _v0 = $author$project$Anim$Internal$Property$Skew$toTuple(start);
		var startX = _v0.a;
		var startY = _v0.b;
		var _v1 = $author$project$Anim$Internal$Property$Skew$toTuple(end);
		var endX = _v1.a;
		var endY = _v1.b;
		var dx = endX - startX;
		var dy = endY - startY;
		return $elm$core$Basics$sqrt((dx * dx) + (dy * dy));
	});
var $author$project$Anim$Internal$Property$Translate$support = {
	c4: F2(
		function (_v0, _v1) {
			var a = _v0;
			var b = _v1;
			return {b_: a.b_ + b.b_, b$: a.b$ + b.b$, b0: a.b0 + b.b0};
		}),
	d3: $elm$core$Basics$identity,
	bp: F2(
		function (factor, _v2) {
			var coords = _v2;
			return {b_: coords.b_ * factor, b$: coords.b$ * factor, b0: coords.b0 * factor};
		}),
	e3: F2(
		function (_v3, _v4) {
			var a = _v3;
			var b = _v4;
			return {b_: a.b_ - b.b_, b$: a.b$ - b.b$, b0: a.b0 - b.b0};
		}),
	fm: function (_v5) {
		var coords = _v5;
		return coords;
	},
	fw: $author$project$Anim$Internal$Property$Translate$default
};
var $author$project$Anim$Internal$Property$Translate$distance = $author$project$Anim$Internal$Property$Shared$Axis3$distance($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Shared$TimeSpec$duration = F2(
	function (distance, timeSpec) {
		if (!timeSpec.$) {
			var ms = timeSpec.a;
			return ms;
		} else {
			var unitsPerSecond = timeSpec.a;
			return (!unitsPerSecond) ? 0 : ((distance / unitsPerSecond) * 1000);
		}
	});
var $author$project$Anim$Internal$Extra$Color$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Opacity$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$PerspectiveOrigin$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Rotate$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Scale$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Size$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Skew$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Translate$duration = $author$project$Shared$TimeSpec$duration;
var $author$project$Anim$Internal$Property$Opacity$Opacity = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Property$Opacity$fromFloat = function (o) {
	return o;
};
var $author$project$Shared$TimeSpec$Duration = function (a) {
	return {$: 0, a: a};
};
var $author$project$Motion$Easing$EaseInOut = {$: 19};
var $author$project$Anim$Internal$Builder$resolveMaybeWithDefault = F3(
	function (local, global, _default) {
		var _v0 = _Utils_Tuple2(local, global);
		if (!_v0.a.$) {
			var value = _v0.a.a;
			return value;
		} else {
			if (!_v0.b.$) {
				var _v1 = _v0.a;
				var value = _v0.b.a;
				return value;
			} else {
				var _v2 = _v0.a;
				var _v3 = _v0.b;
				return _default;
			}
		}
	});
var $author$project$Anim$Internal$Builder$resolveDelayWithDefault = $author$project$Anim$Internal$Builder$resolveMaybeWithDefault;
var $author$project$Anim$Internal$Builder$resolveEasingWithDefault = $author$project$Anim$Internal$Builder$resolveMaybeWithDefault;
var $author$project$Anim$Internal$Builder$resolveTimingWithDefault = $author$project$Anim$Internal$Builder$resolveMaybeWithDefault;
var $author$project$Shared$Spring$Critically = function (a) {
	return {$: 1, a: a};
};
var $author$project$Shared$Spring$Overdamped = function (a) {
	return {$: 2, a: a};
};
var $author$project$Shared$Spring$Underdamped = function (a) {
	return {$: 0, a: a};
};
var $author$project$Shared$Spring$precompute = function (_v0) {
	var spring = _v0.aU;
	var from = _v0.bH;
	var to = _v0.bW;
	var x0 = from - to;
	var v0 = spring.aG;
	var m = A2($elm$core$Basics$max, 1.0e-6, spring.aq);
	var k = A2($elm$core$Basics$max, 0, spring.av);
	var omega0 = $elm$core$Basics$sqrt(k / m);
	var c = A2($elm$core$Basics$max, 0, spring.al);
	var zeta = (k <= 0) ? 1.0 : (c / (2.0 * $elm$core$Basics$sqrt(k * m)));
	if ($elm$core$Basics$abs(zeta - 1.0) < 1.0e-4) {
		return $author$project$Shared$Spring$Critically(
			{b1: x0, b5: v0 + (omega0 * x0), K: omega0});
	} else {
		if (zeta < 1.0) {
			var omegaD = omega0 * $elm$core$Basics$sqrt(1.0 - (zeta * zeta));
			return $author$project$Shared$Spring$Underdamped(
				{b1: x0, b5: (v0 + ((zeta * omega0) * x0)) / omegaD, K: omega0, bh: omegaD, a0: zeta});
		} else {
			var disc = $elm$core$Basics$sqrt((zeta * zeta) - 1.0);
			var r1 = (-omega0) * (zeta - disc);
			var r2 = (-omega0) * (zeta + disc);
			var a = (v0 - (r2 * x0)) / (r1 - r2);
			return $author$project$Shared$Spring$Overdamped(
				{b1: a, b5: x0 - a, aS: r1, aT: r2});
		}
	}
};
var $elm$core$Basics$e = _Basics_e;
var $elm$core$Basics$ge = _Utils_ge;
var $elm$core$Basics$min = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) < 0) ? x : y;
	});
var $author$project$Shared$Spring$settleTimeS = function (sol) {
	var epsilon = 0.005;
	var cap = 8.0;
	switch (sol.$) {
		case 0:
			var omega0 = sol.a.K;
			var zeta = sol.a.a0;
			var a = sol.a.b1;
			var b = sol.a.b5;
			if ((zeta * omega0) <= 0) {
				return cap;
			} else {
				var envMax = $elm$core$Basics$sqrt((a * a) + (b * b));
				return (_Utils_cmp(envMax, epsilon) < 1) ? 0.0 : A2(
					$elm$core$Basics$min,
					cap,
					A2($elm$core$Basics$logBase, $elm$core$Basics$e, envMax / epsilon) / (zeta * omega0));
			}
		case 1:
			var omega0 = sol.a.K;
			var a = sol.a.b1;
			var b = sol.a.b5;
			if (omega0 <= 0) {
				return cap;
			} else {
				var envMax = $elm$core$Basics$abs(a) + ($elm$core$Basics$abs(b) / omega0);
				return (_Utils_cmp(envMax, epsilon) < 1) ? 0.0 : A2(
					$elm$core$Basics$min,
					cap,
					A2($elm$core$Basics$logBase, $elm$core$Basics$e, envMax / epsilon) / omega0);
			}
		default:
			var r1 = sol.a.aS;
			var r2 = sol.a.aT;
			var a = sol.a.b1;
			var b = sol.a.b5;
			var _v1 = (_Utils_cmp(
				$elm$core$Basics$abs(r1),
				$elm$core$Basics$abs(r2)) < 0) ? _Utils_Tuple2(r1, a) : _Utils_Tuple2(r2, b);
			var slowR = _v1.a;
			var slowCoef = _v1.b;
			return ((slowR >= 0) || (_Utils_cmp(
				$elm$core$Basics$abs(slowCoef),
				epsilon) < 1)) ? cap : A2(
				$elm$core$Basics$min,
				cap,
				A2(
					$elm$core$Basics$logBase,
					$elm$core$Basics$e,
					$elm$core$Basics$abs(slowCoef) / epsilon) / $elm$core$Basics$abs(slowR));
	}
};
var $author$project$Shared$Spring$settleTimeMs = function (params) {
	return $author$project$Shared$Spring$settleTimeS(
		$author$project$Shared$Spring$precompute(params)) * 1000.0;
};
var $author$project$Motion$Internal$Spring$unwrap = function (_v0) {
	var config = _v0;
	return config;
};
var $author$project$Anim$Internal$Builder$processStandardAnimation = function (_v0) {
	var config = _v0.C;
	var globalData = _v0.G;
	var defaultStart = _v0.D;
	var distanceFn = _v0.E;
	var durationFn = _v0.F;
	var speedFn = _v0.O;
	var wrapper = _v0.Q;
	var start = A2($elm$core$Maybe$withDefault, defaultStart, config.aV);
	var resolvedTiming = A3(
		$author$project$Anim$Internal$Builder$resolveTimingWithDefault,
		config.bt,
		globalData.I,
		$author$project$Shared$TimeSpec$Duration(0));
	var resolvedSpring = function () {
		var _v2 = config.aU;
		if (!_v2.$) {
			var s = _v2.a;
			return $elm$core$Maybe$Just(s);
		} else {
			return globalData.U;
		}
	}();
	var distance_ = A2(distanceFn, start, config.c);
	var rawDuration = A2(durationFn, distance_, resolvedTiming);
	var duration_ = function () {
		if (!resolvedSpring.$) {
			var s = resolvedSpring.a;
			return $author$project$Shared$Spring$settleTimeMs(
				{
					bH: 0,
					aU: $author$project$Motion$Internal$Spring$unwrap(s),
					bW: 1
				});
		} else {
			return rawDuration;
		}
	}();
	var speed_ = A3(speedFn, distance_, duration_, resolvedTiming);
	return wrapper(
		{
			ba: A3($author$project$Anim$Internal$Builder$resolveDelayWithDefault, config.ba, globalData.T, 0),
			bF: distance_,
			cb: $elm$core$Basics$round(duration_),
			bc: A3($author$project$Anim$Internal$Builder$resolveEasingWithDefault, config.bc, globalData.H, $author$project$Motion$Easing$EaseInOut),
			c: config.c,
			cU: speed_,
			aU: resolvedSpring,
			aV: config.aV,
			bt: resolvedTiming
		});
};
var $author$project$Shared$TimeSpec$speed = F3(
	function (distance_, duration_, timeSpec) {
		if (!timeSpec.$) {
			var ms = timeSpec.a;
			return (ms <= 0) ? ((distance_ * duration_) * 1000) : (distance_ / (ms / 1000));
		} else {
			var unitsPerSecond = timeSpec.a;
			return unitsPerSecond;
		}
	});
var $author$project$Anim$Internal$Extra$Color$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Opacity$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$PerspectiveOrigin$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Rotate$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Scale$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Size$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Skew$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Property$Translate$speed = $author$project$Shared$TimeSpec$speed;
var $author$project$Anim$Internal$Extra$Color$Rgba = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Extra$Color$transparent = $author$project$Anim$Internal$Extra$Color$Rgba(
	{b1: 0, b5: 255, ch: 255, cN: 255});
var $author$project$Anim$Internal$Builder$processProperty = F2(
	function (globalData, property) {
		switch (property.$) {
			case 0:
				var cssName = property.a;
				var unit = property.b;
				var config = property.c;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							C: config,
							D: 0,
							E: F2(
								function (a, b) {
									return $elm$core$Basics$abs(b - a);
								}),
							F: $author$project$Shared$TimeSpec$duration,
							G: globalData,
							O: $author$project$Shared$TimeSpec$speed,
							Q: A2($author$project$Anim$Internal$Builder$ProcessedCustomPropertyConfig, cssName, unit)
						}));
			case 1:
				var cssName = property.a;
				var config = property.b;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							C: config,
							D: $author$project$Anim$Internal$Extra$Color$transparent,
							E: $author$project$Anim$Internal$Extra$Color$distance,
							F: $author$project$Anim$Internal$Extra$Color$duration,
							G: globalData,
							O: $author$project$Anim$Internal$Extra$Color$speed,
							Q: $author$project$Anim$Internal$Builder$ProcessedCustomColorPropertyConfig(cssName)
						}));
			case 2:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{
							C: config,
							D: $author$project$Anim$Internal$Property$Opacity$fromFloat(1.0),
							E: $author$project$Anim$Internal$Property$Opacity$distance,
							F: $author$project$Anim$Internal$Property$Opacity$duration,
							G: globalData,
							O: $author$project$Anim$Internal$Property$Opacity$speed,
							Q: $author$project$Anim$Internal$Builder$ProcessedOpacityConfig
						}));
			case 3:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{C: config, D: $author$project$Anim$Internal$Property$PerspectiveOrigin$default, E: $author$project$Anim$Internal$Property$PerspectiveOrigin$distance, F: $author$project$Anim$Internal$Property$PerspectiveOrigin$duration, G: globalData, O: $author$project$Anim$Internal$Property$PerspectiveOrigin$speed, Q: $author$project$Anim$Internal$Builder$ProcessedPerspectiveOriginConfig}));
			case 4:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{C: config, D: $author$project$Anim$Internal$Property$Rotate$default, E: $author$project$Anim$Internal$Property$Rotate$distance, F: $author$project$Anim$Internal$Property$Rotate$duration, G: globalData, O: $author$project$Anim$Internal$Property$Rotate$speed, Q: $author$project$Anim$Internal$Builder$ProcessedRotateConfig}));
			case 5:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{C: config, D: $author$project$Anim$Internal$Property$Scale$default, E: $author$project$Anim$Internal$Property$Scale$distance, F: $author$project$Anim$Internal$Property$Scale$duration, G: globalData, O: $author$project$Anim$Internal$Property$Scale$speed, Q: $author$project$Anim$Internal$Builder$ProcessedScaleConfig}));
			case 6:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{C: config, D: $author$project$Anim$Internal$Property$Size$default, E: $author$project$Anim$Internal$Property$Size$distance, F: $author$project$Anim$Internal$Property$Size$duration, G: globalData, O: $author$project$Anim$Internal$Property$Size$speed, Q: $author$project$Anim$Internal$Builder$ProcessedSizeConfig}));
			case 7:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{C: config, D: $author$project$Anim$Internal$Property$Skew$default, E: $author$project$Anim$Internal$Property$Skew$distance, F: $author$project$Anim$Internal$Property$Skew$duration, G: globalData, O: $author$project$Anim$Internal$Property$Skew$speed, Q: $author$project$Anim$Internal$Builder$ProcessedSkewConfig}));
			default:
				var config = property.a;
				return $elm$core$Maybe$Just(
					$author$project$Anim$Internal$Builder$processStandardAnimation(
						{C: config, D: $author$project$Anim$Internal$Property$Translate$default, E: $author$project$Anim$Internal$Property$Translate$distance, F: $author$project$Anim$Internal$Property$Translate$duration, G: globalData, O: $author$project$Anim$Internal$Property$Translate$speed, Q: $author$project$Anim$Internal$Builder$ProcessedTranslateConfig}));
		}
	});
var $author$project$Anim$Internal$Builder$processProperties = function (defaults) {
	return $elm$core$List$filterMap(
		$author$project$Anim$Internal$Builder$processProperty(defaults));
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations = F2(
	function (animations, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{aM: animations});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteEntry = F2(
	function (entry, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{bD: entry});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteExit = F2(
	function (exit, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{bE: exit});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState = F2(
	function (state, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{aR: state});
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$CustomColorProperty = F2(
	function (a, b) {
		return {$: 1, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$CustomProperty = F3(
	function (a, b, c) {
		return {$: 0, a: a, b: b, c: c};
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$Opacity = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$PerspectiveOrigin = function (a) {
	return {$: 3, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$Rotate = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$Scale = function (a) {
	return {$: 5, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$Size = function (a) {
	return {$: 6, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$Skew = function (a) {
	return {$: 7, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$Translate = function (a) {
	return {$: 8, a: a};
};
var $author$project$Anim$Internal$Property$Opacity$default = 1;
var $author$project$Anim$Internal$Extra$Color$Rgb = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Extra$Color$fromRGB = function (_v0) {
	var r = _v0.cN;
	var g = _v0.ch;
	var b = _v0.b5;
	return $author$project$Anim$Internal$Extra$Color$Rgb(
		{b5: b, ch: g, cN: r});
};
var $elm$core$Basics$cos = _Basics_cos;
var $elm$core$Basics$pow = _Basics_pow;
var $elm$core$Basics$sin = _Basics_sin;
var $author$project$Shared$Spring$displacement = F2(
	function (sol, t) {
		switch (sol.$) {
			case 0:
				var omega0 = sol.a.K;
				var omegaD = sol.a.bh;
				var zeta = sol.a.a0;
				var a = sol.a.b1;
				var b = sol.a.b5;
				return A2($elm$core$Basics$pow, $elm$core$Basics$e, ((-zeta) * omega0) * t) * ((a * $elm$core$Basics$cos(omegaD * t)) + (b * $elm$core$Basics$sin(omegaD * t)));
			case 1:
				var omega0 = sol.a.K;
				var a = sol.a.b1;
				var b = sol.a.b5;
				return (a + (b * t)) * A2($elm$core$Basics$pow, $elm$core$Basics$e, (-omega0) * t);
			default:
				var r1 = sol.a.aS;
				var r2 = sol.a.aT;
				var a = sol.a.b1;
				var b = sol.a.b5;
				return (a * A2($elm$core$Basics$pow, $elm$core$Basics$e, r1 * t)) + (b * A2($elm$core$Basics$pow, $elm$core$Basics$e, r2 * t));
		}
	});
var $author$project$Shared$Spring$valueAt = F2(
	function (params, timeMs) {
		return params.bW + A2(
			$author$project$Shared$Spring$displacement,
			$author$project$Shared$Spring$precompute(params),
			timeMs / 1000.0);
	});
var $author$project$Anim$Internal$Engine$Sub$Generator$springEasingFunction = F2(
	function (s, durationMs) {
		var safeDuration = (durationMs <= 0) ? 1 : durationMs;
		var motion = {
			bH: 0,
			aU: $author$project$Motion$Internal$Spring$unwrap(s),
			bW: 1
		};
		return function (t) {
			return A2($author$project$Shared$Spring$valueAt, motion, t * safeDuration);
		};
	});
var $elm$core$List$tail = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(xs);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm_community$easing_functions$Ease$bezier = F5(
	function (x1, y1, x2, y2, time) {
		var pair = F4(
			function (interpolate, _v2, _v3, v) {
				var a0 = _v2.a;
				var b0 = _v2.b;
				var a1 = _v3.a;
				var b1 = _v3.b;
				return _Utils_Tuple2(
					A3(interpolate, a0, a1, v),
					A3(interpolate, b0, b1, v));
			});
		var lerp = F3(
			function (from, to, v) {
				return from + ((to - from) * v);
			});
		var casteljau = function (ps) {
			if (ps.b && (!ps.b.b)) {
				var _v1 = ps.a;
				var x = _v1.a;
				var y = _v1.b;
				return y;
			} else {
				var xs = ps;
				return casteljau(
					A3(
						$elm$core$List$map2,
						F2(
							function (x, y) {
								return A4(pair, lerp, x, y, time);
							}),
						xs,
						A2(
							$elm$core$Maybe$withDefault,
							_List_Nil,
							$elm$core$List$tail(xs))));
			}
		};
		return casteljau(
			_List_fromArray(
				[
					_Utils_Tuple2(0, 0),
					_Utils_Tuple2(x1, y1),
					_Utils_Tuple2(x2, y2),
					_Utils_Tuple2(1, 1)
				]));
	});
var $author$project$Shared$Easing$customBackOut = F2(
	function (strength, t) {
		var s = strength;
		var p = t - 1;
		return ((p * p) * (((s + 1) * p) + s)) + 1;
	});
var $author$project$Shared$Easing$customBackIn = F2(
	function (strength, t) {
		return 1.0 - A2($author$project$Shared$Easing$customBackOut, strength, 1.0 - t);
	});
var $author$project$Shared$Easing$customBackInOut = F2(
	function (_v0, t) {
		var strengthIn = _v0.a;
		var strengthOut = _v0.b;
		return (t < 0.5) ? (A2($author$project$Shared$Easing$customBackIn, strengthIn, t * 2) * 0.5) : (0.5 + (A2($author$project$Shared$Easing$customBackOut, strengthOut, (t - 0.5) * 2) * 0.5));
	});
var $elm_community$easing_functions$Ease$inBack = function (time) {
	return (time * time) * ((2.70158 * time) - 1.70158);
};
var $elm_community$easing_functions$Ease$flip = F2(
	function (easing, time) {
		return 1 - easing(1 - time);
	});
var $elm_community$easing_functions$Ease$outBounce = function (time) {
	var t4 = time - (2.625 / 2.75);
	var t3 = time - (2.25 / 2.75);
	var t2 = time - (1.5 / 2.75);
	var a = 7.5625;
	return (_Utils_cmp(time, 1 / 2.75) < 0) ? ((a * time) * time) : ((_Utils_cmp(time, 2 / 2.75) < 0) ? (((a * t2) * t2) + 0.75) : ((_Utils_cmp(time, 2.5 / 2.75) < 0) ? (((a * t3) * t3) + 0.9375) : (((a * t4) * t4) + 0.984375)));
};
var $elm_community$easing_functions$Ease$inBounce = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$outBounce);
var $elm_community$easing_functions$Ease$outCirc = function (time) {
	return $elm$core$Basics$sqrt(
		1 - A2($elm$core$Basics$pow, time - 1, 2));
};
var $elm_community$easing_functions$Ease$inCirc = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$outCirc);
var $elm_community$easing_functions$Ease$inCubic = function (time) {
	return A2($elm$core$Basics$pow, time, 3);
};
var $elm$core$Basics$pi = _Basics_pi;
var $elm_community$easing_functions$Ease$inElastic = function (time) {
	if (time === 0.0) {
		return 0.0;
	} else {
		var t = time - 1;
		var s = 0.075;
		var p = 0.3;
		return -(A2($elm$core$Basics$pow, 2, 10 * t) * $elm$core$Basics$sin(((t - s) * (2 * $elm$core$Basics$pi)) / p));
	}
};
var $elm_community$easing_functions$Ease$inExpo = function (time) {
	return (time === 0.0) ? 0.0 : A2($elm$core$Basics$pow, 2, 10 * (time - 1));
};
var $elm_community$easing_functions$Ease$inOut = F3(
	function (e1, e2, time) {
		return (time < 0.5) ? (e1(time * 2) / 2) : (0.5 + (e2((time - 0.5) * 2) / 2));
	});
var $elm_community$easing_functions$Ease$outBack = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inBack);
var $elm_community$easing_functions$Ease$inOutBack = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inBack, $elm_community$easing_functions$Ease$outBack);
var $elm_community$easing_functions$Ease$inOutBounce = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inBounce, $elm_community$easing_functions$Ease$outBounce);
var $elm_community$easing_functions$Ease$inOutCirc = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inCirc, $elm_community$easing_functions$Ease$outCirc);
var $elm_community$easing_functions$Ease$outCubic = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inCubic);
var $elm_community$easing_functions$Ease$inOutCubic = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inCubic, $elm_community$easing_functions$Ease$outCubic);
var $elm_community$easing_functions$Ease$outElastic = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inElastic);
var $elm_community$easing_functions$Ease$inOutElastic = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inElastic, $elm_community$easing_functions$Ease$outElastic);
var $elm_community$easing_functions$Ease$outExpo = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inExpo);
var $elm_community$easing_functions$Ease$inOutExpo = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inExpo, $elm_community$easing_functions$Ease$outExpo);
var $elm_community$easing_functions$Ease$inQuad = function (time) {
	return A2($elm$core$Basics$pow, time, 2);
};
var $elm_community$easing_functions$Ease$outQuad = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inQuad);
var $elm_community$easing_functions$Ease$inOutQuad = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inQuad, $elm_community$easing_functions$Ease$outQuad);
var $elm_community$easing_functions$Ease$inQuart = function (time) {
	return A2($elm$core$Basics$pow, time, 4);
};
var $elm_community$easing_functions$Ease$outQuart = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inQuart);
var $elm_community$easing_functions$Ease$inOutQuart = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inQuart, $elm_community$easing_functions$Ease$outQuart);
var $elm_community$easing_functions$Ease$inQuint = function (time) {
	return A2($elm$core$Basics$pow, time, 5);
};
var $elm_community$easing_functions$Ease$outQuint = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$inQuint);
var $elm_community$easing_functions$Ease$inOutQuint = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inQuint, $elm_community$easing_functions$Ease$outQuint);
var $elm_community$easing_functions$Ease$outSine = function (time) {
	return $elm$core$Basics$sin(time * ($elm$core$Basics$pi / 2));
};
var $elm_community$easing_functions$Ease$inSine = $elm_community$easing_functions$Ease$flip($elm_community$easing_functions$Ease$outSine);
var $elm_community$easing_functions$Ease$inOutSine = A2($elm_community$easing_functions$Ease$inOut, $elm_community$easing_functions$Ease$inSine, $elm_community$easing_functions$Ease$outSine);
var $elm_community$easing_functions$Ease$linear = $elm$core$Basics$identity;
var $author$project$Shared$Easing$toFunction = function (easing) {
	switch (easing.$) {
		case 12:
			var p1x = easing.a;
			var p1y = easing.b;
			var p2x = easing.c;
			var p2y = easing.d;
			return A4($elm_community$easing_functions$Ease$bezier, p1x, p1y, p2x, p2y);
		case 26:
			return $elm_community$easing_functions$Ease$linear;
		case 16:
			return $elm_community$easing_functions$Ease$inOutQuad;
		case 17:
			return $elm_community$easing_functions$Ease$inQuad;
		case 18:
			return $elm_community$easing_functions$Ease$outQuad;
		case 19:
			return $elm_community$easing_functions$Ease$inOutQuad;
		case 36:
			return $elm_community$easing_functions$Ease$inSine;
		case 37:
			return $elm_community$easing_functions$Ease$outSine;
		case 38:
			return $elm_community$easing_functions$Ease$inOutSine;
		case 27:
			return $elm_community$easing_functions$Ease$inQuad;
		case 28:
			return $elm_community$easing_functions$Ease$outQuad;
		case 29:
			return $elm_community$easing_functions$Ease$inOutQuad;
		case 13:
			return $elm_community$easing_functions$Ease$inCubic;
		case 14:
			return $elm_community$easing_functions$Ease$outCubic;
		case 15:
			return $elm_community$easing_functions$Ease$inOutCubic;
		case 30:
			return $elm_community$easing_functions$Ease$inQuart;
		case 31:
			return $elm_community$easing_functions$Ease$outQuart;
		case 32:
			return $elm_community$easing_functions$Ease$inOutQuart;
		case 33:
			return $elm_community$easing_functions$Ease$inQuint;
		case 34:
			return $elm_community$easing_functions$Ease$outQuint;
		case 35:
			return $elm_community$easing_functions$Ease$inOutQuint;
		case 23:
			return $elm_community$easing_functions$Ease$inExpo;
		case 24:
			return $elm_community$easing_functions$Ease$outExpo;
		case 25:
			return $elm_community$easing_functions$Ease$inOutExpo;
		case 9:
			return $elm_community$easing_functions$Ease$inCirc;
		case 10:
			return $elm_community$easing_functions$Ease$outCirc;
		case 11:
			return $elm_community$easing_functions$Ease$inOutCirc;
		case 0:
			return $elm_community$easing_functions$Ease$inBack;
		case 1:
			return $elm_community$easing_functions$Ease$outBack;
		case 2:
			return $elm_community$easing_functions$Ease$inOutBack;
		case 3:
			var strength = easing.a;
			return $author$project$Shared$Easing$customBackIn(strength);
		case 4:
			var strength = easing.a;
			return $author$project$Shared$Easing$customBackOut(strength);
		case 5:
			var strengthTuple = easing.a;
			return $author$project$Shared$Easing$customBackInOut(strengthTuple);
		case 20:
			return $elm_community$easing_functions$Ease$inElastic;
		case 21:
			return $elm_community$easing_functions$Ease$outElastic;
		case 22:
			return $elm_community$easing_functions$Ease$inOutElastic;
		case 6:
			return $elm_community$easing_functions$Ease$inBounce;
		case 7:
			return $elm_community$easing_functions$Ease$outBounce;
		default:
			return $elm_community$easing_functions$Ease$inOutBounce;
	}
};
var $author$project$Anim$Internal$Engine$Sub$Generator$toAnimation = F2(
	function (isComplete, propertyConfig) {
		var build = F2(
			function (_default, config) {
				var durationMs = config.cb;
				var easingFn = function () {
					var _v1 = config.aU;
					if (!_v1.$) {
						var s = _v1.a;
						return A2($author$project$Anim$Internal$Engine$Sub$Generator$springEasingFunction, s, durationMs);
					} else {
						return $author$project$Shared$Easing$toFunction(config.bc);
					}
				}();
				return {
					dK: config.ba,
					dR: easingFn,
					cc: 0.0,
					c: config.c,
					bN: isComplete,
					aV: A2($elm$core$Maybe$withDefault, _default, config.aV),
					fq: durationMs
				};
			});
		switch (propertyConfig.$) {
			case 0:
				var cssName = propertyConfig.a;
				var unit = propertyConfig.b;
				var config = propertyConfig.c;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'custom:' + cssName,
						A3(
							$author$project$Anim$Internal$Engine$Sub$Animation$CustomProperty,
							cssName,
							unit,
							A2(build, 0, config))));
			case 1:
				var cssName = propertyConfig.a;
				var config = propertyConfig.b;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'customColor:' + cssName,
						A2(
							$author$project$Anim$Internal$Engine$Sub$Animation$CustomColorProperty,
							cssName,
							A2(
								build,
								$author$project$Anim$Internal$Extra$Color$fromRGB(
									{b5: 0, ch: 0, cN: 0}),
								config))));
			case 2:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'opacity',
						$author$project$Anim$Internal$Engine$Sub$Animation$Opacity(
							A2(build, $author$project$Anim$Internal$Property$Opacity$default, config))));
			case 3:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'perspectiveOrigin',
						$author$project$Anim$Internal$Engine$Sub$Animation$PerspectiveOrigin(
							A2(build, $author$project$Anim$Internal$Property$PerspectiveOrigin$default, config))));
			case 4:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'rotate',
						$author$project$Anim$Internal$Engine$Sub$Animation$Rotate(
							A2(build, $author$project$Anim$Internal$Property$Rotate$default, config))));
			case 5:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'scale',
						$author$project$Anim$Internal$Engine$Sub$Animation$Scale(
							A2(build, $author$project$Anim$Internal$Property$Scale$default, config))));
			case 6:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'size',
						$author$project$Anim$Internal$Engine$Sub$Animation$Size(
							A2(build, $author$project$Anim$Internal$Property$Size$default, config))));
			case 7:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'skew',
						$author$project$Anim$Internal$Engine$Sub$Animation$Skew(
							A2(build, $author$project$Anim$Internal$Property$Skew$default, config))));
			default:
				var config = propertyConfig.a;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(
						'translate',
						$author$project$Anim$Internal$Engine$Sub$Animation$Translate(
							A2(build, $author$project$Anim$Internal$Property$Translate$default, config))));
		}
	});
var $author$project$Anim$Internal$Engine$Sub$Generator$init = F3(
	function (discreteEntryProps, discreteExitProps, properties) {
		var processedProps = A2($author$project$Anim$Internal$Builder$processProperties, $author$project$Anim$Internal$Builder$initDefaults, properties);
		var animations = $author$project$Anim$Internal$Engine$Sub$Animations$fromList(
			A2(
				$elm$core$List$filterMap,
				$author$project$Anim$Internal$Engine$Sub$Generator$toAnimation(true),
				processedProps));
		return A2(
			$author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteExit,
			discreteExitProps,
			A2(
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteEntry,
				discreteEntryProps,
				A2(
					$author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations,
					animations,
					A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState, 4, $author$project$Anim$Internal$Engine$Sub$AnimGroup$init))));
	});
var $elm$core$Dict$map = F2(
	function (func, dict) {
		if (dict.$ === -2) {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				A2(func, key, value),
				A2($elm$core$Dict$map, func, left),
				A2($elm$core$Dict$map, func, right));
		}
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$map = F2(
	function (f, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$map, f, dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$PropertyBaselines = $elm$core$Basics$identity;
var $author$project$Anim$Internal$Builder$PropertyBaselines$empty = $elm$core$Dict$empty;
var $author$project$Anim$Internal$Builder$PropertyBaselines$CustomColorPropertyValue = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty = F3(
	function (cssPropertyName, value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'customColor:' + cssPropertyName,
			$author$project$Anim$Internal$Builder$PropertyBaselines$CustomColorPropertyValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$CustomPropertyValue = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty = F4(
	function (cssPropertyName, value, unit, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'custom:' + cssPropertyName,
			A2($author$project$Anim$Internal$Builder$PropertyBaselines$CustomPropertyValue, value, unit),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$OpacityValue = function (a) {
	return {$: 2, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'opacity',
			$author$project$Anim$Internal$Builder$PropertyBaselines$OpacityValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$PerspectiveOriginValue = function (a) {
	return {$: 3, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'perspectiveOrigin',
			$author$project$Anim$Internal$Builder$PropertyBaselines$PerspectiveOriginValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$RotateValue = function (a) {
	return {$: 4, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setRotate = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'rotate',
			$author$project$Anim$Internal$Builder$PropertyBaselines$RotateValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$ScaleValue = function (a) {
	return {$: 5, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setScale = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'scale',
			$author$project$Anim$Internal$Builder$PropertyBaselines$ScaleValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$SizeValue = function (a) {
	return {$: 6, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setSize = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'size',
			$author$project$Anim$Internal$Builder$PropertyBaselines$SizeValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$SkewValue = function (a) {
	return {$: 7, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setSkew = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'skew',
			$author$project$Anim$Internal$Builder$PropertyBaselines$SkewValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$TranslateValue = function (a) {
	return {$: 8, a: a};
};
var $author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate = F2(
	function (value, _v0) {
		var dict = _v0;
		return A3(
			$elm$core$Dict$insert,
			'translate',
			$author$project$Anim$Internal$Builder$PropertyBaselines$TranslateValue(value),
			dict);
	});
var $author$project$Anim$Internal$Builder$extractPropertyBaseline = F2(
	function (propConfig, baselines) {
		switch (propConfig.$) {
			case 8:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate, cfg.c, baselines);
			case 4:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setRotate, cfg.c, baselines);
			case 5:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setScale, cfg.c, baselines);
			case 7:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSkew, cfg.c, baselines);
			case 2:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity, cfg.c, baselines);
			case 3:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin, cfg.c, baselines);
			case 6:
				var cfg = propConfig.a;
				return A2($author$project$Anim$Internal$Builder$PropertyBaselines$setSize, cfg.c, baselines);
			case 0:
				var cssName = propConfig.a;
				var unit = propConfig.b;
				var cfg = propConfig.c;
				return A4($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty, cssName, cfg.c, unit, baselines);
			default:
				var cssName = propConfig.a;
				var cfg = propConfig.b;
				return A3($author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty, cssName, cfg.c, baselines);
		}
	});
var $author$project$Anim$Internal$Builder$extractBaselinesFromConfig = function (elementConfig) {
	return A3($elm$core$List$foldl, $author$project$Anim$Internal$Builder$extractPropertyBaseline, $author$project$Anim$Internal$Builder$PropertyBaselines$empty, elementConfig.z);
};
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$insert = F3(
	function (name, value, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$insert, name, value, dict);
	});
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === -2) {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$merge = F2(
	function (_v0, _v1) {
		var base = _v0;
		var override = _v1;
		return A2($elm$core$Dict$union, override, base);
	});
var $elm$core$Dict$merge = F6(
	function (leftStep, bothStep, rightStep, leftDict, rightDict, initialResult) {
		var stepState = F3(
			function (rKey, rValue, _v0) {
				stepState:
				while (true) {
					var list = _v0.a;
					var result = _v0.b;
					if (!list.b) {
						return _Utils_Tuple2(
							list,
							A3(rightStep, rKey, rValue, result));
					} else {
						var _v2 = list.a;
						var lKey = _v2.a;
						var lValue = _v2.b;
						var rest = list.b;
						if (_Utils_cmp(lKey, rKey) < 0) {
							var $temp$rKey = rKey,
								$temp$rValue = rValue,
								$temp$_v0 = _Utils_Tuple2(
								rest,
								A3(leftStep, lKey, lValue, result));
							rKey = $temp$rKey;
							rValue = $temp$rValue;
							_v0 = $temp$_v0;
							continue stepState;
						} else {
							if (_Utils_cmp(lKey, rKey) > 0) {
								return _Utils_Tuple2(
									list,
									A3(rightStep, rKey, rValue, result));
							} else {
								return _Utils_Tuple2(
									rest,
									A4(bothStep, lKey, lValue, rValue, result));
							}
						}
					}
				}
			});
		var _v3 = A3(
			$elm$core$Dict$foldl,
			stepState,
			_Utils_Tuple2(
				$elm$core$Dict$toList(leftDict),
				initialResult),
			rightDict);
		var leftovers = _v3.a;
		var intermediateResult = _v3.b;
		return A3(
			$elm$core$List$foldl,
			F2(
				function (_v4, result) {
					var k = _v4.a;
					var v = _v4.b;
					return A3(leftStep, k, v, result);
				}),
			intermediateResult,
			leftovers);
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict = function (_v0) {
	var dict = _v0;
	return dict;
};
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$merge = F6(
	function (leftStep, bothStep, rightStep, dictB, dictC, _v0) {
		var dictA = _v0;
		return A6(
			$elm$core$Dict$merge,
			F2(
				function (k, b) {
					return A2(
						$elm$core$Basics$composeR,
						$elm$core$Basics$identity,
						A2(
							$elm$core$Basics$composeR,
							A2(leftStep, k, b),
							$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict));
				}),
			F3(
				function (k, b, c) {
					return A2(
						$elm$core$Basics$composeR,
						$elm$core$Basics$identity,
						A2(
							$elm$core$Basics$composeR,
							A3(bothStep, k, b, c),
							$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict));
				}),
			F2(
				function (k, c) {
					return A2(
						$elm$core$Basics$composeR,
						$elm$core$Basics$identity,
						A2(
							$elm$core$Basics$composeR,
							A2(rightStep, k, c),
							$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict));
				}),
			dictB,
			dictC,
			dictA);
	});
var $author$project$Anim$Internal$Builder$mergeBaselines = function (_v0) {
	var data = _v0;
	var state = data.A;
	var animation = data.e;
	var newBaselines = A2(
		$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
		F2(
			function (_v1, config) {
				return $author$project$Anim$Internal$Builder$extractBaselinesFromConfig(config);
			}),
		animation.y);
	var mergeBoth = F3(
		function (key, _new, old) {
			return A2(
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
				key,
				A2($author$project$Anim$Internal$Builder$PropertyBaselines$merge, old, _new));
		});
	var newState = _Utils_update(
		state,
		{
			az: A6(
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$merge,
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
				mergeBoth,
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(newBaselines),
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(state.az),
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$init)
		});
	return _Utils_update(
		data,
		{A: newState});
};
var $author$project$Anim$Internal$Engine$Sub$init = function (propertyInitializers) {
	if (!propertyInitializers.b) {
		return A2(
			$author$project$Anim$Internal$Engine$Sub$AnimState,
			{
				aj: $author$project$Anim$Internal$Builder$init(_List_Nil),
				p: _List_Nil,
				X: false
			},
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$init);
	} else {
		var builder = $author$project$Anim$Internal$Builder$init(propertyInitializers);
		var initGroup = F2(
			function (_v1, _v2) {
				var properties = _v2.z;
				return A3(
					$author$project$Anim$Internal$Engine$Sub$Generator$init,
					$author$project$Anim$Internal$Builder$getDiscreteEntryProperties(builder),
					$author$project$Anim$Internal$Builder$getDiscreteExitProperties(builder),
					properties);
			});
		var animGroups = $author$project$Anim$Internal$Builder$getAnimGroups(builder);
		return A2(
			$author$project$Anim$Internal$Engine$Sub$AnimState,
			{
				aj: $author$project$Anim$Internal$Builder$clearAnimData(
					$author$project$Anim$Internal$Builder$mergeBaselines(builder)),
				p: _List_Nil,
				X: false
			},
			A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$map, initGroup, animGroups));
	}
};
var $author$project$Anim$Engine$Sub$init = $author$project$Anim$Internal$Engine$Sub$init;
var $author$project$Anim$Internal$Builder$TranslateConfig = function (a) {
	return {$: 8, a: a};
};
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === -2) {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1) {
					case 0:
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 1:
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $author$project$Anim$Internal$Builder$getFrozenAxes = F2(
	function (propName, _v0) {
		var data = _v0;
		return A2(
			$elm$core$Maybe$withDefault,
			_List_Nil,
			A2($elm$core$Dict$get, propName, data.e.ao));
	});
var $elm$core$List$isEmpty = function (xs) {
	if (!xs.b) {
		return true;
	} else {
		return false;
	}
};
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $elm$core$List$member = F2(
	function (x, xs) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a, x);
			},
			xs);
	});
var $author$project$Anim$Internal$Builder$Property$applyFrozenAxes = F6(
	function (propertyName, toRec, fromRec, calcDistance, builder, config) {
		var frozenAxes = A2($author$project$Anim$Internal$Builder$getFrozenAxes, propertyName, builder);
		if ($elm$core$List$isEmpty(frozenAxes)) {
			return config;
		} else {
			var _v0 = config.aV;
			if (_v0.$ === 1) {
				return config;
			} else {
				var startVal = _v0.a;
				var startRecord = toRec(startVal);
				var endRecord = toRec(config.c);
				var end = fromRec(
					{
						b_: A2($elm$core$List$member, 'x', frozenAxes) ? startRecord.b_ : endRecord.b_,
						b$: A2($elm$core$List$member, 'y', frozenAxes) ? startRecord.b$ : endRecord.b$,
						b0: A2($elm$core$List$member, 'z', frozenAxes) ? startRecord.b0 : endRecord.b0
					});
				return _Utils_update(
					config,
					{
						bF: A2(calcDistance, startVal, end),
						c: end
					});
			}
		}
	});
var $author$project$Anim$Internal$Property$Shared$Axis3$fromRecord = function (support) {
	return support.d3;
};
var $author$project$Anim$Internal$Property$Translate$fromRecord = $author$project$Anim$Internal$Property$Shared$Axis3$fromRecord($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Property$Shared$Axis3$toRecord = function (support) {
	return support.fm;
};
var $author$project$Anim$Internal$Property$Translate$toRecord = $author$project$Anim$Internal$Property$Shared$Axis3$toRecord($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$get = F2(
	function (name, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$get, name, dict);
	});
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (!maybe.$) {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Anim$Internal$Builder$getCurrentAnimGroupConfig = function (_v0) {
	var data = _v0;
	var _v1 = data.e.aC;
	if (_v1.$ === 1) {
		return {z: _List_Nil, q: data.b.ab};
	} else {
		var animGroupName = _v1.a;
		return A2(
			$elm$core$Maybe$withDefault,
			{z: _List_Nil, q: data.b.ab},
			A2(
				$elm$core$Maybe$map,
				function (config) {
					return _Utils_update(
						config,
						{
							q: function () {
								var _v2 = data.b.ab;
								if (!_v2.$) {
									var globalOrder = _v2.a;
									return $elm$core$Maybe$Just(globalOrder);
								} else {
									return config.q;
								}
							}()
						});
				},
				A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.e.y)));
	}
};
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $elm$core$Basics$not = _Basics_not;
var $author$project$Anim$Internal$Builder$propertyType = function (prop) {
	switch (prop.$) {
		case 0:
			var cssName = prop.a;
			return 'custom:' + cssName;
		case 1:
			var cssName = prop.a;
			return 'customColor:' + cssName;
		case 2:
			return 'opacity';
		case 3:
			return 'perspectiveOrigin';
		case 4:
			return 'rotate';
		case 5:
			return 'scale';
		case 6:
			return 'size';
		case 7:
			return 'skew';
		default:
			return 'translate';
	}
};
var $author$project$Anim$Internal$Builder$updateCurrentConfig = F2(
	function (config, _v0) {
		var data = _v0;
		var _v1 = data.e.aC;
		if (_v1.$ === 1) {
			return data;
		} else {
			var animKey = _v1.a;
			var newPropertyTypes = A2($elm$core$List$map, $author$project$Anim$Internal$Builder$propertyType, config.z);
			var anim = data.e;
			var mergedConfig = function () {
				var _v2 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animKey, anim.y);
				if (!_v2.$) {
					var existing = _v2.a;
					var mergedOrder = function () {
						var _v3 = config.q;
						if (!_v3.$) {
							return config.q;
						} else {
							return existing.q;
						}
					}();
					var filteredExisting = A2(
						$elm$core$List$filter,
						function (p) {
							return !A2(
								$elm$core$List$member,
								$author$project$Anim$Internal$Builder$propertyType(p),
								newPropertyTypes);
						},
						existing.z);
					return _Utils_update(
						existing,
						{
							z: _Utils_ap(filteredExisting, config.z),
							q: mergedOrder
						});
				} else {
					return config;
				}
			}();
			return _Utils_update(
				data,
				{
					e: _Utils_update(
						anim,
						{
							y: A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animKey, mergedConfig, anim.y)
						})
				});
		}
	});
var $author$project$Anim$Internal$Builder$Property$add = F2(
	function (propertyConfig, builder) {
		var config = $author$project$Anim$Internal$Builder$getCurrentAnimGroupConfig(builder);
		return A2(
			$author$project$Anim$Internal$Builder$updateCurrentConfig,
			_Utils_update(
				config,
				{
					z: _Utils_ap(
						config.z,
						_List_fromArray(
							[propertyConfig]))
				}),
			builder);
	});
var $author$project$Anim$Internal$Builder$Property$configsMatch = F2(
	function (prop1, prop2) {
		var _v0 = _Utils_Tuple2(prop1, prop2);
		_v0$9:
		while (true) {
			switch (_v0.a.$) {
				case 0:
					if (!_v0.b.$) {
						var _v1 = _v0.a;
						var name1 = _v1.a;
						var _v2 = _v0.b;
						var name2 = _v2.a;
						return _Utils_eq(name1, name2);
					} else {
						break _v0$9;
					}
				case 1:
					if (_v0.b.$ === 1) {
						var _v3 = _v0.a;
						var name1 = _v3.a;
						var _v4 = _v0.b;
						var name2 = _v4.a;
						return _Utils_eq(name1, name2);
					} else {
						break _v0$9;
					}
				case 2:
					if (_v0.b.$ === 2) {
						return true;
					} else {
						break _v0$9;
					}
				case 3:
					if (_v0.b.$ === 3) {
						return true;
					} else {
						break _v0$9;
					}
				case 4:
					if (_v0.b.$ === 4) {
						return true;
					} else {
						break _v0$9;
					}
				case 5:
					if (_v0.b.$ === 5) {
						return true;
					} else {
						break _v0$9;
					}
				case 6:
					if (_v0.b.$ === 6) {
						return true;
					} else {
						break _v0$9;
					}
				case 7:
					if (_v0.b.$ === 7) {
						return true;
					} else {
						break _v0$9;
					}
				default:
					if (_v0.b.$ === 8) {
						return true;
					} else {
						break _v0$9;
					}
			}
		}
		return false;
	});
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Anim$Internal$Builder$Property$find = function (predicate) {
	return A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Internal$Builder$getCurrentAnimGroupConfig,
		A2(
			$elm$core$Basics$composeR,
			function ($) {
				return $.z;
			},
			A2(
				$elm$core$Basics$composeR,
				$elm$core$List$filter(predicate),
				$elm$core$List$head)));
};
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $author$project$Anim$Internal$Builder$Property$replace = F2(
	function (propertyConfig, builder) {
		var config = $author$project$Anim$Internal$Builder$getCurrentAnimGroupConfig(builder);
		var properties = _Utils_ap(
			A2(
				$elm$core$List$filter,
				A2(
					$elm$core$Basics$composeL,
					$elm$core$Basics$not,
					$author$project$Anim$Internal$Builder$Property$configsMatch(propertyConfig)),
				config.z),
			_List_fromArray(
				[propertyConfig]));
		return A2(
			$author$project$Anim$Internal$Builder$updateCurrentConfig,
			_Utils_update(
				config,
				{z: properties}),
			builder);
	});
var $author$project$Anim$Internal$Builder$Property$upsert = F2(
	function (propertyConfig, builder) {
		var _v0 = A2(
			$author$project$Anim$Internal$Builder$Property$find,
			$author$project$Anim$Internal$Builder$Property$configsMatch(propertyConfig),
			builder);
		if (!_v0.$) {
			return A2($author$project$Anim$Internal$Builder$Property$replace, propertyConfig, builder);
		} else {
			return A2($author$project$Anim$Internal$Builder$Property$add, propertyConfig, builder);
		}
	});
var $author$project$Anim$Internal$Builder$Translate$build = function (_v0) {
	var config = _v0.a;
	var builder = _v0.b;
	return A2(
		$author$project$Anim$Internal$Builder$Property$upsert,
		$author$project$Anim$Internal$Builder$TranslateConfig(
			A6($author$project$Anim$Internal$Builder$Property$applyFrozenAxes, 'translate', $author$project$Anim$Internal$Property$Translate$toRecord, $author$project$Anim$Internal$Property$Translate$fromRecord, $author$project$Anim$Internal$Property$Translate$distance, builder, config)),
		builder);
};
var $author$project$Anim$Internal$Builder$Translate$TranslateBuilder = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $author$project$Anim$Internal$Builder$Property$defaultConfig = function (defaultEnd) {
	return {ba: $elm$core$Maybe$Nothing, bF: 0, bc: $elm$core$Maybe$Nothing, c: defaultEnd, aU: $elm$core$Maybe$Nothing, aV: $elm$core$Maybe$Nothing, bt: $elm$core$Maybe$Nothing};
};
var $author$project$Anim$Internal$Builder$Translate$defaultConfig = $author$project$Anim$Internal$Builder$Property$defaultConfig($author$project$Anim$Internal$Property$Translate$default);
var $author$project$Anim$Internal$Builder$for = F2(
	function (elementId, _v0) {
		var data = _v0;
		var anim = data.e;
		return _Utils_update(
			data,
			{
				e: _Utils_update(
					anim,
					{
						aC: $elm$core$Maybe$Just(elementId)
					})
			});
	});
var $elm$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		if (!maybeValue.$) {
			var value = maybeValue.a;
			return callback(value);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$Anim$Internal$Builder$getDelay = function (_v0) {
	var data = _v0;
	return data.b.T;
};
var $author$project$Anim$Internal$Builder$getEasing = function (_v0) {
	var data = _v0;
	return data.b.H;
};
var $author$project$Anim$Internal$Builder$getSpring = function (_v0) {
	var data = _v0;
	return data.b.U;
};
var $author$project$Anim$Internal$Builder$getTimeSpec = function (_v0) {
	var data = _v0;
	return data.b.I;
};
var $author$project$Anim$Internal$Builder$Property$applyGlobalDefaults = F2(
	function (builder, config) {
		return _Utils_update(
			config,
			{
				ba: function () {
					var _v0 = config.ba;
					if (!_v0.$) {
						var delay_ = _v0.a;
						return $elm$core$Maybe$Just(delay_);
					} else {
						return $author$project$Anim$Internal$Builder$getDelay(builder);
					}
				}(),
				bc: function () {
					var _v1 = config.bc;
					if (!_v1.$) {
						var easing_ = _v1.a;
						return $elm$core$Maybe$Just(easing_);
					} else {
						return $author$project$Anim$Internal$Builder$getEasing(builder);
					}
				}(),
				aU: function () {
					var _v2 = config.aU;
					if (!_v2.$) {
						var spring_ = _v2.a;
						return $elm$core$Maybe$Just(spring_);
					} else {
						return $author$project$Anim$Internal$Builder$getSpring(builder);
					}
				}(),
				bt: function () {
					var _v3 = config.bt;
					if (!_v3.$) {
						var timing_ = _v3.a;
						return $elm$core$Maybe$Just(timing_);
					} else {
						return $author$project$Anim$Internal$Builder$getTimeSpec(builder);
					}
				}()
			});
	});
var $author$project$Anim$Internal$Builder$getAnimGroupConfig = F2(
	function (animGroupName, _v0) {
		var data = _v0;
		return A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, data.e.y);
	});
var $author$project$Anim$Internal$Builder$getBaseline = F2(
	function (key, _v0) {
		var data = _v0;
		return A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, key, data.A.az);
	});
var $author$project$Anim$Internal$Builder$getRuntimeBaseline = F2(
	function (key, _v0) {
		var data = _v0;
		return A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, key, data.A.bo);
	});
var $author$project$Anim$Internal$Builder$Property$for = F5(
	function (animGroupName, extractBaseline, extractExisting, defaultConfig_, builder) {
		var runtimeValue = A2(
			$elm$core$Maybe$andThen,
			extractBaseline,
			A2($author$project$Anim$Internal$Builder$getRuntimeBaseline, animGroupName, builder));
		var existingConfig = A2(
			$elm$core$Maybe$andThen,
			A2(
				$elm$core$Basics$composeR,
				function ($) {
					return $.z;
				},
				A2(
					$elm$core$Basics$composeR,
					$elm$core$List$filterMap(extractExisting),
					$elm$core$List$head)),
			A2($author$project$Anim$Internal$Builder$getAnimGroupConfig, animGroupName, builder));
		var baselineValue = A2(
			$elm$core$Maybe$andThen,
			extractBaseline,
			A2($author$project$Anim$Internal$Builder$getBaseline, animGroupName, builder));
		if (!existingConfig.$) {
			var config = existingConfig.a;
			return A2(
				$author$project$Anim$Internal$Builder$Property$applyGlobalDefaults,
				builder,
				_Utils_update(
					config,
					{
						ba: $elm$core$Maybe$Nothing,
						bF: 0,
						bc: $elm$core$Maybe$Nothing,
						c: config.c,
						aU: $elm$core$Maybe$Nothing,
						aV: $elm$core$List$head(
							A2(
								$elm$core$List$filterMap,
								$elm$core$Basics$identity,
								_List_fromArray(
									[
										runtimeValue,
										baselineValue,
										$elm$core$Maybe$Just(config.c)
									]))),
						bt: $elm$core$Maybe$Nothing
					}));
		} else {
			var _v1 = _Utils_Tuple2(runtimeValue, baselineValue);
			if (!_v1.a.$) {
				if (!_v1.b.$) {
					var runtime = _v1.a.a;
					var baseline = _v1.b.a;
					return A2(
						$author$project$Anim$Internal$Builder$Property$applyGlobalDefaults,
						builder,
						_Utils_update(
							defaultConfig_,
							{
								c: baseline,
								aV: $elm$core$Maybe$Just(runtime)
							}));
				} else {
					var runtime = _v1.a.a;
					var _v2 = _v1.b;
					return A2(
						$author$project$Anim$Internal$Builder$Property$applyGlobalDefaults,
						builder,
						_Utils_update(
							defaultConfig_,
							{
								c: runtime,
								aV: $elm$core$Maybe$Just(runtime)
							}));
				}
			} else {
				if (!_v1.b.$) {
					var _v3 = _v1.a;
					var baseline = _v1.b.a;
					return A2(
						$author$project$Anim$Internal$Builder$Property$applyGlobalDefaults,
						builder,
						_Utils_update(
							defaultConfig_,
							{
								c: baseline,
								aV: $elm$core$Maybe$Just(baseline)
							}));
				} else {
					var _v4 = _v1.a;
					var _v5 = _v1.b;
					return A2($author$project$Anim$Internal$Builder$Property$applyGlobalDefaults, builder, defaultConfig_);
				}
			}
		}
	});
var $author$project$Anim$Internal$Builder$PropertyBaselines$getTranslate = function (_v0) {
	var dict = _v0;
	return A2(
		$elm$core$Maybe$andThen,
		function (v) {
			if (v.$ === 8) {
				var t = v.a;
				return $elm$core$Maybe$Just(t);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		A2($elm$core$Dict$get, 'translate', dict));
};
var $author$project$Anim$Internal$Builder$Translate$for = F2(
	function (animGroupName, builder) {
		var extractExisting = function (propertyConfig) {
			if (propertyConfig.$ === 8) {
				var cfg = propertyConfig.a;
				return $elm$core$Maybe$Just(cfg);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		};
		var config = A5($author$project$Anim$Internal$Builder$Property$for, animGroupName, $author$project$Anim$Internal$Builder$PropertyBaselines$getTranslate, extractExisting, $author$project$Anim$Internal$Builder$Translate$defaultConfig, builder);
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			config,
			A2($author$project$Anim$Internal$Builder$for, animGroupName, builder));
	});
var $author$project$Anim$Internal$Builder$Translate$default = 0.0;
var $author$project$Anim$Internal$Builder$Translate$from = F2(
	function (value, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			_Utils_update(
				config,
				{
					aV: $elm$core$Maybe$Just(value)
				}),
			builder);
	});
var $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple = F2(
	function (support, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		var z = _v0.c;
		return support.d3(
			{b_: x, b$: y, b0: z});
	});
var $author$project$Anim$Internal$Property$Translate$fromTriple = $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Builder$Translate$fromXYZ = F3(
	function (x, y, z) {
		return $author$project$Anim$Internal$Builder$Translate$from(
			$author$project$Anim$Internal$Property$Translate$fromTriple(
				_Utils_Tuple3(x, y, z)));
	});
var $author$project$Anim$Internal$Builder$Property$getFloat = F2(
	function (getAxis, _default) {
		return A2(
			$elm$core$Basics$composeR,
			$elm$core$Maybe$map(getAxis),
			$elm$core$Maybe$withDefault(_default));
	});
var $author$project$Anim$Internal$Property$Translate$getZ = function (_v0) {
	var coords = _v0;
	return coords.b0;
};
var $author$project$Anim$Internal$Builder$Translate$fromXY = F3(
	function (x, y, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		var z = A3($author$project$Anim$Internal$Builder$Property$getFloat, $author$project$Anim$Internal$Property$Translate$getZ, $author$project$Anim$Internal$Builder$Translate$default, config.aV);
		return A4(
			$author$project$Anim$Internal$Builder$Translate$fromXYZ,
			x,
			y,
			z,
			A2($author$project$Anim$Internal$Builder$Translate$TranslateBuilder, config, builder));
	});
var $author$project$Anim$Property$Translate$fromXY = $author$project$Anim$Internal$Builder$Translate$fromXY;
var $author$project$Anim$Internal$Builder$Translate$to = F2(
	function (value, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		var startVal = A2($elm$core$Maybe$withDefault, $author$project$Anim$Internal$Property$Translate$default, config.aV);
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			_Utils_update(
				config,
				{
					bF: A2($author$project$Anim$Internal$Property$Translate$distance, startVal, value),
					c: value,
					aV: $elm$core$Maybe$Just(startVal)
				}),
			builder);
	});
var $author$project$Anim$Internal$Builder$Translate$toXYZ = F3(
	function (x, y, z) {
		return $author$project$Anim$Internal$Builder$Translate$to(
			$author$project$Anim$Internal$Property$Translate$fromTriple(
				_Utils_Tuple3(x, y, z)));
	});
var $author$project$Anim$Internal$Builder$Translate$toXY = F3(
	function (x, y, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		var z = $author$project$Anim$Internal$Property$Translate$getZ(config.c);
		return A4(
			$author$project$Anim$Internal$Builder$Translate$toXYZ,
			x,
			y,
			z,
			A2($author$project$Anim$Internal$Builder$Translate$TranslateBuilder, config, builder));
	});
var $author$project$Anim$Property$Translate$initXY = F4(
	function (animationKey, x, y, animBuilder) {
		return $author$project$Anim$Internal$Builder$Translate$build(
			A3(
				$author$project$Anim$Internal$Builder$Translate$toXY,
				x,
				y,
				A3(
					$author$project$Anim$Property$Translate$fromXY,
					x,
					y,
					A2($author$project$Anim$Internal$Builder$Translate$for, animationKey, animBuilder))));
	});
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$init = function (_v0) {
	var width = _v0.c$;
	var height = _v0.cj;
	var w = width - 20;
	var h = height - 75;
	return _Utils_Tuple2(
		{
			o: $author$project$Anim$Engine$Sub$init(
				_List_fromArray(
					[
						A3($author$project$Anim$Property$Translate$initXY, $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$animGroupName, (w - $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$boxWidth) / 2, (h - $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$boxWidth) / 2)
					])),
			cj: h,
			c$: w
		},
		$elm$core$Platform$Cmd$none);
};
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$GotAnimationUpdate = function (a) {
	return {$: 0, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$AnimationFrame = $elm$core$Basics$identity;
var $elm$core$Platform$Sub$map = _Platform_map;
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $elm$core$Platform$Sub$none = $elm$core$Platform$Sub$batch(_List_Nil);
var $elm$browser$Browser$AnimationManager$Delta = function (a) {
	return {$: 1, a: a};
};
var $elm$browser$Browser$AnimationManager$State = F3(
	function (subs, request, oldTime) {
		return {bQ: oldTime, cP: request, cV: subs};
	});
var $elm$browser$Browser$AnimationManager$init = $elm$core$Task$succeed(
	A3($elm$browser$Browser$AnimationManager$State, _List_Nil, $elm$core$Maybe$Nothing, 0));
var $elm$core$Process$kill = _Scheduler_kill;
var $elm$browser$Browser$AnimationManager$now = _Browser_now(0);
var $elm$browser$Browser$AnimationManager$rAF = _Browser_rAF(0);
var $elm$core$Platform$sendToSelf = _Platform_sendToSelf;
var $elm$core$Process$spawn = _Scheduler_spawn;
var $elm$browser$Browser$AnimationManager$onEffects = F3(
	function (router, subs, _v0) {
		var request = _v0.cP;
		var oldTime = _v0.bQ;
		var _v1 = _Utils_Tuple2(request, subs);
		if (_v1.a.$ === 1) {
			if (!_v1.b.b) {
				var _v2 = _v1.a;
				return $elm$browser$Browser$AnimationManager$init;
			} else {
				var _v4 = _v1.a;
				return A2(
					$elm$core$Task$andThen,
					function (pid) {
						return A2(
							$elm$core$Task$andThen,
							function (time) {
								return $elm$core$Task$succeed(
									A3(
										$elm$browser$Browser$AnimationManager$State,
										subs,
										$elm$core$Maybe$Just(pid),
										time));
							},
							$elm$browser$Browser$AnimationManager$now);
					},
					$elm$core$Process$spawn(
						A2(
							$elm$core$Task$andThen,
							$elm$core$Platform$sendToSelf(router),
							$elm$browser$Browser$AnimationManager$rAF)));
			}
		} else {
			if (!_v1.b.b) {
				var pid = _v1.a.a;
				return A2(
					$elm$core$Task$andThen,
					function (_v3) {
						return $elm$browser$Browser$AnimationManager$init;
					},
					$elm$core$Process$kill(pid));
			} else {
				return $elm$core$Task$succeed(
					A3($elm$browser$Browser$AnimationManager$State, subs, request, oldTime));
			}
		}
	});
var $elm$time$Time$Posix = $elm$core$Basics$identity;
var $elm$time$Time$millisToPosix = $elm$core$Basics$identity;
var $elm$browser$Browser$AnimationManager$onSelfMsg = F3(
	function (router, newTime, _v0) {
		var subs = _v0.cV;
		var oldTime = _v0.bQ;
		var send = function (sub) {
			if (!sub.$) {
				var tagger = sub.a;
				return A2(
					$elm$core$Platform$sendToApp,
					router,
					tagger(
						$elm$time$Time$millisToPosix(newTime)));
			} else {
				var tagger = sub.a;
				return A2(
					$elm$core$Platform$sendToApp,
					router,
					tagger(newTime - oldTime));
			}
		};
		return A2(
			$elm$core$Task$andThen,
			function (pid) {
				return A2(
					$elm$core$Task$andThen,
					function (_v1) {
						return $elm$core$Task$succeed(
							A3(
								$elm$browser$Browser$AnimationManager$State,
								subs,
								$elm$core$Maybe$Just(pid),
								newTime));
					},
					$elm$core$Task$sequence(
						A2($elm$core$List$map, send, subs)));
			},
			$elm$core$Process$spawn(
				A2(
					$elm$core$Task$andThen,
					$elm$core$Platform$sendToSelf(router),
					$elm$browser$Browser$AnimationManager$rAF)));
	});
var $elm$browser$Browser$AnimationManager$Time = function (a) {
	return {$: 0, a: a};
};
var $elm$browser$Browser$AnimationManager$subMap = F2(
	function (func, sub) {
		if (!sub.$) {
			var tagger = sub.a;
			return $elm$browser$Browser$AnimationManager$Time(
				A2($elm$core$Basics$composeL, func, tagger));
		} else {
			var tagger = sub.a;
			return $elm$browser$Browser$AnimationManager$Delta(
				A2($elm$core$Basics$composeL, func, tagger));
		}
	});
_Platform_effectManagers['Browser.AnimationManager'] = _Platform_createManager($elm$browser$Browser$AnimationManager$init, $elm$browser$Browser$AnimationManager$onEffects, $elm$browser$Browser$AnimationManager$onSelfMsg, 0, $elm$browser$Browser$AnimationManager$subMap);
var $elm$browser$Browser$AnimationManager$subscription = _Platform_leaf('Browser.AnimationManager');
var $elm$browser$Browser$AnimationManager$onAnimationFrameDelta = function (tagger) {
	return $elm$browser$Browser$AnimationManager$subscription(
		$elm$browser$Browser$AnimationManager$Delta(tagger));
};
var $elm$browser$Browser$Events$onAnimationFrameDelta = $elm$browser$Browser$AnimationManager$onAnimationFrameDelta;
var $author$project$Anim$Internal$Engine$Sub$subscriptions = F2(
	function (toMsg, _v0) {
		var state = _v0.a;
		return state.X ? A2(
			$elm$core$Platform$Sub$map,
			toMsg,
			$elm$browser$Browser$Events$onAnimationFrameDelta($elm$core$Basics$identity)) : $elm$core$Platform$Sub$none;
	});
var $author$project$Anim$Engine$Sub$subscriptions = $author$project$Anim$Internal$Engine$Sub$subscriptions;
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$subscriptions = function (model) {
	return A2($author$project$Anim$Engine$Sub$subscriptions, $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$GotAnimationUpdate, model.o);
};
var $author$project$Anim$Internal$Engine$Sub$Started = function (a) {
	return {$: 0, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Animations$add = F2(
	function (_v0, _v1) {
		var additional = _v0;
		var existing = _v1;
		return A2($elm$core$Dict$union, existing, additional);
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$addAnimation = F2(
	function (additional, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{
				aM: A2($author$project$Anim$Internal$Engine$Sub$Animations$add, additional, group.aM)
			});
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$foldl = F3(
	function (f, acc, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$foldl, f, acc, dict);
	});
var $author$project$Anim$Internal$Builder$addAnimationToHistory = F2(
	function (processedData, _v0) {
		var data = _v0;
		return A3(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$foldl,
			F3(
				function (animGroupName, groupConfig, _v1) {
					var accData = _v1;
					var state = accData.A;
					var existingHistory = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, state.ay);
					var updatedHistory = function () {
						if (existingHistory.$ === 1) {
							return {aO: groupConfig, be: _List_Nil};
						} else {
							var existing = existingHistory.a;
							return {
								aO: groupConfig,
								be: A2($elm$core$List$cons, existing.aO, existing.be)
							};
						}
					}();
					return _Utils_update(
						accData,
						{
							A: _Utils_update(
								state,
								{
									ay: A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animGroupName, updatedHistory, state.ay)
								})
						});
				}),
			data,
			processedData.bJ);
	});
var $author$project$Anim$Internal$Engine$Shared$PlayState$Running = 1;
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getTransformOrder = function (_v0) {
	var group = _v0;
	return group.q;
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimationDirection = F2(
	function (direction, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{ah: direction});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setCurrentIteration = F2(
	function (currentIteration, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{bC: currentIteration});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setIterationCount = F2(
	function (iterationCount, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{ac: iterationCount});
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$setTransformOrder = F2(
	function (transformOrder, _v0) {
		var group = _v0;
		return _Utils_update(
			group,
			{q: transformOrder});
	});
var $author$project$Anim$Internal$Engine$Sub$Generator$generateAnimation = F7(
	function (iterationCount, directionConfig, maybeOrder, discreteEntryProps, discreteExitProps, existingAnimation, properties) {
		var transformOrder = function () {
			if (!maybeOrder.$) {
				var order = maybeOrder.a;
				return order;
			} else {
				return A2(
					$elm$core$Maybe$withDefault,
					$author$project$Anim$Extra$TransformOrder$default,
					A2($elm$core$Maybe$map, $author$project$Anim$Internal$Engine$Sub$AnimGroup$getTransformOrder, existingAnimation));
			}
		}();
		var animations = $author$project$Anim$Internal$Engine$Sub$Animations$fromList(
			A2(
				$elm$core$List$filterMap,
				$author$project$Anim$Internal$Engine$Sub$Generator$toAnimation(false),
				properties));
		return A2(
			$author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteExit,
			discreteExitProps,
			A2(
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$setDiscreteEntry,
				discreteEntryProps,
				A2(
					$author$project$Anim$Internal$Engine$Sub$AnimGroup$setTransformOrder,
					transformOrder,
					A2(
						$author$project$Anim$Internal$Engine$Sub$AnimGroup$setCurrentIteration,
						1,
						A2(
							$author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimationDirection,
							directionConfig,
							A2(
								$author$project$Anim$Internal$Engine$Sub$AnimGroup$setIterationCount,
								iterationCount,
								A2(
									$author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState,
									1,
									A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations, animations, $author$project$Anim$Internal$Engine$Sub$AnimGroup$init))))))));
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations = function (_v0) {
	var group = _v0;
	return group.aM;
};
var $author$project$Anim$Internal$Builder$injectCurrentStates = F2(
	function (animGroups, _v0) {
		var data = _v0;
		var state = data.A;
		var runtimeSnapshots = A2(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
			F2(
				function (_v1, animation) {
					return animation.eH;
				}),
			animGroups);
		var mergedRuntimeBaselines = A6(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$merge,
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
			F3(
				function (key, _new, old) {
					return A2(
						$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
						key,
						A2($author$project$Anim$Internal$Builder$PropertyBaselines$merge, old, _new));
				}),
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(runtimeSnapshots),
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$toDict(state.az),
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$init);
		return _Utils_update(
			data,
			{
				A: _Utils_update(
					state,
					{bo: mergedRuntimeBaselines})
			});
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$names = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$keys(dict);
};
var $author$project$Anim$Internal$Builder$process = function (_v0) {
	var data = _v0;
	return {
		ah: data.f.ah,
		T: data.b.T,
		H: data.b.H,
		U: data.b.U,
		I: data.b.I,
		bJ: A2(
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
			F2(
				function (_v1, group) {
					return {
						z: A2($author$project$Anim$Internal$Builder$processProperties, data.b, group.z),
						q: function () {
							var _v2 = group.q;
							if (!_v2.$) {
								return group.q;
							} else {
								return data.b.ab;
							}
						}()
					};
				}),
			data.e.y),
		ac: data.f.ac
	};
};
var $author$project$Anim$Internal$Extra$Color$Hsl = function (a) {
	return {$: 3, a: a};
};
var $author$project$Anim$Internal$Extra$Color$Hsla = function (a) {
	return {$: 4, a: a};
};
var $elm$core$List$maximum = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(
			A3($elm$core$List$foldl, $elm$core$Basics$max, x, xs));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$List$minimum = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(
			A3($elm$core$List$foldl, $elm$core$Basics$min, x, xs));
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$Anim$Internal$Extra$Color$rgbToHsl = function (rgb_) {
	var r = rgb_.cN / 255;
	var g = rgb_.ch / 255;
	var b = rgb_.b5 / 255;
	var maxVal = A2(
		$elm$core$Maybe$withDefault,
		0,
		$elm$core$List$maximum(
			_List_fromArray(
				[r, g, b])));
	var minVal = A2(
		$elm$core$Maybe$withDefault,
		0,
		$elm$core$List$minimum(
			_List_fromArray(
				[r, g, b])));
	var delta = maxVal - minVal;
	var h = (!delta) ? 0 : (_Utils_eq(maxVal, r) ? (60 * A2($author$project$Anim$Internal$Extra$Color$floatMod, (g - b) / delta, 6)) : (_Utils_eq(maxVal, g) ? (60 * (((b - r) / delta) + 2)) : (60 * (((r - g) / delta) + 4))));
	var hNormalized = (h < 0) ? (h + 360) : ((h >= 360) ? (h - 360) : h);
	var l = (maxVal + minVal) / 2;
	var s = (!delta) ? 0 : (delta / (1 - $elm$core$Basics$abs((2 * l) - 1)));
	return {ci: hNormalized, cr: l * 100, cQ: s * 100};
};
var $author$project$Anim$Internal$Extra$Color$rgbaToHsla = function (rgba_) {
	var rgb_ = {b5: rgba_.b5, ch: rgba_.ch, cN: rgba_.cN};
	var hsla_ = $author$project$Anim$Internal$Extra$Color$rgbToHsl(rgb_);
	return {b1: rgba_.b1, ci: hsla_.ci, cr: hsla_.cr, cQ: hsla_.cQ};
};
var $author$project$Anim$Internal$Extra$Color$toHsl = function (color) {
	switch (color.$) {
		case 3:
			var hsl_ = color.a;
			return hsl_;
		case 4:
			var hslaValue = color.a;
			return {ci: hslaValue.ci, cr: hslaValue.cr, cQ: hslaValue.cQ};
		default:
			return $author$project$Anim$Internal$Extra$Color$rgbToHsl(
				$author$project$Anim$Internal$Extra$Color$toRgb(color));
	}
};
var $author$project$Anim$Internal$Extra$Color$toHsla = function (color) {
	switch (color.$) {
		case 4:
			var hsla_ = color.a;
			return hsla_;
		case 2:
			var rgba_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$rgbaToHsla(rgba_);
		default:
			var hslValue = $author$project$Anim$Internal$Extra$Color$toHsl(color);
			return {b1: 1.0, ci: hslValue.ci, cr: hslValue.cr, cQ: hslValue.cQ};
	}
};
var $author$project$Anim$Internal$Extra$Color$hslaToRgba = function (hslaValue) {
	var rgb_ = $author$project$Anim$Internal$Extra$Color$hslToRgb(
		{ci: hslaValue.ci, cr: hslaValue.cr, cQ: hslaValue.cQ});
	return {b1: hslaValue.b1, b5: rgb_.b5, ch: rgb_.ch, cN: rgb_.cN};
};
var $author$project$Anim$Internal$Extra$Color$toRgba = function (color) {
	switch (color.$) {
		case 2:
			var rgba_ = color.a;
			return rgba_;
		case 4:
			var hsla_ = color.a;
			return $author$project$Anim$Internal$Extra$Color$hslaToRgba(hsla_);
		case 5:
			var elmColor_ = color.a;
			var rgba_ = $avh4$elm_color$Color$toRgba(elmColor_);
			return {
				b1: rgba_.a1,
				b5: $elm$core$Basics$round(rgba_.bB * 255),
				ch: $elm$core$Basics$round(rgba_.bI * 255),
				cN: $elm$core$Basics$round(rgba_.bS * 255)
			};
		default:
			var rgb_ = $author$project$Anim$Internal$Extra$Color$toRgb(color);
			return {b1: 1.0, b5: rgb_.b5, ch: rgb_.ch, cN: rgb_.cN};
	}
};
var $author$project$Anim$Internal$Extra$Color$interpolate = F3(
	function (t, start, end) {
		interpolate:
		while (true) {
			var _v0 = _Utils_Tuple2(start, end);
			_v0$5:
			while (true) {
				switch (_v0.a.$) {
					case 0:
						if (!_v0.b.$) {
							var startHex = _v0.a.a;
							var endHex = _v0.b.a;
							var startRgb = $author$project$Anim$Internal$Extra$Color$hexToRgb(startHex);
							var endRgb = $author$project$Anim$Internal$Extra$Color$hexToRgb(endHex);
							var g = $elm$core$Basics$round(startRgb.ch + ((endRgb.ch - startRgb.ch) * t));
							var r = $elm$core$Basics$round(startRgb.cN + ((endRgb.cN - startRgb.cN) * t));
							var b = $elm$core$Basics$round(startRgb.b5 + ((endRgb.b5 - startRgb.b5) * t));
							return $author$project$Anim$Internal$Extra$Color$Rgb(
								{b5: b, ch: g, cN: r});
						} else {
							break _v0$5;
						}
					case 1:
						if (_v0.b.$ === 1) {
							var startRgb = _v0.a.a;
							var endRgb = _v0.b.a;
							var r = $elm$core$Basics$round(startRgb.cN + ((endRgb.cN - startRgb.cN) * t));
							var g = $elm$core$Basics$round(startRgb.ch + ((endRgb.ch - startRgb.ch) * t));
							var b = $elm$core$Basics$round(startRgb.b5 + ((endRgb.b5 - startRgb.b5) * t));
							return $author$project$Anim$Internal$Extra$Color$Rgb(
								{b5: b, ch: g, cN: r});
						} else {
							break _v0$5;
						}
					case 2:
						if (_v0.b.$ === 2) {
							var startRgba = _v0.a.a;
							var endRgba = _v0.b.a;
							var r = $elm$core$Basics$round(startRgba.cN + ((endRgba.cN - startRgba.cN) * t));
							var g = $elm$core$Basics$round(startRgba.ch + ((endRgba.ch - startRgba.ch) * t));
							var b = $elm$core$Basics$round(startRgba.b5 + ((endRgba.b5 - startRgba.b5) * t));
							var a = startRgba.b1 + ((endRgba.b1 - startRgba.b1) * t);
							return $author$project$Anim$Internal$Extra$Color$Rgba(
								{b1: a, b5: b, ch: g, cN: r});
						} else {
							break _v0$5;
						}
					case 3:
						if (_v0.b.$ === 3) {
							var startHsl = _v0.a.a;
							var endHsl = _v0.b.a;
							var s = startHsl.cQ + ((endHsl.cQ - startHsl.cQ) * t);
							var l = startHsl.cr + ((endHsl.cr - startHsl.cr) * t);
							var h = startHsl.ci + ((endHsl.ci - startHsl.ci) * t);
							return $author$project$Anim$Internal$Extra$Color$Hsl(
								{ci: h, cr: l, cQ: s});
						} else {
							break _v0$5;
						}
					case 4:
						if (_v0.b.$ === 4) {
							var startHsla = _v0.a.a;
							var endHsla = _v0.b.a;
							var s = startHsla.cQ + ((endHsla.cQ - startHsla.cQ) * t);
							var l = startHsla.cr + ((endHsla.cr - startHsla.cr) * t);
							var h = startHsla.ci + ((endHsla.ci - startHsla.ci) * t);
							var a = startHsla.b1 + ((endHsla.b1 - startHsla.b1) * t);
							return $author$project$Anim$Internal$Extra$Color$Hsla(
								{b1: a, ci: h, cr: l, cQ: s});
						} else {
							break _v0$5;
						}
					default:
						break _v0$5;
				}
			}
			var startAlpha = function () {
				switch (start.$) {
					case 2:
						var rgba_ = start.a;
						return rgba_.b1;
					case 4:
						var hsla_ = start.a;
						return hsla_.b1;
					case 5:
						var elmColor_ = start.a;
						var rgba_ = $avh4$elm_color$Color$toRgba(elmColor_);
						return rgba_.a1;
					default:
						return 1.0;
				}
			}();
			var _v1 = _Utils_Tuple2(start, end);
			switch (_v1.b.$) {
				case 3:
					var startHsla = $author$project$Anim$Internal$Extra$Color$toHsla(start);
					var endHsla = $author$project$Anim$Internal$Extra$Color$toHsla(end);
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Hsla(startHsla),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Hsla(
						_Utils_update(
							endHsla,
							{b1: startAlpha}));
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				case 4:
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Hsla(
						$author$project$Anim$Internal$Extra$Color$toHsla(start)),
						$temp$end = end;
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				case 1:
					var startRgba = $author$project$Anim$Internal$Extra$Color$toRgba(start);
					var endRgba = $author$project$Anim$Internal$Extra$Color$toRgba(end);
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Rgba(startRgba),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Rgba(
						_Utils_update(
							endRgba,
							{b1: startAlpha}));
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				case 0:
					var startRgba = $author$project$Anim$Internal$Extra$Color$toRgba(start);
					var endRgba = $author$project$Anim$Internal$Extra$Color$toRgba(end);
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Rgba(startRgba),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Rgba(
						_Utils_update(
							endRgba,
							{b1: startAlpha}));
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				case 2:
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Rgba(
						$author$project$Anim$Internal$Extra$Color$toRgba(start)),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Rgba(
						$author$project$Anim$Internal$Extra$Color$toRgba(end));
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
				default:
					var startRgba = $author$project$Anim$Internal$Extra$Color$toRgba(start);
					var endRgba = $author$project$Anim$Internal$Extra$Color$toRgba(end);
					var $temp$t = t,
						$temp$start = $author$project$Anim$Internal$Extra$Color$Rgba(startRgba),
						$temp$end = $author$project$Anim$Internal$Extra$Color$Rgba(endRgba);
					t = $temp$t;
					start = $temp$start;
					end = $temp$end;
					continue interpolate;
			}
		}
	});
var $author$project$Anim$Internal$Engine$Sub$Interpolation$calculateProgress = function (timing) {
	if (timing.bN || (timing.fq <= 0)) {
		return 1.0;
	} else {
		var animationElapsedMs = A2($elm$core$Basics$max, 0, timing.cc - timing.dK);
		return (animationElapsedMs <= 0) ? 0.0 : A2($elm$core$Basics$min, 1.0, animationElapsedMs / timing.fq);
	}
};
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateEasedProgress = F2(
	function (interpolate, anim) {
		var easedProgress = anim.dR(
			$author$project$Anim$Internal$Engine$Sub$Interpolation$calculateProgress(anim));
		return A3(interpolate, easedProgress, anim.aV, anim.c);
	});
var $author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateEasedProgress;
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat = F3(
	function (t, start, end) {
		return start + ((end - start) * t);
	});
var $author$project$Anim$Internal$Engine$Sub$interpolateFloat = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat;
var $author$project$Anim$Internal$Property$Opacity$toFloat = function (_v0) {
	var o = _v0;
	return o;
};
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateOpacity = F3(
	function (t, start, end) {
		return $author$project$Anim$Internal$Property$Opacity$fromFloat(
			A3(
				$author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat,
				t,
				$author$project$Anim$Internal$Property$Opacity$toFloat(start),
				$author$project$Anim$Internal$Property$Opacity$toFloat(end)));
	});
var $author$project$Anim$Internal$Engine$Sub$interpolateOpacity = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateOpacity;
var $author$project$Anim$Internal$Property$PerspectiveOrigin$Px = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Property$PerspectiveOrigin$interpolate = F3(
	function (t, start, end) {
		var _v0 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(start);
		var sx = _v0.a;
		var sy = _v0.b;
		var _v1 = $author$project$Anim$Internal$Property$PerspectiveOrigin$toTuple(end);
		var ex = _v1.a;
		var ey = _v1.b;
		var ix = sx + ((ex - sx) * t);
		var iy = sy + ((ey - sy) * t);
		if (!end.$) {
			return $author$project$Anim$Internal$Property$PerspectiveOrigin$Percent(
				{b_: ix, b$: iy});
		} else {
			return $author$project$Anim$Internal$Property$PerspectiveOrigin$Px(
				{b_: ix, b$: iy});
		}
	});
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolatePerspectiveOrigin = $author$project$Anim$Internal$Property$PerspectiveOrigin$interpolate;
var $author$project$Anim$Internal$Engine$Sub$interpolatePerspectiveOrigin = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolatePerspectiveOrigin;
var $author$project$Anim$Internal$Property$Rotate$fromTriple = $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple($author$project$Anim$Internal$Property$Rotate$support);
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTriple = F5(
	function (toTriple, fromTriple, t, start, end) {
		var _v0 = toTriple(start);
		var s1 = _v0.a;
		var s2 = _v0.b;
		var s3 = _v0.c;
		var _v1 = toTriple(end);
		var e1 = _v1.a;
		var e2 = _v1.b;
		var e3 = _v1.c;
		return fromTriple(
			_Utils_Tuple3(
				A3($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat, t, s1, e1),
				A3($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat, t, s2, e2),
				A3($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat, t, s3, e3)));
	});
var $author$project$Anim$Internal$Property$Shared$Axis3$toTriple = F2(
	function (support, coord) {
		var record = support.fm(coord);
		return _Utils_Tuple3(record.b_, record.b$, record.b0);
	});
var $author$project$Anim$Internal$Property$Rotate$toTriple = $author$project$Anim$Internal$Property$Shared$Axis3$toTriple($author$project$Anim$Internal$Property$Rotate$support);
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateRotate = A2($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTriple, $author$project$Anim$Internal$Property$Rotate$toTriple, $author$project$Anim$Internal$Property$Rotate$fromTriple);
var $author$project$Anim$Internal$Engine$Sub$interpolateRotate = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateRotate;
var $author$project$Anim$Internal$Property$Scale$fromTriple = $author$project$Anim$Internal$Property$Shared$Axis3$fromTriple($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Property$Scale$toTriple = $author$project$Anim$Internal$Property$Shared$Axis3$toTriple($author$project$Anim$Internal$Property$Scale$support);
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateScale = A2($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTriple, $author$project$Anim$Internal$Property$Scale$toTriple, $author$project$Anim$Internal$Property$Scale$fromTriple);
var $author$project$Anim$Internal$Engine$Sub$interpolateScale = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateScale;
var $author$project$Anim$Internal$Property$Size$fromTuple = function (_v0) {
	var width = _v0.a;
	var height = _v0.b;
	return {ci: height, t: width};
};
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTuple = F5(
	function (toTuple, fromTuple, t, start, end) {
		var _v0 = toTuple(start);
		var s1 = _v0.a;
		var s2 = _v0.b;
		var _v1 = toTuple(end);
		var e1 = _v1.a;
		var e2 = _v1.b;
		return fromTuple(
			_Utils_Tuple2(
				A3($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat, t, s1, e1),
				A3($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateFloat, t, s2, e2)));
	});
var $author$project$Anim$Internal$Property$Size$toTuple = function (_v0) {
	var dimensions = _v0;
	return _Utils_Tuple2(dimensions.t, dimensions.ci);
};
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateSize = A2($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTuple, $author$project$Anim$Internal$Property$Size$toTuple, $author$project$Anim$Internal$Property$Size$fromTuple);
var $author$project$Anim$Internal$Engine$Sub$interpolateSize = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateSize;
var $author$project$Anim$Internal$Property$Skew$fromTuple = function (_v0) {
	var x = _v0.a;
	var y = _v0.b;
	return {b_: x, b$: y};
};
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateSkew = A2($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTuple, $author$project$Anim$Internal$Property$Skew$toTuple, $author$project$Anim$Internal$Property$Skew$fromTuple);
var $author$project$Anim$Internal$Engine$Sub$interpolateSkew = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateSkew;
var $author$project$Anim$Internal$Property$Translate$toTriple = $author$project$Anim$Internal$Property$Shared$Axis3$toTriple($author$project$Anim$Internal$Property$Translate$support);
var $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTranslate = A2($author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTriple, $author$project$Anim$Internal$Property$Translate$toTriple, $author$project$Anim$Internal$Property$Translate$fromTriple);
var $author$project$Anim$Internal$Engine$Sub$interpolateTranslate = $author$project$Anim$Internal$Engine$Sub$Interpolation$interpolateTranslate;
var $author$project$Anim$Internal$Engine$Sub$extractPropertyCurrentState = F2(
	function (anim, states) {
		switch (anim.$) {
			case 0:
				var cssName = anim.a;
				var unit = anim.b;
				var a = anim.c;
				return A4(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setCustomProperty,
					cssName,
					A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateFloat, a),
					unit,
					states);
			case 1:
				var cssName = anim.a;
				var a = anim.b;
				return A3(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setCustomColorProperty,
					cssName,
					A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Extra$Color$interpolate, a),
					states);
			case 2:
				var a = anim.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setOpacity,
					A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateOpacity, a),
					states);
			case 3:
				var a = anim.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setPerspectiveOrigin,
					A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolatePerspectiveOrigin, a),
					states);
			case 4:
				var a = anim.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setRotate,
					A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateRotate, a),
					states);
			case 5:
				var a = anim.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setScale,
					A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateScale, a),
					states);
			case 6:
				var a = anim.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setSize,
					A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateSize, a),
					states);
			case 7:
				var a = anim.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setSkew,
					A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateSkew, a),
					states);
			default:
				var a = anim.a;
				return A2(
					$author$project$Anim$Internal$Builder$PropertyBaselines$setTranslate,
					A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateTranslate, a),
					states);
		}
	});
var $author$project$Anim$Internal$Engine$Sub$Animations$foldl = F3(
	function (f, acc, _v0) {
		var dict = _v0;
		return A3($elm$core$Dict$foldl, f, acc, dict);
	});
var $author$project$Anim$Internal$Engine$Sub$extractElementCurrentStates = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations,
	A2(
		$author$project$Anim$Internal$Engine$Sub$Animations$foldl,
		function (_v0) {
			return $author$project$Anim$Internal$Engine$Sub$extractPropertyCurrentState;
		},
		$author$project$Anim$Internal$Builder$PropertyBaselines$empty));
var $author$project$Anim$Internal$Engine$Sub$setSnapshot = function (anims) {
	return A2(
		$author$project$Anim$Internal$Engine$Shared$AnimGroups$map,
		F2(
			function (_v0, anim) {
				return {
					eH: $author$project$Anim$Internal$Engine$Sub$extractElementCurrentStates(anim)
				};
			}),
		anims);
};
var $author$project$Anim$Internal$Engine$Sub$animate = F2(
	function (_v0, build) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var insertAnimGroup = F3(
			function (animGroupName, animGroup, acc) {
				var _v1 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, acc);
				if (_v1.$ === 1) {
					return A3($author$project$Anim$Internal$Engine$Shared$AnimGroups$insert, animGroupName, animGroup, acc);
				} else {
					var existing = _v1.a;
					return A3(
						$author$project$Anim$Internal$Engine$Shared$AnimGroups$insert,
						animGroupName,
						A2(
							$author$project$Anim$Internal$Engine$Sub$AnimGroup$addAnimation,
							$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations(existing),
							animGroup),
						acc);
				}
			});
		var builder = build(
			A2(
				$author$project$Anim$Internal$Builder$injectCurrentStates,
				$author$project$Anim$Internal$Engine$Sub$setSnapshot(animGroups),
				state.aj));
		var processed = $author$project$Anim$Internal$Builder$process(builder);
		var generateAnimGroup = F2(
			function (animGroupName, config) {
				return A7(
					$author$project$Anim$Internal$Engine$Sub$Generator$generateAnimation,
					processed.ac,
					processed.ah,
					config.q,
					$author$project$Anim$Internal$Builder$getDiscreteEntryProperties(builder),
					$author$project$Anim$Internal$Builder$getDiscreteExitProperties(builder),
					A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, animGroups),
					config.z);
			});
		var startedEvents = A2(
			$elm$core$List$map,
			$author$project$Anim$Internal$Engine$Sub$Started,
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$names(processed.bJ));
		return A2(
			$author$project$Anim$Internal$Engine$Sub$AnimState,
			{
				aj: $author$project$Anim$Internal$Builder$clearAnimData(
					$author$project$Anim$Internal$Builder$mergeBaselines(
						A2($author$project$Anim$Internal$Builder$addAnimationToHistory, processed, builder))),
				p: _Utils_ap(state.p, startedEvents),
				X: true
			},
			A3(
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$foldl,
				insertAnimGroup,
				animGroups,
				A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$map, generateAnimGroup, processed.bJ)));
	});
var $author$project$Anim$Engine$Sub$animate = $author$project$Anim$Internal$Engine$Sub$animate;
var $author$project$Anim$Internal$Builder$addIfMissing = F2(
	function (item, list) {
		return A2($elm$core$List$member, item, list) ? list : A2($elm$core$List$cons, item, list);
	});
var $author$project$Anim$Internal$Builder$freezePropertyName = function (prop) {
	switch (prop) {
		case 0:
			return 'translate';
		case 1:
			return 'rotate';
		case 2:
			return 'scale';
		default:
			return 'skew';
	}
};
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === -1) && (dict.d.$ === -1)) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.e.d.$ === -1) && (!dict.e.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, 1, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === -1) && (dict.d.$ === -1)) && (dict.e.$ === -1)) {
		if ((dict.d.d.$ === -1) && (!dict.d.d.a)) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				0,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, 1, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr === 1) {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					1,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, 0, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, 0, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === -1) && (!left.a)) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, 0, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === -1) && (right.a === 1)) {
					if (right.d.$ === -1) {
						if (right.d.a === 1) {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === -1) && (dict.d.$ === -1)) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor === 1) {
			if ((lLeft.$ === -1) && (!lLeft.a)) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === -1) {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === -2) {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === -1) && (left.a === 1)) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === -1) && (!lLeft.a)) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === -1) {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === -1) {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === -1) {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === -1) && (!_v0.a)) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, 1, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$update = F3(
	function (targetKey, alter, dictionary) {
		var _v0 = alter(
			A2($elm$core$Dict$get, targetKey, dictionary));
		if (!_v0.$) {
			var value = _v0.a;
			return A3($elm$core$Dict$insert, targetKey, value, dictionary);
		} else {
			return A2($elm$core$Dict$remove, targetKey, dictionary);
		}
	});
var $author$project$Anim$Internal$Builder$freezeAxes = F3(
	function (axes, properties, _v0) {
		var data = _v0;
		var propNames = A2($elm$core$List$map, $author$project$Anim$Internal$Builder$freezePropertyName, properties);
		var anim = data.e;
		var newFrozenAxes = A3(
			$elm$core$List$foldl,
			F2(
				function (propName, dict) {
					return A3(
						$elm$core$Dict$update,
						propName,
						function (maybeAxes) {
							if (!maybeAxes.$) {
								var existing = maybeAxes.a;
								return $elm$core$Maybe$Just(
									A3($elm$core$List$foldl, $author$project$Anim$Internal$Builder$addIfMissing, existing, axes));
							} else {
								return $elm$core$Maybe$Just(axes);
							}
						},
						dict);
				}),
			anim.ao,
			propNames);
		return _Utils_update(
			data,
			{
				e: _Utils_update(
					anim,
					{ao: newFrozenAxes})
			});
	});
var $author$project$Anim$Internal$Engine$Sub$freezeAxes = $author$project$Anim$Internal$Builder$freezeAxes;
var $author$project$Anim$Engine$Sub$freezeX = $author$project$Anim$Internal$Engine$Sub$freezeAxes(
	_List_fromArray(
		['x']));
var $author$project$Anim$Engine$Sub$freezeY = $author$project$Anim$Internal$Engine$Sub$freezeAxes(
	_List_fromArray(
		['y']));
var $author$project$Motion$Easing$BounceOut = {$: 7};
var $author$project$Anim$Property$Translate$build = $author$project$Anim$Internal$Builder$Translate$build;
var $author$project$Anim$Internal$Builder$Property$easing = F2(
	function (easing_, config) {
		return _Utils_update(
			config,
			{
				bc: $elm$core$Maybe$Just(easing_),
				aU: $elm$core$Maybe$Nothing
			});
	});
var $author$project$Anim$Internal$Builder$Translate$easing = F2(
	function (easing_, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			A2($author$project$Anim$Internal$Builder$Property$easing, easing_, config),
			builder);
	});
var $author$project$Anim$Property$Translate$easing = $author$project$Anim$Internal$Builder$Translate$easing;
var $author$project$Anim$Property$Translate$for = $author$project$Anim$Internal$Builder$Translate$for;
var $author$project$Shared$TimeSpec$Speed = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Builder$Property$speed = F2(
	function (value, config) {
		return _Utils_update(
			config,
			{
				bt: $elm$core$Maybe$Just(
					$author$project$Shared$TimeSpec$Speed(value))
			});
	});
var $author$project$Anim$Internal$Builder$Translate$speed = F2(
	function (value, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		return A2(
			$author$project$Anim$Internal$Builder$Translate$TranslateBuilder,
			A2($author$project$Anim$Internal$Builder$Property$speed, value, config),
			builder);
	});
var $author$project$Anim$Property$Translate$speed = $author$project$Anim$Internal$Builder$Translate$speed;
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveBox = function (moveFunc) {
	return A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Property$Translate$for($author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$animGroupName),
		A2(
			$elm$core$Basics$composeR,
			moveFunc,
			A2(
				$elm$core$Basics$composeR,
				$author$project$Anim$Property$Translate$speed(200),
				A2(
					$elm$core$Basics$composeR,
					$author$project$Anim$Property$Translate$easing($author$project$Motion$Easing$BounceOut),
					$author$project$Anim$Property$Translate$build))));
};
var $author$project$Anim$Internal$Property$Translate$getX = function (_v0) {
	var coords = _v0;
	return coords.b_;
};
var $author$project$Anim$Internal$Builder$Translate$toY = F2(
	function (y, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		var z = $author$project$Anim$Internal$Property$Translate$getZ(config.c);
		var x = $author$project$Anim$Internal$Property$Translate$getX(config.c);
		return A4(
			$author$project$Anim$Internal$Builder$Translate$toXYZ,
			x,
			y,
			z,
			A2($author$project$Anim$Internal$Builder$Translate$TranslateBuilder, config, builder));
	});
var $author$project$Anim$Property$Translate$toY = $author$project$Anim$Internal$Builder$Translate$toY;
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveDown = function (height) {
	return $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveBox(
		$author$project$Anim$Property$Translate$toY(height - $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$boxWidth));
};
var $author$project$Anim$Internal$Property$Translate$getY = function (_v0) {
	var coords = _v0;
	return coords.b$;
};
var $author$project$Anim$Internal$Builder$Translate$toX = F2(
	function (x, _v0) {
		var config = _v0.a;
		var builder = _v0.b;
		var z = $author$project$Anim$Internal$Property$Translate$getZ(config.c);
		var y = $author$project$Anim$Internal$Property$Translate$getY(config.c);
		return A4(
			$author$project$Anim$Internal$Builder$Translate$toXYZ,
			x,
			y,
			z,
			A2($author$project$Anim$Internal$Builder$Translate$TranslateBuilder, config, builder));
	});
var $author$project$Anim$Property$Translate$toX = $author$project$Anim$Internal$Builder$Translate$toX;
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveLeft = $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveBox(
	$author$project$Anim$Property$Translate$toX(0));
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveRight = function (width) {
	return $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveBox(
		$author$project$Anim$Property$Translate$toX(width - $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$boxWidth));
};
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveUp = $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveBox(
	$author$project$Anim$Property$Translate$toY(0));
var $author$project$Anim$Internal$Builder$FreezeTranslate = 0;
var $author$project$Anim$Internal$Engine$Sub$freezeTranslate = 0;
var $author$project$Anim$Engine$Sub$translate = $author$project$Anim$Internal$Engine$Sub$freezeTranslate;
var $elm$core$Tuple$mapSecond = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			x,
			func(y));
	});
var $author$project$Anim$Engine$Sub$Cancelled = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $author$project$Anim$Engine$Sub$Paused = F2(
	function (a, b) {
		return {$: 4, a: a, b: b};
	});
var $author$project$Anim$Engine$Sub$Restarted = function (a) {
	return {$: 3, a: a};
};
var $author$project$Anim$Engine$Sub$Resumed = function (a) {
	return {$: 5, a: a};
};
var $author$project$Anim$Engine$Sub$Started = function (a) {
	return {$: 0, a: a};
};
var $author$project$Anim$Engine$Sub$toControlAnimEvent = function (event) {
	switch (event.$) {
		case 0:
			var key = event.a;
			return $elm$core$Maybe$Just(
				$author$project$Anim$Engine$Sub$Started(key));
		case 1:
			var key = event.a;
			var progressValue = event.b;
			return $elm$core$Maybe$Just(
				A2($author$project$Anim$Engine$Sub$Cancelled, key, progressValue));
		case 2:
			var key = event.a;
			var progressValue = event.b;
			return $elm$core$Maybe$Just(
				A2($author$project$Anim$Engine$Sub$Paused, key, progressValue));
		case 3:
			var key = event.a;
			return $elm$core$Maybe$Just(
				$author$project$Anim$Engine$Sub$Resumed(key));
		default:
			var key = event.a;
			return $elm$core$Maybe$Just(
				$author$project$Anim$Engine$Sub$Restarted(key));
	}
};
var $author$project$Anim$Engine$Sub$Ended = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Engine$Sub$Iteration = F2(
	function (a, b) {
		return {$: 6, a: a, b: b};
	});
var $author$project$Anim$Engine$Sub$Progress = F2(
	function (a, b) {
		return {$: 7, a: a, b: b};
	});
var $author$project$Anim$Engine$Sub$toTickAnimEvent = function (event) {
	switch (event.$) {
		case 1:
			var key = event.a;
			return $elm$core$Maybe$Just(
				$author$project$Anim$Engine$Sub$Ended(key));
		case 2:
			var key = event.a;
			var iterationNumber = event.b;
			return $elm$core$Maybe$Just(
				A2($author$project$Anim$Engine$Sub$Iteration, key, iterationNumber));
		default:
			var key = event.a;
			var progressValue = event.b;
			return $elm$core$Maybe$Just(
				A2($author$project$Anim$Engine$Sub$Progress, key, progressValue));
	}
};
var $author$project$Anim$Engine$Sub$toAnimEvent = function (event) {
	if (!event.$) {
		var tickEvent = event.a;
		return $author$project$Anim$Engine$Sub$toTickAnimEvent(tickEvent);
	} else {
		var controlEvent = event.a;
		return $author$project$Anim$Engine$Sub$toControlAnimEvent(controlEvent);
	}
};
var $author$project$Anim$Internal$Engine$Sub$Control = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Tick = function (a) {
	return {$: 0, a: a};
};
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$fromList = A2($elm$core$Basics$composeL, $elm$core$Basics$identity, $elm$core$Dict$fromList);
var $elm$core$Dict$values = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, valueList) {
				return A2($elm$core$List$cons, value, valueList);
			}),
		_List_Nil,
		dict);
};
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$groups = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$values(dict);
};
var $author$project$Anim$Internal$Engine$Shared$PlayState$isRunning = function (state) {
	return state === 1;
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$isRunning = function (_v0) {
	var group = _v0;
	return $author$project$Anim$Internal$Engine$Shared$PlayState$isRunning(group.aR);
};
var $author$project$Anim$Internal$Engine$Sub$Ended = function (a) {
	return {$: 1, a: a};
};
var $author$project$Anim$Internal$Engine$Sub$Progress = F2(
	function (a, b) {
		return {$: 0, a: a, b: b};
	});
var $elm$core$List$all = F2(
	function (isOkay, list) {
		return !A2(
			$elm$core$List$any,
			A2($elm$core$Basics$composeL, $elm$core$Basics$not, isOkay),
			list);
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$toTiming = function (anim) {
	return {dK: anim.dK, cc: anim.cc, bN: anim.bN, fq: anim.fq};
};
var $author$project$Anim$Internal$Engine$Sub$Animation$foldTiming = F2(
	function (f, anim) {
		switch (anim.$) {
			case 0:
				var a = anim.c;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 1:
				var a = anim.b;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 2:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 3:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 4:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 5:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 6:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			case 7:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
			default:
				var a = anim.a;
				return f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a));
		}
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getCurrentIteration = function (_v0) {
	var group = _v0;
	return group.bC;
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getIterations = function (_v0) {
	var group = _v0;
	return group.ac;
};
var $author$project$Anim$Internal$Engine$Shared$PlayState$Paused = 2;
var $author$project$Anim$Internal$Engine$Shared$PlayState$isPaused = function (state) {
	return state === 2;
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$isPaused = function (_v0) {
	var group = _v0;
	return $author$project$Anim$Internal$Engine$Shared$PlayState$isPaused(group.aR);
};
var $author$project$Anim$Internal$Engine$Sub$Iteration = F2(
	function (a, b) {
		return {$: 2, a: a, b: b};
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimationDirection = function (_v0) {
	var group = _v0;
	return group.ah;
};
var $author$project$Anim$Internal$Engine$Sub$Animations$map = F2(
	function (f, _v0) {
		var dict = _v0;
		return A2($elm$core$Dict$map, f, dict);
	});
var $elm$core$Basics$modBy = _Basics_modBy;
var $author$project$Anim$Internal$Engine$Sub$Animation$applyTiming = F2(
	function (timing, anim) {
		return _Utils_update(
			anim,
			{dK: timing.dK, cc: timing.cc, bN: timing.bN, fq: timing.fq});
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$mapTiming = F2(
	function (f, anim) {
		var apply = function (a) {
			return A2(
				$author$project$Anim$Internal$Engine$Sub$Animation$applyTiming,
				f(
					$author$project$Anim$Internal$Engine$Sub$Animation$toTiming(a)),
				a);
		};
		switch (anim.$) {
			case 8:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Translate(
					apply(a));
			case 4:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Rotate(
					apply(a));
			case 7:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Skew(
					apply(a));
			case 5:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Scale(
					apply(a));
			case 2:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Opacity(
					apply(a));
			case 3:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$PerspectiveOrigin(
					apply(a));
			case 6:
				var a = anim.a;
				return $author$project$Anim$Internal$Engine$Sub$Animation$Size(
					apply(a));
			case 0:
				var cssName = anim.a;
				var unit = anim.b;
				var a = anim.c;
				return A3(
					$author$project$Anim$Internal$Engine$Sub$Animation$CustomProperty,
					cssName,
					unit,
					apply(a));
			default:
				var cssName = anim.a;
				var a = anim.b;
				return A2(
					$author$project$Anim$Internal$Engine$Sub$Animation$CustomColorProperty,
					cssName,
					apply(a));
		}
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$reset = $author$project$Anim$Internal$Engine$Sub$Animation$mapTiming(
	function (t) {
		return _Utils_update(
			t,
			{cc: 0, bN: false});
	});
var $author$project$Anim$Internal$Engine$Sub$Animation$reverse = function (anim) {
	var swap = function (a) {
		return _Utils_update(
			a,
			{c: a.aV, aV: a.c});
	};
	switch (anim.$) {
		case 8:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Translate(
				swap(a));
		case 4:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Rotate(
				swap(a));
		case 7:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Skew(
				swap(a));
		case 5:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Scale(
				swap(a));
		case 2:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Opacity(
				swap(a));
		case 3:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$PerspectiveOrigin(
				swap(a));
		case 6:
			var a = anim.a;
			return $author$project$Anim$Internal$Engine$Sub$Animation$Size(
				swap(a));
		case 0:
			var cssName = anim.a;
			var unit = anim.b;
			var a = anim.c;
			return A3(
				$author$project$Anim$Internal$Engine$Sub$Animation$CustomProperty,
				cssName,
				unit,
				swap(a));
		default:
			var cssName = anim.a;
			var a = anim.b;
			return A2(
				$author$project$Anim$Internal$Engine$Sub$Animation$CustomColorProperty,
				cssName,
				swap(a));
	}
};
var $author$project$Anim$Internal$Engine$Sub$iterateAnimGroup = F3(
	function (animGroupName, animGroup, animations) {
		var nextIteration = $author$project$Anim$Internal$Engine$Sub$AnimGroup$getCurrentIteration(animGroup) + 1;
		var shouldReverse = function () {
			var _v1 = $author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimationDirection(animGroup);
			if (_v1 === 1) {
				return !A2($elm$core$Basics$modBy, 2, nextIteration);
			} else {
				return false;
			}
		}();
		var anims = A2(
			$author$project$Anim$Internal$Engine$Sub$Animations$map,
			F2(
				function (_v0, anim) {
					var reversed = shouldReverse ? $author$project$Anim$Internal$Engine$Sub$Animation$reverse(anim) : anim;
					return $author$project$Anim$Internal$Engine$Sub$Animation$reset(reversed);
				}),
			animations);
		return _Utils_Tuple2(
			A2(
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState,
				1,
				A2(
					$author$project$Anim$Internal$Engine$Sub$AnimGroup$setCurrentIteration,
					nextIteration,
					A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations, anims, animGroup))),
			_List_fromArray(
				[
					A2($author$project$Anim$Internal$Engine$Sub$Iteration, animGroupName, nextIteration)
				]));
	});
var $author$project$Anim$Internal$Engine$Sub$Animations$list = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$values(dict);
};
var $author$project$Anim$Internal$Engine$Sub$calculateProgress = $author$project$Anim$Internal$Engine$Sub$Interpolation$calculateProgress;
var $author$project$Anim$Internal$Engine$Sub$overallProgress = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations,
	A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Internal$Engine$Sub$Animations$list,
		A2(
			$elm$core$Basics$composeR,
			$elm$core$List$map(
				$author$project$Anim$Internal$Engine$Sub$Animation$foldTiming($author$project$Anim$Internal$Engine$Sub$calculateProgress)),
			A2(
				$elm$core$Basics$composeR,
				$elm$core$List$maximum,
				$elm$core$Maybe$withDefault(0)))));
var $author$project$Anim$Internal$Engine$Sub$updateTiming = function (deltaMs) {
	return $author$project$Anim$Internal$Engine$Sub$Animation$mapTiming(
		function (timing) {
			if (timing.bN) {
				return timing;
			} else {
				var newElapsedMs = timing.cc + deltaMs;
				var animationElapsedMs = A2($elm$core$Basics$max, 0, newElapsedMs - timing.dK);
				return _Utils_update(
					timing,
					{
						cc: newElapsedMs,
						bN: _Utils_cmp(animationElapsedMs, timing.fq) > -1
					});
			}
		});
};
var $author$project$Anim$Internal$Engine$Sub$handleTick = F3(
	function (deltaMs, animGroupName, animGroup) {
		if ($author$project$Anim$Internal$Engine$Sub$AnimGroup$isPaused(animGroup)) {
			return _Utils_Tuple2(animGroup, _List_Nil);
		} else {
			var updatedAnimations = A2(
				$author$project$Anim$Internal$Engine$Sub$Animations$map,
				function (_v1) {
					return $author$project$Anim$Internal$Engine$Sub$updateTiming(deltaMs);
				},
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations(animGroup));
			var allPropertiesComplete = A2(
				$elm$core$List$all,
				$author$project$Anim$Internal$Engine$Sub$Animation$foldTiming(
					function ($) {
						return $.bN;
					}),
				$author$project$Anim$Internal$Engine$Sub$Animations$list(updatedAnimations));
			if (allPropertiesComplete && $author$project$Anim$Internal$Engine$Sub$AnimGroup$isRunning(animGroup)) {
				var shouldIterate = function () {
					var _v0 = $author$project$Anim$Internal$Engine$Sub$AnimGroup$getIterations(animGroup);
					switch (_v0.$) {
						case 2:
							return true;
						case 1:
							var totalIterations = _v0.a;
							return _Utils_cmp(
								$author$project$Anim$Internal$Engine$Sub$AnimGroup$getCurrentIteration(animGroup),
								totalIterations) < 0;
						default:
							return false;
					}
				}();
				return shouldIterate ? A3($author$project$Anim$Internal$Engine$Sub$iterateAnimGroup, animGroupName, animGroup, updatedAnimations) : _Utils_Tuple2(
					A2(
						$author$project$Anim$Internal$Engine$Sub$AnimGroup$setPlayState,
						4,
						A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations, updatedAnimations, animGroup)),
					_List_fromArray(
						[
							$author$project$Anim$Internal$Engine$Sub$Ended(animGroupName)
						]));
			} else {
				var updatedAnimGroup = A2($author$project$Anim$Internal$Engine$Sub$AnimGroup$setAnimations, updatedAnimations, animGroup);
				return _Utils_Tuple2(
					updatedAnimGroup,
					$author$project$Anim$Internal$Engine$Sub$AnimGroup$isRunning(updatedAnimGroup) ? _List_fromArray(
						[
							A2(
							$author$project$Anim$Internal$Engine$Sub$Progress,
							animGroupName,
							$author$project$Anim$Internal$Engine$Sub$overallProgress(updatedAnimGroup))
						]) : _List_Nil);
			}
		}
	});
var $author$project$Anim$Internal$Engine$Sub$tick = F2(
	function (deltaMs, _v0) {
		var animGroupName = _v0.a;
		var animGroup = _v0.b;
		var _v1 = A3($author$project$Anim$Internal$Engine$Sub$handleTick, deltaMs, animGroupName, animGroup);
		var newAnimGroup = _v1.a;
		var events = _v1.b;
		return _Utils_Tuple2(
			_Utils_Tuple2(animGroupName, newAnimGroup),
			events);
	});
var $author$project$Anim$Internal$Engine$Shared$AnimGroups$toList = function (_v0) {
	var dict = _v0;
	return $elm$core$Dict$toList(dict);
};
var $elm$core$List$unzip = function (pairs) {
	var step = F2(
		function (_v0, _v1) {
			var x = _v0.a;
			var y = _v0.b;
			var xs = _v1.a;
			var ys = _v1.b;
			return _Utils_Tuple2(
				A2($elm$core$List$cons, x, xs),
				A2($elm$core$List$cons, y, ys));
		});
	return A3(
		$elm$core$List$foldr,
		step,
		_Utils_Tuple2(_List_Nil, _List_Nil),
		pairs);
};
var $author$project$Anim$Internal$Engine$Sub$update = F2(
	function (msg, _v0) {
		var state = _v0.a;
		var animGroups = _v0.b;
		var deltaMs = msg;
		var _v2 = $elm$core$List$unzip(
			A2(
				$elm$core$List$map,
				$author$project$Anim$Internal$Engine$Sub$tick(deltaMs),
				$author$project$Anim$Internal$Engine$Shared$AnimGroups$toList(animGroups)));
		var groups = _v2.a;
		var events = _v2.b;
		var allEvents = $elm$core$List$concat(events);
		var updatedGroups = $author$project$Anim$Internal$Engine$Shared$AnimGroups$fromList(groups);
		var stillRunning = A2(
			$elm$core$List$any,
			$author$project$Anim$Internal$Engine$Sub$AnimGroup$isRunning,
			$author$project$Anim$Internal$Engine$Shared$AnimGroups$groups(updatedGroups));
		return _Utils_Tuple2(
			A2(
				$author$project$Anim$Internal$Engine$Sub$AnimState,
				{aj: state.aj, p: _List_Nil, X: stillRunning},
				updatedGroups),
			_Utils_ap(
				A2($elm$core$List$map, $author$project$Anim$Internal$Engine$Sub$Control, state.p),
				A2($elm$core$List$map, $author$project$Anim$Internal$Engine$Sub$Tick, allEvents)));
	});
var $author$project$Anim$Engine$Sub$update = function (msg) {
	return A2(
		$elm$core$Basics$composeR,
		$author$project$Anim$Internal$Engine$Sub$update(msg),
		$elm$core$Tuple$mapSecond(
			$elm$core$List$filterMap($author$project$Anim$Engine$Sub$toAnimEvent)));
};
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$update = F2(
	function (msg, model) {
		switch (msg.$) {
			case 0:
				var animationMsg = msg.a;
				var _v1 = A2($author$project$Anim$Engine$Sub$update, animationMsg, model.o);
				var newAnimState = _v1.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{o: newAnimState}),
					$elm$core$Platform$Cmd$none);
			case 1:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							o: A2(
								$author$project$Anim$Engine$Sub$animate,
								model.o,
								A2(
									$elm$core$Basics$composeR,
									$author$project$Anim$Engine$Sub$freezeY(
										_List_fromArray(
											[$author$project$Anim$Engine$Sub$translate])),
									$author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveLeft))
						}),
					$elm$core$Platform$Cmd$none);
			case 2:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							o: A2(
								$author$project$Anim$Engine$Sub$animate,
								model.o,
								A2(
									$elm$core$Basics$composeR,
									$author$project$Anim$Engine$Sub$freezeY(
										_List_fromArray(
											[$author$project$Anim$Engine$Sub$translate])),
									$author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveRight(model.c$)))
						}),
					$elm$core$Platform$Cmd$none);
			case 3:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							o: A2(
								$author$project$Anim$Engine$Sub$animate,
								model.o,
								A2(
									$elm$core$Basics$composeR,
									$author$project$Anim$Engine$Sub$freezeX(
										_List_fromArray(
											[$author$project$Anim$Engine$Sub$translate])),
									$author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveUp))
						}),
					$elm$core$Platform$Cmd$none);
			default:
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							o: A2(
								$author$project$Anim$Engine$Sub$animate,
								model.o,
								A2(
									$elm$core$Basics$composeR,
									$author$project$Anim$Engine$Sub$freezeX(
										_List_fromArray(
											[$author$project$Anim$Engine$Sub$translate])),
									$author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$moveDown(model.cj)))
						}),
					$elm$core$Platform$Cmd$none);
		}
	});
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$MoveDown = {$: 4};
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$MoveLeft = {$: 1};
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$MoveRight = {$: 2};
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$MoveUp = {$: 3};
var $elm$core$String$fromFloat = _String_fromNumber;
var $elm$core$Basics$neq = _Utils_notEqual;
var $author$project$Anim$Internal$Property$Rotate$toCssString = function (_v0) {
	var angles = _v0;
	var parts = A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[
				(!(!angles.b_)) ? $elm$core$Maybe$Just(
				'rotateX(' + ($elm$core$String$fromFloat(angles.b_) + 'deg)')) : $elm$core$Maybe$Nothing,
				(!(!angles.b$)) ? $elm$core$Maybe$Just(
				'rotateY(' + ($elm$core$String$fromFloat(angles.b$) + 'deg)')) : $elm$core$Maybe$Nothing,
				(!(!angles.b0)) ? $elm$core$Maybe$Just(
				'rotateZ(' + ($elm$core$String$fromFloat(angles.b0) + 'deg)')) : $elm$core$Maybe$Nothing
			]));
	return $elm$core$List$isEmpty(parts) ? 'rotateZ(0deg)' : A2($elm$core$String$join, ' ', parts);
};
var $author$project$Anim$Internal$Property$Scale$toCssString = function (_v0) {
	var x = _v0.b_;
	var y = _v0.b$;
	var z = _v0.b0;
	var parts = A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[
				(x !== 1.0) ? $elm$core$Maybe$Just(
				'scaleX(' + ($elm$core$String$fromFloat(x) + ')')) : $elm$core$Maybe$Nothing,
				(y !== 1.0) ? $elm$core$Maybe$Just(
				'scaleY(' + ($elm$core$String$fromFloat(y) + ')')) : $elm$core$Maybe$Nothing,
				(z !== 1.0) ? $elm$core$Maybe$Just(
				'scaleZ(' + ($elm$core$String$fromFloat(z) + ')')) : $elm$core$Maybe$Nothing
			]));
	if (!parts.b) {
		return 'scale3d(1,1,1)';
	} else {
		if (!parts.b.b) {
			var single = parts.a;
			return single;
		} else {
			var multiple = parts;
			return A2($elm$core$String$join, ' ', multiple);
		}
	}
};
var $author$project$Anim$Internal$Property$Skew$toCssString = function (_v0) {
	var values = _v0;
	var parts = A2(
		$elm$core$List$filterMap,
		$elm$core$Basics$identity,
		_List_fromArray(
			[
				(!(!values.b_)) ? $elm$core$Maybe$Just(
				'skewX(' + ($elm$core$String$fromFloat(values.b_) + 'deg)')) : $elm$core$Maybe$Nothing,
				(!(!values.b$)) ? $elm$core$Maybe$Just(
				'skewY(' + ($elm$core$String$fromFloat(values.b$) + 'deg)')) : $elm$core$Maybe$Nothing
			]));
	if (!parts.b) {
		return 'skew(0deg, 0deg)';
	} else {
		if (!parts.b.b) {
			var single = parts.a;
			return single;
		} else {
			var multiple = parts;
			return A2($elm$core$String$join, ' ', multiple);
		}
	}
};
var $author$project$Anim$Internal$Property$Translate$toCssString = function (_v0) {
	var coords = _v0;
	return 'translate3d(' + ($elm$core$String$fromFloat(coords.b_) + ('px, ' + ($elm$core$String$fromFloat(coords.b$) + ('px, ' + ($elm$core$String$fromFloat(coords.b0) + 'px)')))));
};
var $author$project$Anim$Internal$Engine$Sub$collectCurrentTransform = F2(
	function (anim, acc) {
		switch (anim.$) {
			case 8:
				var a = anim.a;
				return _Utils_update(
					acc,
					{
						bu: $author$project$Anim$Internal$Property$Translate$toCssString(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateTranslate, a))
					});
			case 4:
				var a = anim.a;
				return _Utils_update(
					acc,
					{
						bm: $author$project$Anim$Internal$Property$Rotate$toCssString(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateRotate, a))
					});
			case 7:
				var a = anim.a;
				return _Utils_update(
					acc,
					{
						bq: $author$project$Anim$Internal$Property$Skew$toCssString(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateSkew, a))
					});
			case 5:
				var a = anim.a;
				return _Utils_update(
					acc,
					{
						bp: $author$project$Anim$Internal$Property$Scale$toCssString(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateScale, a))
					});
			default:
				return acc;
		}
	});
var $elm$core$List$concatMap = F2(
	function (f, list) {
		return $elm$core$List$concat(
			A2($elm$core$List$map, f, list));
	});
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getDiscreteEntry = function (_v0) {
	var group = _v0;
	return group.bD;
};
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $author$project$Anim$Internal$Engine$Sub$discreteEntryStyles = A2(
	$elm$core$Basics$composeR,
	$author$project$Anim$Internal$Engine$Sub$AnimGroup$getDiscreteEntry,
	A2(
		$elm$core$Basics$composeR,
		$elm$core$Dict$toList,
		$elm$core$List$map(
			function (_v0) {
				var prop = _v0.a;
				var value = _v0.b;
				return A2($elm$html$Html$Attributes$style, prop, value);
			})));
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$getDiscreteExit = function (_v0) {
	var group = _v0;
	return group.bE;
};
var $author$project$Anim$Internal$Engine$Shared$PlayState$isComplete = function (state) {
	return state === 4;
};
var $author$project$Anim$Internal$Engine$Sub$AnimGroup$isComplete = function (_v0) {
	var group = _v0;
	return $author$project$Anim$Internal$Engine$Shared$PlayState$isComplete(group.aR);
};
var $author$project$Anim$Internal$Engine$Sub$discreteExitStyles = function (animGroup) {
	return A2(
		$elm$core$List$map,
		function (_v0) {
			var prop = _v0.a;
			var from = _v0.b.bH;
			var to = _v0.b.bW;
			return $author$project$Anim$Internal$Engine$Sub$AnimGroup$isComplete(animGroup) ? A2($elm$html$Html$Attributes$style, prop, to) : A2($elm$html$Html$Attributes$style, prop, from);
		},
		$elm$core$Dict$toList(
			$author$project$Anim$Internal$Engine$Sub$AnimGroup$getDiscreteExit(animGroup)));
};
var $author$project$Anim$Internal$Builder$emptyTransformParts = {bm: '', bp: '', bq: '', bu: ''};
var $elm$core$String$concat = function (strings) {
	return A2($elm$core$String$join, '', strings);
};
var $avh4$elm_color$Color$toCssString = function (_v0) {
	var r = _v0.a;
	var g = _v0.b;
	var b = _v0.c;
	var a = _v0.d;
	var roundTo = function (x) {
		return $elm$core$Basics$round(x * 1000) / 1000;
	};
	var pct = function (x) {
		return $elm$core$Basics$round(x * 10000) / 100;
	};
	return $elm$core$String$concat(
		_List_fromArray(
			[
				'rgba(',
				$elm$core$String$fromFloat(
				pct(r)),
				'%,',
				$elm$core$String$fromFloat(
				pct(g)),
				'%,',
				$elm$core$String$fromFloat(
				pct(b)),
				'%,',
				$elm$core$String$fromFloat(
				roundTo(a)),
				')'
			]));
};
var $author$project$Anim$Internal$Extra$Color$toCssString = function (color) {
	var stringify = F2(
		function (constructor, components) {
			return constructor + ('(' + (A2($elm$core$String$join, ', ', components) + ')'));
		});
	switch (color.$) {
		case 0:
			var hex = color.a;
			return hex;
		case 1:
			var r = color.a.cN;
			var g = color.a.ch;
			var b = color.a.b5;
			return A2(
				stringify,
				'rgb',
				_List_fromArray(
					[
						$elm$core$String$fromInt(r),
						$elm$core$String$fromInt(g),
						$elm$core$String$fromInt(b)
					]));
		case 2:
			var r = color.a.cN;
			var g = color.a.ch;
			var b = color.a.b5;
			var a = color.a.b1;
			return A2(
				stringify,
				'rgba',
				_List_fromArray(
					[
						$elm$core$String$fromInt(r),
						$elm$core$String$fromInt(g),
						$elm$core$String$fromInt(b),
						$elm$core$String$fromFloat(a)
					]));
		case 3:
			var h = color.a.ci;
			var s = color.a.cQ;
			var l = color.a.cr;
			return A2(
				stringify,
				'hsl',
				_List_fromArray(
					[
						$elm$core$String$fromFloat(h),
						$elm$core$String$fromFloat(s) + '%',
						$elm$core$String$fromFloat(l) + '%'
					]));
		case 4:
			var h = color.a.ci;
			var s = color.a.cQ;
			var l = color.a.cr;
			var a = color.a.b1;
			return A2(
				stringify,
				'hsla',
				_List_fromArray(
					[
						$elm$core$String$fromFloat(h),
						$elm$core$String$fromFloat(s) + '%',
						$elm$core$String$fromFloat(l) + '%',
						$elm$core$String$fromFloat(a)
					]));
		default:
			var elmColor_ = color.a;
			return $avh4$elm_color$Color$toCssString(elmColor_);
	}
};
var $author$project$Anim$Internal$Property$PerspectiveOrigin$toCssString = function (origin) {
	if (!origin.$) {
		var x = origin.a.b_;
		var y = origin.a.b$;
		return $elm$core$String$fromFloat(x) + ('% ' + ($elm$core$String$fromFloat(y) + '%'));
	} else {
		var x = origin.a.b_;
		var y = origin.a.b$;
		return $elm$core$String$fromFloat(x) + ('px ' + ($elm$core$String$fromFloat(y) + 'px'));
	}
};
var $author$project$Anim$Internal$Engine$Sub$getNonTransformStyleAttribute = function (anim) {
	switch (anim.$) {
		case 0:
			var cssName = anim.a;
			var unit = anim.b;
			var a = anim.c;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					cssName,
					_Utils_ap(
						$elm$core$String$fromFloat(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateFloat, a)),
						unit))
				]);
		case 1:
			var cssName = anim.a;
			var a = anim.b;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					cssName,
					$author$project$Anim$Internal$Extra$Color$toCssString(
						A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Extra$Color$interpolate, a)))
				]);
		case 2:
			var a = anim.a;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					'opacity',
					$elm$core$String$fromFloat(
						$author$project$Anim$Internal$Property$Opacity$toFloat(
							A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateOpacity, a))))
				]);
		case 3:
			var a = anim.a;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					'perspective-origin',
					$author$project$Anim$Internal$Property$PerspectiveOrigin$toCssString(
						A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolatePerspectiveOrigin, a)))
				]);
		case 4:
			return _List_Nil;
		case 5:
			return _List_Nil;
		case 6:
			var a = anim.a;
			var size = A2($author$project$Anim$Internal$Engine$Sub$interpolateEasedProgress, $author$project$Anim$Internal$Engine$Sub$interpolateSize, a);
			var _v1 = $author$project$Anim$Internal$Property$Size$toTuple(size);
			var width = _v1.a;
			var height = _v1.b;
			return _List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromFloat(width) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromFloat(height) + 'px')
				]);
		case 7:
			return _List_Nil;
		default:
			return _List_Nil;
	}
};
var $author$project$Anim$Internal$Engine$Sub$transformOrderToPart = F2(
	function (parts, property) {
		switch (property) {
			case 0:
				return parts.bu;
			case 1:
				return parts.bm;
			case 2:
				return parts.bq;
			default:
				return parts.bp;
		}
	});
var $author$project$Anim$Internal$Engine$Sub$attributes = F2(
	function (animGroupName, _v0) {
		var animGroups = _v0.b;
		var _v1 = A2($author$project$Anim$Internal$Engine$Shared$AnimGroups$get, animGroupName, animGroups);
		if (_v1.$ === 1) {
			return _List_Nil;
		} else {
			var animGroup = _v1.a;
			var discreteStyles = _Utils_ap(
				$author$project$Anim$Internal$Engine$Sub$discreteEntryStyles(animGroup),
				$author$project$Anim$Internal$Engine$Sub$discreteExitStyles(animGroup));
			var currentOrder = $author$project$Anim$Internal$Engine$Sub$AnimGroup$getTransformOrder(animGroup);
			var anims = $author$project$Anim$Internal$Engine$Sub$Animations$list(
				$author$project$Anim$Internal$Engine$Sub$AnimGroup$getAnimations(animGroup));
			var nonTransformStyles = A2($elm$core$List$concatMap, $author$project$Anim$Internal$Engine$Sub$getNonTransformStyleAttribute, anims);
			var transformParts = A3($elm$core$List$foldl, $author$project$Anim$Internal$Engine$Sub$collectCurrentTransform, $author$project$Anim$Internal$Builder$emptyTransformParts, anims);
			var transformString = A2(
				$elm$core$String$join,
				' ',
				A2(
					$elm$core$List$filter,
					A2($elm$core$Basics$composeL, $elm$core$Basics$not, $elm$core$String$isEmpty),
					A2(
						$elm$core$List$map,
						$author$project$Anim$Internal$Engine$Sub$transformOrderToPart(transformParts),
						currentOrder)));
			var transformStyle = $elm$core$String$isEmpty(transformString) ? _List_Nil : _List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'transform', transformString)
				]);
			return _Utils_ap(
				transformStyle,
				_Utils_ap(nonTransformStyles, discreteStyles));
		}
	});
var $author$project$Anim$Engine$Sub$attributes = $author$project$Anim$Internal$Engine$Sub$attributes;
var $elm$json$Json$Encode$string = _Json_wrap;
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $elm$html$Html$div = _VirtualDom_node('div');
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 0, a: a};
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$view = function (model) {
	var button = F3(
		function (bgColor, label, onClickMsg) {
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Events$onClick(onClickMsg),
						$elm$html$Html$Attributes$class('ui-action-button'),
						A2($elm$html$Html$Attributes$style, 'display', 'inline-block'),
						A2($elm$html$Html$Attributes$style, 'margin-left', '10px'),
						A2($elm$html$Html$Attributes$style, 'margin-right', '10px'),
						A2($elm$html$Html$Attributes$style, 'padding', '10px'),
						A2($elm$html$Html$Attributes$style, 'background-color', bgColor),
						A2($elm$html$Html$Attributes$style, 'color', 'white'),
						A2($elm$html$Html$Attributes$style, 'cursor', 'pointer')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text(label)
					]));
		});
	var moveDownButton = A3(button, '#FFC107', 'Move Down', $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$MoveDown);
	var moveLeftButton = A3(button, '#007BFF', 'Move Left', $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$MoveLeft);
	var moveRightButton = A3(button, '#28A745', 'Move Right', $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$MoveRight);
	var moveUpButton = A3(button, '#6F42C1', 'Move Up', $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$MoveUp);
	var box = A2(
		$elm$html$Html$div,
		_Utils_ap(
			A2($author$project$Anim$Engine$Sub$attributes, $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$animGroupName, model.o),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$Attributes$style,
					'width',
					$elm$core$String$fromFloat($author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$boxWidth) + 'px'),
					A2(
					$elm$html$Html$Attributes$style,
					'height',
					$elm$core$String$fromFloat($author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$boxWidth) + 'px'),
					A2($elm$html$Html$Attributes$style, 'background-color', '#FF5733'),
					A2($elm$html$Html$Attributes$style, 'position', 'relative'),
					A2($elm$html$Html$Attributes$style, 'margin-top', '20px')
				])),
		_List_Nil);
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				A2($elm$html$Html$Attributes$style, 'text-align', 'center')
			]),
		_List_fromArray(
			[moveLeftButton, moveRightButton, moveUpButton, moveDownButton, box]));
};
var $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$main = $elm$browser$Browser$element(
	{ee: $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$init, e2: $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$subscriptions, ft: $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$update, fu: $author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$view});
_Platform_export({'Animation':{'Sub':{'InterruptingAnimations':{'FreezeAxis':{'Main':{'init':$author$project$Animation$Sub$InterruptingAnimations$FreezeAxis$Main$main(
	A2(
		$elm$json$Json$Decode$andThen,
		function (width) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (height) {
					return $elm$json$Json$Decode$succeed(
						{cj: height, c$: width});
				},
				A2($elm$json$Json$Decode$field, 'height', $elm$json$Json$Decode$float));
		},
		A2($elm$json$Json$Decode$field, 'width', $elm$json$Json$Decode$float)))(0)}}}}}});}(this));