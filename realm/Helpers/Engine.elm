module Helpers.Engine exposing (..)

import Data.Engine exposing (..)
import Dict
import Helpers.Utils
    exposing
        ( first3
        , isJust
        , map3Second
        , second3
        , third3
        )
import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))
import Json.Encode as JE
import List.Extra as List
import Ports exposing (addKeyFrame)
import Realm exposing (..)
import Realm.Elements as E
import Realm.Layout as L
import Realm.Properties as P
import Realm.Style exposing (..)


-- utils


type alias Common =
    { grid : Maybe Grid
    , animation : Maybe Animation
    , reference : Maybe String
    }


type alias Grid =
    { id : Maybe String
    , justifyContent : Maybe String
    , alignItems : Maybe String
    , margin : Maybe (List String)
    , padding : Maybe (List String)
    }


type alias Animation =
    { name : Maybe String
    , duration : Maybe Float
    , direction : Maybe String
    , function : Maybe String
    , fillMode : Maybe String
    , delay : Maybe Float
    , keyframes : Maybe JE.Value
    }


commonDecoder : JD.Decoder Common
commonDecoder =
    JD.succeed Common
        |: JD.maybe (JD.at [ "common", "grid" ] gridDecoder)
        |: JD.maybe (JD.at [ "common", "animation" ] animationDecoder)
        |: JD.maybe (JD.at [ "common", "reference-image" ] JD.string)


gridDecoder : JD.Decoder Grid
gridDecoder =
    JD.succeed Grid
        |: JD.maybe (JD.field "id" JD.string)
        |: JD.maybe (JD.field "justifyContent" JD.string)
        |: JD.maybe (JD.field "alignItems" JD.string)
        |: JD.maybe (JD.field "margin" (JD.list JD.string))
        |: JD.maybe (JD.field "padding" (JD.list JD.string))


animationDecoder : JD.Decoder Animation
animationDecoder =
    JD.succeed Animation
        |: JD.maybe (JD.field "name" JD.string)
        |: JD.maybe (JD.field "duration" JD.float)
        |: JD.maybe (JD.field "direction" JD.string)
        |: JD.maybe (JD.field "function" JD.string)
        |: JD.maybe (JD.field "fillMode" JD.string)
        |: JD.maybe (JD.field "delay" JD.float)
        |: JD.maybe (JD.field "keyframes" JD.value)


gridStyle : Maybe Grid -> Maybe Animation -> Maybe (List Style)
gridStyle c a =
    case c of
        Just grid ->
            Just <|
                [ gridArea <| Maybe.withDefault "" grid.id
                , L.justifyContent <| Maybe.withDefault "" grid.justifyContent
                , L.alignItems <| Maybe.withDefault "" grid.alignItems
                , L.rawMargin <| (List.foldr (++) " " <| List.intersperse " " <| Maybe.withDefault [ "" ] grid.margin)
                , L.rawPadding <| (List.foldr (++) " " <| List.intersperse " " <| Maybe.withDefault [ "" ] grid.padding)
                , boxSizing "border-box"
                ]
                    ++ (case a of
                            Just animation ->
                                [ animationName <| Maybe.withDefault "" grid.id
                                , animationDuration <| toString (Maybe.withDefault 0 animation.duration) ++ "s"
                                , animationDelay <| toString (Maybe.withDefault 0 animation.delay) ++ "s"
                                , animationDirection <| Maybe.withDefault "" animation.direction
                                , animationTimingFunction <| Maybe.withDefault "" animation.function
                                , animationFillMode <| Maybe.withDefault "" animation.fillMode
                                ]

                            Nothing ->
                                []
                       )

        Nothing ->
            Nothing


fromSession : String -> Maybe String
fromSession key =
    case Native.Helpers.fromSession key of
        "" ->
            Nothing

        a ->
            Just a


attachSession : WidgetSpec -> WidgetSpec
attachSession ({ id, config } as spec) =
    case JD.decodeValue (JD.dict JD.value) config of
        Ok dict ->
            let
                session =
                    { trackerId = fromSession "trackerId"
                    , user =
                        case
                            ( fromSession "userId"
                            , fromSession "userName"
                            , fromSession "phone"
                            )
                        of
                            ( Just id, name, Just phone ) ->
                                Just
                                    { id = id
                                    , name = name
                                    , phone = phone
                                    }

                            _ ->
                                Nothing
                    }
                        |> sessionDataE
            in
            dict
                |> Dict.get "common"
                |> Maybe.withDefault (JE.object [])
                |> JD.decodeValue (JD.dict JD.value)
                |> Result.withDefault Dict.empty
                |> Dict.insert "session" session
                |> (\common -> Dict.insert "common" (common |> Dict.toList |> JE.object) dict)
                |> Dict.toList
                |> JE.object
                |> WidgetSpec id

        Err _ ->
            spec



-- init


getIdAndKeyframe : WidgetSpec -> ( JE.Value, String )
getIdAndKeyframe spec =
    let
        kf =
            case JD.decodeValue commonDecoder spec.config of
                Ok common ->
                    case common.animation of
                        Just a ->
                            Maybe.withDefault JE.null a.keyframes

                        Nothing ->
                            JE.null

                Err e ->
                    Debug.crash ("Widget(" ++ spec.id ++ ") decoder failed")

        id =
            case JD.decodeValue commonDecoder spec.config of
                Ok common ->
                    case common.grid of
                        Just a ->
                            Maybe.withDefault "" a.id

                        Nothing ->
                            ""

                Err e ->
                    Debug.crash ("Widget(" ++ spec.id ++ ") decoder failed")
    in
    ( kf, id )


init :
    WidgetSpec
    -> (WidgetMsg -> msg)
    -> ( WidgetModel, Cmd msg, LayoutRequest )
init specWithoutSession tagger =
    let
        ( spec, widget ) =
            let
                spec =
                    attachSession specWithoutSession
            in
            ( spec, getWidget spec.id )

        ( kf, id ) =
            getIdAndKeyframe spec
    in
    case JD.decodeValue widget.decoder spec.config of
        Ok config ->
            let
                ( a, b, c ) =
                    widget.init config
                        |> map3Second (Cmd.map tagger)
            in
            ( a
            , Cmd.batch
                [ b
                , addKeyFrame <|
                    JE.object
                        [ ( "property", kf )
                        , ( "id", JE.string id )
                        ]
                ]
            , c
            )

        Err e ->
            Debug.crash ("Widget(" ++ spec.id ++ ") decoder failed")


initList :
    List WidgetSpec
    -> (Int -> WidgetMsg -> msg)
    -> ( List WidgetModel, Cmd msg, LayoutRequest )
initList specs tagger =
    let
        lst =
            List.indexedMap (\i spec -> init spec (tagger i)) specs
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )


initS :
    WidgetSpec
    -> (SWidgetMsg -> msg)
    -> ( SWidgetModel, Cmd msg, LayoutRequest )
initS spec tagger =
    let
        widget =
            getSWidget spec.id

        ( kf, id ) =
            getIdAndKeyframe spec
    in
    case JD.decodeValue widget.decoder spec.config of
        Ok config ->
            let
                ( a, b, c ) =
                    widget.init config
                        |> map3Second (Cmd.map tagger)
            in
            ( a
            , Cmd.batch
                [ b
                , addKeyFrame <|
                    JE.object
                        [ ( "property", kf )
                        , ( "id", JE.string id )
                        ]
                ]
            , c
            )

        Err e ->
            Debug.crash ("String Widget(" ++ spec.id ++ ") decoder failed")


initSList :
    List WidgetSpec
    -> (Int -> SWidgetMsg -> msg)
    -> ( List SWidgetModel, Cmd msg, LayoutRequest )
initSList specs tagger =
    let
        lst =
            List.indexedMap (\i spec -> initS spec (tagger i)) specs
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )


initI :
    WidgetSpec
    -> (IWidgetMsg -> msg)
    -> ( IWidgetModel, Cmd msg, LayoutRequest )
initI spec tagger =
    let
        widget =
            getIWidget spec.id

        ( kf, id ) =
            getIdAndKeyframe spec
    in
    case JD.decodeValue widget.decoder spec.config of
        Ok config ->
            let
                ( a, b, c ) =
                    widget.init config
                        |> map3Second (Cmd.map tagger)
            in
            ( a
            , Cmd.batch
                [ b
                , addKeyFrame <|
                    JE.object
                        [ ( "property", kf )
                        , ( "id", JE.string id )
                        ]
                ]
            , c
            )

        Err e ->
            Debug.crash ("Integer Widget(" ++ spec.id ++ ") decoder failed")


initIList :
    List WidgetSpec
    -> (Int -> IWidgetMsg -> msg)
    -> ( List IWidgetModel, Cmd msg, LayoutRequest )
initIList specs tagger =
    let
        lst =
            List.indexedMap (\i spec -> initI spec (tagger i)) specs
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )


initB :
    WidgetSpec
    -> (BWidgetMsg -> msg)
    -> ( BWidgetModel, Cmd msg, LayoutRequest )
initB spec tagger =
    let
        widget =
            getBWidget spec.id
    in
    case JD.decodeValue widget.decoder spec.config of
        Ok config ->
            widget.init config
                |> map3Second (Cmd.map tagger)

        Err e ->
            Debug.crash ("Bool Widget(" ++ spec.id ++ ") decoder failed")


initBList :
    List WidgetSpec
    -> (Int -> BWidgetMsg -> msg)
    -> ( List BWidgetModel, Cmd msg, LayoutRequest )
initBList specs tagger =
    let
        lst =
            List.indexedMap (\i spec -> initB spec (tagger i)) specs
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )


initDt :
    WidgetSpec
    -> (DtWidgetMsg -> msg)
    -> ( DtWidgetModel, Cmd msg, LayoutRequest )
initDt spec tagger =
    let
        widget =
            getDtWidget spec.id
    in
    case JD.decodeValue widget.decoder spec.config of
        Ok config ->
            widget.init config
                |> map3Second (Cmd.map tagger)

        Err e ->
            Debug.crash ("Date Widget(" ++ spec.id ++ ") decoder failed")


initDtList :
    List WidgetSpec
    -> (Int -> DtWidgetMsg -> msg)
    -> ( List DtWidgetModel, Cmd msg, LayoutRequest )
initDtList specs tagger =
    let
        lst =
            List.indexedMap (\i spec -> initDt spec (tagger i)) specs
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )



-- update


update :
    WidgetSpec
    -> WidgetMsg
    -> WidgetModel
    -> (WidgetMsg -> msg)
    -> ( WidgetModel, Cmd msg, LayoutRequest )
update spec msg model tagger =
    (getWidget spec.id).update msg model
        |> map3Second (Cmd.map tagger)


updateList :
    List WidgetSpec
    -> WidgetMsg
    -> List WidgetModel
    -> Int
    -> (Int -> WidgetMsg -> msg)
    -> ( List WidgetModel, Cmd msg, LayoutRequest )
updateList specs msg models index tagger =
    let
        lst =
            List.zip specs models
                |> List.indexedMap
                    (\i ( spec, model ) ->
                        if index == i then
                            update spec msg model (tagger i)
                        else
                            ( model, Cmd.none, Nothing )
                    )
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )


updateS :
    WidgetSpec
    -> SWidgetMsg
    -> SWidgetModel
    -> (SWidgetMsg -> msg)
    -> ( SWidgetModel, Cmd msg, LayoutRequest )
updateS spec msg model tagger =
    (getSWidget spec.id).update msg model
        |> map3Second (Cmd.map tagger)


updateSList :
    List WidgetSpec
    -> SWidgetMsg
    -> List SWidgetModel
    -> Int
    -> (Int -> SWidgetMsg -> msg)
    -> ( List SWidgetModel, Cmd msg, LayoutRequest )
updateSList specs msg models index tagger =
    let
        lst =
            List.zip specs models
                |> List.indexedMap
                    (\i ( spec, model ) ->
                        if index == i then
                            updateS spec msg model (tagger i)
                        else
                            ( model, Cmd.none, Nothing )
                    )
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )


updateI :
    WidgetSpec
    -> IWidgetMsg
    -> IWidgetModel
    -> (IWidgetMsg -> msg)
    -> ( IWidgetModel, Cmd msg, LayoutRequest )
updateI spec msg model tagger =
    (getIWidget spec.id).update msg model
        |> map3Second (Cmd.map tagger)


updateIList :
    List WidgetSpec
    -> IWidgetMsg
    -> List IWidgetModel
    -> Int
    -> (Int -> IWidgetMsg -> msg)
    -> ( List IWidgetModel, Cmd msg, LayoutRequest )
updateIList specs msg models index tagger =
    let
        lst =
            List.zip specs models
                |> List.indexedMap
                    (\i ( spec, model ) ->
                        if index == i then
                            updateI spec msg model (tagger i)
                        else
                            ( model, Cmd.none, Nothing )
                    )
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )


updateB :
    WidgetSpec
    -> BWidgetMsg
    -> BWidgetModel
    -> (BWidgetMsg -> msg)
    -> ( BWidgetModel, Cmd msg, LayoutRequest )
updateB spec msg model tagger =
    (getBWidget spec.id).update msg model
        |> map3Second (Cmd.map tagger)


updateBList :
    List WidgetSpec
    -> BWidgetMsg
    -> List BWidgetModel
    -> Int
    -> (Int -> BWidgetMsg -> msg)
    -> ( List BWidgetModel, Cmd msg, LayoutRequest )
updateBList specs msg models index tagger =
    let
        lst =
            List.zip specs models
                |> List.indexedMap
                    (\i ( spec, model ) ->
                        if index == i then
                            updateB spec msg model (tagger i)
                        else
                            ( model, Cmd.none, Nothing )
                    )
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )



updateDt :
    WidgetSpec
    -> DtWidgetMsg
    -> DtWidgetModel
    -> (DtWidgetMsg -> msg)
    -> ( DtWidgetModel, Cmd msg, LayoutRequest )
updateDt spec msg model tagger =
    (getDtWidget spec.id).update msg model
        |> map3Second (Cmd.map tagger)


updateDtList :
    List WidgetSpec
    -> DtWidgetMsg
    -> List DtWidgetModel
    -> Int
    -> (Int -> DtWidgetMsg -> msg)
    -> ( List DtWidgetModel, Cmd msg, LayoutRequest )
updateDtList specs msg models index tagger =
    let
        lst =
            List.zip specs models
                |> List.indexedMap
                    (\i ( spec, model ) ->
                        if index == i then
                            updateDt spec msg model (tagger i)
                        else
                            ( model, Cmd.none, Nothing )
                    )
    in
    ( List.map first3 lst
    , List.map second3 lst
        |> Cmd.batch
    , List.map third3 lst
        |> batchLR
    )



-- subscription


subscriptions :
    List WidgetSpec
    -> List ( WidgetMsg -> msg, WidgetModel )
    -> Sub msg
subscriptions specs models =
    List.zip specs models
        |> List.map
            (\( spec, ( tagger, model ) ) ->
                (getWidget spec.id).subscriptions model
                    |> Sub.map tagger
            )
        |> Sub.batch


subscriptionS :
    List WidgetSpec
    -> List ( SWidgetMsg -> msg, SWidgetModel )
    -> Sub msg
subscriptionS specs models =
    List.zip specs models
        |> List.map
            (\( spec, ( tagger, model ) ) ->
                (getSWidget spec.id).subscription model
                    |> Sub.map tagger
            )
        |> Sub.batch


subscriptionI :
    List WidgetSpec
    -> List ( IWidgetMsg -> msg, IWidgetModel )
    -> Sub msg
subscriptionI specs models =
    List.zip specs models
        |> List.map
            (\( spec, ( tagger, model ) ) ->
                (getIWidget spec.id).subscription model
                    |> Sub.map tagger
            )
        |> Sub.batch


subscriptionB :
    List WidgetSpec
    -> List ( BWidgetMsg -> msg, BWidgetModel )
    -> Sub msg
subscriptionB specs models =
    List.zip specs models
        |> List.map
            (\( spec, ( tagger, model ) ) ->
                (getBWidget spec.id).subscription model
                    |> Sub.map tagger
            )
        |> Sub.batch



subscriptionDt :
    List WidgetSpec
    -> List ( DtWidgetMsg -> msg, DtWidgetModel )
    -> Sub msg
subscriptionDt specs models =
    List.zip specs models
        |> List.map
            (\( spec, ( tagger, model ) ) ->
                (getDtWidget spec.id).subscription model
                    |> Sub.map tagger
            )
        |> Sub.batch



-- values


valuesList : List WidgetSpec -> List WidgetModel -> List ( String, Result String JE.Value )
valuesList specs models =
    List.zip specs models
        |> List.map
            (\( spec, model ) ->
                values spec model
            )
        |> List.concat


values : WidgetSpec -> WidgetModel -> List ( String, Result String JE.Value )
values { id } model =
    (getWidget id).values model


valuesS : WidgetSpec -> SWidgetModel -> List ( String, Result String JE.Value )
valuesS { id } model =
    (getSWidget id).values model


valuesI : WidgetSpec -> IWidgetModel -> List ( String, Result String JE.Value )
valuesI { id } model =
    (getIWidget id).values model


valuesB : WidgetSpec -> BWidgetModel -> List ( String, Result String JE.Value )
valuesB { id } model =
    (getBWidget id).values model



valuesDt : WidgetSpec -> DtWidgetModel -> List ( String, Result String JE.Value )
valuesDt { id } model =
    (getDtWidget id).values model



-- appFn : WidgetSpec -> WidgetModel -> CustDecoder a -> Result String a
-- custDecoder : JD.Decoder RData
-- custDecoder =
--      [
--         (JD.at [ "name" ] JD.string)
--         (JD.at [ "age" ] JD.int)
--         (JD.at [ "address" ] JD.string)
--         (JD.at [ "yesno" ] JD.bool)
--         -- (JD.at [ "fk" ] ekey)
--         -- (JD.at [ "date" ] date)
--      ]
-- view


view : WidgetSpec -> WidgetModel -> (WidgetMsg -> msg) -> Node msg
view spec model tagger =
    wrapGrid spec
        ((getWidget spec.id).view model
            |> Realm.map tagger
        )


wrapGrid : WidgetSpec -> Node msg -> Node msg
wrapGrid spec view =
    case JD.decodeValue commonDecoder spec.config of
        Ok common ->
            let
                gridView =
                    case gridStyle common.grid common.animation of
                        Just g ->
                            E.view [ style g ]
                                [ view
                                ]

                        Nothing ->
                            view
            in
            if Native.Helpers.isShiftKeyDown () then
                case common.reference of
                    Just r ->
                        E.view [ style <| Maybe.withDefault [] (gridStyle common.grid common.animation) ]
                            [ E.image [ P.src r ] []
                            ]

                    Nothing ->
                        gridView
            else
                gridView

        Err e ->
            Debug.crash ("Widget(" ++ spec.id ++ ") decoder failed")


viewList :
    List WidgetSpec
    -> List WidgetModel
    -> (Int -> WidgetMsg -> msg)
    -> List (Node msg)
viewList specs models tagger =
    List.zip specs models
        |> List.indexedMap
            (\i ( spec, model ) ->
                wrapGrid spec
                    ((getWidget spec.id).view model
                        |> Realm.map (tagger i)
                    )
            )


viewS : WidgetSpec -> SWidgetModel -> (SWidgetMsg -> msg) -> Node msg
viewS spec model tagger =
    wrapGrid spec
        ((getSWidget spec.id).view model
            |> Realm.map tagger
        )


viewSList :
    List WidgetSpec
    -> List SWidgetModel
    -> (Int -> SWidgetMsg -> msg)
    -> List (Node msg)
viewSList specs models tagger =
    List.zip specs models
        |> List.indexedMap
            (\i ( spec, model ) ->
                wrapGrid spec
                    ((getSWidget spec.id).view model
                        |> Realm.map (tagger i)
                    )
            )


viewI : WidgetSpec -> IWidgetModel -> (IWidgetMsg -> msg) -> Node msg
viewI spec model tagger =
    (getIWidget spec.id).view model
        |> Realm.map tagger


viewIList :
    List WidgetSpec
    -> List IWidgetModel
    -> (Int -> IWidgetMsg -> msg)
    -> List (Node msg)
viewIList specs models tagger =
    List.zip specs models
        |> List.indexedMap
            (\i ( spec, model ) ->
                wrapGrid spec
                    ((getIWidget spec.id).view model
                        |> Realm.map (tagger i)
                    )
            )


viewB : WidgetSpec -> BWidgetModel -> (BWidgetMsg -> msg) -> Node msg
viewB spec model tagger =
    (getBWidget spec.id).view model
        |> Realm.map tagger


viewBList :
    List WidgetSpec
    -> List BWidgetModel
    -> (Int -> BWidgetMsg -> msg)
    -> List (Node msg)
viewBList specs models tagger =
    List.zip specs models
        |> List.indexedMap
            (\i ( spec, model ) ->
                (getBWidget spec.id).view model
                    |> Realm.map (tagger i)
            )




viewDt : WidgetSpec -> DtWidgetModel -> (DtWidgetMsg -> msg) -> Node msg
viewDt spec model tagger =
    (getDtWidget spec.id).view model
        |> Realm.map tagger


viewDtList :
    List WidgetSpec
    -> List DtWidgetModel
    -> (Int -> DtWidgetMsg -> msg)
    -> List (Node msg)
viewDtList specs models tagger =
    List.zip specs models
        |> List.indexedMap
            (\i ( spec, model ) ->
                (getDtWidget spec.id).view model
                    |> Realm.map (tagger i)
            )



-- utilities


batchLR : List LayoutRequest -> LayoutRequest
batchLR =
    List.filter isJust
        >> List.head
        >> Maybe.withDefault Nothing
