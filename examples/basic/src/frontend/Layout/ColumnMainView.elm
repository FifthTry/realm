module Widget.Layout.ColumnMainView exposing (Config, Model, Msg(..), config, init, subscriptions, update, view, widget)

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
    , left : List DE.WidgetSpec
    , mainLeft : List DE.WidgetSpec
    , mainRight : List DE.WidgetSpec
    , right : List DE.WidgetSpec
    , footer : DE.WidgetSpec
    }


config : JD.Decoder Config
config =
    JD.list DE.widgetSpec
        |> JD.andThen
            (\l ->
                case l of
                    [ h, s1, s2, s3, s4, m1, m2, m3, m4, m5, m6, m7, m8, s5, s6, s7, s8, f, _, _, _ ] ->
                        Config h [ s1, s2, s3, s4 ] [ m1, m2, m3, m4 ] [ m5, m6, m7, m8 ] [ s5, s6, s7, s8 ] f
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
    , left : List DE.WidgetModel
    , mainLeft : List DE.WidgetModel
    , mainRight : List DE.WidgetModel
    , right : List DE.WidgetModel
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

        ( ml_s, ml_c, ml_l ) =
            HE.initList c.mainLeft MainLeftMsg

        ( mr_s, mr_c, mr_l ) =
            HE.initList c.mainRight MainRightMsg

        ( r_s, r_c, r_l ) =
            HE.initList c.right RightMsg

        ( f_s, f_c, f_l ) =
            HE.init c.footer FooterMsg
    in
    ( { config = c
      , header = h_s
      , left = l_s
      , mainLeft = ml_s
      , mainRight = mr_s
      , right = r_s
      , footer = f_s
      }
    , Cmd.batch [ h_c, l_c, r_c, ml_c, mr_c, f_c ]
    , HE.batchLR [ h_l, l_l, r_l, ml_l, mr_l, f_l ]
    )



-- update


type Msg
    = HeaderMsg DE.WidgetMsg
    | LeftMsg Int DE.WidgetMsg
    | MainLeftMsg Int DE.WidgetMsg
    | MainRightMsg Int DE.WidgetMsg
    | RightMsg Int DE.WidgetMsg
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

        MainLeftMsg i imsg ->
            HE.updateList m.config.mainLeft imsg m.mainLeft i MainLeftMsg
                |> map3First (\um -> { m | mainLeft = um })

        MainRightMsg i imsg ->
            HE.updateList m.config.mainRight imsg m.mainRight i MainRightMsg
                |> map3First (\um -> { m | mainRight = um })

        RightMsg i imsg ->
            HE.updateList m.config.right imsg m.right i RightMsg
                |> map3First (\um -> { m | right = um })

        FooterMsg imsg ->
            HE.update m.config.footer imsg m.footer FooterMsg
                |> map3First (\um -> { m | footer = um })



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions m =
    HE.subscriptions (m.config.header :: m.config.footer :: (m.config.left ++ m.config.mainLeft ++ m.config.mainRight ++ m.config.right))
        (( HeaderMsg, m.header )
            :: ( FooterMsg, m.footer )
            :: (List.indexedMap (\i c -> ( LeftMsg i, c )) m.left
                    ++ List.indexedMap (\i c -> ( MainLeftMsg i, c )) m.mainLeft
                    ++ List.indexedMap (\i c -> ( MainRightMsg i, c )) m.mainRight
                    ++ List.indexedMap (\i c -> ( RightMsg i, c )) m.right
               )
        )



-- view


view : Model -> Node Msg
view m =
    L.row_ C.columnOuterWrapper
        [ L.column C.contentWrapper
            []
            [ HE.view m.config.header m.header HeaderMsg
            , L.row_ C.mainPage
                [ L.column_ C.page
                    [ L.row_ C.columnWrapper
                        [ E.scrollView
                            [ R.style C.columnWidgetWrapper ]
                            [ L.column_ [] <|
                                HE.viewList m.config.left m.left LeftMsg
                            , L.column_ [] <|
                                HE.viewList m.config.mainLeft m.mainLeft MainLeftMsg
                            , L.column_ [] <|
                                HE.viewList m.config.mainRight m.mainRight MainRightMsg
                            , L.column_ [] <|
                                HE.viewList m.config.right m.right RightMsg
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
