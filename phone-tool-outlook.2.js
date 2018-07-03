$(".bidi.allowTextSelection").each(
    function(a,b) {
	var content = b.innerHTML;
	var matches;
	if (matches = content.match(/&lt;(\w+)@amazon.com&gt;/) ){
	    console.log(matches[1]);
	    var link = "https://phonetool.amazon.com/users/" + matches[1];
	    var elem = $('<a/>', { href: link, text: 'phonetool', target: "_blank" });
	    b.innerHTML = null;
	    $(b).append(elem);
	}
    });
