var getDocumentLayoutOutput = function() {
    var layoutOutput = {};
    var json = document.getElementById("data").text;
    json = json.replace(/&quot;/g, '"').replace(/&amp;/g, "&").replace(/&#x27;/g, "'").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
    try {
        layoutOutput = JSON.parse(json).result;
    } catch (e) {}
    return layoutOutput;
};

function load_src(source) {
    var scriptNode = document.createElement("script");
    scriptNode.text = source;
    document.body.appendChild(scriptNode);
}

function get_app(id) {
    var current = Elm;
    mod_list = id.split(".");
    for (x in mod_list) {
        current = current[mod_list[x]];
    }
    return current;
}

function loadWidget(widget) {
    console.log("loadWidget", widget);
    inner_div_id = widget.uid + "_actual";
    var div = document.getElementById(inner_div_id);
    if (div === null) {
        div = document.createElement("div");
        div.setAttribute("id", inner_div_id);
        document.getElementById(widget.uid).appendChild(div);
    }
    subscribeApp(inner_div_id, widget.id, widget.config);
}

function subscribeApp(uid, id, config) {
    var app = get_app(id).init({
        node: document.getElementById(uid),
        flags: config
    });
    app.ports.loadWidget.subscribe(loadWidget);
}

function main() {
    var data = getDocumentLayoutOutput();
    console.log(data);
    for (dep in data.deps) {
        console.log(data.deps[dep]);
        load_src(data.deps[dep].source);
    }
    console.log("hello");
    subscribeApp("main", data.widget.id, data.widget.config);
}

main();