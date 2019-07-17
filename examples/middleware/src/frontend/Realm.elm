port module Realm exposing (Flag, WidgetSpec, child, loadWidget, wrapped)

import Html as H exposing (..)
import Html.Attributes as H exposing (..)
import Json.Encode as JE


port loadWidget : JE.Value -> Cmd msg


type alias WidgetSpec =
    { id : String
    , config : JE.Value
    , uid : String
    }


type alias Flag config =
    { uid : String
    , config : config
    }


child : WidgetSpec -> Html msg
child spec =
    H.div [ H.id spec.uid ] []


wrapped : String -> List (Html msg) -> Html msg
wrapped uid html =
    H.div [ H.id uid ] html
