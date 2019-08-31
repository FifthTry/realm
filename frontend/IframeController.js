app = null;

if (Elm.Test) {
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

        var iframe = window.frames[0];
        if (!iframe || !iframe.handleCmd) {
            lastCmd = cmd;
        } else {
            iframe.handleCmd(cmd);
        }
    });
}

function iframeLoaded() {
    var iframe = window.frames[0];
    if (!iframe || !lastCmd) {
        return;
    }

    fixIframeDimensions();
    iframe.handleCmd(lastCmd);
}
