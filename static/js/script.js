
function callback (a) {
	alert(a);
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
					contentWindow.location.href = 'javascript:parent.callback(' + message.body + ')';
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
