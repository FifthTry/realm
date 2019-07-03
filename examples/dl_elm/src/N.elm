module N exposing (main)

import Browser
import Html exposing (..)
import Json.Encode as JE
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
    { zone : Time.Zone
    , time : Time.Posix
    , uid : String
    }


init : Realm.Flag Config -> ( Model, Cmd Msg )
init flag =
    ( Model Time.utc (Time.millisToPosix 0) flag.uid
      -- , Task.perform AdjustTimeZone Time.here
    , Realm.loadWidget
        (JE.object
            [ ( "uid", JE.string "uu" )
            , ( "id", JE.string "ii" )
            , ( "config", JE.null )
            ]
        )
    )



-- UPDATE


type Msg
    = Tick Time.Posix
    | AdjustTimeZone Time.Zone


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            ( { model | time = newTime }
            , Cmd.none
            )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every 1000 Tick



-- VIEW


view : Model -> Html Msg
view model =
    view2 model
        |> Realm.wrapped model.uid


view2 : Model -> List (Html Msg)
view2 model =
    let
        hour =
            String.fromInt (Time.toHour model.zone model.time)

        minute =
            String.fromInt (Time.toMinute model.zone model.time)

        second =
            String.fromInt (Time.toSecond model.zone model.time)
    in
    [ h1 [] [ text (hour ++ ":" ++ minute ++ ":" ++ second) ] ]
