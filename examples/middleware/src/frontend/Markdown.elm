module Markdown exposing (main)

import Browser
import Css exposing (..)
import Debug
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Parser
import Html.Parser.Util
import Realm



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
    { body : String
    }


type alias Model =
    { config : Config
    , uid : String
    }


type Msg
    = NoOp



{-
   init : Realm.Flag Config -> ( Model, Cmd Msg )
   init flag =
       ( Model "Hello World!" flag.uid
       , Cmd.none
       )
-}


init : Realm.Flag Config -> ( Model, Cmd Msg )
init c =
    ( { config = c.config, uid = c.uid }, Cmd.none )


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
    case Html.Parser.run model.config.body of
        Ok lst ->
            [ div
                [ style "color" "green"
                , style "background-color" "red"
                , style "height" "90px"
                , style "width" "100%"
                ]
                (Html.Parser.Util.toVirtualDom lst)
            ]

        Err err ->
            [ Html.text <| "things failed: " ++ Debug.toString err ]
