port module Realm.Ports exposing (..)

import Json.Encode as JE


port copyToClipboard : String -> Cmd msg


port initializeFtd : JE.Value -> Cmd msg


port renderFtd : JE.Value -> Cmd msg


port setFtdBool : JE.Value -> Cmd msg


port setFtdMultiValue : JE.Value -> Cmd msg


port ftdHandle : (JE.Value -> msg) -> Sub msg


port navigate : String -> Cmd msg


port shutdown : (() -> msg) -> Sub msg


port toIframe : JE.Value -> Cmd msg


port fromIframe : (JE.Value -> msg) -> Sub msg


port changePage : JE.Value -> Cmd msg


port triggerReload : String -> Cmd msg


port triggerClassReload : String -> Cmd msg


port viewPortChanged : (JE.Value -> msg) -> Sub msg


port setSessionStorage : JE.Value -> Cmd msg


port setLocalStorage : JE.Value -> Cmd msg


port deleteSessionStorage : JE.Value -> Cmd msg


port onScroll_ : (() -> msg) -> Sub msg


onScroll : msg -> Sub msg
onScroll =
    always >> onScroll_


port onUnloading : (Bool -> msg) -> Sub msg


port setLoading : () -> Cmd msg


port cancelLoading : () -> Cmd msg


port disableScrolling : () -> Cmd msg


port enableScrolling : () -> Cmd msg


port scrollIntoView : String -> Cmd msg
