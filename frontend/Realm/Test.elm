port module Realm.Test exposing (Step(..), Test, app)

import Browser as B
import Element as E
import Element.Border as EB
import Html as H
import Html.Attributes as HA
import Json.Decode as JD
import Json.Encode as JE
import Realm as R
import Realm.Ports exposing (fromIframe, toIframe)
import Realm.Utils as U


type alias Test =
    ( String, List Step )


type Step
    = Navigate String String String
    | Submit String String JE.Value


type alias Config =
    { tests : List Test
    , title : String
    }


type alias Model =
    { context : Context
    , result : List TestResult
    , config : Config
    , testDone : Bool
    }


type alias TestResult =
    { id : String
    , result : List (List R.TestResult)
    }


type Msg
    = FromChild JE.Value
    | NoOp


init : Config -> () -> url -> key -> ( Model, Cmd Msg )
init config _ _ _ =
    { context = JE.object [], result = [], config = config, testDone = False }
        |> getNextStep


getNextStep : Model -> ( Model, Cmd Msg )
getNextStep m =
    ( m, navigate "Index" "anonymous" "/" (JE.object []) |> Tuple.second )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg m =
    case Debug.log "Test.msg" msg of
        NoOp ->
            ( m, Cmd.none )

        FromChild v ->
            let
                _ =
                    Debug.log "FromChild" <|
                        Debug.toString (JD.decodeValue (JD.list R.testResult) v)
            in
            ( m, Cmd.none )


document : Model -> B.Document Msg
document m =
    { title = m.config.title ++ " Test", body = [ E.layout [] (view m) ] }


view : Model -> E.Element Msg
view m =
    E.row [ E.width E.fill, E.height E.fill ]
        [ E.column
            [ E.height E.fill
            , E.width (E.px 200)
            , EB.widthEach { bottom = 0, left = 0, right = 1, top = 0 }
            ]
            [ E.paragraph
                [ E.padding 5
                , EB.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
                ]
              <|
                [ E.text <| m.config.title ++ " Tests" ]
            , listOfTests m
            ]
        , E.el [ E.height E.fill, E.width E.fill ] <|
            E.html
                (H.node "iframe"
                    [ HA.style "width" "100%"
                    , HA.style "border" "none"
                    , HA.src "/iframe/"
                    ]
                    []
                )
        ]


testView : Test -> Maybe TestResult -> E.Element Msg
testView (id, steps) mr =
    E.text id


listOfTests : Model -> E.Element Msg
listOfTests m =
    U.zip testView m.config.tests m.result
        |> E.column []


subscriptions : Model -> Sub Msg
subscriptions _ =
    fromIframe FromChild


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


navigate : String -> String -> String -> Context -> ( Context, Cmd Msg )
navigate elm id url ctx =
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


submit : String -> String -> JE.Value -> Context -> ( Context, Cmd Msg )
submit elm id payload ctx =
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
