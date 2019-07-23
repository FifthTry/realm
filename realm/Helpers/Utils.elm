module Helpers.Utils exposing (..)

import Date exposing (Date)
import Dict exposing (Dict)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Native.Helpers
import Native.Realm
import Realm.Style as Style exposing (..)
import RemoteData as RD
import Task


type LogLevel
    = Debug
    | Info
    | Warn
    | Error
    | Fatal


log : LogLevel -> String -> a -> a
log level =
    Native.Helpers.log (String.toLower (toString level))


withCommas : Int -> String
withCommas =
    Native.Helpers.numberWithCommas



dictGetOrCrash : String -> Dict comparable b -> comparable -> b
dictGetOrCrash msg d key =
    case Dict.get key d of
        Just v ->
            v

        Nothing ->
            Debug.crash
                (msg ++ ": key=" ++ toString key ++ "; dict=" ++ toString d)


url : String -> List ( String, String ) -> String
url baseUrl query =
    case query of
        [] ->
            baseUrl

        _ ->
            let
                queryPairs =
                    query
                        |> List.map
                            (\( key, value ) ->
                                Http.encodeUri key ++ "=" ++ Http.encodeUri value
                            )

                queryString =
                    queryPairs |> String.join "&"
            in
            baseUrl ++ "?" ++ queryString


api : String -> String
api name =
    -- TODO [jatinderjit]: solve this (make it work for both native and web)
    Native.Realm.prefix ++ "/api/" ++ name ++ "/"


nonAPIAPI : String -> String
nonAPIAPI name =
    -- TODO [jatinderjit]: solve this (make it work for both native and web)
    Native.Realm.prefix ++ "/" ++ name ++ "/"


api2 : String -> List ( String, String ) -> String
api2 name list =
    url (api name) list


api3 : String -> List ( String, String ) -> String
api3 name list =
    url (nonAPIAPI name) list


isSuccess : Result a b -> Bool
isSuccess a =
    Result.map (\_ -> True) a
        |> onError False


isJust : Maybe a -> Bool
isJust a =
    case a of
        Just _ ->
            True

        Nothing ->
            False


orCrash : String -> Maybe a -> a
orCrash msg m =
    case m of
        Just a ->
            a

        Nothing ->
            Debug.crash msg


orCrash2 : String -> RD.RemoteData e a -> a
orCrash2 msg m =
    case m of
        RD.Success a ->
            a

        r ->
            Debug.crash (msg ++ toString r)


orCrash3 : String -> Result err a -> a
orCrash3 msg m =
    case m of
        Result.Ok a ->
            a

        Result.Err err ->
            Debug.crash (msg ++ toString err)


onError : a -> Result b a -> a
onError default result =
    case result of
        Ok value ->
            value

        Err _ ->
            default


map3First : (a -> b) -> ( a, a2, a3 ) -> ( b, a2, a3 )
map3First func ( x, y, z ) =
    ( func x, y, z )


map4First : (a -> b) -> ( a, a2, a3, a4 ) -> ( b, a2, a3, a4 )
map4First func ( x, y, z, d ) =
    ( func x, y, z, d )


map3Second : (a2 -> b) -> ( a, a2, a3 ) -> ( a, b, a3 )
map3Second func ( x, y, z ) =
    ( x, func y, z )


map4Second : (a2 -> b) -> ( a, a2, a3, a4 ) -> ( a, b, a3, a4 )
map4Second func ( x, y, z, d ) =
    ( x, func y, z, d )


map3Third : (a3 -> b) -> ( a, a2, a3 ) -> ( a, a2, b )
map3Third func ( x, y, z ) =
    ( x, y, func z )


twoToThree : c -> ( a, b ) -> ( a, b, c )
twoToThree c ( a, b ) =
    ( a, b, c )


twoToThree2 : b -> ( a, c ) -> ( a, b, c )
twoToThree2 b ( a, c ) =
    ( a, b, c )


threeToTwo3 : ( a, b, c ) -> ( a, b )
threeToTwo3 ( a, b, c ) =
    ( a, b )


threeToFour3 : c -> ( a, b, d ) -> ( a, b, c, d )
threeToFour3 c ( a, b, d ) =
    ( a, b, c, d )


fourToThree3 : ( a, b, c, d ) -> ( a, b, d )
fourToThree3 ( a, b, c, d ) =
    ( a, b, d )


forNothing : Maybe a -> b -> Maybe b
forNothing ma b =
    case ma of
        Just _ ->
            Nothing

        Nothing ->
            Just b


first3 : ( a, b, c ) -> a
first3 ( a, _, _ ) =
    a


second3 : ( a, b, c ) -> b
second3 ( _, b, _ ) =
    b


third3 : ( a, b, c ) -> c
third3 ( _, _, c ) =
    c


dropThird : ( a, b, c ) -> ( a, b )
dropThird ( a, b, _ ) =
    ( a, b )


dropFirst : ( a, b, c ) -> ( b, c )
dropFirst ( a, b, c ) =
    ( b, c )


dropThirdFromFourTuple : ( a, b, c, d ) -> ( a, b, d )
dropThirdFromFourTuple ( a, b, c, d ) =
    ( a, b, d )


mapFirstThreeTuple : (a -> b) -> ( a, a2, a3 ) -> ( b, a2, a3 )
mapFirstThreeTuple func ( x, y, z ) =
    ( func x, y, z )


mapSecondThreeTuple : (a -> b) -> ( a1, a, a3 ) -> ( a1, b, a3 )
mapSecondThreeTuple func ( x, y, z ) =
    ( x, func y, z )


mapThirdThreeTuple : (a -> b) -> ( a1, a2, a ) -> ( a1, a2, b )
mapThirdThreeTuple func ( x, y, z ) =
    ( x, y, func z )


maybeE : (a -> JE.Value) -> Maybe a -> JE.Value
maybeE fn m =
    case m of
        Just a ->
            fn a

        Nothing ->
            JE.null


{-| Encode a list of variables, given the encoder for variable
-}
listE : (a -> JE.Value) -> List a -> JE.Value
listE encoder =
    JE.list << List.map encoder


dictE : (a -> JE.Value) -> Dict String a -> JE.Value
dictE enc d =
    List.map (\( k, v ) -> ( k, enc v )) (Dict.toList d)
        |> JE.object


maybeFieldWithDefault : String -> a -> JD.Decoder a -> JD.Decoder a
maybeFieldWithDefault name default decoder =
    JD.maybe (JD.field name decoder)
        |> JD.andThen
            (\v ->
                JD.succeed <|
                    Maybe.withDefault default v
            )


tuple : JD.Decoder a -> JD.Decoder b -> JD.Decoder ( a, b )
tuple a b =
    JD.map2 (,) (JD.index 0 a) (JD.index 1 b)


decodeValue : JD.Decoder a -> JE.Value -> Maybe a
decodeValue dec v =
    JD.decodeValue dec v
        |> Result.toMaybe


yesno : Bool -> a -> a -> a
yesno cond yes no =
    if cond then
        yes
    else
        no


joinList : String -> List String -> String
joinList separator =
    List.foldr (++) "" << List.intersperse separator


type YesNo a
    = YesNo a a


generateMsg : msg -> Cmd msg
generateMsg msg =
    Task.perform (always msg) (Task.succeed ())


(<:>) : a -> a -> YesNo a
(<:>) yes no =
    YesNo yes no
infixl 2 <:>


(?) : Bool -> YesNo a -> a
(?) cond (YesNo yes no) =
    if cond then
        yes
    else
        no
infixl 1 ?


getFormattedIDVamount : Float -> String
getFormattedIDVamount num =
    yesno (num < 0) "- ₹ " "₹ " ++ (Native.Helpers.formatAmount <| abs num)


getFormattedAmount : Int -> String
getFormattedAmount num =
    yesno (num < 0) "- ₹ " "₹ " ++ getFormattedNumber (abs num)


getFormattedFloatAmount : Float -> String
getFormattedFloatAmount num =
    yesno (num < 0) "- ₹ " "₹ " ++ (Native.Helpers.numberWithCommas <| abs num)


getFormattedNumber : Int -> String
getFormattedNumber num =
    withCommas num


getMonthInWords : Int -> String
getMonthInWords i =
    case i of
        1 ->
            "Jan"

        2 ->
            "Feb"

        3 ->
            "Mar"

        4 ->
            "Apr"

        5 ->
            "May"

        6 ->
            "Jun"

        7 ->
            "Jul"

        8 ->
            "Aug"

        9 ->
            "Sep"

        10 ->
            "Oct"

        11 ->
            "Nov"

        12 ->
            "Dec"

        _ ->
            Debug.crash "Month number out of range"


ellipses : Int -> Maybe String -> Maybe String
ellipses length text =
    case text of
        Just a ->
            let
                t =
                    String.slice 0 length a
            in
            if String.length a > length then
                Just (t ++ "...")
            else
                Just t

        Nothing ->
            Nothing


type alias Dimension =
    { width : Maybe String
    , height : Maybe String
    , line_break : Maybe String
    }


getDimension : Maybe String -> Maybe Dimension
getDimension style =
    let
        x =
            case style of
                Just style ->
                    Just { width = String.split ":" style |> List.tail |> Maybe.withDefault [] |> List.head, height = Nothing, line_break = Nothing }

                Nothing ->
                    Nothing
    in
    x


getWidth : Maybe Dimension -> List Style
getWidth dim =
    case dim of
        Just dim ->
            case dim.width of
                Just width ->
                    [ rawWidth <| width ++ "%"
                    , paddingHorizontal 15
                    , boxSizing "border-box"
                    ]

                Nothing ->
                    fullWidth

        Nothing ->
            fullWidth


fullWidth : List Style
fullWidth =
    [ rawWidth <| "100%"
    , paddingHorizontal 15
    , boxSizing "border-box"
    ]


range : Int -> Int -> Int -> List Int
range min max step =
    if min <= max then
        min :: range (min + step) max step
    else
        []


uptoTwoDecimal : Float -> Float
uptoTwoDecimal v =
    v * 100 |> round |> toFloat |> flip (/) 100


scrollPosition : JD.Decoder ( Int, Int )
scrollPosition =
    JD.string
        |> JD.andThen
            (\s ->
                case String.split "," s of
                    [ xs, ys ] ->
                        case ( String.toInt xs, String.toInt ys ) of
                            ( Ok x, Ok y ) ->
                                JD.succeed ( x, y )

                            _ ->
                                JD.fail "Coordinates not integers"

                    _ ->
                        JD.fail "Coordinates not found"
            )
