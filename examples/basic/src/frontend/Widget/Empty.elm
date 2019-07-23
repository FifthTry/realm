module Widget.Empty exposing (..)

import Data.Engine exposing (LayoutRequest, Widget)
import Json.Decode as JD
import Realm exposing (Node)
import Realm.Layout as L


type alias Config =
    {}


type alias Model =
    {}


type Msg
    = Msg


decoder : JD.Decoder Config
decoder =
    JD.succeed {}


init : Config -> ( Model, Cmd Msg, LayoutRequest )
init c =
    ( {}, Cmd.none, Nothing )


update : Msg -> Model -> ( Model, Cmd Msg, LayoutRequest )
update msg model =
    ( model, Cmd.none, Nothing )


subscriptions : Model -> Sub Msg
subscriptions m =
    Sub.none


view : Model -> Node Msg
view model =
    L.dummy


widget : Widget Config Model Msg
widget =
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    , decoder = decoder
    , values = \_ -> []
    }
