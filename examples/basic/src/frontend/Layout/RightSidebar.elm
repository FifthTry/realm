module Widget.Layout.RightSidebar exposing (Config, Model, Msg(..), config, init, subscriptions, update, view, widget)

import Data.Engine as DE exposing (LayoutRequest, Widget)
import Helpers.Engine as HE
import Helpers.Utils exposing (map3First, map3Second)
import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))
import Realm as R exposing (Node)
import Realm.Elements as E
import Realm.Layout as L
import Style as C


-- config


type alias Config =
    { header : DE.WidgetSpec
    , sidebar : List DE.WidgetSpec
    , mainbar : List DE.WidgetSpec
    , footer : DE.WidgetSpec
    }


config : JD.Decoder Config
config =
    JD.list DE.widgetSpec
        |> JD.andThen
            (\l ->
                case l of
                    [ h, m1, m2, m3, m4, m5, m6, m7, m8, s1, s2, s3, s4, s5, s6, s7, s8, f, _, _, _ ] ->
                        Config h [ s1, s2, s3, s4, s5, s6, s7, s8 ] [ m1, m2, m3, m4, m5, m6, m7, m8 ] f
                            |> JD.succeed

                    _ ->
                        Debug.crash
                            ("more/less elements than needed(got "
                                ++ toString (List.length l)
                                ++ ", expected 21): "
                                ++ toString l
                            )
            )



-- model


type alias Model =
    { config : Config
    , header : DE.WidgetModel
    , sidebar : List DE.WidgetModel
    , mainbar : List DE.WidgetModel
    , footer : DE.WidgetModel
    }



-- init


init : Config -> ( Model, Cmd Msg, LayoutRequest )
init c =
    let
        ( h_s, h_c, h_l ) =
            HE.init c.header HeaderMsg

        ( l_s, l_c, l_l ) =
            HE.initList c.sidebar SidebarMsg

        ( r_s, r_c, r_l ) =
            HE.initList c.mainbar MainbarMsg

        ( f_s, f_c, f_l ) =
            HE.init c.footer FooterMsg
    in
    ( { config = c
      , header = h_s
      , sidebar = l_s
      , mainbar = r_s
      , footer = f_s
      }
    , Cmd.batch [ h_c, l_c, r_c, f_c ]
    , HE.batchLR [ h_l, l_l, r_l, f_l ]
    )



-- update


type Msg
    = HeaderMsg DE.WidgetMsg
    | SidebarMsg Int DE.WidgetMsg
    | MainbarMsg Int DE.WidgetMsg
    | FooterMsg DE.WidgetMsg


update : Msg -> Model -> ( Model, Cmd Msg, LayoutRequest )
update msg m =
    case msg of
        HeaderMsg imsg ->
            HE.update m.config.header imsg m.header HeaderMsg
                |> map3First (\um -> { m | header = um })

        SidebarMsg i imsg ->
            HE.updateList m.config.sidebar imsg m.sidebar i SidebarMsg
                |> map3First (\um -> { m | sidebar = um })

        MainbarMsg i imsg ->
            HE.updateList m.config.mainbar imsg m.mainbar i MainbarMsg
                |> map3First (\um -> { m | mainbar = um })

        FooterMsg imsg ->
            HE.update m.config.footer imsg m.footer FooterMsg
                |> map3First (\um -> { m | footer = um })



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions m =
    HE.subscriptions (m.config.header :: m.config.footer :: (m.config.sidebar ++ m.config.mainbar))
        (( HeaderMsg, m.header )
            :: ( FooterMsg, m.footer )
            :: (List.indexedMap (\i c -> ( SidebarMsg i, c )) m.sidebar
                    ++ List.indexedMap (\i c -> ( MainbarMsg i, c )) m.mainbar
               )
        )



-- view


view : Model -> Node Msg
view m =
    L.row_ C.wrapper
        [ L.column C.contentWrapper
            []
            [ HE.view m.config.header m.header HeaderMsg
            , L.row_ C.mainPage
                ([ L.column_ C.page
                    [ L.column_ C.pageWrapperSideWrapper
                        [ E.scrollView
                            [ R.style C.componenSideBarWrapper ]
                            (HE.viewList m.config.mainbar m.mainbar MainbarMsg)
                        ]
                    ]
                 ]
                    ++ HE.viewList m.config.sidebar m.sidebar SidebarMsg
                )
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
