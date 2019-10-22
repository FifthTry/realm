module Realm.Utils exposing (Field, Form, Rendered(..), button, contains, edges, emptyField, err, escEnter, fi, fieldError, fieldNoError, fieldValid, fieldValue, fieldsNoError, form, formE, html, htmlLine, iff, link, mapAIth, mapIth, match, matchCtx, matchCtx2, maybe, maybeE, maybeS, onEnter, onlyErrors, rendered, renderedE, result, val, withError, yesno, zip)

import Array exposing (Array)
import Dict exposing (Dict)
import Element as E
import Element.Events as EE
import Element.Input as EI
import Html.Events
import Html.Parser
import Html.Parser.Util
import Json.Decode as JD
import Json.Encode as JE
import Realm as R


mapIth : Int -> (a -> a) -> List a -> List a
mapIth idx f =
    List.indexedMap (\i a -> yesno (i == idx) (f a) a)


mapAIth : Int -> (a -> a) -> Array a -> Array a
mapAIth idx f =
    Array.indexedMap (\i a -> yesno (i == idx) (f a) a)


iff : Bool -> E.Element msg -> E.Element msg
iff c e =
    yesno c e E.none


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
                                JD.fail "Not the enter key"
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


type Rendered
    = Rendered String


rendered : JD.Decoder Rendered
rendered =
    JD.map Rendered JD.string


renderedE : Rendered -> JE.Value
renderedE (Rendered md) =
    JE.string md


html : List (E.Attribute (R.Msg msg)) -> Rendered -> E.Element (R.Msg msg)
html attrs (Rendered md) =
    case Html.Parser.run md of
        Ok r ->
            Html.Parser.Util.toVirtualDom r
                |> List.map E.html
                |> E.textColumn attrs

        Err e ->
            E.text (Debug.toString e)


htmlLine : List (E.Attribute (R.Msg msg)) -> Rendered -> E.Element (R.Msg msg)
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


link :
    String
    -> List (E.Attribute msg)
    -> (String -> msg)
    -> E.Element msg
    -> E.Element msg
link url attrs msg label =
    E.link (EE.onClick (msg url) :: attrs) { label = label, url = url }


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


type alias Field =
    { value : String
    , error : Maybe String
    , edited : Bool
    }


emptyField : Field
emptyField =
    { value = ""
    , edited = False
    , error = Nothing
    }


fi : String -> R.In -> Form -> Field
fi name in_ f =
    let
        v =
            val name in_ f
    in
    { value = v, edited = v /= "", error = err name f }


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


onlyErrors : String -> List String -> R.In -> Form -> R.TestResult
onlyErrors tid names in_ f =
    let
        unexpected =
            f
                |> Dict.toList
                |> List.filter (\( n, ( _, e ) ) -> e /= Nothing && not (contains n names))
                |> List.map (\( n, _ ) -> n)
    in
    if List.isEmpty unexpected then
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
                        unexpected
                    )


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


match : String -> a -> a -> R.TestResult
match tid exp got =
    if exp /= got then
        R.TestFailed tid ("Expected: " ++ Debug.toString exp ++ " got: " ++ Debug.toString got)

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
