module Realm exposing (App, In, Msg(..), TestFlags, TestResult(..), app, controller, document, getHash, init0, pushHash, result, sub0, test, test0, testResult, update0)

import Browser as B
import Browser.Events as BE
import Browser.Navigation as BN
import Dict exposing (Dict)
import Element as E
import Html as H
import Json.Decode as JD
import Json.Encode as JE
import Platform
import Realm.Ports exposing (shutdown, toIframe)
import Task
import Url exposing (Url)


type alias Model model =
    { model : Result PortError model
    , key : BN.Key
    , url : Url
    , shuttingDown : Bool
    , title : String
    , dict : Dict String String
    , clearedHash : Bool
    , device : E.Device
    , height : Int
    , width : Int
    }


type Msg msg
    = UrlRequest B.UrlRequest
    | Msg msg
    | UrlChange Url
    | Shutdown ()
    | UpdateHashKV String String
    | OnResize Int Int


type alias In =
    { title : String
    , hash : Dict String String
    , device : E.Device
    , height : Int
    , width : Int
    }


type alias App config model msg =
    { config : JD.Decoder config
    , init : In -> config -> ( model, Cmd (Msg msg) )
    , update : In -> msg -> model -> ( model, Cmd (Msg msg) )
    , subscriptions : In -> model -> Sub (Msg msg)
    , document : In -> model -> B.Document (Msg msg)
    }


type alias Flags =
    { config : JE.Value
    , title : String
    , width : Int
    , height : Int
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

        ( im, cmd, ( device, height, width ) ) =
            case JD.decodeValue a.config flags.config of
                Ok config ->
                    let
                        d =
                            E.classifyDevice flags
                    in
                    a.init
                        { title = flags.title
                        , hash = hash
                        , device = d
                        , height = flags.height
                        , width = flags.width
                        }
                        config
                        |> Tuple.mapFirst Ok
                        |> (\( f, s ) -> ( f, s, ( d, flags.height, flags.width ) ))

                Err e ->
                    ( Err { value = flags.config, jd = e }
                    , Cmd.none
                    , ( { class = E.Desktop, orientation = E.Landscape }
                      , 1024
                      , 1024
                      )
                    )
    in
    ( { url = url
      , key = key
      , model = im
      , shuttingDown = False
      , title = flags.title
      , dict = hash
      , clearedHash = False
      , device = device
      , height = height
      , width = width
      }
    , cmd
    )


appUpdate :
    App config model msg
    -> Msg msg
    -> Model model
    -> ( Model model, Cmd (Msg msg) )
appUpdate a msg am =
    case Debug.log "Realm.update" ( msg, am.shuttingDown ) of
        ( Msg imsg, False ) ->
            case am.model of
                Err _ ->
                    ( am, Cmd.none )

                Ok model ->
                    a.update
                        { title = am.title
                        , hash = am.dict
                        , device = am.device
                        , height = am.height
                        , width = am.width
                        }
                        imsg
                        model
                        |> Tuple.mapFirst (\m_ -> { am | model = Ok m_ })

        ( UrlRequest (B.Internal url), False ) ->
            ( am, BN.pushUrl am.key (Url.toString url) )

        ( UrlRequest (B.External url), False ) ->
            ( am, BN.load url )

        ( UrlChange _, False ) ->
            ( am, Cmd.none )

        ( UpdateHashKV k "", False ) ->
            let
                m =
                    { am
                        | dict =
                            Dict.remove
                                (Url.percentEncode k)
                                am.dict
                    }
            in
            ( m, updateHash m )

        ( UpdateHashKV k v, False ) ->
            let
                m =
                    { am
                        | dict =
                            Dict.insert
                                (Url.percentEncode k)
                                (Url.percentEncode v)
                                am.dict
                    }
            in
            ( m, updateHash m )

        ( Shutdown _, False ) ->
            ( { am | shuttingDown = True }, Cmd.none )

        _ ->
            ( am, Cmd.none )


appSubscriptions : App config model msg -> Model model -> Sub (Msg msg)
appSubscriptions a am =
    case ( am.model, am.shuttingDown ) of
        ( Ok model, False ) ->
            Sub.batch
                [ shutdown Shutdown
                , a.subscriptions
                    { title = am.title
                    , hash = am.dict
                    , device = am.device
                    , height = am.height
                    , width = am.width
                    }
                    model
                , BE.onResize OnResize
                ]

        _ ->
            Sub.none


appDocument : App config model msg -> Model model -> B.Document (Msg msg)
appDocument a am =
    case ( am.model, am.shuttingDown ) of
        ( Err e, False ) ->
            { title = "failed to parse", body = [ H.text (Debug.toString e) ] }

        ( Ok model, False ) ->
            a.document
                { title = am.title
                , hash = am.dict
                , device = am.device
                , height = am.height
                , width = am.width
                }
                model

        ( _, True ) ->
            { title = "shuttingDown", body = [] }


updateHash : Model model -> Cmd (Msg msg)
updateHash m =
    BN.replaceUrl m.key <|
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


init0 : In -> config -> ( config, Cmd (Msg msg) )
init0 _ c =
    ( c, Cmd.none )


sub0 : In -> model -> Sub (Msg msg)
sub0 _ _ =
    Sub.none


update0 : In -> msg -> model -> ( model, Cmd (Msg msg) )
update0 _ _ model =
    ( model, Cmd.none )


document : In -> E.Element (Msg msg) -> B.Document (Msg msg)
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


pushHash : String -> String -> Cmd (Msg msg)
pushHash k v =
    UpdateHashKV k v
        |> Task.succeed
        |> Task.perform identity


type alias TestFlags config =
    { id : String
    , config : config
    , title : String
    , context : JE.Value
    , width : Int
    , height : Int
    }


testFlags : JD.Decoder config -> JD.Decoder (TestFlags config)
testFlags config =
    JD.map6 TestFlags
        (JD.field "id" JD.string)
        (JD.field "config" config)
        (JD.field "title" JD.string)
        (JD.field "context" JD.value)
        (JD.field "width" JD.int)
        (JD.field "height" JD.int)


type alias TModel model =
    { title : String
    , model : Maybe model
    , shuttingDown : Bool
    , device : E.Device
    , height : Int
    , width : Int
    }


testInit :
    TestApp config model msg
    -> JE.Value
    -> Url
    -> BN.Key
    -> ( TModel model, Cmd (Msg msg) )
testInit t flags _ _ =
    case JD.decodeValue (testFlags t.config) flags of
        Ok tflags ->
            let
                device =
                    E.classifyDevice tflags
            in
            t.init
                { title = tflags.title
                , hash = Dict.empty
                , device = device
                , height = tflags.height
                , width = tflags.width
                }
                tflags
                |> Tuple.mapFirst
                    (\m ->
                        { title = tflags.title
                        , model = Just m
                        , shuttingDown = False
                        , device = device
                        , height = tflags.height
                        , width = tflags.width
                        }
                    )

        Err e ->
            ( { model = Nothing
              , title = Debug.toString e
              , shuttingDown = False
              , device = { class = E.Desktop, orientation = E.Landscape }
              , height = 1024
              , width = 1024
              }
            , result Cmd.none [ BadConfig <| JD.errorToString e ]
            )


testUpdate :
    TestApp config model msg
    -> Msg msg
    -> TModel model
    -> ( TModel model, Cmd (Msg msg) )
testUpdate t msg m =
    case ( m.model, msg ) of
        ( Just model, Msg imsg ) ->
            t.update
                { title = m.title
                , hash = Dict.empty
                , device = m.device
                , height = m.height
                , width = m.width
                }
                imsg
                model
                |> Tuple.mapFirst (\m2 -> { m | model = Just m2 })

        ( _, Shutdown () ) ->
            ( { m | shuttingDown = True }, Cmd.none )

        _ ->
            ( m, Cmd.none )


testDocument :
    TestApp config model msg
    -> TModel model
    -> B.Document (Msg msg)
testDocument t m =
    case ( m.shuttingDown, m.model ) of
        ( False, Just model ) ->
            t.document
                { title = m.title
                , hash = Dict.empty
                , device = m.device
                , height = m.height
                , width = m.width
                }
                model

        _ ->
            { title = m.title, body = [ H.text m.title ] }


testSubscriptions :
    TestApp config model msg
    -> TModel model
    -> Sub (Msg msg)
testSubscriptions t m =
    case ( m.shuttingDown, m.model ) of
        ( False, Just model ) ->
            Sub.batch
                [ t.subscriptions
                    { title = m.title
                    , hash = Dict.empty
                    , device = m.device
                    , height = m.height
                    , width = m.width
                    }
                    model
                , BE.onResize OnResize
                , shutdown Shutdown
                ]

        _ ->
            Sub.none


test : TestApp config model msg -> Program JE.Value (TModel model) (Msg msg)
test t =
    B.application
        { init = testInit t
        , view = testDocument t
        , update = testUpdate t
        , subscriptions = testSubscriptions t
        , onUrlRequest = UrlRequest
        , onUrlChange = UrlChange
        }


type alias TestApp config model msg =
    { config : JD.Decoder config
    , init : In -> TestFlags config -> ( model, Cmd (Msg msg) )
    , update : In -> msg -> model -> ( model, Cmd (Msg msg) )
    , subscriptions : In -> model -> Sub (Msg msg)
    , document : In -> model -> B.Document (Msg msg)
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
                        JD.map TestPassed (JD.field "id" JD.string)

                    "BadConfig" ->
                        JD.map BadConfig (JD.field "message" JD.string)

                    "Screenshot" ->
                        JD.map Screenshot (JD.field "id" JD.string)

                    "BadElm" ->
                        JD.map BadElm (JD.field "message" JD.string)

                    "TestDone" ->
                        JD.succeed TestDone

                    _ ->
                        JD.fail <| "unknown kind: " ++ kind
            )


test0 :
    App config model msg
    -> (In -> TestFlags config -> ( model, Cmd (Msg msg) ))
    -> Program JE.Value (TModel model) (Msg msg)
test0 a init =
    test
        { config = a.config
        , init = init
        , update = \i msg m -> a.update i msg m
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


result : Cmd (Msg msg) -> List TestResult -> Cmd (Msg msg)
result c list =
    Cmd.batch [ c, JE.list controller list |> toIframe ]
