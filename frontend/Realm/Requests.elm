module Realm.Requests exposing (ApiData, BResult, Data, Error(..), LayoutResponse(..), bresult, getTrace, layoutResponse, submit, try, try2)

import Dict exposing (Dict)
import Http
import Json.Decode as JD
import Json.Encode as JE
import Realm.Trace as Tr
import RemoteData as RD


type Error
    = HttpError (Maybe Tr.Trace) Http.Error
    | FieldErrors (Maybe Tr.Trace) (Dict String String)
    | Error (Maybe Tr.Trace) String


getTrace : Error -> Maybe Tr.Trace
getTrace e =
    case e of
        HttpError tr _ ->
            tr

        FieldErrors tr _ ->
            tr

        Error tr _ ->
            tr


type StringOrDict
    = AString String
    | ADict (Dict String String)


type alias BResult a =
    { success : Bool
    , result : Maybe a
    , error : Maybe StringOrDict
    , trace : Maybe Tr.Trace
    , context : Maybe JE.Value
    }


fmaybe : String -> JD.Decoder a -> JD.Decoder (Maybe a)
fmaybe name decoder =
    let
        maybe : JD.Decoder a -> JD.Decoder (Maybe a)
        maybe dec =
            JD.oneOf [ JD.null Nothing, JD.map Just dec ]
    in
    JD.maybe (JD.field name (maybe decoder))
        |> JD.andThen (\v -> JD.succeed (Maybe.withDefault Nothing v))


bresult : JD.Decoder a -> JD.Decoder (BResult a)
bresult decoder =
    JD.field "success" JD.bool
        |> JD.andThen
            (\success ->
                if success then
                    JD.map5 BResult
                        (JD.succeed True)
                        (JD.field "result" decoder |> JD.map Just)
                        (JD.succeed Nothing)
                        (fmaybe "trace" Tr.trace)
                        (fmaybe "context" JD.value)

                else
                    let
                        dec =
                            JD.oneOf
                                [ JD.map AString JD.string
                                , JD.map ADict (JD.dict JD.string)
                                ]
                                |> JD.map Just
                    in
                    JD.map5 BResult
                        (JD.succeed False)
                        (JD.succeed Nothing)
                        (JD.oneOf [ JD.field "error" dec, JD.field "errors" dec ])
                        (fmaybe "trace" Tr.trace)
                        (fmaybe "context" JD.value)
            )


try : Result Http.Error (BResult a) -> ApiData a
try res =
    (case res of
        Ok b ->
            if b.success then
                case b.result of
                    Just c ->
                        Ok
                            { trace = b.trace
                            , context = b.context
                            , data = c
                            }

                    Nothing ->
                        Err (Error b.trace "Got success with no result.")

            else
                case b.error of
                    Just (AString s) ->
                        Err (Error b.trace s)

                    Just (ADict d) ->
                        Err (FieldErrors b.trace d)

                    Nothing ->
                        Err (Error b.trace "success false, but no error")

        Err e ->
            Err (HttpError Nothing e)
    )
        |> RD.fromResult


try2 : (a -> msg) -> (Error -> msg) -> Result Http.Error (BResult a) -> msg
try2 ok err res =
    case res of
        Ok b ->
            if b.success then
                case b.result of
                    Just c ->
                        ok c

                    Nothing ->
                        err (Error b.trace "Got success with no result.")

            else
                case b.error of
                    Just (AString s) ->
                        err (Error b.trace s)

                    Just (ADict d) ->
                        err (FieldErrors b.trace d)

                    Nothing ->
                        err (Error b.trace "success false, but no error")

        Err e ->
            err (HttpError Nothing e)


type alias Data a =
    { trace : Maybe Tr.Trace
    , context : Maybe JE.Value
    , data : a
    }


type alias ApiData a =
    RD.RemoteData Error (Data a)


type LayoutResponse
    = Navigate JE.Value
    | FErrors (Dict String String)


layoutResponse : JD.Decoder LayoutResponse
layoutResponse =
    JD.field "kind" JD.string
        |> JD.andThen
            (\tag ->
                case tag of
                    "navigate" ->
                        JD.field "data" (JD.map Navigate JD.value)

                    "errors" ->
                        JD.field "data" (JD.map FErrors (JD.dict JD.string))

                    _ ->
                        JD.fail <| "unknown tag: " ++ tag
            )


submit : JD.Decoder a -> (a -> msg) -> (Error -> msg) -> ( String, JE.Value ) -> Cmd msg
submit dec ok err ( url, data ) =
    Http.post
        { url = url
        , body = Http.jsonBody data
        , expect = Http.expectJson (try2 ok err) (bresult dec)
        }
