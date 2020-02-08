(function (window) {
    "use strict";

    var iOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
    var ratio = window.devicePixelRatio || 1;
    var screen = {
        width : window.screen.width * ratio,
        height : window.screen.height * ratio
    };
    var iphoneX = (iOS && screen.width === 1242 && screen.height === 2688)? 1 : 0;

    var darkMode = !!(
        window.matchMedia
        && window.matchMedia('(prefers-color-scheme: dark)').matches
    );

    var testContext = null;
    var unloadTest = 0;

    window.realm_app = null;

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

    function disableScrolling() {
        var x=window.scrollX;
        var y=window.scrollY;
        window.onscroll=function(){window.scrollTo(x, y);};
    }

    function enableScrolling() {
        window.onscroll=function(){};
    }

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
            if (theApp.cancel_loading) {
                return;
            }
            if (theApp && theApp.ports && theApp.ports.onUnloading) {
                theApp.ports.onUnloading.send(null);
            }
        }, 200);
    }

    function navigate(url, isPop) {
        console.log("navigate", url);
        if (url.indexOf("?") !== -1) {
            url = url + "&realm_mode=layout";
        } else {
            url = url + "?realm_mode=layout";
        }

        showLoading(window.realm_app);
        ajax(url, null, function (t) {loadPage(t, false, isPop);});
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

    function detectNotch() {
        var _notch = 0;
        if (!iphoneX) {
            return _notch;
        }

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
        if (
            window.realm_app
            && window.realm_app.ports
            && window.realm_app.ports.viewPortChanged
        ) {
            window.realm_app.ports.viewPortChanged.send({
                "width": window.innerWidth,
                "height": window.innerHeight,
                "notch": detectNotch(),
            })
        }
    }

    function shutdown() {
        unloadTest = 0;

        if (!window.realm_app) {
            console.log("shutdown: nothing to shutdown");
            // nothing to shutdown
            return
        }

        if (window.realm_app.ports && window.realm_app.ports.shutdown) {
            console.log("shutdown: sending shutdown signal");
            window.realm_app.ports.shutdown.send(null);

            // this is used to show loading dialog
            window.realm_app.is_shutting_down = true;

            if (window.realm_app_shutdown) {
                // this is our "hook", a client app can configure this to do something
                // specific when app is shutting down
                window.realm_app_shutdown();
            }
        } else {
            console.log("shutdown: no port to send shutdown signal on");
        }
    }

    function waitAfterShutdown(cb) {
        if (!window.realm_app) {
            // if app is not there, there is no need to wait, there was nothing
            // to shutdown
            console.log("waitAfterShutdown: nothing to wait");
            return false;
        }

        if (unloadTest > 10) {
            // time to give up
            console.log("waitAfterShutdown: too many attempts");
            return true;
        }

        // if we are here means the app was there, which we have triggered a shutdown
        // on, and unloadTest attempts is below 10.
        //
        // app is supposed to create an element with the ID: appShutdownEmptyElement
        // when its shutdown successfully, lets see if its there or not:
        if (!!document.getElementById("appShutdownEmptyElement")) {
            console.log("waitAfterShutdown: shutdown successful");
            // wonderful, we found our element, no need to wait further
            return false;
        }

        // the element is still not there :-(, wait more
        console.log("waitAfterShutdown: enqueueing");
        window.requestAnimationFrame(cb);
        unloadTest += 1;

        return true;
    }

    function loadPage(text, isSubmit, isPop) {
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

        shutdown();

        function loadNow() {
            // wait for previous app to cleanup
            if (waitAfterShutdown(loadNow)) {
                return;
            }

            if (data.url !== document.location.pathname + document.location.search || !!data.replace) {
                if (!!data.replace) {
                    history.replaceState(null, null, data.replace);
                } else {
                    history.replaceState(null, null, data.url);
                }

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

            var app = getApp(id);
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
            enableScrolling();
            if (app.ports && app.ports.navigate) {
                app.ports.navigate.subscribe(navigate);
            }
            if (app.ports && app.ports.setLoading) {
                app.ports.setLoading.subscribe(function() {showLoading(app)});
            }
            if (app.ports && app.ports.cancelLoading) {
                app.ports.cancelLoading.subscribe(
                    function() { app.cancel_loading = true }
                );
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
            if (app.ports && app.ports.disableScrolling) {
                app.ports.disableScrolling.subscribe(disableScrolling);
            }
            if (app.ports && app.ports.enableScrolling) {
                app.ports.enableScrolling.subscribe(enableScrolling);
            }

            if (app.ports && window.realm_extra_ports) {
                for (var portName in app.ports) {
                    if(window.realm_extra_ports.hasOwnProperty(portName)) {
                        app.ports[portName].subscribe(window.realm_extra_ports[portName]);
                    }
                }
            }

            // trying to disable auto scroll behaviour, but its buggy
            if (!isPop) {
                // scroll to top on page change

                // For Safari
                document.body.scrollTop = 0;
                // For Chrome, Firefox, IE and Opera
                document.documentElement.scrollTop = 0;
            }

            window.realm_app = app;
            if (window.realm_app_init) {
                window.realm_app_init(id, flags, app);
            }

            console.log("initialized app", id, flags, app);
        }

        loadNow();
    }

    function handleCmd(cmd) {
        console.log("got message from parent", cmd);
        if (cmd.action === "navigate") {
            testContext = cmd;
            navigate(cmd.url);
        } else if (cmd.action === "submit") {
            testContext = cmd;
            submit(cmd.payload);
        } else if (cmd.action === "render") {
            shutdown();

            function renderNow() {
                // wait for previous app to cleanup
                if (waitAfterShutdown(renderNow)) {
                    return;
                }

                cmd.width = window.innerWidth;
                cmd.height = window.innerHeight;
                cmd.iphoneX = iphoneX;
                cmd.notch = detectNotch();
                cmd.darkMode = darkMode;
                window.realm_app = getApp(cmd.id).init({flags: cmd});

                // why are we not subscribing to ports?
                if (window.realm_app_init) {
                    window.realm_app_init(id, flags, window.realm_app);
                }
            }

            renderNow();
        }
    }

    function main() {
        if (document.location.pathname === "/iframe/") {
            window.handleCmd = handleCmd;
            window.parent.iframeLoaded();
        } else {
            loadPage(document.getElementById("data").text, false);
        }

        window.addEventListener("resize", viewPortChanged);
        window.addEventListener("orientationchange", viewPortChanged);
        window.onpopstate = function () {
            navigate(document.location.pathname + document.location.search, true);
        };
    }

    main();
}(this));
