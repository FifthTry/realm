port module Realm.Storybook exposing (Story, app)

import Browser as B
import Browser.Events as BE
import Element as E
import Element.Background as Bg
import Element.Border as EB
import Element.Events as EE
import Element.Font as EF
import Element.Keyed as EK
import Html as H
import Html.Attributes as HA
import Json.Encode as JE
import Realm.Ports exposing (resize, toIframe)
import Realm.Utils as U


edges : { top : Int, right : Int, bottom : Int, left : Int }
edges =
    { top = 0, right = 0, bottom = 0, left = 0 }


type alias Story =
    { title : String
    , pageTitle : String
    , id : String
    , elmId : String
    , config : JE.Value
    }


type alias Model =
    { current : Maybe ( String, String ) -- index id, story id
    , config : Config
    , device : E.Device
    }


type alias Config =
    { stories : List ( String, List Story )
    , title : String
    }


type Msg
    = Navigate String String
    | NoOp
    | SetDevice E.Device


mobile : E.Device
mobile =
    { class = E.Phone, orientation = E.Portrait }


desktop : E.Device
desktop =
    { class = E.Desktop, orientation = E.Landscape }


init : Config -> () -> url -> key -> ( Model, Cmd Msg )
init config _ _ _ =
    ( { current = Nothing, config = config, device = desktop }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg m =
    case Debug.log "Design.msg" ( msg, m.current ) of
        ( Navigate sid pid, _ ) ->
            ( { m | current = Just ( sid, pid ) }
            , getStory m.config.stories sid pid
                |> Maybe.map render
                |> Maybe.withDefault Cmd.none
            )

        ( NoOp, _ ) ->
            ( m, Cmd.none )

        ( SetDevice d, Just ( sid, pid ) ) ->
            ( { m | device = d }
            , Cmd.batch
                [ resize ()
                , getStory m.config.stories sid pid
                    |> Maybe.map render
                    |> Maybe.withDefault Cmd.none
                ]
            )

        ( SetDevice _, Nothing ) ->
            ( m, Cmd.none )


getStory : List ( String, List Story ) -> String -> String -> Maybe Story
getStory stories sid pid =
    List.filter (\( i, _ ) -> i == sid) stories
        |> List.head
        |> Maybe.andThen (\( _, ls ) -> List.filter (\s -> s.id == pid) ls |> List.head)


document : Model -> B.Document Msg
document m =
    { title = m.config.title ++ " Storybook", body = [ E.layout [] (view m) ] }


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
                [ E.text <| m.config.title ++ " Storybook" ]
            , listOfStories m
            ]
        , EK.el [ E.height E.fill, iframeWidth m, E.centerX, E.centerY ] <|
            U.yesno (m.current == Nothing) ( "intro", intro m ) <|
                ( "iframe"
                , E.html
                    (H.node "iframe"
                        [ HA.style "width" "100%"

                        -- , HA.style "height" "100%"
                        , HA.style "border" "none"
                        , HA.src "/iframe/"
                        ]
                        []
                    )
                )
        ]


iframeWidth : Model -> E.Attribute Msg
iframeWidth m =
    if m.device == desktop then
        E.width E.fill

    else
        E.width <| E.px 414


intro : Model -> E.Element Msg
intro m =
    E.column [ E.centerX, E.centerY ]
        [ E.paragraph [ EF.center, E.padding 10, EF.light, EF.size 14 ] <|
            [ E.text "Welcome to," ]
        , E.paragraph [ EF.center ] <| [ E.text <| m.config.title ++ " Storybook" ]
        , E.paragraph [ EF.center, E.paddingXY 0 40, EF.light, EF.size 14, EF.italic ] <|
            [ E.text "Select an item in left menu bar" ]
        ]


storyView : String -> Model -> Story -> E.Element Msg
storyView sid m s =
    if Just ( sid, s.id ) == m.current then
        E.textColumn [ E.width E.fill ]
            [ E.paragraph
                [ EE.onClick (Navigate sid s.id)
                , E.paddingXY 5 3
                , EF.light
                , EF.regular
                , Bg.color <| E.rgb 0.93 0.93 0.93
                ]
                [ E.text <| "- " ++ s.title ]
            , E.paragraph [ E.pointer ]
                [ E.el
                    [ E.paddingEach { edges | right = 10, left = 10 }
                    , EE.onClick (SetDevice mobile)
                    ]
                  <|
                    E.text <|
                        "mobile"
                            ++ U.yesno (m.device == mobile) "*" ""
                , E.el [ EE.onClick (SetDevice desktop) ] <|
                    E.text <|
                        "desktop"
                            ++ U.yesno (m.device == desktop) "*" ""
                ]
            ]

    else
        E.paragraph [ EE.onClick (Navigate sid s.id), E.pointer, E.paddingXY 5 3, EF.light ]
            [ E.text <| "- " ++ s.title ]


storySection : Model -> ( String, List Story ) -> E.Element Msg
storySection m ( sid, slist ) =
    E.column [ EB.widthEach { bottom = 1, left = 0, right = 0, top = 0 }, E.width E.fill ] <|
        E.paragraph [ E.paddingEach { bottom = 3, left = 5, right = 5, top = 4 } ]
            [ E.text sid ]
            :: List.map (storyView sid m) slist


listOfStories : Model -> E.Element Msg
listOfStories m =
    E.column [ E.width E.fill ] <| List.map (storySection m) m.config.stories


subscriptions : Model -> Sub Msg
subscriptions _ =
    BE.onResize (always (always NoOp))


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
        , ( "id", JE.string s.elmId )
        , ( "config", s.config )
        , ( "title", JE.string s.pageTitle )
        ]
        |> toIframe
