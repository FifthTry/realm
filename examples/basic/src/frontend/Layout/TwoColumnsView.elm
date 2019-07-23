module Widget.Layout.TwoColumnsView exposing (Config, Model, Msg(..), config, init, subscriptions, update, view, widget)

import Data.Engine as DE exposing (LayoutRequest, Widget)
import Helpers.Engine as HE
import Helpers.Utils exposing (map3First, map3Second, orCrash3)
import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))
import Json.Encode as JE
import Realm as R exposing (Node)
import Realm.Elements as E
import Realm.Layout as L
import Style as C


-- config


type alias Config =
    { header : DE.WidgetSpec
    , left : List DE.WidgetSpec
    , right : List DE.WidgetSpec
    , lower : List DE.WidgetSpec
    , footer : DE.WidgetSpec
    }


config : JD.Decoder Config
config =
    JD.list JD.value
        |> JD.andThen
            (\l ->
                case l of
                    [ h, c1, c2, c3, c4, c5, c6, c7, c8, vfw, f ] ->
                        case
                            ( JD.decodeValue DE.widgetSpec h
                            , JD.decodeValue (JD.list DE.widgetSpec) <| JE.list [ c1, c2, c3, c4 ]
                            , JD.decodeValue (JD.list DE.widgetSpec) <| JE.list [ c5, c6, c7, c8 ]
                            , JD.decodeValue (JD.list DE.widgetSpec) vfw
                            , JD.decodeValue DE.widgetSpec f
                            )
                        of
                            ( Ok h, Ok l, Ok r, Ok fw, Ok f ) ->
                                JD.succeed <| Config h l r fw f

                            _ ->
                                JD.fail "failed to decode different group of elements"

                    _ ->
                        JD.fail
                            ("more/less elements than needed(got "
                                ++ toString (List.length l)
                                ++ ", expected 16): "
                                ++ toString l
                            )
            )



-- model


type alias Model =
    { config : Config
    , header : DE.WidgetModel
    , left : List DE.WidgetModel
    , right : List DE.WidgetModel
    , lower : List DE.WidgetModel
    , footer : DE.WidgetModel
    }



-- init


init : Config -> ( Model, Cmd Msg, LayoutRequest )
init c =
    let
        ( h_s, h_c, h_l ) =
            HE.init c.header HeaderMsg

        ( l_s, l_c, l_l ) =
            HE.initList c.left LeftMsg

        ( r_s, r_c, r_l ) =
            HE.initList c.right RightMsg

        ( o_s, o_c, o_l ) =
            HE.initList c.lower LowerMsg

        ( f_s, f_c, f_l ) =
            HE.init c.footer FooterMsg
    in
    ( { config = c
      , header = h_s
      , left = l_s
      , right = r_s
      , lower = o_s
      , footer = f_s
      }
    , Cmd.batch [ h_c, l_c, r_c, o_c, f_c ]
    , HE.batchLR [ h_l, l_l, r_l, o_l, f_l ]
    )



-- update


type Msg
    = HeaderMsg DE.WidgetMsg
    | LeftMsg Int DE.WidgetMsg
    | RightMsg Int DE.WidgetMsg
    | LowerMsg Int DE.WidgetMsg
    | FooterMsg DE.WidgetMsg


update : Msg -> Model -> ( Model, Cmd Msg, LayoutRequest )
update msg m =
    case msg of
        HeaderMsg imsg ->
            HE.update m.config.header imsg m.header HeaderMsg
                |> map3First (\um -> { m | header = um })

        LeftMsg i imsg ->
            HE.updateList m.config.left imsg m.left i LeftMsg
                |> map3First (\um -> { m | left = um })

        RightMsg i imsg ->
            HE.updateList m.config.right imsg m.right i RightMsg
                |> map3First (\um -> { m | right = um })

        LowerMsg i imsg ->
            HE.updateList m.config.lower imsg m.lower i LowerMsg
                |> map3First (\um -> { m | lower = um })

        FooterMsg imsg ->
            HE.update m.config.footer imsg m.footer FooterMsg
                |> map3First (\um -> { m | footer = um })



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions m =
    HE.subscriptions (m.config.header :: m.config.footer :: (m.config.left ++ m.config.right ++ m.config.lower))
        (( HeaderMsg, m.header )
            :: ( FooterMsg, m.footer )
            :: (List.indexedMap (\i c -> ( LeftMsg i, c )) m.left
                    ++ List.indexedMap (\i c -> ( RightMsg i, c )) m.right
                    ++ List.indexedMap (\i c -> ( LowerMsg i, c )) m.lower
               )
        )



-- view


view : Model -> Node Msg
view m =
    L.column_ C.wrapper
        [ L.column C.contentWrapper
            []
            [ HE.view m.config.header m.header HeaderMsg
            , L.row_ C.mainPage
                [ L.column_ C.page
                    [ L.column_ C.pageWrapper2
                        [ E.scrollView
                            [ R.style C.componentWrapper2 ]
                            [ L.row_ []
                                [ L.column_ C.pageWrapper2Left
                                    (HE.viewList m.config.left m.left LeftMsg)
                                , L.column_ C.pageWrapper2Right
                                    (HE.viewList m.config.right m.right RightMsg)
                                ]
                            , L.column_ []
                                (HE.viewList m.config.lower m.lower LowerMsg)
                            ]
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
