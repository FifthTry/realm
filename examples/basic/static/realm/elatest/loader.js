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
    var app = get_app(widget.id).init({
        node: document.getElementById(widget.uid),
        flags: {
            config: widget.config,
            uid: widget.uid
        }
    });
    console.log("widget", app);
    if (app.ports) {
        app.ports.loadWidget.subscribe(loadWidget);
    }
}

function main() {
    var data = getDocumentLayoutOutput();
    console.log(data);
    for (dep in data.deps) {
        console.log(data.deps[dep]);
        load_src(data.deps[dep].source);
    }
    console.log("hello");
    loadWidget({
        uid: "main",
        id: data.widget.id,
        config: data.widget.config
    });
}

main();