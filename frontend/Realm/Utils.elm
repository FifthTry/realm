module Realm.Utils exposing (Field, rtl, ltr, Form, Rendered(..), button, contains, edges, emptyField, err, escEnter, false, fi, fieldError, fieldNoError, fieldValid, fieldValue, fieldsNoError, form, formE, html, htmlLine, htmlWith, iff, lGet, mapAIth, mapIth, match, matchCtx, matchCtx2, maybe, maybeE, maybeS, message, mif, nif, niff, onEnter, onEsc, rendered, renderedE, renderedToString, result, style, text, title, true, val, withError, withFocus, yesno, zip)

import Array exposing (Array)
import Dict exposing (Dict)
import Element as E
import Element.Input as EI
import Html.Attributes as HA
import Html.Events
import Html.Parser
import Html.Parser.Util
import Json.Decode as JD
import Json.Encode as JE
import Realm as R
import Task


title : String -> E.Attribute msg
title =
    HA.title >> E.htmlAttribute


style : String -> String -> E.Attribute msg
style k v =
    E.htmlAttribute (HA.style k v)


lGet : Int -> List a -> Maybe a
lGet idx lst =
    case ( idx, lst ) of
        ( 0, f :: _ ) ->
            Just f

        ( _, _ :: rst ) ->
            lGet (idx - 1) rst

        _ ->
            Nothing


mapIth : Int -> (a -> a) -> List a -> List a
mapIth idx f =
    List.indexedMap (\i a -> yesno (i == idx) (f a) a)


mapAIth : Int -> (a -> a) -> Array a -> Array a
mapAIth idx f =
    Array.indexedMap (\i a -> yesno (i == idx) (f a) a)


iff : Bool -> E.Element msg -> E.Element msg
iff c e =
    yesno c e E.none


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


nif : Maybe a -> E.Element msg -> E.Element msg
nif m f =
    case m of
        Just _ ->
            E.none

        Nothing ->
            f


onEnter : msg -> E.Attribute msg
onEnter msg =
    E.htmlAttribute
        (Html.Events.on "keyup"
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


onEsc : msg -> E.Attribute msg
onEsc esc =
    E.htmlAttribute
        (Html.Events.on "keyup"
            (JD.succeed esc)
        )


escEnter : msg -> msg -> E.Attribute msg
escEnter esc enter =
    E.htmlAttribute
        (Html.Events.on "keyup"
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
        (Html.Events.on "keyup"
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
    case Html.Parser.run md of
        Ok r ->
            Html.Parser.Util.toVirtualDom r
                |> List.map E.html
                |> E.textColumn attrs

        Err e ->
            E.text (Debug.toString e)


htmlWith :
    List (E.Attribute msg)
    -> (E.Element msg -> E.Element msg)
    -> Rendered
    -> E.Element msg
htmlWith attrs wrapper (Rendered md) =
    case Html.Parser.run md of
        Ok r ->
            Html.Parser.Util.toVirtualDom r
                |> List.map (E.html >> wrapper)
                |> E.textColumn attrs

        Err e ->
            E.text (Debug.toString e)


htmlLine : List (E.Attribute msg) -> Rendered -> E.Element msg
htmlLine attrs (Rendered md) =
    case Html.Parser.run md of
        Ok r ->
            Html.Parser.Util.toVirtualDom r
                |> List.map E.html
                |> E.paragraph attrs

        Err e ->
            E.text (Debug.toString e)


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


true : String -> Bool -> R.TestResult
true tid v =
    match tid v True


false : String -> Bool -> R.TestResult
false tid v =
    match tid v False


match : String -> a -> a -> R.TestResult
match tid exp got =
    if exp /= got then
        R.TestFailed tid
            ("Expected: " ++ Debug.toString exp ++ " got: " ++ Debug.toString got)

    else
        R.TestPassed tid


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
                        ++ Debug.toString exp
                        ++ " got: "
                        ++ Debug.toString got

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
