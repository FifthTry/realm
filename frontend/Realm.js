(function () {
    "use strict";

    var log = console.log;
    // console.log = function() {};

    var inChangePage = false;

    var iOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
    var ratio = window.devicePixelRatio || 1;
    var screen = {
        width: window.screen.width * ratio,
        height: window.screen.height * ratio
    };
    var iphoneX = (iOS && screen.width === 1242 && screen.height === 2688) ? 1 : 0;

    var testContext = null;
    var unloadTest = 0;

    var isDev = false;
    var domain = "";

    window.realm_app = null;

    var NOOP = function () { };

    var MODE_NOTHING = 0;
    var MODE_CACHE = 1;
    var MODE_PURE = 2;
    var MODE_ISED = 3;

    var USER_DATA_URL = "/__realm__user__/"; // ensure its in sync with sw.js
    var TEMPLATE_URL = "/__realm__template__/"; // ensure its in sync with sw.js

    var is_first_load = true;
    var user_data = null;

    function setSessionStorage(data) {
        localStorage.setItem(data.key, JSON.stringify(data.value.local));
        sessionStorage.setItem(data.key, JSON.stringify(data.value.session));
    }
    function setLocalStorage(data) {
        localStorage.setItem(data.key, JSON.stringify(data.value));
    }
    function deleteSessionStorage(data) {
        sessionStorage.setItem(data.key, null);
        localStorage.setItem(data.key, null);
    }

    function scrollIntoView(id) {
        var element = document.getElementById(id);
        if (element != null) {
            element.scrollIntoView();
        }
    }

    function disableScrolling() {
        console.log("disableScrolling");

        var x = window.scrollX;
        var y = window.scrollY;

        window.onscroll = function () {
            window.scrollTo(x, y);
            sendScroll();
        };
    }

    function sendScroll() {
        if (!!window.realm_app.ports.onScroll_) {
            window.realm_app.ports.onScroll_.send(null);
        }
    }

    function enableScrolling() {
        console.log("enableScrolling");
        window.onscroll = sendScroll;
    }

    function getApp(id) {
        // id Pages.Index: js will contain Elm.Pages.Index (Elm.Pages.Index.init())
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
        if (!theApp) {
            console.log("showLoading: got null");
            return;
        }

        console.log("showLoading: setting timer");
        window.setTimeout(function () {
            if (theApp.is_shutting_down) {
                console.log("is_shutting_down is true");
                console.log("showLoading: app shutting down");
                return;
            }
            if (theApp.cancel_loading) {
                console.log("showLoading: loading has been cancelled");
                return;
            }
            if (theApp && theApp.ports && theApp.ports.onUnloading) {
                console.log("showLoading: sending signal to app");
                theApp.showing_loading = true;
                theApp.ports.onUnloading.send(true);
            }
        }, 300);
    }

    function cancelLoading(theApp) {
        if (!!theApp.showing_loading) {
            console.log("cancelLoading: after loading");
            theApp.ports.onUnloading.send(false);
        } else {
            console.log("cancelLoading: before loading");
            theApp.cancel_loading = true;
        }
    }

    function navigate(url, isPop, pageLoad) {
        // if old url and url only differ in hash then return
        console.log("navigate", url);
        enableScrolling();
        // TODO: Fix replay test.
        // var url = new URL(url, document.location.href);
        // url = url.origin + url.pathname + url.search;
        // url = url.pathname + url.search;

        // TODO: if URL is no longer pointing to self domain, document.location = url?

        if (url.indexOf("/test/replay/") === 0) {
            document.location = url;
            return;
        }

        console.log("navigate", url, isPop, pageLoad, url.indexOf("/test/replay/"));
        var realm_navigation_context = {
            ctx: Math.random(),
            mode: MODE_NOTHING,
        };

        if (pageLoad) {
            window.realm_navigation_context = realm_navigation_context;
            console.log("page load, not trying ised");
            loadPage(
                document.getElementById("data").text,
                url, false, false, MODE_ISED,
                realm_navigation_context.ctx,
            );
            return;
        }

        // [see https://www.fifthtry.com/amitu/realm/proposal/offline/ for design]
        //
        // we have to make (race) (upto) three requests here:
        //
        // 1. cache: to browser cache (cache key url without realm_mode)
        // 2. pure: in pure mode to CDN edge server
        // 3. ised: if logged in (ud cookie present): in realm mode to backend server
        //
        // we will add a third parameter to loadPage (target, which will be one of
        // cache/pure/ised).
        //
        // we need a "context" or something to indicate that each of these three
        // requests are part of same context, so if context changes (another navigate
        // request comes) before all the responses have been handled, we want to want to
        // ignore those responses. context can be current timestamp in nanoseconds, and
        // has to be passed to loadPage as 5th parameter, as well as stored globally.
        //
        // we also have a precedence rule: nothing < cache < pure < ised (layout), this
        // reflects whats currently displayed in window, lower level content if arrived
        // late can not overwrite higher level content. also error (eg 404) response
        // from only ised mode is shown in browser.
        //
        // window.realm_navigation_context: {
        //     "timestamp": "<timestamp in nanoseconds>",
        //     "state": "nothing",
        //     "url": "url",  // no actual use as of now, for debugging?
        // }
        //

        var ud_cookie_exists = document.cookie.indexOf("ud=") !== -1;
        var running_under_test = !!testContext;

        var try_rust = false; // short for personalised (ud cookie): this request always goes to our final server
        var try_cdn = false; // this request can be cached at edge (mumbai), and can be shared across all users
        var try_browser_cache = false; // this is in browser local cache
        var pure_on_cache_miss = false;
        var page_data_on_cache_miss = false;
        var show_offline_on_cache_miss = false;

        if (running_under_test) {
            try_rust = true;
            try_browser_cache = false;
            try_cdn = false;
            pure_on_cache_miss = false;
            page_data_on_cache_miss = false;
        } else {
            if (is_first_load) {
                if (ud_cookie_exists) {
                    try_cdn = false;
                    try_rust = navigator.onLine;
                    try_browser_cache = !!window.caches;
                    pure_on_cache_miss = false;
                    page_data_on_cache_miss = true;
                    show_offline_on_cache_miss = false;
                } else {
                    try_cdn = navigator.onLine;
                    try_rust = false;
                    try_browser_cache = !!window.caches;
                    pure_on_cache_miss = false;
                    page_data_on_cache_miss = true;
                    show_offline_on_cache_miss = false;
                }
                is_first_load = false;
            } else {
                // not first load
                if (ud_cookie_exists) {
                    try_rust = navigator.onLine;
                    try_cdn = false;
                    try_browser_cache = !!window.caches;
                    pure_on_cache_miss = true;
                    page_data_on_cache_miss = false;
                    show_offline_on_cache_miss = !navigator.onLine;
                } else {
                    try_rust = false;
                    try_cdn = navigator.onLine;
                    try_browser_cache = !!window.caches;
                    pure_on_cache_miss = false;
                    page_data_on_cache_miss = false;
                    show_offline_on_cache_miss = !navigator.onLine;
                }
            }
        }

        // for now we are disabling caching behaviour
        try_rust = true;
        try_browser_cache = false;
        try_cdn = false;
        pure_on_cache_miss = false;
        page_data_on_cache_miss = false;

        function showOffline() {
            loadPage(JSON.stringify(offline_app(url)), url, false, isPop, MODE_CACHE);
        }

        if (!window.caches && !navigator.onLine && !try_cdn && !try_rust) {
            showOffline();
            return;
        }

        var ised_url = "";
        var pure_url = "";
        if (url.indexOf("?") !== -1) {
            ised_url = url + "&realm_mode=ised";
            pure_url = url + "&realm_mode=pure";
        } else {
            ised_url = url + "?realm_mode=ised";
            pure_url = url + "?realm_mode=pure";
        }

        showLoading(window.realm_app);

        if (try_rust) {
            ajax(
                ised_url,
                null,
                function (t) {
                    console.log("navigate: ised response:", ised_url, t.substr(0, 100));

                    if (!t) {
                        console.log("got null response: ignoring", navigator.onLine);
                        return;
                    }

                    loadPage(
                        t, url, false, isPop,
                        MODE_ISED, realm_navigation_context.ctx,
                    );
                }
            );
        }

        if (running_under_test) {
            return;
        }

        function do_pure() {
            ajax(
                pure_url,
                null,
                function (t) {
                    console.log("pure response:", pure_url, t.substr(0, 100));

                    if (!t) {
                        console.log("got null response: ignoring", navigator.onLine);
                        return;
                    }

                    loadPage(
                        t, url, false, isPop,
                        MODE_PURE, realm_navigation_context.ctx,
                    );
                }
            );
        }

        if (try_browser_cache) {
            // we are writing code with assumption that all cache implementations also
            // implement promise based api
            caches.open("realm").then(function (cache) {
                cache.match(url).then(function (r) {
                    if (!!r) {
                        r.text().then(function (text) {
                            console.log("navigate: cache response:", url, text.substr(0, 100));
                            loadPage(
                                text, url, false, isPop,
                                MODE_CACHE, realm_navigation_context.ctx,
                            );
                        });
                    } else {
                        console.log("navigate: cache miss");
                        if (show_offline_on_cache_miss) {
                            showOffline();
                        }

                        if (pure_on_cache_miss) {
                            do_pure();
                        }

                        if (page_data_on_cache_miss) {
                            loadPage(
                                document.getElementById("data").text,
                                url, false, isPop, MODE_PURE,
                                realm_navigation_context.ctx,
                            );
                        }
                    }
                });
            });
        }

        if (try_cdn) {
            do_pure();
        }

        window.realm_navigation_context = realm_navigation_context;
    }

    function unescapeUrlString(urlString) {
        urlString = urlString.replace("\\u003E", '>');
        urlString = urlString.replace("\\u003C", '<');
        urlString = urlString.replace("\\u0026", '&')
        return urlString
    }

    function submit(data) {
        if(typeof data === 'string' || data instanceof String) {
            data = {
                url: unescapeUrlString(data),
                data: {}
            }
        }
        console.log("submit", data.url, data.data);
        var url = data.url;
        if (url.indexOf("?") !== -1) {
            url = url + "&realm_mode=ised";
        } else {
            url = url + "?realm_mode=ised";
        }
        showLoading(window.realm_app);

        // print data.data: if this is null then GET request will go
        ajax(
            url, data.data,
            function (t) {
                loadPage(t, data.url, true, false, MODE_ISED, null);
            }
        );
        window.realm_navigation_context = null;
    }

    window.REALM_SUBMIT = submit;

    function changePage(data) {
        console.log("changePage", data);
        inChangePage = true;
        loadPage(JSON.stringify(data.data), data.url, true, false, MODE_ISED, null);
    }

    function triggerReload(id) {
        if (document.getElementById(id).contentDocument && document.getElementById(id).contentDocument.location) {
            document.getElementById(id).contentDocument.location.reload(true);
        }
    }
    function triggerClassReload(name) {
        var els = document.getElementsByClassName(name);
        if (!els || els.length === 0) return;

        for (var i = 0; i < els.length; i++) {
            if (els[i].contentDocument && els[i].contentDocument.location) {
                els[i].contentDocument.location.reload(true);
            }
        }
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

    function initializeFtd(theApp, data) {
        /*
            data:

            { id: "ftd-main",   // ID of dom node where ftd should render things
            , data: {}          // interpreter data
            }
        */

        // when this is called elm may not yet have constructed the DOM node
        // where wasm should render things, so we subscribe to animation frame
        // and wait for a DOM node with data.id to show up.


        let attempts = 0;

        function inner() {
            if (!document.getElementById(data.id)) {
                if (attempts < 10) {
                    console.log("initializeFtd", data.id, "not yet found");
                    attempts += 1;
                    window.requestAnimationFrame(inner);
                    return;
                } else {
                    console.log("initializeFtd", data.id, "not found after 10 attempts");
                    return;
                }
            }

            console.log("initializeFtd__", data);

            document.getElementById(data.id).innerHTML = data.data.html;

            window.ftd.init(data.id, data.data.data, data.data.external_children);

            theApp.ports.ftdHandle.send({ id: data.id, handle: data.id });
        }

        window.requestAnimationFrame(inner);
    }

    function ports(app) {
        if (app.ports && app.ports.navigate) {
            app.ports.navigate.subscribe(function (u) { navigate(u, false) });
        }
        if (app.ports && app.ports.setLoading) {
            app.ports.setLoading.subscribe(function () { showLoading(app) });
        }
        if (app.ports && app.ports.cancelLoading) {
            app.ports.cancelLoading.subscribe(function () { cancelLoading(app) });
        }
        if (app.ports && app.ports.submit) {
            app.ports.submit.subscribe(submit);
        }
        if (app.ports && app.ports.toIframe) {
            app.ports.toIframe.subscribe(function (r) {
                console.log("loadNow: toIframe", r);
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
        if (app.ports && app.ports.copyToClipboard) {
            app.ports.copyToClipboard.subscribe(copyToClipboard);
        }
        if (app.ports && app.ports.setSessionStorage) {
            app.ports.setSessionStorage.subscribe(setSessionStorage);
        }
        if (app.ports && app.ports.deleteSessionStorage) {
            app.ports.deleteSessionStorage.subscribe(deleteSessionStorage);
        }
        if (app.ports && app.ports.scrollIntoView) {
            app.ports.scrollIntoView.subscribe(scrollIntoView);
        }
        if (app.ports && app.ports.initializeFtd) {
            app.ports.initializeFtd.subscribe(
                function (data) { initializeFtd(app, data); }
            );
        }
        if (app.ports && app.ports.renderFtd) {
            app.ports.renderFtd.subscribe(
                function (handle) {
                    console.log("renderFtd", handle);
                    handle.render();
                }
            );
        }
        if (app.ports && app.ports.setFtdBool) {
            app.ports.setFtdBool.subscribe(
                function (data) {
                    console.log("setFtdBool", data); // TODO: fix this
                    window.ftd.set_bool(data.handle, data.variable, data.value);
                }
            );
        }
        if (app.ports && app.ports.setFtdMultiValue) {
            app.ports.setFtdMultiValue.subscribe(
                function (data) {
                    console.log("setFtdMultiValue", data); // TODO: fix this
                    window.ftd.set_multi_value(data.handle, data.list);
                }
            );
        }

        if (app.ports && window.realm_extra_ports) {
            for (var portName in app.ports) {
                if (window.realm_extra_ports.hasOwnProperty(portName)) {
                    app.ports[portName].subscribe(window.realm_extra_ports[portName]);
                }
            }
        }
        if (app.ports && app.ports.triggerReload) {
            app.ports.triggerReload.subscribe(triggerReload);
        }
        if (app.ports && app.ports.triggerClassReload) {
            app.ports.triggerClassReload.subscribe(triggerClassReload);
        }
        if (app.ports && app.ports.setLocalStorage) {
            app.ports.setLocalStorage.subscribe(setLocalStorage);
        }
    }

    function shutdown() {
        // Notes: https://fifthtry.com/amitu/realm/shutdown/
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

    function loadPage(text, expected_url, isSubmit, isPop, mode, ctx) {
        // if you are reviewing this function, may god have mercy on you! maybe I
        // should have studied computer science in collage instead of mechanical
        // engineering. how do i sleep you ask? with great amount of difficulty.

        console.log("loadPage: called", expected_url, isSubmit, isPop, mode, ctx);

        if (
            !!ctx
            && !!window.realm_navigation_context
            && window.realm_navigation_context.ctx === ctx
            && window.realm_navigation_context.mode < mode
        ) {
            window.realm_navigation_context.mode = mode;
        }

        if (
            !!ctx
            && !!window.realm_navigation_context
            && window.realm_navigation_context.ctx !== ctx
        ) {
            console.log("loadPage: got out of context response, ignoring");
            return;
        }

        if (
            !!mode
            && !!window.realm_navigation_context
            && window.realm_navigation_context.mode > mode
        ) {
            console.log("loadPage: already have better mode stuff, ignoring");
            return;
        }

        var data = null;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.error("loadPage: failed to parse json");
            console.error("loadPage: json: ", text);
            console.error("loadPage: error: ", e);
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
                    { kind: "TestDone" }
                ]);
            }
            throw e;
        }
        console.log("loadPage: data", data);

        isDev = data.dev;
        domain = data.domain;


        if (!!window.caches && data.template) {
            console.log("loadPage: storing template to cache");
            caches.open("realm").then(function (cache) {
                cache.put(TEMPLATE_URL, new Response(data.template)).then(NOOP);
            });
        }

        var found_url = data.redirect || data.replace || data.url;
        var realm_t = found_url.indexOf("&realm_t=");
        if (realm_t !== -1) {
            // only safe because realm_t is last argument
            found_url = found_url.substring(0, realm_t);
        }

        console.log("loadPage: expected", expected_url, "found", found_url);
        var ud_cookie_exists = document.cookie.indexOf("ud=") !== -1;

        if (
            data.id !== "Pages.NotFound"
            && mode === MODE_ISED
            && found_url === expected_url
        ) {
            user_data = data.config.base;
        } else if (!!user_data && (mode === MODE_PURE || mode === MODE_CACHE)) {
            data.config.base = user_data;
        }

        if (mode === MODE_ISED && !!window.caches && !!user_data) {
            // on every ised response we update the cache
            console.log("loadPage: storing user_data to cache");
            caches.open("realm").then(function (cache) {
                cache.put(
                    USER_DATA_URL, new Response(JSON.stringify(user_data))
                ).then(NOOP);
            });
        } else if (!!window.caches) {
            console.log("loadPage: purging user_data from cache");
            caches.open("realm").then(function (cache) {
                cache.delete(USER_DATA_URL).then(NOOP);
            });
        }

        if (
            mode !== MODE_ISED
            && ud_cookie_exists
            && (
                expected_url !== found_url
                || data.id === "Pages.NotFound"
            )
        ) {
            console.log("loadPage: replace/redirect/404, but mode is not ised, ignoring");
            return;
        }

        // NOTE: we want to cache *irrespective* of what isSubmit is.
        if (
            (found_url === expected_url)
            && !!window.caches
            && (
                (mode === MODE_PURE && !ud_cookie_exists)
                || mode === MODE_ISED
            )
            && data.id !== "Pages.NotFound"
        ) {
            caches.open("realm").then(function (cache) {
                console.log("loadPage: storing data to cache", found_url);
                cache.put(found_url, new Response(text)).then(NOOP);
            });
        } else {
            console.log(
                "loadPage: decided not to cache",
                (found_url === expected_url),
                !!window.caches,
                (mode === MODE_PURE && !ud_cookie_exists),
                mode === MODE_ISED,
                data.id !== "Pages.NotFound"
            );
        }

        // redirect if redirect is present
        if (data.redirect && data.id === "") {
            console.log("loadPage: redirect is set, redirecting", data.redirect);
            window.location.replace(data.redirect);
            return;
        }

        shutdown();

        function loadNow() {
            if (
                !!ctx
                && !!window.realm_navigation_context
                && window.realm_navigation_context.ctx !== ctx
            ) {
                console.log("loadNow: got out of context response, ignoring");
                return;
            }

            if (
                !!mode
                && !!window.realm_navigation_context
                && window.realm_navigation_context.mode > mode
            ) {
                console.log("loadNow: already have better mode stuff, ignoring");
                return;
            }

            // wait for previous app to cleanup
            if (waitAfterShutdown(loadNow)) {
                return;
            }

            var hostname = window.location.hostname;

            try {
                var url_constructed = new URL(data.url);
                var url_hostname = url_constructed.hostname;
            } catch (_) {
                var url_hostname = hostname;
            }
            if (hostname != url_hostname) {
                document.location = data.url;
            }

            if (expected_url !== found_url) {
                if (!!data.replace) {
                    console.log("replacing", expected_url, found_url, data.replace);
                    history.replaceState(null, null, data.replace);
                } else {
                    console.log("pushing", expected_url, found_url, data.replace);
                    history.pushState(null, null, data.url);
                }
            }

            if (!isSubmit && data.hash > window.realm_hash && navigator.onLine) {
                console.log("loadNow: realm hash mismatch, reloading");
                document.location.reload();
            }

            var id = data.id; // ELM app name, will be like Pages.Index for example
            var flags = data;

            if (found_url === "/the/__realm_offline_app__/") {
                flags = offline_app(expected_url);
                id = flags.id;
                console.log("using offline app", flags);
            }

            attachFlagVars(flags);

            if (!!testContext) {
                window.parent.app.ports.fromIframe.send([
                    { kind: "Started", flags: data }
                ]);

                if (testContext.elm !== id) {
                    console.log("loadNow: expected", testContext.elm, "got", id);
                    window.parent.app.ports.fromIframe.send([
                        {
                            kind: "BadElm",
                            message: "Expected: " + testContext.elm + " got: " + id
                        },
                        { kind: "TestDone" }
                    ]);
                    return;
                }
                // id is ELM app name, will be like Pages.Index for example. when running under test, dont actually
                // load Elm.Pages.Index.init(), we do Elm.Pages.IndexTest.init()
                id = data.id + "Test";
                flags = attachFlagVars({
                    "id": testContext.id,
                    "title": data.title,
                    "config": data.config,
                    "context": testContext.context,
                });
            }

            var app = getApp(id);
            if (!app) {
                log("loadNow: No app found for ", id);
                if (!!testContext) {
                    window.parent.app.ports.fromIframe.send([
                        {
                            kind: "BadElm",
                            message: "No app found for: " + id
                        },
                        { kind: "TestDone" }
                    ]);
                }
                return;
            }

            app = app.init({ flags: flags });
            ports(app);

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

            console.log("loadNow: initialized app", id, flags, app);
        }

        loadNow();
    }

    function handleCmd(cmd) {
        console.log("got message from parent", cmd);
        if (cmd.action === "navigate") {
            testContext = cmd;
            navigate(cmd.url, false);
        } else if (cmd.action === "submit") {
            testContext = cmd;
            submit(cmd.payload);
        } else if (cmd.action === "load") {
            testContext = cmd;
            loadPage();
        } else if (cmd.action === "render") {
            shutdown();

            function renderNow() {
                // wait for previous app to cleanup
                if (waitAfterShutdown(renderNow)) {
                    return;
                }

                attachFlagVars(cmd.data);
                window.realm_app = getApp(cmd.data.id).init({ flags: cmd.data });
                enableScrolling();

                // TODO: initially we did not subscribe to ports, why?
                ports(window.realm_app);

                if (window.realm_app_init) {
                    window.realm_app_init(cmd.data.id, cmd.data, window.realm_app);
                }
            }

            renderNow();
        }
    }

    function attachFlagVars(flags) {
        flags.width = window.innerWidth;
        flags.height = window.innerHeight;
        flags.iphoneX = iphoneX;
        flags.notch = detectNotch();
        flags.darkMode = !!(
            window.matchMedia
            && window.matchMedia('(prefers-color-scheme: dark)').matches
        );
        flags.now = new Date().getTime();
        flags.dev = isDev;
        flags.domain = domain;

        return flags;
    }

    function execCopy(text) {
        // this is blocking call and less preferred, but has wider browser support
        var textArea = document.createElement("textarea");
        textArea.value = text;

        textArea.style.top = "0";
        textArea.style.left = "0";
        textArea.style.position = "fixed";

        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();

        try {
            document.execCommand('copy');
        } catch (e) {
            console.error('execCopy failed:', e);
        }

        document.body.removeChild(textArea);
    }

    function copyToClipboard(text) {
        if (!navigator.clipboard) {
            execCopy(text);
            return;
        }
        navigator.clipboard.writeText(text).then(
            function () {
                console.log('Async: Copying to clipboard was successful!');
            }, function (e) {
                console.error('copyText: writeText failed', e);
            }
        );
    }

    function main() {
        if (document.location.pathname === "/iframe/") {
            window.handleCmd = handleCmd;
            window.parent.iframeLoaded();
        } else {
            var url = document.location.pathname + document.location.search;
            if (document.cookie.indexOf("ud=") !== -1 && !!window.caches) {
                caches.open("realm").then(function (cache) {
                    cache.match(USER_DATA_URL).then(function (r) {
                        if (!r) {
                            console.log("main: no user in cache");
                            navigate(url, false, true);
                            return;
                        }
                        r.json().then(function (u) {
                            console.log("main: populating user_data from cache");
                            user_data = u;
                            navigate(url, false, true);
                        })
                    });
                });
            } else {
                if (!!window.caches) {
                    console.log("main: purging user_data from cache");
                    caches.open("realm").then(function (cache) {
                        cache.delete(USER_DATA_URL).then(NOOP);
                    });
                }
                navigate(url, false, true);
            }
        }

        window.addEventListener("resize", viewPortChanged);
        window.addEventListener("orientationchange", viewPortChanged);
        window.onpopstate = function () {
            console.log("onpopstate", document.pathname);
            navigate(document.location.pathname + document.location.search, true);
        };

        if ( false &&
            'serviceWorker' in navigator
            && navigator.onLine
            && document.location.toString().indexOf("127.0.0.1") === -1
        ) {
            // in Safari, to see service worker logs Develop -> Service Workers.
            window.addEventListener('load', function () {
                navigator.serviceWorker.register(
                    '/static/' + window.realm_hash + '/sw.js',
                    { "scope": "/" },
                ).then(function () {
                    console.log("registered service worker");
                });
            });
        }
    }

    function detectNotch() {
        var _notch = 0;
        if (!iphoneX) {
            return _notch;
        }

        if ('orientation' in window) {
            // Mobile
            if (window.orientation === 90) {
                _notch = 1;
            } else if (window.orientation === -90) {
                _notch = -1;
            }
        } else if ('orientation' in window.screen) {
            // Webkit
            if (window.screen.orientation.type === 'landscape-primary') {
                _notch = 1;
            } else if (window.screen.orientation.type === 'landscape-secondary') {
                _notch = -1;
            }
        } else if ('mozOrientation' in window.screen) {
            // Firefox
            if (window.screen.mozOrientation === 'landscape-primary') {
                _notch = 1;
            } else if (window.screen.mozOrientation === 'landscape-secondary') {
                _notch = -1;
            }
        }
        return _notch;
    }

    class RealmHTML extends HTMLElement {
        constructor() {
            super();

            this._src = "<h1>hello world</h1>";
        }

        get src() {
            return this._src;
        }

        set src(value) {
            if (value === this._src) {
                return;
            }

            this._src = value;
            this.innerHTML = value;
        }

        connectedCallback() {
            this.innerHTML = this._src;
        }
    }
    customElements.define('realm-html', RealmHTML);


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

    function offline_app(url) {
        var msg = "Offline - Network Not Available";
        return {
            "title": msg,
            "id": "Pages.Offline",
            "config": {
                "message": msg,
                "title": msg,
                "base": user_data,
                "url": url,
            },
            "url": url,
            "replace": null,
            "redirect": null,
            "cache": {
                "etag": null,
                "purge_caches": [],
                "id": "default",
            },
            "hash": "",
            "pure": true,
            "pure_mode": "base",
        };
    }

    main();
    return submit;
})();
