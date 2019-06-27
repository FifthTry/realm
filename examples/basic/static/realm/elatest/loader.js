

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

function hello(){
    var data = getDocumentLayoutOutput();
    console.log(data);

    for (dep in data.deps) {
        load_src(dep.source);
    }

    var app = Elm.[data.widget.id].init({
    	node: document.getElementById('main'),
    	flags:data.widget.config
    });
    app.ports.loadWidget.subscribe(function(handle) {
      console.log("loadWidget", handle);

      var widget = handle.first;
      Elm[widget.id].init({
        node: document.getElementById(widget.uid),
        flags: widget.flags,
      });

      widget = handle.second;
      Elm[widget.id].init({
        node: document.getElementById(widget.uid),
        flags: widget.flags,
      });


    });

}
hello();