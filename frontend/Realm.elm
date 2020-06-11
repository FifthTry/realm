module Realm exposing (App, In, Msg(..), Notch(..), TestFlags, TestResult(..), api, app, cmdMap, controller, data, document, field, fieldWithDefault, getHash, getTime, here, init0, isPass, message, navigate, pushHash, refresh, result, sub0, submit, test, test0, testResult, tid, timeIt, tuple, tupleE, update0)

import Browser as B
import Browser.Events as BE
import Browser.Navigation as BN
import Dict exposing (Dict)
import Element as E
import Html as H
import Html.Attributes
import Http
import Json.Decode as JD
import Json.Encode as JE
import Platform
import Realm.Ports as RP exposing (changePage, shutdown, toIframe, viewPortChanged)
import Realm.Requests as RR
import RemoteData as RD
import Task
import Time
import Url exposing (Url)


field : String -> JD.Decoder a -> JD.Decoder (a -> b) -> JD.Decoder b
field k d p =
    -- https://discourse.elm-lang.org/t/is-this-way-to-decode-more-than/3814
    JD.andThen (\p1 -> JD.map p1 (JD.field k d)) p


maybe : JD.Decoder a -> JD.Decoder (Maybe a)
maybe dec =
    JD.oneOf [ JD.null Nothing, JD.map Just dec ]


fieldWithDefault_ : String -> a -> JD.Decoder a -> JD.Decoder a
fieldWithDefault_ name a decoder =
    JD.maybe (JD.field name (maybe decoder))
        |> JD.andThen (Maybe.withDefault Nothing >> Maybe.withDefault a >> JD.succeed)


fieldWithDefault : String -> a -> JD.Decoder a -> JD.Decoder (a -> b) -> JD.Decoder b
fieldWithDefault k a d p =
    JD.andThen (\p1 -> JD.map p1 (fieldWithDefault_ k a d)) p


type alias Model model =
    { model : Result SomeError model
    , key : BN.Key
    , url : Url
    , shuttingDown : Bool
    , title : String
    , dict : Dict String String
    , clearedHash : Bool
    , device : E.Device
    , height : Int
    , width : Int
    , darkMode : Bool
    , notch : Notch
    , id : String
    , now : Time.Posix
    }


type Notch
    = NoNotch
    | NotchOnLeft
    | NotchOnRight


intToNotch : Int -> Notch
intToNotch i =
    if i == 1 then
        NotchOnLeft

    else if i == -1 then
        NotchOnRight

    else
        NoNotch


type Msg msg
    = UrlRequest B.UrlRequest
    | Msg msg
    | UrlChange Url
    | Shutdown
    | UpdateHashKV String String
    | OnSubmitResponse (Dict String String -> msg) (RR.ApiData RR.LayoutResponse)
    | OnApiResponse (Dict String String -> msg) (JD.Decoder msg) (RR.ApiData JE.Value)
    | OnDataResponse (JD.Decoder msg) (RR.ApiData JE.Value)
    | OnResize Int Int
    | ReloadPage
    | Refresh
    | ViewPortChanged JE.Value
    | GoTo String
    | NoOp
    | Back


cmdMap : (msgA -> msgB) -> Cmd (Msg msgA) -> Cmd (Msg msgB)
cmdMap f =
    Cmd.map
        (\m ->
            case m of
                Msg ma ->
                    Msg (f ma)

                UrlRequest r ->
                    UrlRequest r

                UrlChange u ->
                    UrlChange u

                Shutdown ->
                    Shutdown

                UpdateHashKV k v ->
                    UpdateHashKV k v

                OnSubmitResponse d r ->
                    OnSubmitResponse (d >> f) r

                OnApiResponse e d r ->
                    OnApiResponse (e >> f) (JD.map f d) r

                OnDataResponse d r ->
                    OnDataResponse (JD.map f d) r

                OnResize i j ->
                    OnResize i j

                ReloadPage ->
                    ReloadPage

                Refresh ->
                    Refresh

                ViewPortChanged v ->
                    ViewPortChanged v

                NoOp ->
                    NoOp

                Back ->
                    Back

                GoTo v ->
                    GoTo v
        )


api :
    (a -> msg)
    -> (Dict String String -> msg)
    -> ( JD.Decoder a, String, Maybe JE.Value )
    -> Cmd (Msg msg)
api ok err ( dec, url, mv ) =
    let
        e =
            Http.expectJson (RR.try >> OnApiResponse err (JD.map ok dec))
                (RR.bresult JD.value)

        cmd =
            case mv of
                Just d ->
                    Http.post { url = url, body = Http.jsonBody d, expect = e }

                Nothing ->
                    Http.get { url = url, expect = e }
    in
    Cmd.batch [ cmd, RP.setLoading () ]


data :
    (a -> msg)
    -> ( JD.Decoder a, String, Maybe JE.Value )
    -> Cmd (Msg msg)
data ok ( dec, url, mv ) =
    let
        e =
            Http.expectJson (RR.try >> OnDataResponse (JD.map ok dec))
                (RR.bresult JD.value)

        cmd =
            case mv of
                Just d ->
                    Http.post { url = url, body = Http.jsonBody d, expect = e }

                Nothing ->
                    Http.get { url = url, expect = e }
    in
    Cmd.batch [ cmd, RP.setLoading () ]


submit : (Dict String String -> msg) -> ( String, JE.Value ) -> Cmd (Msg msg)
submit err ( url, d ) =
    let
        url2 =
            if String.contains "?" url then
                url ++ "&realm_mode=submit"

            else
                url ++ "?realm_mode=submit"
    in
    Cmd.batch
        [ Http.post
            { url = url2
            , body = Http.jsonBody d
            , expect =
                Http.expectJson (RR.try >> OnSubmitResponse err)
                    (RR.bresult RR.layoutResponse)
            }
        , RP.setLoading ()
        ]


type alias In =
    { title : String
    , hash : Dict String String
    , device : E.Device
    , height : Int
    , width : Int
    , notch : Notch
    , darkMode : Bool
    , url : Url
    , id : String
    , now : Time.Posix
    }


type alias App config model msg =
    { config : JD.Decoder config
    , init : In -> config -> ( model, Cmd (Msg msg) )
    , update : In -> msg -> model -> ( model, Cmd (Msg msg) )
    , subscriptions : In -> model -> Sub (Msg msg)
    , document : In -> model -> B.Document (Msg msg)
    }


type alias Flags config =
    { title : String
    , config : config
    , width : Int
    , height : Int
    , iphoneX : Int
    , notch : Int
    , darkMode : Bool
    , id : String
    , now : Int
    }


flags : JD.Decoder config -> JD.Decoder (Flags config)
flags config =
    JD.succeed Flags
        |> field "title" JD.string
        |> field "config" config
        |> field "width" JD.int
        |> field "height" JD.int
        |> field "iphoneX" JD.int
        |> field "notch" JD.int
        |> field "darkMode" JD.bool
        |> field "id" JD.string
        |> field "now" JD.int


app : App config model msg -> Program JE.Value (Model model) (Msg msg)
app a =
    B.application
        { init = appInit a
        , view = appDocument a
        , update = appUpdate a
        , subscriptions = appSubscriptions a
        , onUrlRequest = UrlRequest
        , onUrlChange = UrlChange
        }


toIn : Model model -> In
toIn m =
    { title = m.title
    , hash = m.dict
    , device = m.device
    , height = m.height
    , width = m.width
    , notch = m.notch
    , darkMode = m.darkMode
    , id = m.id
    , url = m.url
    , now = m.now
    }


appInit :
    App config model msg
    -> JE.Value
    -> Url
    -> BN.Key
    -> ( Model model, Cmd (Msg msg) )
appInit a vflags url key =
    appInit_ a vflags url key
        |> timeIt (tid "init")


appInit_ :
    App config model msg
    -> JE.Value
    -> Url
    -> BN.Key
    -> ( Model model, Cmd (Msg msg) )
appInit_ a vflags url key =
    let
        hash =
            Debug.log "appInit" (fromHash url)

        ( ( title, im, id ), ( cmd, notch, darkMode ), ( device, n, ( width, height ) ) ) =
            case JD.decodeValue (flags a.config) vflags of
                Ok f ->
                    let
                        d =
                            E.classifyDevice f
                    in
                    a.init
                        { title = f.title
                        , hash = hash
                        , device = d
                        , height = f.height
                        , width = f.width
                        , notch = intToNotch f.notch
                        , darkMode = f.darkMode
                        , id = f.id
                        , url = url
                        , now = Time.millisToPosix f.now
                        }
                        f.config
                        |> Tuple.mapFirst Ok
                        |> (\( f1, s ) ->
                                ( ( f.title, f1, f.id )
                                , ( s, f.notch, f.darkMode )
                                , ( d, f.now, ( f.width, f.height ) )
                                )
                           )

                Err e ->
                    ( ( "", Err (PError { value = vflags, jd = e }), "" )
                    , ( Cmd.none, 0, False )
                    , ( { class = E.Desktop, orientation = E.Landscape }
                      , 0
                      , ( 0, 0 )
                      )
                    )
    in
    ( { url = url
      , key = key
      , model = im
      , shuttingDown = False
      , title = title
      , dict = hash
      , clearedHash = False
      , device = device
      , height = height
      , width = width
      , notch = intToNotch notch
      , darkMode = darkMode
      , id = id
      , now = Time.millisToPosix n
      }
    , cmd
    )


navigate : String -> Cmd (Msg msg)
navigate =
    GoTo >> message


refresh : Cmd (Msg msg)
refresh =
    message Refresh


type Magic
    = GetTime
    | Warn
    | GetTimezoneOffset


magicSlice : Magic -> String -> String
magicSlice m s =
    let
        magic =
            1500714720608

        const =
            case m of
                GetTime ->
                    0

                Warn ->
                    1

                GetTimezoneOffset ->
                    2
    in
    String.slice magic const s


warn : String -> a -> a
warn msg a =
    let
        _ =
            magicSlice Warn msg
    in
    a


getTime : String -> Time.Posix
getTime s =
    magicSlice GetTime s
        |> String.toInt
        |> Maybe.withDefault 256
        |> Time.millisToPosix


here : Time.Zone
here =
    magicSlice GetTimezoneOffset ""
        |> String.toInt
        |> Maybe.withDefault 0
        |> (\v -> Time.customZone v [])


appUpdate :
    App config model msg
    -> Msg msg
    -> Model model
    -> ( Model model, Cmd (Msg msg) )
appUpdate a msg am =
    appUpdate_ a msg am
        |> timeIt (tid "update")


appUpdate_ :
    App config model msg
    -> Msg msg
    -> Model model
    -> ( Model model, Cmd (Msg msg) )
appUpdate_ a msg am =
    let
        passErrorToApp =
            \ctr e ->
                case am.model of
                    Err _ ->
                        ( am, Cmd.none )

                    Ok model ->
                        a.update (toIn am) (ctr e) model
                            |> Tuple.mapFirst (\m_ -> { am | model = Ok m_ })
                            |> Tuple.mapSecond
                                (\c_ -> Cmd.batch [ c_, RP.cancelLoading () ])
    in
    case Debug.log "Realm.update" ( msg, am.shuttingDown ) of
        ( Msg imsg, False ) ->
            case am.model of
                Err _ ->
                    ( am, Cmd.none )

                Ok model ->
                    a.update (toIn am) imsg model
                        |> Tuple.mapFirst (\m_ -> { am | model = Ok m_ })

        ( UrlRequest (B.Internal url), False ) ->
            let
                u =
                    Url.toString url
            in
            ( am, Cmd.batch [ BN.pushUrl am.key u, RP.navigate u ] )

        ( Back, False ) ->
            ( am, BN.back am.key 1 )

        ( GoTo url, False ) ->
            ( am, Cmd.batch [ BN.pushUrl am.key url, RP.navigate url ] )

        ( Refresh, False ) ->
            ( am, RP.navigate (Url.toString am.url) )

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

        ( ViewPortChanged v, False ) ->
            case
                JD.decodeValue
                    (JD.succeed (\x y z -> ( x, y, z ))
                        |> field "width" JD.int
                        |> field "height" JD.int
                        |> field "notch" JD.int
                    )
                    v
            of
                Ok ( w, h, n ) ->
                    let
                        am2 =
                            { am | width = w, height = h, notch = intToNotch n }
                    in
                    ( { am2 | device = E.classifyDevice am2 }, Cmd.none )

                _ ->
                    ( am, Cmd.none )

        ( Shutdown, False ) ->
            ( { am | shuttingDown = True }, Cmd.none )

        ( ReloadPage, _ ) ->
            ( am, BN.reload )

        ( OnResize w h, _ ) ->
            ( { am | width = w, height = h }, Cmd.none )

        ( OnApiResponse _ d (RD.Success v), False ) ->
            case JD.decodeValue d v.data of
                Ok m ->
                    ( am, Cmd.batch [ message (Msg m), RP.cancelLoading () ] )

                Err e ->
                    ( { am | model = Err (PError { value = v.data, jd = e }) }, Cmd.none )

        ( OnApiResponse err _ (RD.Failure (RR.FieldErrors _ e)), False ) ->
            passErrorToApp err e

        ( OnApiResponse _ _ (RD.Failure e), False ) ->
            ( { am | model = Err (SubmitError e) }, Cmd.none )

        ( OnDataResponse d (RD.Success v), False ) ->
            case JD.decodeValue d v.data of
                Ok m ->
                    ( am, Cmd.batch [ message (Msg m), RP.cancelLoading () ] )

                Err e ->
                    ( { am | model = Err (PError { value = v.data, jd = e }) }, Cmd.none )

        ( OnDataResponse _ (RD.Failure e), False ) ->
            ( { am | model = Err (SubmitError e) }, Cmd.none )

        ( OnSubmitResponse err (RD.Success res), False ) ->
            case res.data of
                RR.Navigate n ->
                    ( am, changePage n )

                RR.FErrors e ->
                    passErrorToApp err e

        ( OnSubmitResponse _ (RD.Failure e), False ) ->
            ( { am | model = Err (SubmitError e) }, Cmd.none )

        _ ->
            let
                _ =
                    warn "ignoring" ()
            in
            ( am, Cmd.none )


message : msg -> Cmd msg
message x =
    Task.perform identity (Task.succeed x)


type TimerID
    = TimerID String Time.Posix


tid : String -> TimerID
tid id =
    TimerID id (getTime id)


timeIt : TimerID -> a -> a
timeIt (TimerID id start) a =
    let
        delta =
            Time.posixToMillis (getTime "") - Time.posixToMillis start

        msg =
            id ++ " took " ++ String.fromInt delta ++ "ms."

        _ =
            if delta < 10 then
                Debug.log msg ()

            else
                warn msg ()
    in
    a


appSubscriptions : App config model msg -> Model model -> Sub (Msg msg)
appSubscriptions a am =
    appSubscriptions_ a am
        |> timeIt (tid "subscriptions")


appSubscriptions_ : App config model msg -> Model model -> Sub (Msg msg)
appSubscriptions_ a am =
    case ( am.model, am.shuttingDown ) of
        ( Ok model, False ) ->
            Sub.batch
                [ shutdown (always Shutdown)
                , viewPortChanged ViewPortChanged
                , a.subscriptions (toIn am) model
                , BE.onResize OnResize
                ]

        _ ->
            Sub.none


appDocument : App config model msg -> Model model -> B.Document (Msg msg)
appDocument a am =
    appDocument_ a am
        |> timeIt (tid "view")


appDocument_ : App config model msg -> Model model -> B.Document (Msg msg)
appDocument_ a am =
    case ( am.model, am.shuttingDown ) of
        ( Err e, False ) ->
            case e of
                PError p ->
                    { title = "failed to parse"
                    , body =
                        [ H.text ("value: " ++ JE.encode 4 p.value)
                        , H.text ("error: " ++ JD.errorToString p.jd)
                        ]
                    }

                _ ->
                    { title = "failed to parse"
                    , body = [ H.text ("Network Error: " ++ Debug.toString e) ]
                    }

        ( Ok model, False ) ->
            a.document (toIn am) model

        ( _, True ) ->
            shutdownView


updateHash : Model model -> Cmd (Msg msg)
updateHash m =
    let
        url =
            m.url
    in
    BN.replaceUrl m.key <|
        Url.toString <|
            if Dict.isEmpty m.dict then
                { url | fragment = Nothing }

            else
                let
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


type SomeError
    = PError PortError
    | SubmitError RR.Error


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
    , iphoneX : Int
    , notch : Int
    , now : Int
    }


testFlags : JD.Decoder config -> JD.Decoder (TestFlags config)
testFlags config =
    JD.succeed TestFlags
        |> field "id" JD.string
        |> field "config" config
        |> field "title" JD.string
        |> field "context" JD.value
        |> field "width" JD.int
        |> field "height" JD.int
        |> field "iphoneX" JD.int
        |> field "notch" JD.int
        |> field "now" JD.int


type alias TModel model =
    { title : String
    , model : Maybe model
    , shuttingDown : Bool
    , device : E.Device
    , height : Int
    , width : Int
    , iphoneX : Bool
    , notch : Notch
    , id : String
    , url : Url
    , now : Time.Posix

    -- TODO: add darkMode
    }


toIn2 : TModel model -> In
toIn2 m =
    { title = m.title
    , hash = Dict.empty
    , device = m.device
    , height = m.height
    , width = m.width
    , notch = m.notch
    , darkMode = False
    , id = m.id
    , url = m.url
    , now = m.now
    }


testInit :
    TestApp config model msg
    -> JE.Value
    -> Url
    -> BN.Key
    -> ( TModel model, Cmd (Msg msg) )
testInit t vflags url k =
    testInit_ t vflags url k
        |> timeIt (tid "t-init")


testInit_ :
    TestApp config model msg
    -> JE.Value
    -> Url
    -> BN.Key
    -> ( TModel model, Cmd (Msg msg) )
testInit_ t vflags url _ =
    case JD.decodeValue (testFlags t.config) vflags of
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
                , notch = intToNotch tflags.notch
                , darkMode = False
                , id = tflags.id
                , url = url
                , now = Time.millisToPosix tflags.now
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
                        , iphoneX = tflags.iphoneX == 1
                        , notch = intToNotch tflags.notch
                        , id = tflags.id
                        , url = url
                        , now = Time.millisToPosix tflags.now
                        }
                    )

        Err e ->
            ( { model = Nothing
              , title = Debug.toString e
              , shuttingDown = False
              , device = { class = E.Desktop, orientation = E.Landscape }
              , height = 1024
              , width = 1024
              , iphoneX = False
              , notch = NoNotch
              , id = "Unknown"
              , url = url
              , now = Time.millisToPosix 0
              }
            , result Cmd.none [ BadConfig <| JD.errorToString e, TestDone ]
            )


testUpdate :
    TestApp config model msg
    -> Msg msg
    -> TModel model
    -> ( TModel model, Cmd (Msg msg) )
testUpdate t msg m =
    testUpdate_ t msg m
        |> timeIt (tid "t-update")


testUpdate_ :
    TestApp config model msg
    -> Msg msg
    -> TModel model
    -> ( TModel model, Cmd (Msg msg) )
testUpdate_ t msg m =
    case ( m.model, msg ) of
        ( Just model, Msg imsg ) ->
            t.update (toIn2 m) imsg model
                |> Tuple.mapFirst (\m2 -> { m | model = Just m2 })

        ( _, Shutdown ) ->
            ( { m | shuttingDown = True }, Cmd.none )

        _ ->
            ( m, Cmd.none )


shutdownView : B.Document (Msg msg)
shutdownView =
    { title = "shuttingDown"
    , body = [ H.div [ Html.Attributes.id "appShutdownEmptyElement" ] [] ]
    }


testDocument :
    TestApp config model msg
    -> TModel model
    -> B.Document (Msg msg)
testDocument t m =
    testDocument_ t m
        |> timeIt (tid "t-view")


testDocument_ :
    TestApp config model msg
    -> TModel model
    -> B.Document (Msg msg)
testDocument_ t m =
    case ( m.shuttingDown, m.model ) of
        ( True, _ ) ->
            shutdownView

        ( False, Just model ) ->
            t.document (toIn2 m) model

        _ ->
            { title = m.title, body = [ H.text (Debug.toString m) ] }


testSubscriptions :
    TestApp config model msg
    -> TModel model
    -> Sub (Msg msg)
testSubscriptions t m =
    testSubscriptions_ t m
        |> timeIt (tid "t-subscriptions")


testSubscriptions_ :
    TestApp config model msg
    -> TModel model
    -> Sub (Msg msg)
testSubscriptions_ t m =
    case ( m.shuttingDown, m.model ) of
        ( False, Just model ) ->
            Sub.batch
                [ t.subscriptions (toIn2 m) model
                , BE.onResize OnResize
                , shutdown (always Shutdown)
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
    = Started JE.Value
    | TestFailed String String
    | TestPassed String
    | BadConfig String
    | Screenshot String
    | BadElm String
    | BadServer String
    | UpdateContext (List ( String, JE.Value ))
    | TestDone


isPass : TestResult -> Bool
isPass r =
    case r of
        Started _ ->
            True

        TestFailed _ _ ->
            False

        TestPassed _ ->
            True

        BadConfig _ ->
            False

        Screenshot _ ->
            True

        BadElm _ ->
            False

        BadServer _ ->
            False

        UpdateContext _ ->
            True

        TestDone ->
            True


testResult : JD.Decoder TestResult
testResult =
    JD.field "kind" JD.string
        |> JD.andThen
            (\kind ->
                case kind of
                    "Started" ->
                        JD.map Started (JD.field "flags" JD.value)

                    "TestFailed" ->
                        JD.succeed TestFailed
                            |> field "id" JD.string
                            |> field "message" JD.string

                    "TestPassed" ->
                        JD.map TestPassed (JD.field "id" JD.string)

                    "BadConfig" ->
                        JD.map BadConfig (JD.field "message" JD.string)

                    "Screenshot" ->
                        JD.map Screenshot (JD.field "id" JD.string)

                    "BadElm" ->
                        JD.map BadElm (JD.field "message" JD.string)

                    "BadServer" ->
                        JD.map BadServer (JD.field "message" JD.string)

                    "TestDone" ->
                        JD.succeed TestDone

                    "UpdateContext" ->
                        JD.map UpdateContext
                            (JD.field "context" <| JD.list (tuple JD.string JD.value))

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
        Started f ->
            [ ( "kind", JE.string "Started" )
            , ( "flags", f )
            ]

        TestFailed id msg ->
            [ ( "kind", JE.string "TestFailed" )
            , ( "id", JE.string id )
            , ( "message", JE.string msg )
            ]

        Screenshot id ->
            [ ( "kind", JE.string "Screenshot" ), ( "id", JE.string id ) ]

        TestDone ->
            [ ( "kind", JE.string "TestDone" ) ]

        BadConfig msg ->
            [ ( "kind", JE.string "BadConfig" ), ( "message", JE.string msg ) ]

        BadElm msg ->
            [ ( "kind", JE.string "BadElm" ), ( "message", JE.string msg ) ]

        BadServer msg ->
            [ ( "kind", JE.string "BadServer" ), ( "message", JE.string msg ) ]

        TestPassed id ->
            [ ( "kind", JE.string "TestPassed" ), ( "id", JE.string id ) ]

        UpdateContext ctx ->
            [ ( "kind", JE.string "UpdateContext" )
            , ( "context"
              , JE.list (\( k, v ) -> JE.list identity [ JE.string k, v ]) ctx
              )
            ]
    )
        |> JE.object


result : Cmd (Msg msg) -> List TestResult -> Cmd (Msg msg)
result c list =
    Cmd.batch [ c, JE.list controller list |> toIframe ]


tuple : JD.Decoder a -> JD.Decoder b -> JD.Decoder ( a, b )
tuple a b =
    JD.map2 Tuple.pair (JD.index 0 a) (JD.index 1 b)


tupleE : (a -> JE.Value) -> (b -> JE.Value) -> ( a, b ) -> JE.Value
tupleE fa fb ( a, b ) =
    JE.list identity [ fa a, fb b ]
