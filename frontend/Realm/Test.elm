port module Realm.Test exposing (Test, app, navigate, submit)

import Browser as B
import Element as E
import Html as H
import Html.Attributes as HA
import Json.Encode as JE
import Realm as R
import Realm.Ports exposing (fromIframe, toIframe)


type alias Test =
    ( String, List Step )


type alias Step =
    Context -> ( Context, Cmd Msg )


type alias TestResult =
    { id : String
    , result : List R.TestResult
    }


type alias Model =
    { tid : Int
    , sid : Int
    , context : Context
    , result : List String
    , config : Config
    }


type Msg
    = FromChild JE.Value
    | NoOp


init : Config -> () -> url -> key -> ( Model, Cmd Msg )
init config _ _ _ =
    let
        ( context, cmd ) =
            navigate (JE.int 1) "Index" "anonymous" "/"
    in
    ( { tid = 0, sid = 0, context = context, result = [], config = config }, cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg m =
    case Debug.log "Test.msg" msg of
        _ ->
            ( m, Cmd.none )


document : Model -> B.Document Msg
document m =
    { title = m.config.title ++ " Test", body = [ E.layout [] (view m) ] }


view : Model -> E.Element Msg
view m =
    E.column [ E.width E.fill, E.height E.fill ]
        [ E.text <| m.config.title ++ " Test"
        , E.text (Debug.toString m)
        , E.el [ E.height E.fill, E.width E.fill ] <|
            E.html
                (H.node "iframe"
                    [ HA.style "width" "100%"

                    -- , HA.style "border" "none"
                    , HA.src "/iframe/"
                    ]
                    []
                )
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    fromIframe FromChild


type alias Config =
    { tests : List Test
    , title : String
    }


app : Config -> Program () Model Msg
app config =
    B.application
        { init = init config
        , view = document
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = always NoOp
        , onUrlChange = always NoOp
        }


type alias Context =
    JE.Value


navigate : Context -> String -> String -> String -> ( Context, Cmd Msg )
navigate ctx elm id url =
    ( ctx
    , JE.object
        [ ( "action", JE.string "navigate" )
        , ( "url", JE.string url )
        , ( "context", ctx )
        , ( "id", JE.string id )
        , ( "elm", JE.string <| "Pages." ++ elm )
        ]
        |> toIframe
    )


submit : Context -> String -> String -> JE.Value -> ( Context, Cmd Msg )
submit ctx elm id payload =
    ( ctx
    , JE.object
        [ ( "action", JE.string "navigate" )
        , ( "payload", payload )
        , ( "context", ctx )
        , ( "id", JE.string id )
        , ( "elm", JE.string <| "Pages." ++ elm )
        ]
        |> toIframe
    )
