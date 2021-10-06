module Realm.Utils exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Element as E
import Element.Input as EI
import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as JD
import Json.Encode as JE
import Realm as R
import Realm.Ports as RP
import Slug
import Task
import Time


initializeFtd : String -> JE.Value -> Cmd msg
initializeFtd ftdId data =
    [ ( "id", JE.string ftdId ), ( "data", data ) ]
        |> JE.object
        |> RP.initializeFtd


setFtdBool : String -> Bool -> JE.Value -> Cmd msg
setFtdBool var value handle =
    [ ( "variable", JE.string var )
    , ( "value", JE.bool value )
    , ( "handle", handle )
    ]
        |> JE.object
        |> RP.setFtdBool


setMultiAndRender : List ( String, JE.Value ) -> JE.Value -> Cmd msg
setMultiAndRender list handle =
    [ ( "list", JE.list (R.tupleE JE.string identity) list )
    , ( "handle", handle )
    ]
        |> JE.object
        |> RP.setFtdMultiValue


isMobile : E.Device -> Bool
isMobile device =
    case device.class of
        E.Phone ->
            True

        _ ->
            False


renderFtd : JE.Value -> Cmd msg
renderFtd handle =
    RP.renderFtd handle


type alias FTDHandle =
    { id : String
    , handle : JE.Value
    }


ftdHandle : JD.Decoder FTDHandle
ftdHandle =
    JD.succeed FTDHandle
        |> R.field "id" JD.string
        |> R.field "handle" JD.value


id : String -> E.Attribute msg
id =
    HA.id >> E.htmlAttribute


class : String -> E.Attribute msg
class =
    HA.class >> E.htmlAttribute


maximumWidthOfApp : Int -> E.Attribute msg
maximumWidthOfApp w =
    E.width (E.px w)


jo : List ( String, JE.Value ) -> Maybe JE.Value
jo =
    JE.object >> Just


iframe : String -> List (H.Attribute msg) -> E.Element msg
iframe src attrs =
    E.html <| H.node "iframe" (HA.src src :: attrs) []


title : String -> E.Attribute msg
title =
    HA.title >> E.htmlAttribute


style : String -> String -> E.Attribute msg
style k v =
    E.htmlAttribute (HA.style k v)


maxContent : E.Attribute msg
maxContent =
    style "width" "max-content"


lGet : Int -> List a -> Maybe a
lGet idx lst =
    case ( idx, lst ) of
        ( 0, f :: _ ) ->
            Just f

        ( _, _ :: rst ) ->
            lGet (idx - 1) rst

        _ ->
            Nothing


deleteIth : Int -> List a -> List a
deleteIth index lst =
    List.take index lst ++ List.drop (index + 1) lst


mapIth : Int -> (a -> a) -> List a -> List a
mapIth idx f =
    List.indexedMap (\i a -> yesno (i == idx) (f a) a)


mapAIth : Int -> (a -> a) -> Array a -> Array a
mapAIth idx f =
    Array.indexedMap (\i a -> yesno (i == idx) (f a) a)


isJust : Maybe a -> Bool
isJust n =
    Maybe.map (always True) n |> Maybe.withDefault False


iff : Bool -> E.Element msg -> E.Element msg
iff c e =
    yesno c e E.none


listNotEmpty : List a -> Bool
listNotEmpty l =
    not (List.isEmpty l)


niff : Bool -> E.Element msg -> E.Element msg
niff c e =
    yesno c E.none e


mif : Maybe a -> (a -> E.Element msg) -> E.Element msg
mif m f =
    case m of
        Just a ->
            f a

        Nothing ->
            E.none


dalways : c -> a -> b -> c
dalways c _ _ =
    c


mif2 : Maybe a -> E.Element msg -> E.Element msg
mif2 m f =
    case m of
        Just _ ->
            f

        Nothing ->
            E.none


nif : Maybe a -> E.Element msg -> E.Element msg
nif m f =
    case m of
        Just _ ->
            E.none

        Nothing ->
            f


mifab : Maybe a -> b -> b -> b
mifab m f1 f2 =
    case m of
        Just _ ->
            f1

        Nothing ->
            f2


onEnter : msg -> E.Attribute msg
onEnter msg =
    E.htmlAttribute
        (HE.on "keyup"
            (JD.field "key" JD.string
                |> JD.andThen
                    (\key ->
                        if key == "Enter" then
                            JD.succeed msg

                        else
                            JD.fail "Not the enter key"
                    )
            )
        )


onSpecialS : msg -> E.Attribute msg
onSpecialS msg =
    E.htmlAttribute
        (HE.custom
            "keydown"
            (JD.map2 Tuple.pair
                (JD.field "key" JD.string)
                (JD.field "metaKey" JD.bool
                    |> JD.andThen
                        (\v ->
                            if v then
                                JD.succeed True

                            else
                                JD.field "ctrlKey" JD.bool
                        )
                )
                |> JD.andThen
                    (\( key, special ) ->
                        case
                            ( key, special )
                        of
                            ( "s", True ) ->
                                JD.succeed { message = msg, stopPropagation = True, preventDefault = True }

                            _ ->
                                JD.fail "error while clicking"
                    )
            )
        )


onEsc : msg -> E.Attribute msg
onEsc esc =
    E.htmlAttribute
        (HE.on "keyup"
            (JD.succeed esc)
        )


onClick : msg -> E.Attribute msg
onClick msg =
    E.htmlAttribute
        (HE.custom
            "click"
            (JD.succeed
                { message = msg
                , stopPropagation = True
                , preventDefault = True
                }
            )
        )


onShiftClick : (Bool -> msg) -> E.Attribute msg
onShiftClick msg =
    let
        fn : Bool -> JD.Decoder { message : msg, stopPropagation : Bool, preventDefault : Bool }
        fn v =
            JD.succeed
                { message = msg v
                , stopPropagation = True
                , preventDefault = True
                }
    in
    E.htmlAttribute
        (HE.custom "click"
            (JD.field "shiftKey" JD.bool |> JD.andThen fn)
        )


onDoubleClick : msg -> E.Attribute msg
onDoubleClick msg =
    E.htmlAttribute
        (HE.custom
            "dblclick"
            (JD.succeed
                { message = msg
                , stopPropagation = True
                , preventDefault = True
                }
            )
        )


onFocus : msg -> E.Attribute msg
onFocus msg =
    E.htmlAttribute
        (HE.custom
            "focus"
            (JD.succeed
                { message = msg
                , stopPropagation = True
                , preventDefault = True
                }
            )
        )


escEnter : msg -> msg -> E.Attribute msg
escEnter esc enter =
    E.htmlAttribute
        (HE.on "keyup"
            (JD.field "key" JD.string
                |> JD.andThen
                    (\key ->
                        case key of
                            "Enter" ->
                                JD.succeed enter

                            "Escape" ->
                                JD.succeed esc

                            _ ->
                                JD.fail "Nor the enter, nor the escape key"
                    )
            )
        )


onSpaceOrEnter : msg -> E.Attribute msg
onSpaceOrEnter msg =
    E.htmlAttribute
        (HE.on "keyup"
            (JD.field "key" JD.string
                |> JD.andThen
                    (\key ->
                        if key == " " || key == "Enter" then
                            JD.succeed msg

                        else
                            JD.fail "Not the space key"
                    )
            )
        )


slugify : String -> String
slugify s =
    s
        |> Slug.generate
        |> Maybe.map Slug.toString
        |> Maybe.withDefault s


button :
    List (E.Attribute msg)
    ->
        { onPress : Maybe msg
        , label : E.Element msg
        }
    -> E.Element msg
button attrs args =
    case args.onPress of
        Just msg ->
            EI.button (onSpaceOrEnter msg :: attrs) args

        Nothing ->
            EI.button attrs args


maybe : JD.Decoder a -> JD.Decoder (Maybe a)
maybe dec =
    JD.oneOf [ JD.null Nothing, JD.map Just dec ]


mString : String -> JD.Decoder (Maybe String -> a) -> JD.Decoder a
mString key =
    R.field key (maybe JD.string)


fmaybe : String -> JD.Decoder a -> JD.Decoder (Maybe a)
fmaybe name decoder =
    JD.maybe (JD.field name (maybe decoder))
        |> JD.andThen (\v -> JD.succeed (Maybe.withDefault Nothing v))


fieldWithDefault : String -> a -> JD.Decoder a -> JD.Decoder a
fieldWithDefault name a decoder =
    JD.maybe (JD.field name (maybe decoder))
        |> JD.andThen (Maybe.withDefault Nothing >> Maybe.withDefault a >> JD.succeed)


rtl : E.Attribute msg
rtl =
    "rtl"
        |> HA.attribute "dir"
        |> E.htmlAttribute


ltr : E.Attribute msg
ltr =
    "ltr"
        |> HA.attribute "dir"
        |> E.htmlAttribute


posix : JD.Decoder Time.Posix
posix =
    JD.map Time.millisToPosix JD.int


posixE : Time.Posix -> JE.Value
posixE t =
    JE.int (Time.posixToMillis t)


type Rendered
    = Rendered String


renderedToString : Rendered -> String
renderedToString (Rendered r) =
    r


rendered : JD.Decoder Rendered
rendered =
    JD.map Rendered JD.string


renderedE : Rendered -> JE.Value
renderedE (Rendered md) =
    JE.string md


html : List (E.Attribute msg) -> Rendered -> E.Element msg
html attrs (Rendered md) =
    E.el attrs
        (E.html <|
            H.node "realm-html"
                [ HA.src md, HA.style "white-space" "initial" ]
                []
        )


htmlWith :
    List (E.Attribute msg)
    -> (E.Element msg -> E.Element msg)
    -> Rendered
    -> E.Element msg
htmlWith attrs _ r =
    html attrs r


htmlLine : List (E.Attribute msg) -> Rendered -> E.Element msg
htmlLine =
    html


pre : List (H.Attribute msg) -> String -> E.Element msg
pre styles s =
    E.html
        (H.pre
            ([ HA.style "overflow-x" "auto"
             , HA.style "overflow-y" "hidden"
             , HA.style "padding" "8px"
             , HA.style "margin" "0"
             ]
                ++ styles
            )
            [ H.text s ]
        )


edges : { top : Int, right : Int, bottom : Int, left : Int }
edges =
    { top = 0, right = 0, bottom = 0, left = 0 }


maybeE : (a -> JE.Value) -> Maybe a -> JE.Value
maybeE fn m =
    case m of
        Just a ->
            fn a

        Nothing ->
            JE.null


maybeS : Maybe String -> JE.Value
maybeS =
    maybeE JE.string


text : List (E.Attribute msg) -> String -> E.Element msg
text attrs txt =
    E.el attrs (E.text txt)


yesno : Bool -> a -> a -> a
yesno y a1 a2 =
    if y then
        a1

    else
        a2


subIfJust : Maybe a -> Sub msg -> Sub msg
subIfJust ma s =
    ma |> Maybe.map (always s) |> Maybe.withDefault Sub.none


subIfNothing : Maybe a -> Sub msg -> Sub msg
subIfNothing ma s =
    case ma of
        Just _ ->
            Sub.none

        Nothing ->
            s


yesno1 : Bool -> ( a, a ) -> a
yesno1 y ( a1, a2 ) =
    if y then
        a1

    else
        a2


none : E.Attribute msg
none =
    HA.attribute "d-none" "none"
        |> E.htmlAttribute


aif : Bool -> E.Attribute msg -> E.Attribute msg
aif b a =
    if b then
        a

    else
        none


aifn : Bool -> E.Attribute msg -> E.Attribute msg
aifn b a =
    if b then
        none

    else
        a


type alias Form =
    Dict String ( String, Maybe String )


formE : Form -> JE.Value
formE =
    JE.dict identity
        (\( v, me ) ->
            let
                jv =
                    JE.string v

                jme =
                    maybeS me
            in
            JE.list identity [ jv, jme ]
        )


form : JD.Decoder Form
form =
    JD.dict (R.tuple JD.string (maybe JD.string))


fieldValid : Field -> Bool
fieldValid f =
    f.value /= "" && f.error == Nothing


withError : Dict String String -> String -> Field -> Field
withError d k f =
    { f | error = Dict.get k d }


message : msg -> Cmd msg
message x =
    Task.perform identity (Task.succeed x)


type alias Field =
    { value : String
    , error : Maybe String
    , edited : Bool
    , focused : Bool
    }


withInitialValue : String -> Field
withInitialValue v =
    { value = v
    , edited = False
    , error = Nothing
    , focused = False
    }


emptyField : Field
emptyField =
    { value = ""
    , edited = False
    , error = Nothing
    , focused = False
    }


withFocus : Field -> Bool -> Field
withFocus f foc =
    { f | focused = foc }


fi : String -> R.In -> Form -> Field
fi name in_ f =
    let
        v =
            val name in_ f
    in
    { value = v, edited = v /= "", error = err name f, focused = False }


fieldError : String -> String -> String -> R.In -> Form -> R.TestResult
fieldError tid name error in_ f =
    let
        field =
            fi name in_ f
    in
    if field.error /= Just error then
        R.TestFailed tid <|
            "Expected: "
                ++ error
                ++ ", got: "
                ++ Maybe.withDefault "no error" field.error

    else
        R.TestPassed tid


fieldValue : String -> String -> String -> R.In -> Form -> R.TestResult
fieldValue tid name value in_ f =
    let
        field =
            fi name in_ f
    in
    if field.value /= value then
        R.TestFailed tid <| "Expected: " ++ value ++ ", got: " ++ field.value

    else
        R.TestPassed tid


fieldNoError : String -> String -> R.In -> Form -> R.TestResult
fieldNoError tid name in_ f =
    let
        field =
            fi name in_ f
    in
    if field.error /= Nothing then
        R.TestFailed tid <|
            "Expected No Error, got: "
                ++ Maybe.withDefault "no error" field.error

    else
        R.TestPassed tid


contains : a -> List a -> Bool
contains a lst =
    not (List.isEmpty (List.filter (\name -> name == a) lst))


fieldsNoError : String -> List String -> R.In -> Form -> R.TestResult
fieldsNoError tid names in_ f =
    let
        fieldsWithError =
            List.filter (\name -> (fi name in_ f).error /= Nothing) names
    in
    if List.isEmpty fieldsWithError then
        R.TestPassed tid

    else
        R.TestFailed tid <|
            "Following fields have errors: "
                ++ String.join
                    " & "
                    (List.map
                        (\name ->
                            name ++ ":" ++ Maybe.withDefault "" (fi name in_ f).error
                        )
                        fieldsWithError
                    )


val : String -> R.In -> Form -> String
val f in_ frm =
    -- server side value precedes hash value
    Dict.get f frm
        |> Maybe.map (\( v, _ ) -> v)
        |> Maybe.withDefault (R.getHash f in_)


err : String -> Form -> Maybe String
err f frm =
    Dict.get f frm
        |> Maybe.andThen (\( _, e ) -> e)


zip : (a -> Maybe b -> c) -> List a -> List b -> List c
zip fn la lb =
    case ( la, lb ) of
        ( a :: ra, b :: rb ) ->
            fn a (Just b) :: zip fn ra rb

        ( a :: ra, [] ) ->
            fn a Nothing :: zip fn ra []

        ( [], _ ) ->
            []


result : JD.Decoder e -> JD.Decoder s -> JD.Decoder (Result e s)
result ed sd =
    JD.oneOf [ JD.field "Err" (JD.map Err ed), JD.field "Ok" (JD.map Ok sd) ]


resultE : (a -> JE.Value) -> (b -> JE.Value) -> Result a b -> JE.Value
resultE a b r =
    case r of
        Ok b_ ->
            b b_

        Err a_ ->
            a a_


true : String -> Bool -> R.TestResult
true tid v =
    match tid True v


true2 : String -> Bool -> JE.Value -> R.TestResult
true2 tid v _ =
    match tid True v


false : String -> Bool -> R.TestResult
false tid v =
    match tid False v


false2 : String -> Bool -> JE.Value -> R.TestResult
false2 tid v _ =
    match tid False v


match : String -> a -> a -> R.TestResult
match tid left right =
    if left /= right then
        let
            _ =
                R.log "TestID" tid

            expS =
                R.log "left" (R.toString left)

            gotS =
                R.log "right" (R.toString right)
        in
        R.TestFailed tid
            ("Left: " ++ expS ++ " right: " ++ gotS)

    else
        R.TestPassed tid


oneOf : String -> List a -> a -> R.TestResult
oneOf tid exp got =
    if List.member got exp then
        R.TestPassed tid

    else
        R.TestFailed tid
            ("Expected: " ++ R.toString exp ++ " got: " ++ R.toString got)


matchCtx : a -> String -> JD.Decoder a -> JE.Value -> R.TestResult
matchCtx got key dec v =
    let
        tid =
            "matchCTX." ++ key
    in
    case JD.decodeValue (JD.field key dec) v of
        Ok exp ->
            if exp /= got then
                R.TestFailed tid <|
                    "Expected: "
                        ++ R.toString exp
                        ++ " got: "
                        ++ R.toString got

            else
                R.TestPassed tid

        Err e ->
            R.TestFailed tid (JD.errorToString e)


matchCtx2 : String -> ( String, JD.Decoder a, JE.Value ) -> (a -> Bool) -> R.TestResult
matchCtx2 tid ( key, dec, v ) f =
    case JD.decodeValue (JD.field key dec) v of
        Ok a ->
            if f a then
                R.TestFailed tid "Test Failed"

            else
                R.TestPassed tid

        Err e ->
            R.TestFailed tid (JD.errorToString e)


capitalize : String -> String
capitalize str =
    case List.head <| String.toList str of
        Just h ->
            case List.tail <| String.toList str of
                Just t ->
                    (String.toUpper <| String.fromChar h) ++ String.fromList t

                Nothing ->
                    String.toUpper <| String.fromChar h

        Nothing ->
            ""


zIndex : Int -> E.Attribute msg
zIndex i =
    E.htmlAttribute (HA.style "z-index" (String.fromInt i))


ellipses : Int -> String -> String
ellipses i s =
    if String.length s <= i then
        s

    else
        String.slice 0 i s ++ "..."


stickyElement : String -> String -> List (E.Attribute msg)
stickyElement t h =
    [ style "top" t
    , style "height" h
    , style "position" "sticky"
    ]


fixElement : String -> String -> List (E.Attribute msg)
fixElement s h =
    [ style "height" h
    , style "position" "fixed"
    , style "top" s
    , zIndex 10
    ]


row : List (E.Attribute msg) -> List (E.Element msg) -> E.Element msg
row att el =
    E.row ([ style "position" "static" ] ++ att) el


column : List (E.Attribute msg) -> List (E.Element msg) -> E.Element msg
column att el =
    E.column ([ style "position" "static" ] ++ att) el


wrapperRow : List (E.Attribute msg) -> List (E.Element msg) -> E.Element msg
wrapperRow att el =
    E.wrappedRow ([ style "position" "static" ] ++ att) el
