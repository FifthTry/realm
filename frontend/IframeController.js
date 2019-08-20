app = null;

if (Elm.Test) {
    app = Elm.Test.init({});
} else {
    app = Elm.Storybook.init({});
}

function fixHeight() {
    function fixHeightNow() {
        var iframe = document.getElementsByTagName("iframe")[0];
        if (!iframe) {
            window.requestAnimationFrame(fixHeightNow);
            return;
        }

        iframe.height = iframe.parentNode.clientHeight;
    }
    fixHeightNow();
}

fixHeight();

window.addEventListener("resize", fixHeight);

if (app.ports && app.ports.toIframe) {
    app.ports.toIframe.subscribe(function(cmd) {
        console.log("cmd", cmd);

        function sendCmdNow() {
            var iframe = window.frames[0];
            if (!iframe || !iframe.handleCmd) {
                window.setTimeout(sendCmdNow, 10);
                return;
            }
            iframe.handleCmd(cmd);

        }

        sendCmdNow();
    });
}
