

var getDocumentLayoutOutput = function() {
  var layoutOutput = {};
  var json = document.getElementById("data").text;
  json = json.replace(/&quot;/g, '"')
       .replace(/&amp;/g, "&")
       .replace(/&#x27;/g, "'")
       .replace(/&lt;/g, "<")
       .replace(/&gt;/g, ">")
  try {
    layoutOutput = JSON.parse(json).result;
  } catch (e) {
    // TODO:Engine: Log to sentry
  }
  return layoutOutput
};

function load_src(source) {
    var scriptNode = document.createElement("script");
    scriptNode.text = source;
    document.body.appendChild(scriptNode);
}

/*
function get_app(id) {
    // split a.b.c
    var a, b, c = split(id);
    return Elm[a][b]

    var current = Elm;
    while (true) {
        if id.contains(".") {
            var first, rest = split()
            current = current[first];
        }
    }
}
*/

function loadWidget(handle) {
  console.log("loadWidget", handle);

  var widget = handle.first;
  var app = Elm[widget.id].init({
    node: document.getElementById(widget.uid),
    flags: widget.flags,
  });

  app.ports.loadWidget.subscribe(loadWidget);

}

function main(){
    var data = getDocumentLayoutOutput();
    console.log(data);

    for (dep in data.deps) {
        console.log(data.deps[dep])
        load_src(data.deps[dep].source);
    }

    console.log("hello");

    var app = Elm[data.widget.id].init({
    	node: document.getElementById('main'),
    	flags:data.widget.config
    });

    /*var app = Elm["F"]["M"].init({
    	node: document.getElementById('main'),
    	flags:data.widget.config
    });*/


    app.ports.loadWidget.subscribe(loadWidget);

}
main();