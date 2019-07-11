module Widgets.BWidgets.TextWidget exposing (main)

import Browser
import Html exposing (..)
import Realm
import Task
import Time



-- MAIN


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Config =
    {}


type alias Model =
    { content : String
    , uid : String
    }


init : Realm.Flag Config -> ( Model, Cmd Msg )
init flag =
    ( Model "Hello World!" flag.uid
    , Cmd.none
    )



-- UPDATE


type Msg
    = Tick Time.Posix
    | AdjustTimeZone Time.Zone


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    view2 model
        |> Realm.wrapped model.uid


view2 : Model -> List (Html Msg)
view2 model =
    [ h1 [] [ text model.content ] ]
