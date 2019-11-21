module Realm.Test exposing (FormErrorAssertion(..), Step(..), Test, app, only)

import Array exposing (Array)
import Browser as B
import Browser.Events as BE
import Dict exposing (Dict)
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
import Realm.Requests as RR
import Realm.Utils exposing (edges, yesno)
import RemoteData as RD


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
    | SubmitS ( String, String ) String (String -> JE.Value)
    | SubmitForm String String ( String, JE.Value )
    | FormError String (List FormErrorAssertion) ( String, JE.Value )
    | FormErrorS ( String, String ) (List FormErrorAssertion) (String -> ( String, JE.Value ))


type FormErrorAssertion
    = ErrorPresent String
    | ExactError String String
    | ErrorAbsent String
    | TotalErrors Int


only : String -> String -> List FormErrorAssertion
only key val =
    [ ExactError key val, TotalErrors 1 ]


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
    | OnSubmitResponse FormThing (RR.ApiData RR.LayoutResponse)


type FormThing
    = FormErrorTest String (List FormErrorAssertion)
    | SubmitTest String String



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


submit2 : FormThing -> ( String, JE.Value ) -> Cmd Msg
submit2 thing ( url, data ) =
    let
        url2 =
            if String.contains "?" url then
                url ++ "&realm_mode=submit"

            else
                url ++ "?realm_mode=submit"
    in
    Http.post
        { url = url2
        , body = Http.jsonBody data
        , expect =
            Http.expectJson (RR.try >> OnSubmitResponse thing)
                (RR.bresult RR.layoutResponse)
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
                            navigate elm
                                id
                                (resolve key JD.string f (JE.object m.context))
                                m.context

                        Submit elm id payload ->
                            submit elm id payload m.context

                        SubmitForm elm id ( url, data ) ->
                            submit2 (SubmitTest elm id) ( url, data )

                        SubmitS ( elm, id ) key f ->
                            submit elm
                                id
                                (resolveA key JD.string f (JE.object m.context))
                                m.context

                        FormError id assertions ( url, data ) ->
                            submit2 (FormErrorTest id assertions) ( url, data )

                        FormErrorS ( id, key ) assertions f ->
                            submit2 (FormErrorTest id assertions)
                                (resolveA2 key JD.string f (JE.object m.context))

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


resolveA : String -> JD.Decoder a -> (a -> JE.Value) -> JE.Value -> JE.Value
resolveA key dec f v =
    case JD.decodeValue (JD.field key dec) v of
        Ok a ->
            f a

        Err _ ->
            -- "TODO: fix this"
            JE.null


resolveA2 :
    String
    -> JD.Decoder a
    -> (a -> ( String, JE.Value ))
    -> JE.Value
    -> ( String, JE.Value )
resolveA2 key dec f v =
    case JD.decodeValue (JD.field key dec) v of
        Ok a ->
            f a

        Err _ ->
            -- "TODO: fix this"
            ( "", JE.null )


insertResults : List R.TestResult -> Int -> Model -> Model
insertResults results idx m =
    m.tests
        |> Array.get idx
        |> Maybe.map
            (\tr ->
                { tr | results = tr.results ++ results }
            )
        |> Maybe.map (\r -> Array.set idx r m.tests)
        |> Maybe.map (\tests -> { m | tests = tests })
        |> Maybe.withDefault m


checkAssertions : List FormErrorAssertion -> Dict String String -> List R.TestResult
checkAssertions assertions d =
    let
        checkAssertion : FormErrorAssertion -> R.TestResult
        checkAssertion assertion =
            case assertion of
                ErrorPresent key ->
                    case Dict.get key d of
                        Just val ->
                            R.TestPassed ("ErrorPresent: " ++ key ++ "=" ++ val)

                        Nothing ->
                            R.TestFailed "ErrorPresent" <|
                                "Expected error in "
                                    ++ key
                                    ++ ", found nothing."

                ExactError key val ->
                    case Dict.get key d of
                        Just got ->
                            if got == val then
                                R.TestPassed ("ExactError: " ++ key)

                            else
                                R.TestFailed "ExactError" <|
                                    "Expected "
                                        ++ key
                                        ++ " error to be "
                                        ++ val
                                        ++ ", found:"
                                        ++ val
                                        ++ "."

                        Nothing ->
                            R.TestFailed "ExactError" <|
                                "Expected error in "
                                    ++ key
                                    ++ ", found nothing."

                ErrorAbsent key ->
                    case Dict.get key d of
                        Nothing ->
                            R.TestPassed ("ErrorAbsent: " ++ key)

                        Just _ ->
                            R.TestFailed "ErrorAbsent" <|
                                "Expected error in "
                                    ++ key
                                    ++ ", found nothing."

                TotalErrors t ->
                    let
                        size =
                            Dict.size d
                    in
                    if size == t then
                        R.TestPassed <|
                            "TotalErrors: found "
                                ++ String.fromInt t
                                ++ " error"
                                ++ (if t == 1 then
                                        ""

                                    else
                                        "s"
                                   )
                                ++ " as expected."

                    else
                        R.TestFailed "TotalErrors" <|
                            "Expected "
                                ++ String.fromInt t
                                ++ " errors, found "
                                ++ String.fromInt size
                                ++ ". Errors: "
                                ++ Debug.toString d
    in
    List.map checkAssertion assertions ++ [ R.TestDone ]


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
                            insertResults results idx m

                        f =
                            \r mod ->
                                case r of
                                    R.UpdateContext lst ->
                                        { mod | context = m.context ++ lst }

                                    _ ->
                                        mod

                        m3 =
                            results
                                |> List.foldl f m2
                    in
                    if List.any ((==) R.TestDone) (Debug.log "results" results) then
                        doStep (idx + 1) False m3

                    else
                        ( m3, Cmd.none )

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

        ( OnSubmitResponse (FormErrorTest _ assertions) (RD.Success (RR.FErrors d)), Just idx ) ->
            let
                results =
                    checkAssertions assertions d
            in
            doStep (idx + 1) False (insertResults results idx m)

        ( OnSubmitResponse (FormErrorTest id _) (RD.Success (RR.Navigate _)), Just idx ) ->
            doStep (idx + 1)
                False
                (insertResults
                    [ R.TestFailed id "Expected errors, found Navigation", R.TestDone ]
                    idx
                    m
                )

        ( OnSubmitResponse (FormErrorTest id _) (RD.Failure e), Just idx ) ->
            -- test failed
            doStep (idx + 1)
                False
                (insertResults
                    [ R.TestFailed id ("Request failed: " ++ Debug.toString e)
                    , R.TestDone
                    ]
                    idx
                    m
                )

        ( OnSubmitResponse (SubmitTest id _) (RD.Success (RR.FErrors d)), Just idx ) ->
            doStep (idx + 1)
                False
                (insertResults
                    [ R.TestFailed id
                        ("Expected Navigation, found FormErrors: " ++ Debug.toString d)
                    , R.TestDone
                    ]
                    idx
                    m
                )

        ( OnSubmitResponse (SubmitTest elm id) (RD.Success (RR.Navigate payload)), Just _ ) ->
            ( m, submit elm id payload m.context )

        ( OnSubmitResponse (SubmitTest id _) (RD.Failure e), Just idx ) ->
            -- test failed
            doStep (idx + 1)
                False
                (insertResults
                    [ R.TestFailed id ("Request failed: " ++ Debug.toString e)
                    , R.TestDone
                    ]
                    idx
                    m
                )

        ( OnSubmitResponse _ _, _ ) ->
            -- shouldn't happen
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

        SubmitForm p id _ ->
            p ++ ":" ++ id

        SubmitS ( p, id ) _ _ ->
            p ++ ":" ++ id

        FormError id _ _ ->
            "FormError:" ++ id

        FormErrorS ( id, _ ) _ _ ->
            "FormError:" ++ id


resultView : Model -> R.TestResult -> E.Element Msg
resultView _ r =
    let
        p =
            \t ->
                E.paragraph
                    [ E.paddingEach { bottom = 3, left = 15, right = 5, top = 4 }
                    , EF.light
                    , EF.size 14
                    , EF.color (yesno (R.isPass r) (E.rgb 0 0 0) (E.rgb 0.93 0 0))
                    ]
                    [ E.text <| "> " ++ t ]
    in
    case r of
        R.TestDone ->
            E.none

        R.UpdateContext lst ->
            ("UpdateContext: " ++ String.join "," (List.map Tuple.first lst))
                |> p

        _ ->
            r
                |> Debug.toString
                |> p


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
