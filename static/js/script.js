
uneval = function (o) {
	switch (typeof o) {
		case "undefined" : return "(void 0)";
		case "boolean"   : return String(o);
		case "number"    : return String(o);
		case "string"    : return '"' + o.replace(/[^a-z !@#$%^&*()=_+{}\[\]|;:'"<>,.\/?-]/gi, function (_) { return '\\u' + (0x10000 + _.charCodeAt(0)).toString(16).slice(1) }) + '"';
		case "function"  : return "(" + o.toString() + ")";
		case "object"    :
			if (o == null) return "null";
			var type = Object.prototype.toString.call(o).match(/\[object (.+)\]/);
			if (!type) throw TypeError("unknown type:"+o);
			switch (type[1]) {
				case "Array":
					var ret = [];
					for (var i = 0, l = o.length; i < l; ret.push(arguments.callee(o[i++])));
					return "[" + ret.join(", ") + "]";
				case "Object":
					var ret = [];
					for (var i in o) if (o.hasOwnProperty(i)) {
						ret.push(arguments.callee(i) + ":" + arguments.callee(o[i]));
					}
					return "({" + ret.join(", ") + "})";
				case "Number":
					return "(new Number(" + o + "))";
				case "String":
					return "(new String(" + arguments.callee(o) + "))";
				case "Date":
					return "(new Date(" + o.getTime() + "))";
				default:
					if (o.toSource) return o.toSource();
					return String(o);
			}
	}
	return "";
}


function callback (id, a) {
	document.title = id + ',' + a;
	$.ajax({
		url: '/api/done',
		dataType : 'json',
		data : {
			m : uneval(a),
			id : id
		}
	});
}

$(function () {
	var contentWindow = document.getElementById('content').contentWindow;

	function read () {
		$.ajax({
			url: '/api/read',
			dataType : 'json',
			success : function (data) {
				var messages = data.messages;
				for (var i = 0, len = messages.length; i < len; i++) {
					var message = messages[i];
					try {
						code = 'try{parent.callback(' + message.id + ', ' + message.body + ')}catch(e){parent.callback(' + message.id + ', String(e))}';
						fun = new Function(code); // check syntax error
						contentWindow.location.href = 'javascript:' + code;
					} catch (e) {
						parent.callback(message.id, String(e));
					}
				}
			},

			complete : function () {
				setTimeout(function () {
					read();
				}, 500);
			}
		});
	}
	read();
});
