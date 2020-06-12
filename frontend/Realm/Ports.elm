port module Realm.Ports exposing (cancelLoading, changePage, copyToClipboard, disableScrolling, enableScrolling, fromIframe, navigate, onScroll, onUnloading, setLoading, shutdown, toIframe, viewPortChanged)

import Json.Encode as JE


port copyToClipboard : String -> Cmd msg


port navigate : String -> Cmd msg


port shutdown : (() -> msg) -> Sub msg


port toIframe : JE.Value -> Cmd msg


port fromIframe : (JE.Value -> msg) -> Sub msg


port changePage : JE.Value -> Cmd msg


port viewPortChanged : (JE.Value -> msg) -> Sub msg


port onScroll_ : (() -> msg) -> Sub msg


onScroll : msg -> Sub msg
onScroll =
    always >> onScroll_


port onUnloading : (Bool -> msg) -> Sub msg


port setLoading : () -> Cmd msg


port cancelLoading : () -> Cmd msg


port disableScrolling : () -> Cmd msg


port enableScrolling : () -> Cmd msg
