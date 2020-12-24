console.log = function() {}

app = null;

if (Elm.RealmTest) {
    app = Elm.RealmTest.init({});
} else if (Elm.Test) {
    app = Elm.Test.init({});
} else {
    app = Elm.Storybook.init({});
}

function fixIframeDimensions() {
    function fixIframeDimensionsNow() {
        var iframe = document.getElementsByTagName("iframe")[0];
        if (!iframe) {
            window.requestAnimationFrame(fixIframeDimensionsNow);
            return;
        }

        iframe.height = iframe.parentNode.clientHeight;
        iframe.width = iframe.parentNode.clientWidth;
        iframe.style.height = iframe.parentNode.clientHeight + "px";
        iframe.style.width = iframe.parentNode.clientWidth + "px";
    }
    fixIframeDimensionsNow();
}

fixIframeDimensions();

window.addEventListener("resize", fixIframeDimensions);

var lastCmd = null;

if (app.ports && app.ports.toIframe) {
    app.ports.toIframe.subscribe(function(cmd) {
        console.log("cmd", cmd);
        // we unconditionally set this because iframe reloads in case outer page URL
        // changes (which we change to keep collection of story id etc in storybook).
        lastCmd = cmd;

        var iframe = window.frames[0];
        if (iframe && iframe.handleCmd) {
            console.log("sending command to iframe");
            iframe.handleCmd(cmd);
        } else {
            console.log("iframe not ready", !!iframe);
        }
    });
}

function iframeLoaded() {
    // this function is called by iframe.js after it is loaded in browser: can the
    // window.iframes[0] still be null? I had added this clause but combined with
    // !lastCmd so not sure if it was really because both can happen, or because i
    // was just being defensive.

    // var iframe = window.frames[0];
    // if (!iframe) {
    //     return;
    // }

    fixIframeDimensions();
    if (lastCmd) {
        // the following intentionally does not do null check as I want this to crash
        // if my assumption is invalid.e
        window.frames[0].handleCmd(lastCmd);
    }
}
