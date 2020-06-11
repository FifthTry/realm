// NOTE: when debugging service worker consider closing all tabs with your site to
//       allow it to re-install.

// NOTE: in Safari, to see service worker logs Develop -> Service Workers.

self.addEventListener('install', function(event) {
    event.waitUntil(
        caches.open('realm').then(function (cache) {
            console.log("sw: installed", realm_hash);
            return cache.addAll([
                '/static/elm.' + realm_hash + ".js",
                '/static/sw.' + realm_hash + ".js",
            ]);
        })
    );
});

self.addEventListener('activate', function() {
    console.log("sw: activated");
});

var USER_DATA_URL = "/__realm__user__/"; // ensure its in sync with Realm.js
var TEMPLATE_URL = "/__realm__template__/"; // ensure its in sync with Realm.js

self.addEventListener('fetch', function(event) {
    console.log("fetch", event, realm_hash);
    var url = new URL(event.request.url);
    var url = url.pathname + url.search;

    if (url.indexOf("realm_mode=") !== -1) {
        console.log("sw: is realm request, trying net", url);
        event.respondWith(fetch(event.request));
        return;
    }

    if (url.startsWith("/static/")) {
        return event.respondWith(new Promise(function (resolve) {
            caches.open("realm").then(function (cache) {
                console.log("is static, responding with cache");
                cache.match(event.request).then(function (resp) {
                    if (resp) {
                        resolve(resp);
                    }

                    return fetch(event.request).then(function  (resp) {
                        if(!resp || resp.status !== 200 || resp.type !== 'basic') {
                            resolve(resp);
                        }
                        return cache.put(event.request, resp.clone()).then(function () {
                            resolve(resp)
                        });
                    });
                });
            });
        }));
    }

    event.respondWith(new Promise(function (resolve, _reject) {
        caches.open("realm").then(function (cache) {
            function gotPageData(user_data, template, page_data) {
                var init = {"headers": {"Content-Type":  "text/html"}};
                var msg = "Offline - Network Not Available";
                if (!template) {
                    console.log("sw: template not found");
                    fetch(event.request).then(resolve);
                    return;
                }

                if (!!page_data && !!user_data) {
                    // TODO: instead of hard-coding ".base" make it configurable
                    console.log("sw: attaching user_data");
                    page_data.config.base = user_data;
                }

                if (!page_data && navigator.onLine) {
                    console.log("sw: no page data, but online, using fetch");
                    fetch(event.request).then(resolve);
                    return;
                }

                if (!page_data) {
                    console.log("sw: no page data, creating Page.Offline spec");
                    page_data = {
                        "title": msg,
                        "id": "Pages.Offline",
                        "config": {"message": msg, "title": msg, "base": user_data},
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
                    }
                }

                template = template.replace("__realm_title__", escape(page_data.title));
                template = template.replace(
                    "__realm_data__", escape(JSON.stringify(page_data))
                );

                console.log("sw: response", url);
                resolve(new Response(template, init));
            }

            function gotTemplate(user_data, template) {
                cache.match(url).then(function (r) {
                    if (!r) {
                        console.log("sw: no page data in cache");
                        gotPageData(user_data, template, null);
                        return;
                    }
                    r.json().then(function (t) {
                        console.log("sw: got page data from cache");
                        gotPageData(user_data, template, t)
                    })
                })
            }

            function gotUser(user_data) {
                cache.match(TEMPLATE_URL).then(function (r) {
                    if (!r) {
                        console.log("sw: no template in cache");
                        gotPageData(user_data, null, null);
                        return;
                    }
                    r.text().then(function (t) {
                        console.log("sw: got template from cache");
                        gotTemplate(user_data, t)
                    })
                })
            }

            cache.match(USER_DATA_URL).then(function (r) {
                if (!r) {
                    console.log("sw: no user in cache");
                    gotUser(null);
                    return;
                }
                r.json().then(function (u) {
                    console.log("sw: got user_data from cache");
                    gotUser(u)
                })
            });
        });
    }));
});


function replaceAll(str, find, replace) {
  return str.replace(new RegExp(find, 'g'), replace);
}

function escape(s) {
    s = replaceAll(s, '>', "%u003E");
    s = replaceAll(s, '<', "%u003C");
    return replaceAll(s, '&', "%u0026");
}
