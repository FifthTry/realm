(function (window) {
    "use strict";

    var ajax = function (url, data, callback) {
        var x = new (XMLHttpRequest || ActiveXObject)("MSXML2.XMLHTTP.3.0");
        x.open(data ? "POST" : "GET", url, true);
        x.setRequestHeader("Content-type", "application/json");
        x.onreadystatechange = function () {
            x.readyState > 3 && callback && callback(x.responseText, x);
        };
        x.send(JSON.stringify(data)
        );
        return x;
    };

    function getApp(id) {
        var current = Elm;
        var mod_list = id.split(".");
        mod_list.forEach(function (element) {
            current = current[element];
        });
        return current;
    }

    function navigate(url) {
        console.log("navigate", url);
        if (url.indexOf("?") !== -1) {
            url = url + "&realm_mode=layout";
        } else {
            url = url + "?realm_mode=layout";
        }
        ajax(url, null, function (t) {loadPage(t, false);});
    }

    function submit(data) {
        console.log("submit", data);
        ajax(
            data.url + "?realm_mode=layout",
            data.data,
            function (t) {loadPage(t, true);}
        );
    }

    var app = null;
    var testContext = null;

    function loadPage(text, isSubmit) {
        console.log("loadPage", isSubmit);
        if (app && app.ports && app.ports.shutdown) {
            console.log("shutting down");
            app.ports.shutdown.send(null);
        }

        function loadNow() {
            // wait for previous app to cleanup
            console.log("loadNow");
            if (app && document.body.childElementCount !== 0) {
                window.requestAnimationFrame(loadNow);
                return;
            }

            var data = null;
            try {
                data = JSON.parse(text);
            } catch (e) {
                console.log("failed to parse json");
                console.log("json: ", text);
                console.log("error: ", e);
                throw e;
            }
            console.log("data", data);

            if (data.url !== document.location.pathname + document.location.search) {
                history.replaceState(null, null, data.url);
            }

            if (isSubmit) {
                if (data.replace) {
                    console.log("isSubmit, replacing", data.replace);
                    history.replaceState(null, null, data.replace);
                }
                if (data.url !== document.location.pathname) {
                    console.log("isSubmit, pushing", data.url);
                    history.pushState(null, null, data.url);
                }
            }

            var id = data.id;
            var flags = data;
            flags.width = window.innerWidth;
            flags.height = window.innerHeight;

            if (!!testContext) {
                if (testContext.elm !== id) {
                    console.log("expected", testContext.elm, "got", id);
                    window.parent.app.ports.fromIframe.send([
                        {
                            kind: "BadElm",
                            message: "Expected: " + testContext.elm + " got: " + id
                        },
                        {kind: "TestDone"}
                    ]);
                    return;
                }
                id = data.id + "Test";
                flags = {
                    "id": testContext.id,
                    "title": data.title,
                    "config": data.config,
                    "context": testContext.context,
                    "width": window.innerWidth,
                    "height": window.innerHeight
                };
            }

            app = getApp(id).init({flags: flags});
            if (app.ports && app.ports.navigate) {
                app.ports.navigate.subscribe(navigate);
            }
            if (app.ports && app.ports.submit) {
                app.ports.submit.subscribe(submit);
            }
            if (app.ports && app.ports.toIframe) {
                app.ports.toIframe.subscribe(function(r){
                    console.log("toIframe", r);
                    window.parent.app.ports.fromIframe.send(r);
                });
            }
            console.log("initialized app", id, flags, app);
        }

        loadNow();
    }

    window.onpopstate = function () {
        navigate(document.location.pathname + document.location.search);
    };

    function handleCmd(cmd) {
        console.log("got message from parent", cmd);
        if (cmd.action === "navigate") {
            testContext = cmd;
            navigate(cmd.url);
        } else if (cmd.action === "submit") {
            testContext = cmd;
            submit(cmd.payload);
        } else if (cmd.action === "render") {
            if (app && app.ports.shutdown) {
                app.ports.shutdown.send(null);
            }

            function renderNow() {
                // wait for previous app to cleanup
                console.log("renderNow");
                if (app && document.body.childElementCount !== 0) {
                    window.requestAnimationFrame(renderNow);
                    return;
                }

                console.log("renderNow2");
                cmd.width = window.innerWidth;
                cmd.height = window.innerHeight;
                app = getApp(cmd.id).init({flags: cmd});
            }
            renderNow();
        }
    }

    function main() {
        if (document.location.pathname === "/iframe/") {
            console.log("iframe mode loaded");
            window.handleCmd = handleCmd;
            window.parent.iframeLoaded();
        } else {
            loadPage(document.getElementById("data").text, false);
        }
    }

    main();
}(this));
