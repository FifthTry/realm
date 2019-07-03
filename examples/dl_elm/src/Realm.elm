port module Realm exposing (..)
import Json.Encode as JE
import Html as H exposing (..)
import Html.Attributes as H exposing (..)

port loadWidget : JE.Value -> Cmd msg

type alias WidgetSpec = {
    id: String
    , config: JE.Value
    ,uid: String

  }


child : WidgetSpec ->  Html msg
child wspec =
    H.div [ H.id wspec.uid ] []



