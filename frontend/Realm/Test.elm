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
    , result : List R.TestResult
    }


type Msg
    = FromChild JE.Value
    | NoOp


init : Config -> () -> url -> key -> ( Model, Cmd Msg )
init config _ _ _ =
    { context = JE.object []
    , result =
        [ { id = "index", result = [ R.TestPassed "" ] }
        , { id = "login", result = [ R.TestPassed "" ] }
        , { id = "login", result = [ R.TestPassed "", R.TestPassed "" ] }
        ]
    , config = config
    , testDone = False
    }
        |> getNextStep
        |> (\( p, q ) -> ( p, doStep p.context q ))


getNextStep : Model -> ( Model, Maybe Step )
getNextStep m =
    let
        test_done =
            case List.isEmpty (Debug.log "tests lists" m.config.tests) of
                True ->
                    True

                False ->
                    List.length m.result == List.length list

        list =
            m.config.tests
                |> List.map
                    (\( s, l ) ->
                        List.map (\t -> ( s, t )) l
                    )
                |> List.concat

        previous =
            index (List.length m.result) (Debug.log "testlist" list)
                |> Maybe.withDefault ( "", Navigate "" "" "" )

        current =
            index (List.length m.result + 1) list
                |> Maybe.withDefault ( "", Navigate "" "" "" )

        next =
            index (List.length m.result + 1) list
                |> Maybe.withDefault ( "", Navigate "" "" "" )

        nextstep =
            case next of
                ( "", Navigate "" "" "" ) ->
                    Nothing

                _ ->
                    Just (next |> (\( _, s ) -> s))

        currentresult =
            index (List.length m.result) m.result
                |> Maybe.withDefault (TestResult "" [])

        result =
            if test_done then
                m.result

            else if (Debug.log "Previous" previous |> (\( s, _ ) -> s)) == "" then
                List.append m.result [ TestResult (current |> (\( s, _ ) -> s)) [ R.TestPassed "" ] ]

            else if (previous |> (\( s, _ ) -> s)) == (Debug.log "Current" current |> (\( s, _ ) -> s)) then
                List.append m.result [ TestResult (current |> (\( s, _ ) -> s)) (List.append (Debug.log "currentresult" currentresult).result [ R.TestPassed "" ]) ]

            else
                List.append m.result [ TestResult (current |> (\( s, _ ) -> s)) [ R.TestPassed "" ] ]
    in
    ( { m | testDone = test_done, result = Debug.log "results..." result }, nextstep )


index : Int -> List a -> Maybe a
index i list =
    if List.length list >= i then
        List.take i list
            |> List.reverse
            |> List.head

    else
        Nothing


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
testView ( id, steps ) mr =
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


doStep : Context -> Maybe Step -> Cmd Msg
doStep ctx ms =
    case ms of
        Just s ->
            case s of
                Navigate a b c ->
                    navigate a b c ctx |> (\( _, cm ) -> cm)

                Submit a b c ->
                    submit a b c ctx |> (\( _, cm ) -> cm)

        Nothing ->
            Cmd.none


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
