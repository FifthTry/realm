var _VirtualDom_passiveSupported;
try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}
var author$project$M$Model = F3(
	function (name, password, passwordAgain) {
		return {name: name, password: password, passwordAgain: passwordAgain};
	});
var author$project$M$init = function (_n0) {
	return _Utils_Tuple2(
		A3(author$project$M$Model, '', '', ''),
		elm$core$Platform$Cmd$none);
};
var author$project$M$subscriptions = function (_n0) {
	return elm$core$Platform$Sub$none;
};
var author$project$M$update = F2(
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
var author$project$M$Name = function (a) {
	return {$: 'Name', a: a};
};
var author$project$M$Password = function (a) {
	return {$: 'Password', a: a};
};
var author$project$M$PasswordAgain = function (a) {
	return {$: 'PasswordAgain', a: a};
};
var author$project$M$viewInput = F4(
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
var author$project$M$viewValidation = function (model) {
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
var author$project$M$view = function (model) {
	return A2(
		elm$html$Html$div,
		_List_Nil,
		_List_fromArray(
			[
				A4(author$project$M$viewInput, 'text', 'Name', model.name, author$project$M$Name),
				A4(author$project$M$viewInput, 'password', 'Password', model.password, author$project$M$Password),
				A4(author$project$M$viewInput, 'password', 'Re-enter Password', model.passwordAgain, author$project$M$PasswordAgain),
				author$project$M$viewValidation(model)
			]));
};
var author$project$M$main = elm$browser$Browser$element(
	{init: author$project$M$init, subscriptions: author$project$M$subscriptions, update: author$project$M$update, view: author$project$M$view});
_Platform_export({'M':{'init':author$project$M$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)}});
