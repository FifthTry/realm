port module Realm.Test exposing (Step(..), Test, app)

import Array exposing (Array)
import Browser as B
import Browser.Events as BE
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
import Realm.Utils exposing (edges, yesno)


type alias Test =
    { id : String
    , context : List ( String, JE.Value )
    , steps : List Step
    }


type alias TestWithResults =
    { id : String
    , ctx : List ( String, JE.Value )
    , step : Step
    , results : List R.TestResult
    }


type Step
    = Navigate String String String
    | NavigateS ( String, String ) String (String -> String)
    | Submit String String JE.Value


type alias Config =
    { tests : List Test
    , title : String
    }


type alias Model =
    { context : Context
    , current : Maybe Int
    , tests : Array TestWithResults
    , title : String
    , errorOnly : Bool
    }


type Msg
    = FromChild JE.Value
    | NoOp
    | ResetDone
    | OnKey String



-- | GoTo Int


init : Config -> () -> url -> key -> ( Model, Cmd Msg )
init config _ _ _ =
    doStep 0
        False
        { context = []
        , current = Nothing
        , title = config.title
        , tests = flatten config.tests
        , errorOnly = False
        }


doStep : Int -> Bool -> Model -> ( Model, Cmd Msg )
doStep idx postReset m =
    case Array.get idx m.tests of
        Just tr ->
            let
                lastId =
                    m.tests
                        |> Array.get (idx - 1)
                        |> Maybe.map (\t -> t.id)
                        |> Maybe.withDefault "--"

                cmd =
                    case tr.step of
                        Navigate elm id url ->
                            navigate elm id url m.context

                        NavigateS ( elm, id ) key f ->
                            navigate elm id (resolve key JD.string f (JE.object m.context)) m.context

                        Submit elm id payload ->
                            submit elm id payload m.context

                ( cmd2, ctx2, current ) =
                    -- reset db and context when test changes
                    if tr.id /= lastId && not postReset then
                        ( Http.post
                            { url = "/test/reset-db/"
                            , expect = Http.expectString (always ResetDone)
                            , body = Http.emptyBody
                            }
                        , tr.ctx
                        , m.current
                        )

                    else
                        ( cmd, m.context, Just idx )
            in
            ( { m | context = ctx2, current = current }, cmd2 )

        Nothing ->
            ( { m
                | current = Nothing

                -- if any test is failed, narrow to only failed tests
                , errorOnly =
                    m.tests
                        |> Array.filter (\t -> not (isPass t))
                        |> Array.length
                        |> (\c -> c /= 0)
              }
            , Cmd.none
            )


resolve : String -> JD.Decoder a -> (a -> String) -> JE.Value -> String
resolve key dec f v =
    case JD.decodeValue (JD.field key dec) v of
        Ok a ->
            f a

        Err _ ->
            "TODO: fix this"


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
                                    (\tr ->
                                        { tr | results = tr.results ++ results }
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

        ( OnKey "e", _ ) ->
            ( { m | errorOnly = not m.errorOnly }, Cmd.none )

        ( OnKey _, _ ) ->
            ( m, Cmd.none )


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
                        ++ status m
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


isPass : TestWithResults -> Bool
isPass t =
    t.results
        |> List.filter (\r -> not (R.isPass r))
        |> List.length
        |> (\c -> c == 0)


status : Model -> String
status m =
    let
        total =
            String.fromInt (Array.length m.tests)
    in
    case m.current of
        Just i ->
            String.fromInt i ++ " of " ++ total

        Nothing ->
            m.tests
                |> Array.filter (\r -> not (isPass r))
                |> Array.length
                |> (\c ->
                        if c /= 0 then
                            "Failed " ++ String.fromInt c ++ " of " ++ total

                        else
                            "Passed " ++ total
                   )


stepTitle : Step -> String
stepTitle s =
    case s of
        Navigate p id _ ->
            p ++ ":" ++ id

        NavigateS ( p, id ) _ _ ->
            p ++ ":" ++ id

        Submit p id _ ->
            p ++ ":" ++ id


resultView : Model -> R.TestResult -> E.Element Msg
resultView m r =
    if r == R.TestDone then
        E.none

    else
        E.paragraph
            [ E.paddingEach { bottom = 3, left = 15, right = 5, top = 4 }
            , EF.light
            , EF.size 14
            , EF.color (yesno (R.isPass r) (E.rgb 0 0 0) (E.rgb 0.93 0 0))
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
            :: List.map (resultView m) results


testHead : String -> E.Element Msg
testHead title =
    E.paragraph
        [ E.paddingEach { bottom = 3, left = 5, right = 5, top = 4 }
        , EB.widthEach { edges | top = 1 }
        ]
        [ E.text title ]


singleTest :
    Model
    -> ( Int, TestWithResults )
    -> ( String, List (E.Element Msg) )
    -> ( String, List (E.Element Msg) )
singleTest m ( idx, test ) ( cur, body ) =
    let
        sv =
            stepView m idx test.step test.results
    in
    if cur == test.id then
        ( test.id, body ++ [ sv ] )

    else
        ( test.id, body ++ [ testHead test.id, sv ] )


listOfTests : Model -> E.Element Msg
listOfTests m =
    filterErrorOnly m
        |> Array.toIndexedList
        |> List.foldl (singleTest m) ( "", [] )
        |> Tuple.second
        |> E.column [ E.width E.fill ]


filterErrorOnly : Model -> Array TestWithResults
filterErrorOnly { errorOnly, tests } =
    if errorOnly then
        tests
            |> Array.filter (\t -> not (isPass t))

    else
        tests


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ fromIframe FromChild
        , BE.onKeyDown (JD.map OnKey (JD.field "key" JD.string))
        ]


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
    List ( String, JE.Value )


flatten :
    List Test
    -> Array TestWithResults
flatten lst =
    lst
        |> List.map
            (\t ->
                List.map
                    (\step -> { id = t.id, ctx = t.context, step = step, results = [] })
                    t.steps
            )
        |> List.concat
        |> Array.fromList


navigate : String -> String -> String -> Context -> Cmd Msg
navigate elm id url ctx =
    JE.object
        [ ( "action", JE.string "navigate" )
        , ( "url", JE.string url )
        , ( "context", JE.object ctx )
        , ( "id", JE.string id )
        , ( "elm", JE.string <| "Pages." ++ elm )
        ]
        |> toIframe


submit : String -> String -> JE.Value -> Context -> Cmd Msg
submit elm id payload ctx =
    JE.object
        [ ( "action", JE.string "submit" )
        , ( "payload", payload )
        , ( "context", JE.object ctx )
        , ( "id", JE.string id )
        , ( "elm", JE.string <| "Pages." ++ elm )
        ]
        |> toIframe
