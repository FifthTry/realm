import parser
from collections import OrderedDict
# tests

export_test_input = [
('''
function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}





function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		value
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}

_Platform_export({'L':{'init':author$project$L$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)},'N':{'init':author$project$N$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)},'M':{'init':author$project$M$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)}});}(this));
    ''',
 '''_Platform_export({'L':{'init':author$project$L$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)},'N':{'init':author$project$N$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)},'M':{'init':author$project$M$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)}});'''
	 
	 
	 )
]

parse_test_input = [
	# break simple
	('''
function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}





function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		value
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}

_Platform_export({'L':{'init':author$project$L$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)},'N':{'init':author$project$N$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)},'M':{'init':author$project$M$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)}});}(this));
    '''
	 , [
		 ('_VirtualDom_applyAttrs', '''function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}''')
		 , ('_VirtualDom_applyAttrsNS', '''function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		value
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}''')
	 ]
	 )
	
	# break delimiters: function var export
	, ('''
function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}





var author$project$L$view = function (model) {
	return A2(
		elm$html$Html$div,
		_List_fromArray(
			[
				elm$html$Html$Attributes$id('main')
			]),
		_List_fromArray(
			[
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child1')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child2')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child3')
					]),
				_List_fromArray(
					[
						A4(author$project$L$viewInput, 'text', 'Name', model.name, author$project$L$Name),
						A4(author$project$L$viewInput, 'password', 'Password', model.password, author$project$L$Password),
						A4(author$project$L$viewInput, 'password', 'Re-enter Password', model.passwordAgain, author$project$L$PasswordAgain),
						author$project$L$viewValidation(model)
					]))
			]));
};

_Platform_export({'L':{'init':author$project$L$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)},'N':{'init':author$project$N$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)},'M':{'init':author$project$M$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)}});}(this));
    '''
	   ,  [
		   ('_VirtualDom_applyAttrs', '''function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}''')
		   , ('author$project$L$view', '''var author$project$L$view = function (model) {
	return A2(
		elm$html$Html$div,
		_List_fromArray(
			[
				elm$html$Html$Attributes$id('main')
			]),
		_List_fromArray(
			[
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child1')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child2')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child3')
					]),
				_List_fromArray(
					[
						A4(author$project$L$viewInput, 'text', 'Name', model.name, author$project$L$Name),
						A4(author$project$L$viewInput, 'password', 'Password', model.password, author$project$L$Password),
						A4(author$project$L$viewInput, 'password', 'Re-enter Password', model.passwordAgain, author$project$L$PasswordAgain),
						author$project$L$viewValidation(model)
					]))
			]));
};''')
	   ]
	   )
	
	# break delimiters: function var var
	, ('''
function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}





var author$project$L$view = function (model) {
	return A2(
		elm$html$Html$div,
		_List_fromArray(
			[
				elm$html$Html$Attributes$id('main')
			]),
		_List_fromArray(
			[
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child1')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child2')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child3')
					]),
				_List_fromArray(
					[
						A4(author$project$L$viewInput, 'text', 'Name', model.name, author$project$L$Name),
						A4(author$project$L$viewInput, 'password', 'Password', model.password, author$project$L$Password),
						A4(author$project$L$viewInput, 'password', 'Re-enter Password', model.passwordAgain, author$project$L$PasswordAgain),
						author$project$L$viewValidation(model)
					]))
			]));
};


var author$project$L$main = elm$browser$Browser$element(
	{init: author$project$L$init, subscriptions: author$project$L$subscriptions, update: author$project$L$update, view: author$project$L$view});
    '''
	   ,  [
		   ('_VirtualDom_applyAttrs', '''function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}''')
		   , ('author$project$L$view', '''var author$project$L$view = function (model) {
	return A2(
		elm$html$Html$div,
		_List_fromArray(
			[
				elm$html$Html$Attributes$id('main')
			]),
		_List_fromArray(
			[
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child1')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child2')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child3')
					]),
				_List_fromArray(
					[
						A4(author$project$L$viewInput, 'text', 'Name', model.name, author$project$L$Name),
						A4(author$project$L$viewInput, 'password', 'Password', model.password, author$project$L$Password),
						A4(author$project$L$viewInput, 'password', 'Re-enter Password', model.passwordAgain, author$project$L$PasswordAgain),
						author$project$L$viewValidation(model)
					]))
			]));
};'''
		    )
	   ]
	   )

	#regex
	, ('''
function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}

function _()
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}


function z(){
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}


var author$project$L$view = function (model) {
	return A2(
		elm$html$Html$div,
		_List_fromArray(
			[
				elm$html$Html$Attributes$id('main')
			]),
		_List_fromArray(
			[
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child1')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child2')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child3')
					]),
				_List_fromArray(
					[
						A4(author$project$L$viewInput, 'text', 'Name', model.name, author$project$L$Name),
						A4(author$project$L$viewInput, 'password', 'Password', model.password, author$project$L$Password),
						A4(author$project$L$viewInput, 'password', 'Re-enter Password', model.passwordAgain, author$project$L$PasswordAgain),
						author$project$L$viewValidation(model)
					]))
			]));
};


var author$project$L$main = elm$browser$Browser$element(
	{init: author$project$L$init, subscriptions: author$project$L$subscriptions, update: author$project$L$update, view: author$project$L$view});
    '''
	    , [
		   ('_VirtualDom_applyAttrs', '''function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}''')
		   ,('_', '''function _()
{
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}''')
		,('z','''function z(){
	for (var key in attrs)
	{
		var value = attrs[key];
		value
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}''')

	
		   , ('author$project$L$view', '''var author$project$L$view = function (model) {
	return A2(
		elm$html$Html$div,
		_List_fromArray(
			[
				elm$html$Html$Attributes$id('main')
			]),
		_List_fromArray(
			[
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child1')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child2')
					]),
				_List_Nil),
				A2(
				elm$html$Html$div,
				_List_fromArray(
					[
						elm$html$Html$Attributes$id('child3')
					]),
				_List_fromArray(
					[
						A4(author$project$L$viewInput, 'text', 'Name', model.name, author$project$L$Name),
						A4(author$project$L$viewInput, 'password', 'Password', model.password, author$project$L$Password),
						A4(author$project$L$viewInput, 'password', 'Re-enter Password', model.passwordAgain, author$project$L$PasswordAgain),
						author$project$L$viewValidation(model)
					]))
			]));
};''')
	   ]
	   )
	,('''

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
			&& { passive: elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}




var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}


''',  [
		('_VirtualDom_applyEvents', '''function _VirtualDom_applyEvents(domNode, eventNode, events)
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
			&& { passive: elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}''')
		,
		('_VirtualDom_passiveSupported', '''var _VirtualDom_passiveSupported;''')
		, ('try_catch_test', '''try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}''')
	
	])
	

]





diff_test_input = [
	('''
function A(){
		this is A
	}
function B(){
		this is B
	}
function C(){
		this is C
	}
var
	'''
	 ,'''
function A(){
		this is A
	}
function B(){
		this is B
	}
function C(){
		this is C
	}
var
	''',  OrderedDict())
	,('''
function A(){
		this is A
	}
function B(){
		this is B
	}
function C(){
		this is C
	}
var
	'''
	 ,'''
function A(){
		this is A
	}
function G(){
		this is G
	}
function C(){
		this is C
	}
var
	''',  [
		  ('B', '''function B(){
		this is B
	}''')
	  ])
	
,('''
function A(){
		this is A
	}
function B(){
		this is B
	}
function C(){
		this is C
	}
var
	'''
	 ,'''
function Q(){
		this is Q
	}
function B(){
		this is B
	}
function Z(){
		this is Z
	}
var
	''',  [
	  ('A', '''function A(){
		this is A
	}''')
		,('C', '''function C(){
		this is C
	}''')
	  ])
	
]

def test_export_ex():
	def test_export(st, result):
		x = parser.parse(st, 'test').platform_export_statement
		assert (x == result)
	
	for rank, (st, result) in enumerate(export_test_input):
		
		print("rank", rank)
		test_export(st, result)


def test_parse_ex():
	def test_parse(st, result_dic):
		x = parser.parse(st, 'test').identifier_map
		assert (x == result_dic)
	
	for rank, (st, result_lis) in enumerate(parse_test_input):
		result_map = OrderedDict()
		for k, v in result_lis:
			result_map[k] = v
		print("rank", rank)
		test_parse(st, result_map)
		
		
def test_diff_ex():
	def test_diff(l, m, result_dic):
		assert (parser.parse(l, 'l').diff(
			parser.parse(m, 'm')).identifier_map == result_dic)
	
	for l, m, result_lis in diff_test_input:
		result_map = OrderedDict()
		for k, v in result_lis:
			result_map[k] = v
		test_diff(l, m, result_map)
	
	

if __name__ == "__main__":
	test_parse_ex()
	test_diff_ex()
	test_export_ex()




# make tolerant
# use hash in match
