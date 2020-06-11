module Realm.Test exposing (FormErrorAssertion(..), Step(..), Test, api, apiError, apiErrorS, apiFalse, apiOk, apiS, apiTrue, app, gray0, gray1, gray2, gray3, gray4, gray5, gray6, gray7, gray8, gray9, only)

import Array exposing (Array)
import Browser as B
import Browser.Events as BE
import Dict exposing (Dict)
import Element as E
import Element.Background as Bg
import Element.Border as EB
import Element.Events as EE
import Element.Font as EF
import Html.Attributes as HA
import Http
import Json.Decode as JD
import Json.Encode as JE
import Realm as R
import Realm.Ports exposing (fromIframe, toIframe)
import Realm.Requests as RR
import Realm.Trace as Tr
import Realm.Utils as RU exposing (edges, yesno)
import RemoteData as RD


type alias Test =
    { id : String
    , context : List ( String, JE.Value )
    , steps : List Step
    }


type Step
    = Navigate ( String, String ) String
    | NavigateS ( String, String ) String (String -> String)
    | Submit ( String, String ) JE.Value
    | SubmitS ( String, String ) String (String -> JE.Value)
    | SubmitForm ( String, String ) ( String, JE.Value )
    | SubmitFormS ( String, String ) String (String -> ( String, JE.Value ))
    | FormError String (List FormErrorAssertion) ( String, JE.Value )
    | FormErrorS ( String, String ) (List FormErrorAssertion) (String -> ( String, JE.Value ))
    | ApiError String (List FormErrorAssertion) ( String, Maybe JE.Value )
    | ApiErrorS ( String, String ) (List FormErrorAssertion) (String -> ( String, Maybe JE.Value ))
    | Api String (JE.Value -> JE.Value -> List R.TestResult) ( String, Maybe JE.Value )
    | ApiS ( String, String ) (JE.Value -> JE.Value -> List R.TestResult) (String -> ( String, Maybe JE.Value ))
    | Comment String


type FormErrorAssertion
    = ErrorPresent String
    | ExactError String String
    | ErrorAbsent String
    | TotalErrors Int


type alias Config =
    { tests : List Test
    , title : String
    }


type alias First =
    { id : String
    , context : Context
    }


type alias StepWithResults =
    { first : Maybe First
    , step : Step
    , trace : Maybe Tr.Trace
    , results : List R.TestResult
    , data : Maybe JE.Value
    , idx : Int
    }


type alias Trace =
    {}


type alias Selection =
    { selected : Maybe Int
    , showTrace : Bool
    }


type alias Model =
    { context : Context
    , current : Maybe Int
    , tests : Array StepWithResults
    , title : String
    , errorOnly : Bool
    , selection : Selection
    }


type Msg
    = FromChild JE.Value
    | NoOp
    | ResetDone
    | OnKey String
    | OnSubmit2Response FormThing (RR.ApiData RR.LayoutResponse)
    | ApiErrorResponse String (List FormErrorAssertion) (RR.ApiData JE.Value)
    | ApiSuccessResponse String (JE.Value -> JE.Value -> List R.TestResult) (RR.ApiData JE.Value)
    | SMsg SMsg
    | TMsg TMsg
    | Skip


type TMsg
    = TMsg_


type SMsg
    = Select Int
    | UnSelect


type FormThing
    = FormErrorTest String (List FormErrorAssertion)
    | SubmitTest String String



-- | GoTo Int


init : Config -> () -> url -> key -> ( Model, Cmd Msg )
init config _ _ _ =
    doStep 0
        False
        { context = []
        , current = Just -1
        , title = config.title
        , tests = flatten config.tests
        , errorOnly = False
        , selection = { selected = Nothing, showTrace = True }
        }
        |> R.timeIt (R.tid "test-init")


apiErrorRequest :
    String
    -> List FormErrorAssertion
    -> ( String, Maybe JE.Value )
    -> Cmd Msg
apiErrorRequest id assertions ( url, mv ) =
    let
        expect =
            Http.expectJson (RR.try >> ApiErrorResponse id assertions)
                (RR.bresult JD.value)
    in
    case mv of
        Just data ->
            Http.post { url = url, body = Http.jsonBody data, expect = expect }

        Nothing ->
            Http.get { url = url, expect = expect }


apiSuccessRequest :
    String
    -> (JE.Value -> JE.Value -> List R.TestResult)
    -> ( String, Maybe JE.Value )
    -> Cmd Msg
apiSuccessRequest id runner ( url, mv ) =
    let
        expect =
            Http.expectJson (RR.try >> ApiSuccessResponse id runner)
                (RR.bresult JD.value)
    in
    case mv of
        Just data ->
            Http.post { url = url, body = Http.jsonBody data, expect = expect }

        Nothing ->
            Http.get { url = url, expect = expect }


resolveA3 :
    String
    -> JD.Decoder a
    -> (a -> ( String, Maybe JE.Value ))
    -> JE.Value
    -> Maybe ( String, Maybe JE.Value )
resolveA3 key dec f v =
    case JD.decodeValue (JD.field key dec) v of
        Ok a ->
            Just (f a)

        Err _ ->
            Nothing


doStep : Int -> Bool -> Model -> ( Model, Cmd Msg )
doStep idx postReset m =
    let
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
                    Http.expectJson (RR.try >> OnSubmit2Response thing)
                        (RR.bresult RR.layoutResponse)
                }
    in
    case Array.get idx m.tests of
        Just tr ->
            let
                cmd =
                    case tr.step of
                        Comment _ ->
                            R.message Skip

                        Navigate ( elm, id ) url ->
                            navigate elm id url m.context

                        NavigateS ( elm, id ) key f ->
                            navigate elm
                                id
                                (resolve key JD.string f (JE.object m.context))
                                m.context

                        Submit ( elm, id ) payload ->
                            submit elm id payload m.context

                        SubmitForm ( elm, id ) ( url, data ) ->
                            submit2 (SubmitTest elm id) ( url, data )

                        SubmitFormS ( elm, id ) key f ->
                            submit2 (SubmitTest elm id)
                                (resolveA2 key JD.string f (JE.object m.context))

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

                        ApiError id assertions payload ->
                            apiErrorRequest id assertions payload

                        ApiErrorS ( id, key ) assertions f ->
                            case resolveA3 key JD.string f (JE.object m.context) of
                                Just v ->
                                    apiErrorRequest id assertions v

                                Nothing ->
                                    Debug.todo "not handled"

                        Api id runner payload ->
                            apiSuccessRequest id runner payload

                        ApiS ( id, key ) runner f ->
                            case resolveA3 key JD.string f (JE.object m.context) of
                                Just v ->
                                    apiSuccessRequest id runner v

                                Nothing ->
                                    Debug.todo "not handled"

                ( cmd2, ctx2, current ) =
                    -- reset db and context when test changes
                    case ( tr.first, postReset ) of
                        ( Just first, False ) ->
                            ( Http.post
                                { url = "/test/reset-db/"
                                , expect = Http.expectString (always ResetDone)
                                , body = Http.emptyBody
                                }
                            , first.context
                            , m.current
                            )

                        _ ->
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
            Debug.todo "TODO: fix this"


resolveA : String -> JD.Decoder a -> (a -> JE.Value) -> JE.Value -> JE.Value
resolveA key dec f v =
    case JD.decodeValue (JD.field key dec) v of
        Ok a ->
            f a

        Err _ ->
            Debug.todo "TODO: fix this"


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
            Debug.todo "TODO: handle this"


onCurrent : (StepWithResults -> StepWithResults) -> Int -> Model -> Model
onCurrent f idx m =
    m.tests
        |> Array.get idx
        |> Maybe.map f
        |> Maybe.map (\r -> Array.set idx r m.tests)
        |> Maybe.map (\tests -> { m | tests = tests })
        |> Maybe.withDefault m


attachTrace : Tr.Trace -> Int -> Model -> Model
attachTrace tr idx m =
    onCurrent (\s -> { s | trace = Just tr }) idx m


type alias Accumulator acc =
    acc -> acc


type alias IRAData =
    ( List ( String, JE.Value ), Maybe JE.Value )


insertResults : List R.TestResult -> Int -> Model -> Model
insertResults results idx m =
    let
        pluckContextAndData : R.TestResult -> Accumulator IRAData
        pluckContextAndData r ( l, md ) =
            case r of
                R.Started d ->
                    ( l, Just d )

                R.UpdateContext c ->
                    ( l ++ c, md )

                _ ->
                    ( l, md )

        ( context, data ) =
            List.foldl pluckContextAndData ( m.context, Nothing ) results

        f : StepWithResults -> StepWithResults
        f s =
            case ( { s | results = s.results ++ results }, data ) of
                ( m2, Just d ) ->
                    { m2 | data = Just d }

                ( m2, Nothing ) ->
                    m2
    in
    onCurrent f idx { m | context = context }


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
                                        ++ " error to be >"
                                        ++ val
                                        ++ "<, found:>"
                                        ++ got
                                        ++ "<."

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
    (case Debug.log "Test.msg" ( msg, m.current ) of
        ( NoOp, _ ) ->
            ( m, Cmd.none )

        ( SMsg sm, _ ) ->
            upSel sm m

        ( TMsg sm, _ ) ->
            upTr sm m

        ( Skip, Just idx ) ->
            doStep (idx + 1) False m

        ( Skip, Nothing ) ->
            Debug.todo "impossibru"

        ( FromChild v, Just idx ) ->
            case Debug.log "FromChild" <| JD.decodeValue (JD.list R.testResult) v of
                Ok results ->
                    let
                        m2 =
                            insertResults results idx m
                                |> R.timeIt (R.tid "insert-results")

                        f =
                            \r mod ->
                                case r of
                                    R.Started flags ->
                                        case JD.decodeValue (JD.field "trace" Tr.trace) flags of
                                            Ok tr ->
                                                attachTrace tr idx mod
                                                    |> R.timeIt (R.tid "attach-trace")

                                            Err e ->
                                                Debug.todo (Debug.toString e)

                                    R.UpdateContext lst ->
                                        { mod | context = m.context ++ lst }

                                    _ ->
                                        mod

                        m3 =
                            List.foldl f m2 results
                                |> R.timeIt (R.tid "foldl")
                    in
                    if List.any ((==) R.TestDone) (Debug.log "results" results) then
                        doStep (idx + 1) False m3
                            |> R.timeIt (R.tid "doStep")

                    else
                        ( m3, Cmd.none )

                Err _ ->
                    ( m, Cmd.none )

        ( FromChild _, Nothing ) ->
            Debug.todo "impossible"

        ( ResetDone, Nothing ) ->
            Debug.todo "impossible"

        ( ResetDone, Just idx ) ->
            doStep (idx + 1) True m

        ( OnKey "e", _ ) ->
            ( { m | errorOnly = not m.errorOnly }, Cmd.none )

        ( OnKey "Escape", _ ) ->
            upSel UnSelect m

        ( OnKey _, _ ) ->
            ( m, Cmd.none )

        ( ApiErrorResponse id _ (RD.Success v), Just idx ) ->
            let
                m2 =
                    case v.trace of
                        Just tr ->
                            attachTrace tr idx m

                        Nothing ->
                            m
            in
            doStep (idx + 1)
                False
                (insertResults
                    [ R.TestFailed id
                        ("Expected errors, found success: " ++ JE.encode 4 v.data)
                    , R.TestDone
                    ]
                    idx
                    m2
                )

        ( ApiErrorResponse _ assertions (RD.Failure (RR.FieldErrors mtr d)), Just idx ) ->
            let
                results =
                    checkAssertions assertions d

                m2 =
                    case mtr of
                        Just tr ->
                            attachTrace tr idx m

                        Nothing ->
                            m
            in
            doStep (idx + 1) False (insertResults results idx m2)

        ( ApiErrorResponse _ _ _, _ ) ->
            Debug.todo "ApiErrorResponse: not yet implemented"

        ( ApiSuccessResponse _ runner (RD.Success v), Just i ) ->
            let
                m2 =
                    case v.trace of
                        Just tr ->
                            attachTrace tr i m

                        Nothing ->
                            m
            in
            m2
                |> insertResults (runner v.data (JE.object m.context)) i
                |> doStep (i + 1) False

        ( ApiSuccessResponse id _ (RD.Failure e), Just idx ) ->
            let
                m2 =
                    case RR.getTrace e of
                        Just tr ->
                            attachTrace tr idx m

                        Nothing ->
                            m
            in
            doStep (idx + 1)
                False
                (insertResults
                    [ R.TestFailed id ("Request failed: " ++ Debug.toString e)
                    , R.TestDone
                    ]
                    idx
                    m2
                )

        ( ApiSuccessResponse _ _ _, _ ) ->
            Debug.todo "ApiSuccessResponse: not yet implemented"

        ( OnSubmit2Response (FormErrorTest id assertions) (RD.Success res), Just idx ) ->
            let
                m2 =
                    case res.trace of
                        Just tr ->
                            attachTrace tr idx m

                        Nothing ->
                            m
            in
            case res.data of
                RR.FErrors d ->
                    let
                        results =
                            checkAssertions assertions d
                    in
                    m2
                        |> insertResults results idx
                        |> doStep (idx + 1) False

                RR.Navigate _ ->
                    let
                        navigateCmd =
                            -- TODO: show response in browser
                            -- navigate elm id payload m.context
                            Cmd.none

                        results =
                            [ R.TestFailed id "Expected errors, found Navigation", R.TestDone ]

                        m3 =
                            insertResults results idx m2
                    in
                    doStep (idx + 1) False m3
                        |> Tuple.mapSecond (\c -> Cmd.batch [ c, navigateCmd ])

        ( OnSubmit2Response (FormErrorTest id _) (RD.Failure e), Just idx ) ->
            -- test failed
            -- TODO: collect trace after extracting from e
            doStep (idx + 1)
                False
                (insertResults
                    [ R.TestFailed id ("Request failed: " ++ Debug.toString e)
                    , R.TestDone
                    ]
                    idx
                    m
                )

        ( OnSubmit2Response (SubmitTest elm id) (RD.Success res), Just idx ) ->
            let
                m2 =
                    case res.trace of
                        Just tr ->
                            attachTrace tr idx m

                        Nothing ->
                            m
            in
            case res.data of
                RR.FErrors d ->
                    m2
                        |> insertResults
                            [ R.TestFailed id
                                ("Expected Navigation, found FormErrors: " ++ Debug.toString d)
                            , R.TestDone
                            ]
                            idx
                        |> doStep (idx + 1) False

                RR.Navigate payload ->
                    ( m2, submit elm id payload m.context )

        ( OnSubmit2Response (SubmitTest _ id) (RD.Failure e), Just idx ) ->
            -- test failed
            let
                m2 =
                    case RR.getTrace e of
                        Just tr ->
                            attachTrace tr idx m

                        Nothing ->
                            m
            in
            doStep (idx + 1)
                False
                (insertResults
                    [ R.TestFailed id ("Request failed: " ++ Debug.toString e)
                    , R.TestDone
                    ]
                    idx
                    m2
                )

        ( OnSubmit2Response _ _, _ ) ->
            Debug.todo "OnSubmitResponse: must not happen"
    )
        |> R.timeIt (R.tid "test-update")


document : Model -> B.Document Msg
document m =
    { title = m.title ++ " Test", body = [ E.layout [] (view m) ] }
        |> R.timeIt (R.tid "test-view")


view : Model -> E.Element Msg
view m =
    E.row [ E.width E.fill, E.height E.fill, E.inFront (dialog m) ]
        [ E.textColumn
            [ E.height E.fill, E.width (E.px 300), EB.widthEach { edges | right = 1 } ]
            [ status m, listOfTests m ]
        , E.el [ E.height E.fill, E.width E.fill ] <|
            RU.iframe "/iframe/" [ HA.style "width" "100%", HA.style "border" "none" ]
        ]


upTr : TMsg -> Model -> ( Model, Cmd Msg )
upTr msg =
    case msg of
        TMsg_ ->
            Debug.todo "not yet implemented"


traceView : Model -> StepWithResults -> Tr.Trace -> E.Element Msg
traceView _ step tr =
    let
        value : JE.Value -> String
        value v =
            case JD.decodeValue JD.string v of
                Ok val ->
                    val

                Err _ ->
                    JE.encode 4 v

        spanItemView : ( Tr.Duration, Tr.SpanItem ) -> E.Element Msg
        spanItemView ( d, s ) =
            E.row [ E.spacing 10, E.paddingXY 0 5, EF.color gray2, EF.light ]
                [ RU.text [ EF.color gray3, E.width (E.px 50), E.alignTop, EF.alignRight ]
                    (Tr.human False d)
                , case s of
                    Tr.Log msg ->
                        E.text msg

                    Tr.Field k v ->
                        E.paragraph [ E.width (E.fill |> E.maximum 500) ]
                            [ E.text (k ++ ": " ++ value v) ]

                    Tr.Frame sp ->
                        spanView sp
                ]

        spanView : Tr.Span -> E.Element Msg
        spanView s =
            let
                items =
                    Tr.items s
            in
            E.column [ E.padding 0, E.width E.fill ]
                [ E.row [ E.spacing 7 ]
                    [ RU.text [ EF.color gray2, EF.light ] (Tr.id s)
                    , RU.text [ EF.color gray3 ] (Tr.spanDuration False s)
                    ]
                , if List.isEmpty items then
                    E.none

                  else
                    E.column [ E.paddingEach { edges | top = 5 } ]
                        (List.map spanItemView items)
                ]
    in
    E.column
        [ RU.style "position" "fixed"
        , RU.style "bottom" "-1px"
        , RU.style "left" "299px"
        , RU.style "width" "auto"
        , EB.width 1
        , EB.color black
        , E.spacing 10
        , Bg.color white
        , EF.light

        -- TODO: make this device width dependent
        , E.height (E.fill |> E.maximum 700)
        , E.width (E.fill |> E.maximum 900)
        ]
        [ E.row
            [ Bg.color gray6
            , E.padding 10
            , EB.color black
            , E.width E.fill
            , EB.widthEach { edges | bottom = 1 }
            , E.spacing 20
            ]
            [ E.text (tr.id ++ " (" ++ Tr.spanDuration False tr.first ++ ")")
            , RU.text
                [ EF.light
                , EF.color gray2
                , E.pointer
                , E.alignRight
                , EE.onClick (SMsg (Select step.idx))
                ]
                "close"
            ]
        , E.el
            [ E.scrollbars
            , E.height E.fill
            , E.width E.fill
            , E.paddingEach { edges | right = 20 }
            , EF.size 16
            , EF.family [ EF.monospace ]
            ]
            (E.el
                [ E.width E.fill
                , E.height E.fill
                , E.paddingEach { edges | left = 10, right = 10, bottom = 10 }
                ]
                (spanView tr.first)
            )
        ]


onSel : (Selection -> Selection) -> Model -> Model
onSel f m =
    { m | selection = f m.selection }


upSel : SMsg -> Model -> ( Model, Cmd Msg )
upSel msg m =
    case msg of
        Select idx ->
            -- expected behaviour here:
            -- - some items have trace, some do not
            -- - some items have data,  some do not
            -- - if an item with has no data, when we select it, trace view should open
            -- - if an item has data, when selected, current trace view should be
            --   preserved
            let
                r =
                    Array.get idx m.tests
                        |> Maybe.andThen .data
                        |> Maybe.map render
                        |> Maybe.withDefault Cmd.none
                        |> (\c -> ( Just idx, m.selection.showTrace, c ))

                ( selected, showTrace, cmd ) =
                    case m.selection.selected of
                        Just cur ->
                            if cur == idx then
                                case Array.get idx m.tests |> Maybe.andThen .data of
                                    Just _ ->
                                        ( Just idx, not m.selection.showTrace, Cmd.none )

                                    Nothing ->
                                        ( Nothing, not m.selection.showTrace, Cmd.none )

                            else
                                case Array.get idx m.tests |> Maybe.andThen .data of
                                    Just _ ->
                                        r

                                    Nothing ->
                                        ( Just idx, True, Cmd.none )

                        Nothing ->
                            case Array.get idx m.tests |> Maybe.andThen .data of
                                Just _ ->
                                    r

                                Nothing ->
                                    ( Just idx, True, Cmd.none )
            in
            ( onSel (\s -> { s | selected = selected, showTrace = showTrace }) m, cmd )

        UnSelect ->
            ( onSel (\s -> { s | selected = Nothing }) m, Cmd.none )


dialog : Model -> E.Element Msg
dialog m =
    case
        ( m.selection.selected |> Maybe.andThen (\s -> Array.get s m.tests)
        , m.selection.showTrace
        )
    of
        ( Just step, True ) ->
            case step.trace of
                Just tr ->
                    traceView m step tr

                Nothing ->
                    E.none

        _ ->
            E.none


isPass : StepWithResults -> Bool
isPass t =
    t.results
        |> List.filter (\r -> not (R.isPass r))
        |> List.length
        |> (\c -> c == 0)


green =
    E.rgb255 57 117 70


red =
    E.rgb255 203 64 57


black =
    E.rgb255 0 0 0


white =
    E.rgb255 255 255 255


gray0 : E.Color
gray0 =
    E.rgb255 34 37 42


gray1 : E.Color
gray1 =
    E.rgb255 53 58 63


gray2 : E.Color
gray2 =
    E.rgb255 74 80 86


gray3 : E.Color
gray3 =
    E.rgb255 135 142 149


gray4 : E.Color
gray4 =
    E.rgb255 174 181 188


gray5 : E.Color
gray5 =
    E.rgb255 207 212 217


gray6 : E.Color
gray6 =
    E.rgb255 223 226 230


codeBG : E.Color
codeBG =
    E.rgb255 43 48 59


gray7 : E.Color
gray7 =
    E.rgb255 234 236 239


gray8 : E.Color
gray8 =
    E.rgb255 241 243 245


gray9 : E.Color
gray9 =
    E.rgb255 248 249 250


status : Model -> E.Element Msg
status m =
    let
        total =
            String.fromInt (Array.length m.tests)

        fails =
            m.tests |> Array.filter (\r -> not (isPass r)) |> Array.length

        failed =
            fails /= 0

        ( t, c ) =
            case m.current of
                Just i ->
                    if i == -1 then
                        ( "Starting..", black )

                    else
                        ( String.fromInt i ++ " of " ++ total
                        , RU.yesno failed red black
                        )

                Nothing ->
                    if failed then
                        ( "Failed " ++ String.fromInt fails ++ " of " ++ total, red )

                    else
                        ( "Passed " ++ total, green )

        border =
            if m.errorOnly then
                EB.widthEach { edges | bottom = 1 }

            else
                EB.width 0
    in
    E.row [ E.padding 5, E.width E.fill, border ]
        [ E.paragraph [] [ E.text (m.title ++ " Tests") ]
        , RU.text [ EF.color c, E.alignRight, EF.size 16 ] t
        ]


stepTitle : Step -> String
stepTitle s =
    case s of
        Comment c ->
            c

        Navigate ( p, id ) _ ->
            p ++ ":" ++ id

        NavigateS ( p, id ) _ _ ->
            p ++ ":" ++ id

        Submit ( p, id ) _ ->
            p ++ ":" ++ id

        SubmitForm ( p, id ) _ ->
            p ++ ":" ++ id

        SubmitFormS ( p, id ) _ _ ->
            p ++ ":" ++ id

        SubmitS ( p, id ) _ _ ->
            p ++ ":" ++ id

        FormError id _ _ ->
            "FormError:" ++ id

        FormErrorS ( id, _ ) _ _ ->
            "FormError:" ++ id

        ApiError id _ _ ->
            "ApiError:" ++ id

        ApiErrorS ( id, _ ) _ _ ->
            "ApiErrorS:" ++ id

        Api id _ _ ->
            "Api:" ++ id

        ApiS ( id, _ ) _ _ ->
            "ApiS:" ++ id


resultView : Model -> R.TestResult -> E.Element Msg
resultView _ r =
    let
        p =
            \t ->
                E.paragraph
                    [ E.paddingEach { bottom = 3, left = 15, right = 5, top = 4 }
                    , EF.light
                    , EF.size 14
                    , EF.color (yesno (R.isPass r) black red)
                    ]
                    [ E.text <| "> " ++ t ]
    in
    case r of
        R.Started _ ->
            E.none

        R.TestDone ->
            E.none

        R.UpdateContext lst ->
            ("UpdateContext: " ++ String.join "," (List.map Tuple.first lst))
                |> p

        _ ->
            p (Debug.toString r)


stepView : Model -> StepWithResults -> E.Element Msg
stepView m step =
    let
        title =
            "- " ++ stepTitle step.step

        bg =
            if Just step.idx == m.selection.selected then
                Bg.color gray6

            else
                Bg.color white

        badge =
            E.row [ E.spacing 5 ]
                [ case step.data of
                    Just _ ->
                        RU.text [ E.alpha 0.7 ] "👁️"

                    Nothing ->
                        E.none
                , case step.trace of
                    Just tr ->
                        E.text (Tr.spanDuration True tr.first)

                    Nothing ->
                        E.none
                ]

        regular =
            E.textColumn [ E.width E.fill, EE.onClick (SMsg (Select step.idx)), bg ] <|
                E.row []
                    [ E.paragraph [ E.pointer, E.paddingXY 5 3, EF.light ]
                        [ E.text title ]
                    , E.el
                        [ EF.size 14
                        , EF.light
                        , E.alignRight
                        , E.alignTop
                        , EF.color gray3
                        , E.paddingEach { edges | right = 8, top = 7 }
                        ]
                        badge
                    ]
                    :: List.map (resultView m) step.results
    in
    case step.step of
        Comment c ->
            RU.text
                [ E.width E.fill
                , EB.widthXY 0 1
                , E.paddingXY 10 5
                , EF.size 14
                , EF.light
                , EB.color gray3
                , EF.alignRight
                ]
                c

        _ ->
            regular


singleTest : Model -> StepWithResults -> List (E.Element Msg)
singleTest m step =
    let
        sv =
            stepView m step

        testHead : String -> E.Element Msg
        testHead title =
            E.paragraph
                [ E.paddingEach { bottom = 3, left = 5, right = 5, top = 4 }
                , EB.widthEach { edges | top = 1 }
                ]
                [ E.text title ]
    in
    case step.first of
        Just first ->
            [ testHead first.id, sv ]

        Nothing ->
            [ sv ]


listOfTests : Model -> E.Element Msg
listOfTests m =
    filterErrorOnly m
        |> Array.toList
        |> List.map (singleTest m)
        |> List.concat
        |> E.column [ E.width E.fill ]


filterErrorOnly : Model -> Array StepWithResults
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
        |> R.timeIt (R.tid "test-subscriptions")


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
    -> Array StepWithResults
flatten lst =
    let
        f : Test -> List StepWithResults
        f t =
            let
                r : Int -> Step -> StepWithResults
                r idx step =
                    let
                        first =
                            if idx == 0 then
                                Just { id = t.id, context = t.context }

                            else
                                Nothing
                    in
                    { first = first
                    , step = step
                    , results = []
                    , trace = Nothing
                    , data = Nothing
                    , idx = -1
                    }
            in
            List.indexedMap r t.steps

        indexIt : Int -> StepWithResults -> StepWithResults
        indexIt i s =
            { s | idx = i }
    in
    lst
        |> List.map f
        |> List.concat
        |> List.indexedMap indexIt
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


render : JE.Value -> Cmd Msg
render v =
    JE.object [ ( "action", JE.string "render" ), ( "data", v ) ] |> toIframe


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


apiError :
    String
    -> List FormErrorAssertion
    -> ( JD.Decoder a, String, Maybe JE.Value )
    -> Step
apiError id assertions ( _, s, mv ) =
    ApiError id assertions ( s, mv )


apiErrorS :
    ( String, String )
    -> List FormErrorAssertion
    -> (String -> ( String, Maybe JE.Value ))
    -> Step
apiErrorS ( id, key ) assertions f =
    ApiErrorS ( id, key ) assertions f


api :
    String
    -> List (a -> JE.Value -> R.TestResult)
    -> ( JD.Decoder a, String, Maybe JE.Value )
    -> Step
api id assertions ( dec, s, mv ) =
    let
        runner : JE.Value -> JE.Value -> List R.TestResult
        runner av ctx =
            case JD.decodeValue dec av of
                Ok a ->
                    List.map (\f -> f a ctx) assertions ++ [ R.TestDone ]

                Err e ->
                    [ R.TestFailed id (Debug.toString e), R.TestDone ]
    in
    Api id runner ( s, mv )


apiS :
    ( String, String )
    -> List (a -> JE.Value -> R.TestResult)
    -> ( JD.Decoder a, String -> ( String, Maybe JE.Value ) )
    -> Step
apiS ( id, key ) assertions ( dec, fn ) =
    let
        runner : JE.Value -> JE.Value -> List R.TestResult
        runner av ctx =
            case JD.decodeValue dec av of
                Ok a ->
                    List.map (\f -> f a ctx) assertions ++ [ R.TestDone ]

                Err e ->
                    [ R.TestFailed id (Debug.toString e), R.TestDone ]
    in
    ApiS ( id, key ) runner fn


apiOk : String -> ( JD.Decoder (), String, Maybe JE.Value ) -> Step
apiOk id params =
    api id [ \_ _ -> R.TestPassed "Ok" ] params


apiTrue : String -> ( JD.Decoder Bool, String, Maybe JE.Value ) -> Step
apiTrue id params =
    api id [ RU.true2 "got-true" ] params


apiFalse : String -> ( JD.Decoder Bool, String, Maybe JE.Value ) -> Step
apiFalse id params =
    api id [ RU.false2 "got-false" ] params


only : String -> String -> List FormErrorAssertion
only key val =
    [ ExactError key val, TotalErrors 1 ]
