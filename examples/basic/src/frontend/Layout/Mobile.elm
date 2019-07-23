module Widget.Layout.Mobile exposing (Config, Model, Msg(..), config, init, subscriptions, update, view, widget)

import Data.Engine as DE exposing (LayoutRequest, Widget)
import Helpers.Engine as HE
import Helpers.Utils exposing (map3Second)
import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))
import Realm as R exposing (Node)
import Realm.Elements as E
import Realm.Layout as L
import Style as C


-- config


type alias Config =
    { header : DE.WidgetSpec
    , children : List DE.WidgetSpec
    , footer : DE.WidgetSpec
    }


config : JD.Decoder Config
config =
    JD.succeed Config
        |: JD.field "header" DE.widgetSpec
        |: JD.field "children" (JD.list DE.widgetSpec)
        |: JD.field "footer" DE.widgetSpec



-- model


type alias Model =
    { config : Config
    , header : DE.WidgetModel
    , children : List DE.WidgetModel
    , footer : DE.WidgetModel
    }



-- init


init : Config -> ( Model, Cmd Msg, LayoutRequest )
init c =
    let
        ( h, c_h, lo_h ) =
            HE.init c.header HeaderMsg

        ( f, c_f, lo_f ) =
            HE.init c.footer FooterMsg

        ( cs, c_c, lo_c ) =
            HE.initList c.children ChildMsg
    in
    ( { config = c, header = h, footer = f, children = cs }
    , Cmd.batch [ c_h, c_f, c_c ]
    , HE.batchLR [ lo_h, lo_c, lo_f ]
    )



-- update


type Msg
    = HeaderMsg DE.WidgetMsg
    | FooterMsg DE.WidgetMsg
    | ChildMsg Int DE.WidgetMsg


update : Msg -> Model -> ( Model, Cmd Msg, LayoutRequest )
update msg m =
    case msg of
        HeaderMsg imsg ->
            let
                ( h, c, lr ) =
                    HE.update m.config.header imsg m.header HeaderMsg
            in
            ( { m | header = h }, c, lr )

        FooterMsg imsg ->
            let
                ( f, c, lr ) =
                    HE.update m.config.footer imsg m.footer FooterMsg
            in
            ( { m | footer = f }, c, lr )

        ChildMsg i imsg ->
            let
                ( cs, c, lr ) =
                    HE.updateList m.config.children imsg m.children i ChildMsg
            in
            ( { m | children = cs }, c, lr )



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions m =
    HE.subscriptions (m.config.header :: m.config.footer :: m.config.children)
        (( HeaderMsg, m.header )
            :: ( FooterMsg, m.footer )
            :: List.indexedMap (\i c -> ( ChildMsg i, c )) m.children
        )



-- view


view : Model -> Node Msg
view m =
    L.row_ C.wrapper
        [ L.column C.contentWrapper
            []
            [ HE.view m.config.header m.header HeaderMsg
            , L.row_ C.mainPage
                [ E.dummy -- Sidebar comes here
                , L.column_ C.page
                    [ L.column_ C.pageWrapper2
                        [ E.dummy -- ActionBar comes here
                        , E.scrollView
                            [ R.style C.componentWrapper2 ]
                            (HE.viewList m.config.children m.children ChildMsg)
                        ]
                    ]
                ]
            , HE.view m.config.footer m.footer FooterMsg
            ]
        ]



-- boilerplate


widget : Widget Config Model Msg
widget =
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    , decoder = config
    , values = \_ -> []
    }
