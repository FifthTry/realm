port module Realm.Test exposing (Step(..), Test, app)

import Array exposing (Array)
import Browser as B
import Element as E exposing (..)
import Element.Background as Bg
import Element.Border as EB
import Element.Font as EF
import Html as H
import Html.Attributes as HA
import Http
import Json.Decode as JD
import Json.Encode as JE
import Realm as R
import Realm.Ports exposing (fromIframe, toIframe)
import Realm.Utils exposing (edges)


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
    , current : Maybe Int
    , tests : Array ( String, Step, List R.TestResult )
    , title : String
    }


type Msg
    = FromChild JE.Value
    | NoOp
    | ResetDone



-- | GoTo Int


init : Config -> () -> url -> key -> ( Model, Cmd Msg )
init config _ _ _ =
    doStep 0
        False
        { context = JE.object []
        , current = Nothing
        , title = config.title
        , tests = flatten config.tests
        }


doStep : Int -> Bool -> Model -> ( Model, Cmd Msg )
doStep idx postReset m =
    case Array.get idx m.tests of
        Just ( tid, step, _ ) ->
            let
                lastId =
                    m.tests
                        |> Array.get (idx - 1)
                        |> Maybe.map (\( i, _, _ ) -> i)
                        |> Maybe.withDefault "--"

                ( ctx, cmd ) =
                    case step of
                        Navigate elm id url ->
                            navigate elm id url m.context

                        Submit elm id payload ->
                            submit elm id payload m.context

                ( cmd2, ctx2, current ) =
                    -- reset db and context when test changes
                    if tid /= lastId && not postReset then
                        ( Http.post
                            { url = "/test/reset-db/"
                            , expect = Http.expectString (always ResetDone)
                            , body = Http.emptyBody
                            }
                        , JE.object []
                        , m.current
                        )

                    else
                        ( cmd, ctx, Just idx )
            in
            ( { m | context = ctx2, current = current }, cmd2 )

        Nothing ->
            ( { m | current = Nothing }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg m =
    case Debug.log "Test.msg" ( msg, m.current ) of
        ( NoOp, _ ) ->
            ( m, Cmd.none )

        ( FromChild v, Just idx ) ->
            case Debug.log "FromChild" <| JD.decodeValue (JD.list R.testResult) v of
                Ok results ->
                    let
                        m2 =
                            m.tests
                                |> Array.get idx
                                |> Maybe.map
                                    (\( id, step, lst ) ->
                                        ( id, step, lst ++ results )
                                    )
                                |> Maybe.map (\r -> Array.set idx r m.tests)
                                |> Maybe.map (\tests -> { m | tests = tests })
                                |> Maybe.withDefault m
                    in
                    if List.any ((==) R.TestDone) (Debug.log "results" results) then
                        doStep (idx + 1) False m2

                    else
                        ( m2, Cmd.none )

                Err _ ->
                    ( m, Cmd.none )

        ( FromChild _, Nothing ) ->
            -- impossible
            ( m, Cmd.none )

        ( ResetDone, Nothing ) ->
            doStep 0 True m

        ( ResetDone, Just idx ) ->
            doStep (idx + 1) True m


document : Model -> B.Document Msg
document m =
    { title = m.title ++ " Test", body = [ E.layout [] (view m) ] }


view : Model -> E.Element Msg
view m =
    E.row [ E.width E.fill, E.height E.fill ]
        [ E.column
            [ E.height E.fill
            , E.width (E.px 300)
            , EB.widthEach { edges | right = 1 }
            ]
            [ E.paragraph [ E.padding 5 ]
                [ E.text <|
                    m.title
                        ++ " Tests: "
                        ++ Maybe.withDefault "Done" (Maybe.map String.fromInt m.current)
                ]
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


stepTitle : Step -> String
stepTitle s =
    case s of
        Navigate _ id _ ->
            id

        Submit _ id _ ->
            id


resultView : R.TestResult -> E.Element Msg
resultView r =
    if r == R.TestDone then
        E.none

    else
        E.paragraph
            [ E.paddingEach { bottom = 3, left = 15, right = 5, top = 4 }
            , EF.light
            , EF.size 14
            ]
            [ E.text <| "> " ++ Debug.toString r ]


stepView : Model -> Int -> Step -> List R.TestResult -> E.Element Msg
stepView m idx s results =
    E.textColumn [ E.width E.fill ] <|
        (if Just idx == m.current then
            E.paragraph
                [ E.paddingXY 5 3
                , EF.light
                , EF.regular
                , Bg.color <| E.rgb 0.93 0.93 0.93
                ]
                [ E.text <| "- " ++ stepTitle s ]

         else
            E.paragraph [ E.pointer, E.paddingXY 5 3, EF.light ]
                [ E.text <| "- " ++ stepTitle s ]
        )
            :: List.map resultView results


testHead : String -> E.Element Msg
testHead title =
    E.paragraph
        [ E.paddingEach { bottom = 3, left = 5, right = 5, top = 4 }
        , EB.widthEach { edges | top = 1 }
        ]
        [ E.text title ]


singleTest :
    Model
    -> ( Int, ( String, Step, List R.TestResult ) )
    -> ( String, List (E.Element Msg) )
    -> ( String, List (E.Element Msg) )
singleTest m ( idx, ( tid, step, results ) ) ( cur, body ) =
    let
        sv =
            stepView m idx step results
    in
    if cur == tid then
        ( tid, body ++ [ sv ] )

    else
        ( tid, body ++ [ testHead tid, sv ] )


listOfTests : Model -> E.Element Msg
listOfTests m =
    m.tests
        |> Array.toIndexedList
        |> List.foldl (singleTest m) ( "", [] )
        |> Tuple.second
        |> E.column [ E.width E.fill ]


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


flatten : List ( String, List Step ) -> Array ( String, Step, List R.TestResult )
flatten lst =
    lst
        |> List.map (\( s, steps ) -> List.map (\step -> ( s, step, [] )) steps)
        |> List.concat
        |> Array.fromList


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
        [ ( "action", JE.string "submit" )
        , ( "payload", payload )
        , ( "context", ctx )
        , ( "id", JE.string id )
        , ( "elm", JE.string <| "Pages." ++ elm )
        ]
        |> toIframe
    )
