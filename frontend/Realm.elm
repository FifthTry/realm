module Realm exposing (App, In, Out(..), TestFlags, TestResult(..), app, controller, document, getHash, init0, pushHash, result, sub0, test, test0, testResult, third, update0, updateHash)

import Browser as B
import Browser.Navigation as BN
import Dict exposing (Dict)
import Element as E
import Html as H
import Json.Decode as JD
import Json.Encode as JE
import Platform
import Realm.Ports exposing (shutdown, toIframe)
import Url exposing (Url)


type alias Model model =
    { model : Result PortError model
    , key : BN.Key
    , url : Url
    , shuttingDown : Bool
    , title : String
    , dict : Dict String String
    , clearedHash : Bool
    }


type Msg msg
    = UrlRequest B.UrlRequest
    | Msg msg
    | UrlChange Url
    | Shutdown ()


type alias In =
    { title : String
    , hash : Dict String String
    }


type Out
    = UpdateHashKV String String


type alias App config model msg =
    { config : JD.Decoder config
    , init : In -> config -> ( model, Cmd msg, List Out )
    , update : In -> msg -> model -> ( model, Cmd msg, List Out )
    , subscriptions : In -> model -> Sub msg
    , document : In -> model -> B.Document msg
    }


type alias Flags =
    { config : JE.Value
    , title : String
    }


app : App config model msg -> Program Flags (Model model) (Msg msg)
app a =
    B.application
        { init = appInit a
        , view = appDocument a
        , update = appUpdate a
        , subscriptions = appSubscriptions a
        , onUrlRequest = UrlRequest
        , onUrlChange = UrlChange
        }


appInit :
    App config model msg
    -> Flags
    -> Url
    -> BN.Key
    -> ( Model model, Cmd (Msg msg) )
appInit a flags url key =
    let
        hash =
            fromHash url

        ( im, cmd, out ) =
            case JD.decodeValue a.config flags.config of
                Ok config ->
                    a.init { title = flags.title, hash = hash } config
                        |> map1st Ok
                        |> map2nd (Cmd.map Msg)

                Err e ->
                    ( Err { value = flags.config, jd = e }, Cmd.none, [] )

        ( m, cmd2 ) =
            handleOut out <|
                Debug.log "init"
                    { url = url
                    , key = key
                    , model = im
                    , shuttingDown = False
                    , title = flags.title
                    , dict = hash
                    , clearedHash = False
                    }
    in
    ( m, Cmd.batch [ cmd, cmd2 ] )


appUpdate :
    App config model msg
    -> Msg msg
    -> Model model
    -> ( Model model, Cmd (Msg msg) )
appUpdate a msg am =
    case Debug.log "Realm.update" msg of
        Msg imsg ->
            case am.model of
                Err _ ->
                    ( am, Cmd.none )

                Ok model ->
                    let
                        ( m, cmd, out ) =
                            a.update { title = am.title, hash = am.dict } imsg model
                                |> map1st (\m_ -> { am | model = Ok m_ })
                                |> map2nd (Cmd.map Msg)

                        ( m2, cmd2 ) =
                            handleOut out m
                    in
                    ( m2, Cmd.batch [ cmd, cmd2 ] )

        UrlRequest (B.Internal url) ->
            ( am, BN.pushUrl am.key (Url.toString url) )

        UrlRequest (B.External url) ->
            ( am, BN.load url )

        UrlChange _ ->
            ( am, Cmd.none )

        Shutdown _ ->
            ( { am | shuttingDown = True }, Cmd.none )


appSubscriptions : App config model msg -> Model model -> Sub (Msg msg)
appSubscriptions a am =
    case ( am.model, am.shuttingDown ) of
        ( Ok model, False ) ->
            Sub.batch
                [ shutdown Shutdown
                , a.subscriptions { title = am.title, hash = am.dict } model
                    |> Sub.map Msg
                ]

        _ ->
            Sub.none


appDocument : App config model msg -> Model model -> B.Document (Msg msg)
appDocument a am =
    case ( am.model, am.shuttingDown ) of
        ( Err e, False ) ->
            { title = "failed to parse", body = [ H.text (Debug.toString e) ] }

        ( Ok model, False ) ->
            let
                d =
                    a.document { title = am.title, hash = am.dict } model
            in
            { title = d.title, body = List.map (H.map Msg) d.body }

        ( _, True ) ->
            { title = "shuttingDown", body = [] }


handleOut : List Out -> Model model -> ( Model model, Cmd (Msg msg) )
handleOut lst m =
    List.foldl
        (\o ( im, ic ) ->
            case o of
                UpdateHashKV k "" ->
                    ( { im
                        | dict =
                            Dict.remove
                                (Url.percentEncode k)
                                im.dict
                      }
                    , Cmd.batch [ ic, Cmd.none ]
                    )

                UpdateHashKV k v ->
                    ( { im
                        | dict =
                            Dict.insert
                                (Url.percentEncode k)
                                (Url.percentEncode v)
                                im.dict
                      }
                    , Cmd.batch [ ic, Cmd.none ]
                    )
        )
        ( m, Cmd.none )
        lst
        |> updateHash


updateHash : ( Model model, Cmd (Msg msg) ) -> ( Model model, Cmd (Msg msg) )
updateHash ( m, c ) =
    ( m
    , Cmd.batch
        [ c
        , BN.replaceUrl m.key <|
            Url.toString <|
                if Dict.isEmpty m.dict then
                    let
                        url =
                            m.url
                    in
                    { url | fragment = Nothing }

                else
                    let
                        url =
                            m.url

                        hash =
                            m.dict
                                |> Dict.toList
                                |> List.foldl
                                    (\( k, v ) s ->
                                        s
                                            ++ (if String.isEmpty s then
                                                    ""

                                                else
                                                    "&"
                                               )
                                            ++ (k ++ "=" ++ v)
                                    )
                                    ""
                    in
                    { url | fragment = Just hash }
        ]
    )


map1st : (a -> a1) -> ( a, b, c ) -> ( a1, b, c )
map1st f ( a, b, c ) =
    ( f a, b, c )


map2nd : (b -> b1) -> ( a, b, c ) -> ( a, b1, c )
map2nd f ( a, b, c ) =
    ( a, f b, c )


third : c -> ( a, b ) -> ( a, b, c )
third c ( a, b ) =
    ( a, b, c )


init0 : In -> config -> ( config, Cmd msg, List Out )
init0 _ c =
    ( c, Cmd.none, [] )


sub0 : In -> model -> Sub msg
sub0 _ _ =
    Sub.none


update0 : In -> msg -> model -> ( model, Cmd msg, List Out )
update0 _ _ model =
    ( model, Cmd.none, [] )


document : In -> E.Element msg -> B.Document msg
document in_ el =
    { title = in_.title, body = [ E.layout [] el ] }


type alias PortError =
    { value : JE.Value
    , jd : JD.Error
    }


fromHash : Url -> Dict String String
fromHash u =
    u.fragment
        |> Maybe.withDefault ""
        |> String.split "&"
        |> List.map
            (\p ->
                let
                    parts =
                        String.split "=" p
                in
                ( Maybe.withDefault "" <| List.head parts
                , Maybe.withDefault "" (List.head (List.drop 1 parts))
                )
            )
        |> List.filter (\( k, _ ) -> k /= "")
        |> Dict.fromList


getHash : String -> In -> String
getHash k in_ =
    in_.hash
        |> Dict.get k
        |> Maybe.andThen Url.percentDecode
        |> Maybe.withDefault ""


pushHash : String -> String -> List Out
pushHash k v =
    [ UpdateHashKV k v ]


type alias TestFlags config =
    { id : String
    , config : config
    , title : String
    , context : JE.Value
    }


testFlags : JD.Decoder config -> JD.Decoder (TestFlags config)
testFlags config =
    JD.map4 TestFlags
        (JD.field "id" JD.string)
        (JD.field "config" config)
        (JD.field "title" JD.string)
        (JD.field "context" JD.value)


type alias TModel model =
    { title : String
    , model : Maybe model
    , shuttingDown : Bool
    }


type TMsg msg
    = TMsg msg
    | TUrlRequest B.UrlRequest
    | TUrlChange Url
    | TShutdown ()


testInit :
    TestApp config model msg
    -> JE.Value
    -> Url
    -> BN.Key
    -> ( TModel model, Cmd (TMsg msg) )
testInit t flags _ _ =
    case JD.decodeValue (testFlags t.config) flags of
        Ok tflags ->
            t.init { title = tflags.title, hash = Dict.empty } tflags
                |> Tuple.mapFirst
                    (\m ->
                        { title = tflags.title, model = Just m, shuttingDown = False }
                    )
                |> Tuple.mapSecond (Cmd.map TMsg)

        Err e ->
            ( { model = Nothing, title = Debug.toString e, shuttingDown = False }
            , result Cmd.none [ BadConfig <| JD.errorToString e ]
            )


testUpdate :
    TestApp config model msg
    -> TMsg msg
    -> TModel model
    -> ( TModel model, Cmd (TMsg msg) )
testUpdate t msg m =
    case ( m.model, msg ) of
        ( Just model, TMsg imsg ) ->
            t.update { title = m.title, hash = Dict.empty } imsg model
                |> Tuple.mapFirst (\m2 -> { m | model = Just m2 })
                |> Tuple.mapSecond (Cmd.map TMsg)

        ( _, TShutdown () ) ->
            ( { m | shuttingDown = True }, Cmd.none )

        _ ->
            ( m, Cmd.none )


testDocument :
    TestApp config model msg
    -> TModel model
    -> B.Document (TMsg msg)
testDocument t m =
    case ( m.shuttingDown, m.model ) of
        ( False, Just model ) ->
            let
                d =
                    t.document { title = m.title, hash = Dict.empty } model
            in
            { title = d.title, body = List.map (H.map TMsg) d.body }

        _ ->
            { title = m.title, body = [ H.text m.title ] }


testSubscriptions :
    TestApp config model msg
    -> TModel model
    -> Sub (TMsg msg)
testSubscriptions t m =
    case ( m.shuttingDown, m.model ) of
        ( False, Just model ) ->
            t.subscriptions { title = m.title, hash = Dict.empty } model
                |> Sub.map TMsg

        _ ->
            Sub.none


test : TestApp config model msg -> Program JE.Value (TModel model) (TMsg msg)
test t =
    B.application
        { init = testInit t
        , view = testDocument t
        , update = testUpdate t
        , subscriptions = testSubscriptions t
        , onUrlRequest = TUrlRequest
        , onUrlChange = TUrlChange
        }


type alias TestApp config model msg =
    { config : JD.Decoder config
    , init : In -> TestFlags config -> ( model, Cmd msg )
    , update : In -> msg -> model -> ( model, Cmd msg )
    , subscriptions : In -> model -> Sub msg
    , document : In -> model -> B.Document msg
    }


type TestResult
    = TestFailed String String
    | TestPassed String
    | BadConfig String
    | Screenshot String
    | BadElm String
    | TestDone


testResult : JD.Decoder TestResult
testResult =
    JD.field "kind" JD.string
        |> JD.andThen
            (\kind ->
                case kind of
                    "TestFailed" ->
                        JD.map2 TestFailed
                            (JD.field "id" JD.string)
                            (JD.field "message" JD.string)

                    "TestPassed" ->
                        JD.field "id" JD.string
                            |> JD.andThen (\m -> JD.succeed (TestPassed m))

                    "BadConfig" ->
                        JD.field "message" JD.string
                            |> JD.andThen (\m -> JD.succeed (BadConfig m))

                    "Screenshot" ->
                        JD.field "id" JD.string
                            |> JD.andThen (\m -> JD.succeed (Screenshot m))

                    "BadElm" ->
                        JD.field "message" JD.string
                            |> JD.andThen (\m -> JD.succeed (BadElm m))

                    "TestDone" ->
                        JD.succeed TestDone

                    _ ->
                        JD.fail <| "unknown kind: " ++ kind
            )


test0 :
    App config model msg
    -> (In -> TestFlags config -> ( model, Cmd msg ))
    -> Program JE.Value (TModel model) (TMsg msg)
test0 a init =
    test
        { config = a.config
        , init = init
        , update = \i msg m -> a.update i msg m |> (\( m2, c, _ ) -> ( m2, c ))
        , subscriptions = a.subscriptions
        , document = a.document
        }


controller : TestResult -> JE.Value
controller c =
    (case c of
        TestFailed id message ->
            [ ( "kind", JE.string "TestFailed" )
            , ( "id", JE.string id )
            , ( "message", JE.string message )
            ]

        Screenshot id ->
            [ ( "kind", JE.string "Screenshot" ), ( "id", JE.string id ) ]

        TestDone ->
            [ ( "kind", JE.string "TestDone" ) ]

        BadConfig msg ->
            [ ( "kind", JE.string "BadConfig" ), ( "message", JE.string msg ) ]

        BadElm msg ->
            [ ( "kind", JE.string "BadElm" ), ( "message", JE.string msg ) ]

        TestPassed id ->
            [ ( "kind", JE.string "TestPassed" ), ( "id", JE.string id ) ]

    )
        |> JE.object


result : Cmd msg -> List TestResult -> Cmd msg
result c list =
    Cmd.batch [ c, JE.list controller list |> toIframe ]
