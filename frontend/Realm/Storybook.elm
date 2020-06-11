module Realm.Storybook exposing (Story, app)

import Array exposing (Array)
import Browser as B
import Browser.Events as BE
import Browser.Navigation as BN
import Element as E
import Element.Background as Bg
import Element.Border as EB
import Element.Events as EE
import Element.Font as EF
import Element.Keyed as EK
import Html as H
import Html.Attributes as HA
import Http
import Json.Decode as JD
import Json.Encode as JE
import Process
import Realm.Ports as RP
import Realm.Utils as RU exposing (edges)
import Task
import Tuple
import Url exposing (Url)
import Url.Parser exposing ((</>), (<?>))
import Url.Parser.Query as Q


type alias Story =
    { title : String
    , pageTitle : String
    , id : String
    , elmId : String
    , config : JE.Value
    }


type alias Model =
    { current : Maybe Int
    , device : E.Device
    , key : BN.Key
    , hash : Maybe String
    , hideSidebar : Bool
    , stories : Array ( String, Story )
    , title : String
    }


type alias Config =
    { stories : List ( String, List Story )
    , title : String
    }


type Msg
    = Navigate Int
    | NoOp
    | SetDevice E.Device
    | Reset
    | GotHash (Result Http.Error String)
    | AfterPollError
    | ToggleSidebar
    | OnKey String


mobile : E.Device
mobile =
    { class = E.Phone, orientation = E.Portrait }


desktop : E.Device
desktop =
    { class = E.Desktop, orientation = E.Landscape }


init : Config -> () -> Url -> BN.Key -> ( Model, Cmd Msg )
init config _ url key =
    let
        toSidebar : Bool
        toSidebar =
            (Url.Parser.s "storybook" <?> Q.string "sidebar")
                |> (\p -> Url.Parser.parse p url)
                |> Maybe.withDefault Nothing
                |> Maybe.map (\d -> d == "hide")
                |> Maybe.withDefault False

        toDevice : E.Device
        toDevice =
            (Url.Parser.s "storybook" <?> Q.string "device")
                |> (\p -> Url.Parser.parse p url)
                |> Maybe.withDefault Nothing
                |> Maybe.map (\d -> RU.yesno (d == "desktop") desktop mobile)
                |> Maybe.withDefault desktop

        toCurrent : Maybe Int
        toCurrent =
            (Url.Parser.s "storybook" <?> Q.int "current")
                |> (\p -> Url.Parser.parse p url)
                |> Maybe.withDefault Nothing

        stories =
            flatten config.stories

        m =
            { current = toCurrent
            , title = config.title
            , device = toDevice
            , key = key
            , hash = Nothing
            , hideSidebar = toSidebar
            , stories = stories
            }
    in
    ( m
    , Cmd.batch
        [ Cmd.none -- TODO: bring this back: poll "empty"
        , m.current
            |> Maybe.andThen (\idx -> Array.get idx stories)
            |> Maybe.map Tuple.second
            |> Maybe.map render
            |> Maybe.withDefault Cmd.none
        ]
    )


poll : String -> Cmd Msg
poll hash =
    Http.get
        { url = "/storybook/poll/?hash=" ++ Url.percentEncode hash
        , expect = Http.expectString GotHash
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg m =
    case Debug.log "Storybook.msg" ( msg, m.current ) of
        ( Navigate idx, _ ) ->
            let
                m2 =
                    { m | current = Just idx }
            in
            ( m2
            , m.stories
                |> Array.get idx
                |> Maybe.map Tuple.second
                |> Maybe.map render
                |> Maybe.withDefault Cmd.none
                |> updateUrl m2
            )

        ( NoOp, _ ) ->
            ( m, Cmd.none )

        ( Reset, _ ) ->
            let
                m2 =
                    { m | current = Nothing }
            in
            ( m2, updateUrl m2 Cmd.none )

        ( SetDevice d, Just idx ) ->
            update (Navigate idx) { m | device = d }

        ( SetDevice d, Nothing ) ->
            ( { m | device = d }, Cmd.none )

        ( GotHash (Ok hash), _ ) ->
            if m.hash == Nothing then
                ( { m | hash = Just hash }, poll hash )

            else if hash == "" then
                ( m, poll <| Maybe.withDefault "" m.hash )

            else
                ( m, BN.reloadAndSkipCache )

        ( GotHash (Err _), _ ) ->
            ( m, Process.sleep 1000 |> Task.perform (always AfterPollError) )

        ( AfterPollError, _ ) ->
            ( m, poll <| Maybe.withDefault "" m.hash )

        ( ToggleSidebar, Just idx ) ->
            update (Navigate idx) { m | hideSidebar = not m.hideSidebar }

        ( ToggleSidebar, Nothing ) ->
            ( m, Cmd.none )

        ( OnKey "r", _ ) ->
            update Reset m

        ( OnKey "d", _ ) ->
            if m.device == desktop then
                update (SetDevice mobile) m

            else
                update (SetDevice desktop) m

        ( OnKey "f", _ ) ->
            update ToggleSidebar m

        ( OnKey "j", Nothing ) ->
            goto 0 m

        ( OnKey "j", Just idx ) ->
            if idx == Array.length m.stories - 1 then
                update Reset m

            else
                goto (idx + 1) m

        ( OnKey "k", Just 0 ) ->
            update Reset m

        ( OnKey "k", Just idx ) ->
            goto (idx - 1) m

        ( OnKey "k", Nothing ) ->
            goto (Array.length m.stories - 1) m

        ( OnKey _, _ ) ->
            ( m, Cmd.none )


goto : Int -> Model -> ( Model, Cmd Msg )
goto idx m =
    let
        m2 =
            { m | current = Just idx }
    in
    m.stories
        |> Array.get idx
        |> Maybe.map Tuple.second
        |> Maybe.map render
        |> Maybe.map (updateUrl m2)
        |> Maybe.map (Tuple.pair m2)
        -- following must contain m and not m2 because if Array.get failed we do not
        -- want to update current
        |> Maybe.withDefault ( m, Cmd.none )


flatten : List ( String, List Story ) -> Array ( String, Story )
flatten lst =
    lst
        |> List.map (\( s, stories ) -> List.map (\story -> ( s, story )) stories)
        |> List.concat
        |> Array.fromList


document : Model -> B.Document Msg
document m =
    { title = m.title ++ " Storybook", body = [ E.layout [] (view m) ] }


view : Model -> E.Element Msg
view m =
    let
        iframeWidth : E.Attribute Msg
        iframeWidth =
            if m.device == desktop then
                E.width E.fill

            else
                E.width <| E.px 414

        intro : E.Element Msg
        intro =
            E.column []
                [ E.paragraph [ EF.center, E.padding 10, EF.light, EF.size 14 ] <|
                    [ E.text "Welcome to," ]
                , E.paragraph [ EF.center ] <| [ E.text <| m.title ++ " Storybook" ]
                , E.paragraph
                    [ EF.center, E.paddingXY 0 40, EF.light, EF.size 14, EF.italic ]
                  <|
                    [ E.text "Select an item in left menu bar" ]
                ]

        shortcuts : E.Element Msg
        shortcuts =
            E.column []
                [ E.text "Useful Keyboard Shortcuts"
                , E.text "j/k: move up or down"
                , E.text "d: toggle between mobile and desktop"
                , E.text "r: reset the view"
                , E.text "f: toggle full screen mode"
                ]

        welcome : E.Element Msg
        welcome =
            E.column [ E.centerX, E.centerY ] [ intro, shortcuts ]
    in
    E.row [ E.width E.fill, E.height E.fill, Bg.color (E.rgb 0.9 0.9 0.9) ]
        [ RU.yesno m.hideSidebar E.none (sidebar m)
        , EK.el
            [ E.height E.fill
            , iframeWidth
            , E.centerX
            , E.centerY
            , Bg.color (E.rgb 1 1 1)
            ]
          <|
            RU.yesno (m.current == Nothing) ( "welcome", welcome ) <|
                ( "iframe"
                , E.html
                    (H.node "iframe"
                        [ HA.style "width" "100%"
                        , HA.style "border" "none"
                        , HA.src "/iframe/"
                        ]
                        []
                    )
                )
        ]


sidebar : Model -> E.Element Msg
sidebar m =
    E.textColumn
        [ E.height E.fill
        , E.width (E.px 200)
        , EB.widthEach { edges | right = 1 }
        , Bg.color (E.rgb 1 1 1)
        ]
        [ E.row
            [ E.width E.fill, EB.widthEach { edges | bottom = 1 } ]
            [ E.paragraph [ E.padding 5, E.pointer, EE.onClick Reset ]
                [ E.text <| m.title ++ " Storybook" ]
            , RU.yesno (m.device == mobile) "📱" "🖥"
                |> RU.text
                    [ EF.size 16
                    , E.paddingEach { edges | right = 3 }
                    , E.pointer
                    , RU.yesno (m.device == mobile) desktop mobile
                        |> SetDevice
                        |> EE.onClick
                    ]
            ]
        , listOfStories m
        ]


storyView : Model -> Int -> Story -> E.Element Msg
storyView m idx s =
    E.paragraph
        [ EE.onClick (Navigate idx)
        , E.pointer
        , E.paddingXY 5 3
        , EF.light
        , E.alpha (RU.yesno (Just idx == m.current) 1 0.7)
        , RU.aif (Just idx == m.current) (Bg.color <| E.rgb 0.93 0.93 0.93)
        , E.width E.fill
        , EF.size 15
        ]
        [ E.text <| "- " ++ s.title ]


storyHead : String -> E.Element Msg
storyHead title =
    E.paragraph [ E.paddingEach { bottom = 3, left = 5, right = 5, top = 4 } ]
        [ E.text title ]


storySection :
    Model
    -> ( Int, ( String, Story ) )
    -> ( String, List (E.Element Msg) )
    -> ( String, List (E.Element Msg) )
storySection m ( idx, ( sid, story ) ) ( cur, body ) =
    let
        sv =
            storyView m idx story
    in
    if cur == sid then
        ( sid, body ++ [ sv ] )

    else
        ( sid, body ++ [ storyHead sid, sv ] )


listOfStories : Model -> E.Element Msg
listOfStories m =
    m.stories
        |> Array.toIndexedList
        |> List.foldl (storySection m) ( "", [] )
        |> Tuple.second
        |> E.column [ E.width E.fill ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ BE.onResize (always (always NoOp))
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
    JE.Value


render : Story -> Cmd msg
render s =
    JE.object
        [ ( "action", JE.string "render" )
        , ( "data"
          , JE.object
                [ ( "id", JE.string s.elmId )
                , ( "config", s.config )
                , ( "title", JE.string s.pageTitle )
                ]
          )
        ]
        |> RP.toIframe


updateUrl : Model -> Cmd Msg -> Cmd Msg
updateUrl m c =
    let
        u =
            "/storybook/?device="
                ++ RU.yesno (m.device == desktop) "desktop" "mobile"
                ++ (case m.current of
                        Just idx ->
                            "&current=" ++ String.fromInt idx

                        Nothing ->
                            ""
                   )
                ++ RU.yesno m.hideSidebar "&sidebar=hide" "&sidebar=show"
    in
    Cmd.batch [ c, BN.pushUrl m.key u ]
