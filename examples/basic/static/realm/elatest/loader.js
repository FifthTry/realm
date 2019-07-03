

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

function get_app(id) {
    var current = Elm;
    mod_list = id.split('.');

    for (x in mod_list) {
        current = current[mod_list[x]]
    }
    return current;
}

function loadWidgetUtil(uid, id, config){
    var div = document.createElement("div");
    div.setAttribute("id", uid);

    inner_st = uid + "_actual";
    var inner_div =  document.getElementById(inner_st);
    if (inner_div === null){
        inner_div = document.createElement("div");
        inner_div.setAttribute("id", inner_st);
    }

    div.appendChild(inner_div);



    var app = get_app(id).init({
        node: document.getElementById(uid),
        flags: config,
      });
      app.ports.loadWidget.subscribe(loadWidgetUtil);
}

function loadWidget(data) {
  console.log("loadWidget", data);
  for (var i in data){
    widget = data[i];
    console.log("widget", widget, 'get_app', get_app(widget.id));
    loadWidgetUtil(widget.uid, widget.id, widget.config);
  }

}

function main(){
    var data = getDocumentLayoutOutput();
    console.log(data);

    for (dep in data.deps) {
        console.log(data.deps[dep])
        load_src(data.deps[dep].source);
    }

    console.log("hello");

    var app = get_app(data.widget.id).init({
       node: document.getElementById('main'),
       flags: data.widget.config
    });



    /*var app = get_app("F.M").init({
       node: document.getElementById('main'),
       flags:data.widget.config
    });*/


    app.ports.loadWidget.subscribe(loadWidget);

}

main();