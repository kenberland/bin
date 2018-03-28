$("._rpc_41.ms-font-s.allowTextSelection").each(
    function(a,b) {
	var content = b.innerHTML;
	if (content.startsWith("sip:")) {
	    var login = content.match(/^sip:(\w+)/)[1];
	    var link = "https://phonetool.amazon.com/users/" + login;
	    var elem = $('<a/>', { href: link, text: 'phonetool', target: "_blank" });
	    b.innerHTML = null;
	    $(b).append(elem);
	}
    });
