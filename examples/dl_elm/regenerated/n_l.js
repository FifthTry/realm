var _VirtualDom_passiveSupported;
try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}
var author$project$N$Model = F3(
	function (name, password, passwordAgain) {
		return {name: name, password: password, passwordAgain: passwordAgain};
	});
var author$project$N$init = A3(author$project$N$Model, '', '', '');
var author$project$N$update = F2(
	function (msg, model) {
		switch (msg.$) {
			case 'Name':
				var name = msg.a;
				return _Utils_update(
					model,
					{name: name});
			case 'Password':
				var password = msg.a;
				return _Utils_update(
					model,
					{password: password});
			default:
				var password = msg.a;
				return _Utils_update(
					model,
					{passwordAgain: password});
		}
	});
var author$project$N$Name = function (a) {
	return {$: 'Name', a: a};
};
var author$project$N$Password = function (a) {
	return {$: 'Password', a: a};
};
var author$project$N$PasswordAgain = function (a) {
	return {$: 'PasswordAgain', a: a};
};
var author$project$N$viewInput = F4(
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
var author$project$N$viewValidation = function (model) {
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
var author$project$N$view = function (model) {
	return A2(
		elm$html$Html$div,
		_List_Nil,
		_List_fromArray(
			[
				A4(author$project$N$viewInput, 'text', 'Name', model.name, author$project$N$Name),
				A4(author$project$N$viewInput, 'password', 'Password', model.password, author$project$N$Password),
				A4(author$project$N$viewInput, 'password', 'Re-enter Password', model.passwordAgain, author$project$N$PasswordAgain),
				author$project$N$viewValidation(model)
			]));
};
var elm$browser$Browser$sandbox = function (impl) {
	return _Browser_element(
		{
			init: function (_n0) {
				return _Utils_Tuple2(impl.init, elm$core$Platform$Cmd$none);
			},
			subscriptions: function (_n1) {
				return elm$core$Platform$Sub$none;
			},
			update: F2(
				function (msg, model) {
					return _Utils_Tuple2(
						A2(impl.update, msg, model),
						elm$core$Platform$Cmd$none);
				}),
			view: impl.view
		});
};
var author$project$N$main = elm$browser$Browser$sandbox(
	{init: author$project$N$init, update: author$project$N$update, view: author$project$N$view});
_Platform_export({'N':{'init':author$project$N$main(
	elm$json$Json$Decode$succeed(_Utils_Tuple0))(0)}});
