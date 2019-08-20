port module Realm.Ports exposing (fromIframe, navigate, shutdown, submit, toController, toIframe)

import Json.Encode as JE


port submit : JE.Value -> Cmd msg


port navigate : String -> Cmd msg


port shutdown : (() -> msg) -> Sub msg


port toIframe : JE.Value -> Cmd msg


port fromIframe : (JE.Value -> msg) -> Sub msg


port toController : JE.Value -> Cmd msg
