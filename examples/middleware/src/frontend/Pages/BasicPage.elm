module Pages.BasicPage exposing (Config, Model, Msg(..), init, main, subscriptions, update, view, view2)

import Browser
import Html as H exposing (..)
import Html.Attributes as H exposing (..)
import Html.Events exposing (onInput)
import Json.Encode as JE
import Realm


type alias Config =
    { body : Realm.WidgetSpec

    -- ,footer: Realm.WidgetSpec
    -- header: WidgetSpec,
    }


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { config : Config
    }


init : Realm.Flag Config -> ( Model, Cmd Msg )
init flag =
    ( Model flag.config
    , Realm.loadWidget
        (JE.object
            [ ( "uid", JE.string flag.config.body.uid )
            , ( "id", JE.string flag.config.body.id )
            , ( "config", flag.config.body.config )
            ]
        )
    )



-- UPDATE


type Msg
    = String


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
        |> Realm.wrapped "main"


view2 : Model -> List (Html Msg)
view2 model =
    [ Realm.child model.config.body

    -- , Realm.child model.config.footer
    --    , div
    --        [ H.id "child3" ]
    --        [ text (String model)
    --        ]
    ]
