
var _VirtualDom_passiveSupported;
try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}
var author$project$L$Model = F3(
	function (name, password, passwordAgain) {
		return {name: name, password: password, passwordAgain: passwordAgain};
	});
var author$project$L$loadWidget = _Platform_outgoingPort('loadWidget', elm$core$Basics$identity);
var elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			elm$core$List$foldl,
			F2(
				function (_n0, obj) {
					var k = _n0.a;
					var v = _n0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(_Utils_Tuple0),
			pairs));
};
var author$project$L$init = function (_n0) {
	return _Utils_Tuple2(
		A3(author$project$L$Model, '', '', ''),
		author$project$L$loadWidget(
			elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'first',
						elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'uid',
									elm$json$Json$Encode$string('child1')),
									_Utils_Tuple2(
									'id',
									elm$json$Json$Encode$string('M')),
									_Utils_Tuple2(
									'flags',
									elm$json$Json$Encode$object(_List_Nil))
								]))),
						_Utils_Tuple2(
						'second',
						elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'uid',
									elm$json$Json$Encode$string('child2')),
									_Utils_Tuple2(
									'id',
									elm$json$Json$Encode$string('N')),
									_Utils_Tuple2(
									'flags',
									elm$json$Json$Encode$object(_List_Nil))
								])))
					]))));
};
var author$project$L$subscriptions = function (_n0) {
	return elm$core$Platform$Sub$none;
};
var author$project$L$update = F2(
	function (msg, model) {
		switch (msg.$) {
			case 'Name':
				var name = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{name: name}),
					elm$core$Platform$Cmd$none);
			case 'Password':
				var password = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{password: password}),
					elm$core$Platform$Cmd$none);
			default:
				var password = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{passwordAgain: password}),
					elm$core$Platform$Cmd$none);
		}
	});
var author$project$L$Name = function (a) {
	return {$: 'Name', a: a};
};
var author$project$L$Password = function (a) {
	return {$: 'Password', a: a};
};
var author$project$L$PasswordAgain = function (a) {
	return {$: 'PasswordAgain', a: a};
};
var author$project$L$viewInput = F4(
	function (t, p, v, toMsg) {
		return A2(
			elm$html$Html$input,
			_List_fromArray(
				[
					elm$html$Html$Attributes$type_(t),
					elm$html$Html$Attributes$placeholder(p),
					elm$html$Html$Attributes$value(v),
					elm$html$Html$Events$onInput(toMsg)
				]),
			_List_Nil);
	});
var author$project$L$viewValidation = function (model) {
	return (!_Utils_eq(model.password, model.passwordAgain)) ? A2(
		elm$html$Html$div,
		_List_fromArray(
			[
				A2(elm$html$Html$Attributes$style, 'color', 'red')
			]),
		_List_fromArray(
			[
				elm$html$Html$text('Passwords do not match!')
			])) : ((elm$core$String$length(model.password) < 8) ? A2(
		elm$html$Html$div,
		_List_fromArray(
			[
				A2(elm$html$Html$Attributes$style, 'color', 'red')
			]),
		_List_fromArray(
			[
				elm$html$Html$text('Passwords\' minimum length is 8')
			])) : A2(
		elm$html$Html$div,
		_List_fromArray(
			[
				A2(elm$html$Html$Attributes$style, 'color', 'green')
			]),
		_List_fromArray(
			[
				elm$html$Html$text('OK')
			])));
};
var elm$html$Html$Attributes$id = elm$html$Html$Attributes$stringProperty('id');
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
var elm$browser$Browser$element = _Browser_element;
var author$project$N$main = elm$browser$Browser$element(
	{init: author$project$L$init, subscriptions: author$project$L$subscriptions, update: author$project$L$update, view: author$project$L$view});


_Platform_export({'N':{'init':author$project$N$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)}});