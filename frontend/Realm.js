(function (window) {
    "use strict";

    var iOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
    var ratio = window.devicePixelRatio || 1;
    var screen = {
        width : window.screen.width * ratio,
        height : window.screen.height * ratio
    };
    var iphoneX = (iOS && screen.width === 1242 && screen.height === 2688)? 1 : 0;
    var app = null;

    var ajax = function (url, data, callback) {
        var x = new (XMLHttpRequest || ActiveXObject)("MSXML2.XMLHTTP.3.0");
        x.open(data ? "POST" : "GET", url, true);
        x.setRequestHeader("Content-type", "application/json");
        x.onreadystatechange = function () {
            x.readyState > 3 && callback && callback(x.responseText, x);
        };
        x.send(JSON.stringify(data));
        return x;
    };

    function getApp(id) {
        var current = Elm;
        var mod_list = id.split(".");
        mod_list.forEach(function (element) {
            if (current) {
                current = current[element];
            }
        });
        return current;
    }

    function showLoading(theApp) {
        window.setTimeout(function () {
            if (theApp.is_shutting_down) {
                return;
            }
            if (app && app.ports && app.ports.onUnloading) {
                app.ports.onUnloading.send(null);
            }
        }, 200);
    }

    function navigate(url) {
        console.log("navigate", url);
        if (url.indexOf("?") !== -1) {
            url = url + "&realm_mode=layout";
        } else {
            url = url + "?realm_mode=layout";
        }

        showLoading(window.realm_app);
        ajax(url, null, function (t) {loadPage(t, false);});
    }

    function submit(data) {
        console.log("submit", data);
        var url = data.url;
        if (url.indexOf("?") !== -1) {
            url = url + "&realm_mode=layout";
        } else {
            url = url + "?realm_mode=layout";
        }
        showLoading(window.realm_app);
        ajax(url, data.data, function (t) {loadPage(t, true);});
    }

    function changePage(data) {
        console.log("changePage", data);
        loadPage(JSON.stringify(data), true);
    }

    var darkMode = !!(
        window.matchMedia
        && window.matchMedia('(prefers-color-scheme: dark)').matches
    );

    var testContext = null;
    var unloadTest = 0;

    function detectNotch() {
        var _notch = 0;

        if( 'orientation' in window ) {
          // Mobile
          if (window.orientation == 90) {
            _notch = 1;
          } else if (window.orientation == -90) {
            _notch = -1;
          }
        } else if ( 'orientation' in window.screen ) {
          // Webkit
          if( window.screen.orientation.type === 'landscape-primary') {
            _notch = 1;
          } else if( window.screen.orientation.type === 'landscape-secondary') {
            _notch = -1;
          }
        } else if( 'mozOrientation' in window.screen ) {
          // Firefox
          if( window.screen.mozOrientation === 'landscape-primary') {
            _notch = 1;
          } else if( window.screen.mozOrientation === 'landscape-secondary') {
            _notch = -1;
          }
        }
        return _notch;
    }

    function viewPortChanged() {
        app.ports.viewPortChanged.send({
            "width": window.innerWidth,
            "height": window.innerHeight,
            "notch": detectNotch(),
        })
    }

    function loadPage(text, isSubmit) {
        console.log("loadPage", isSubmit);
            var data = null;
            try {
                data = JSON.parse(text);
            } catch (e) {
                console.log("failed to parse json");
                console.log("json: ", text);
                console.log("error: ", e);
                if (!!testContext) {
                    var message = "Server Error: " + e + ", text=" + text;
                    if (text === "") {
                        message = "ServerCrashed (empty body)"
                    }
                    window.parent.app.ports.fromIframe.send([
                        {
                            kind: "BadServer",
                            message: message,
                        },
                        {kind: "TestDone"}
                    ]);
                }
                throw e;
            }
            console.log("data", data);
            //Redirect if redirect is present
            if (data.redirect) {
                window.location.replace(data.redirect);
                return;
            }

        if (app && app.ports && app.ports.shutdown) {
            console.log("shutting down");
            app.ports.shutdown.send(null);
            unloadTest = 0;
            window.realm_app.is_shutting_down = true;
            if (window.realm_app_shutdown) {
                window.realm_app_shutdown();
            }
        }

        function loadNow() {
            // wait for previous app to cleanup
            console.log("loadNow");
            if (
                app
                && !document.getElementById("appShutdownEmptyElement")
                && unloadTest < 10
            ) {
                window.requestAnimationFrame(loadNow);
                unloadTest += 1;
                if (unloadTest === 9) {
                    console.log("too many attempts to get window to clear");
                }
                return;
            }


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
            flags.iphoneX = iphoneX;
            flags.notch = detectNotch();
            flags.darkMode = darkMode;

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
                    "height": window.innerHeight,
                    "iphoneX": iphoneX,
                    "notch": detectNotch(),
                    "darkMode": darkMode
                };
            }

            app = getApp(id);
            if (!app) {
                console.log("No app found for ", id);
                if (!!testContext) {
                    window.parent.app.ports.fromIframe.send([
                        {
                            kind: "BadElm",
                            message: "No app found for: " + id
                        },
                        {kind: "TestDone"}
                    ]);
                }
                return;
            }

            app = app.init({flags: flags});
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
            if (app.ports && app.ports.changePage) {
                app.ports.changePage.subscribe(changePage);
            }
            if (app.ports.viewPortChanged) {
                window.addEventListener("resize", viewPortChanged);
                window.addEventListener("orientationchange", viewPortChanged);
            }

            if (app.ports && window.realm_extra_ports) {
                for (var portName in app.ports) {
                    if(window.realm_extra_ports.hasOwnProperty(portName)) {
                        app.ports[portName].subscribe(window.realm_extra_ports[portName]);
                    }
                }
            }

            // scroll to top on page change
            document.body.scrollTop = 0; // For Safari
            document.documentElement.scrollTop = 0; // For Chrome, Firefox, IE and Opera

            window.realm_app = app;
            if (window.realm_app_init) {
                window.realm_app_init(id, flags, app);
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
