module Widget.Layout.Grid exposing (..)

import Data.Engine as DE exposing (LayoutRequest, Widget)
import Helpers.Engine as HE
import Helpers.Utils exposing (map3Second)
import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))
import Realm as R exposing (Node)
import Realm.Elements as E
import Realm.Layout as L
import Realm.Style exposing (..)
import Style as C


-- config


type alias Gap =
    { both : Maybe String
    , column : Maybe String
    , row : Maybe String
    }


gap : JD.Decoder Gap
gap =
    JD.succeed Gap
        |: JD.maybe (JD.field "both" JD.string)
        |: JD.maybe (JD.field "column" JD.string)
        |: JD.maybe (JD.field "row" JD.string)


type alias Config =
    { area : List (List String)
    , children : List DE.WidgetSpec
    , columns : List String
    , rows : List String
    , gap : Gap
    , justifyContent : String
    , alignContent : String
    , backgroundColor : String
    , width : String
    , padding : List String
    }


config : JD.Decoder Config
config =
    JD.succeed Config
        |: JD.field "area" (JD.list (JD.list JD.string))
        |: JD.field "children" (JD.list DE.widgetSpec)
        |: JD.field "columns" (JD.list JD.string)
        |: JD.field "rows" (JD.list JD.string)
        |: JD.field "gap" gap
        |: JD.field "justifyContent" JD.string
        |: JD.field "alignContent" JD.string
        |: JD.field "backgroundColor" JD.string
        |: JD.field "width" JD.string
        |: JD.field "padding" (JD.list JD.string)



-- model


type alias Model =
    { config : Config
    , children : List DE.WidgetModel
    }



-- init


init : Config -> ( Model, Cmd Msg, LayoutRequest )
init c =
    let
        ( cs, c_c, lo_c ) =
            HE.initList c.children ChildMsg
    in
    ( { config = c, children = cs }
    , Cmd.batch [ c_c ]
    , HE.batchLR [ lo_c ]
    )



-- update


type Msg
    = ChildMsg Int DE.WidgetMsg


update : Msg -> Model -> ( Model, Cmd Msg, LayoutRequest )
update msg m =
    case msg of
        ChildMsg i imsg ->
            let
                ( cs, c, lr ) =
                    HE.updateList m.config.children imsg m.children i ChildMsg
            in
            ( { m | children = cs }, c, lr )



-- subscriptions


subscriptions : Model -> Sub Msg
subscriptions m =
    HE.subscriptions m.config.children
        (List.indexedMap (\i c -> ( ChildMsg i, c )) m.children)



-- view


view : Model -> Node Msg
view m =
    L.grid (wrapper m.config) <|
        HE.viewList m.config.children m.children ChildMsg



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


wrapper : Config -> List Style
wrapper c =
    [ gridTemplateAreas c.area
    , gridTemplateRows <| List.foldr (++) " " <| List.intersperse " " c.rows
    , gridTemplateColumns <| List.foldr (++) " " <| List.intersperse " " c.columns
    , rawBackgroundColor c.backgroundColor
    , rawWidth c.width
    , L.rawPadding <| List.foldr (++) " " <| List.intersperse " " c.padding
    , boxSizing "border-box"

    --    , gridGap c.gap
    ]
