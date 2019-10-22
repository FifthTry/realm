module Realm.Requests exposing (ApiData, BResult, Error(..), LayoutResponse(..), bresult, layoutResponse, try)

import Dict exposing (Dict)
import Http
import Json.Decode as JD
import Json.Encode as JE
import RemoteData as RD


type Error
    = HttpError Http.Error
    | FieldErrors (Dict String String)
    | Error String


error : JD.Decoder Error
error =
    JD.map Error (JD.field "error" JD.string)


type StringOrDict
    = AString String
    | ADict (Dict String String)


type alias BResult a =
    { success : Bool
    , result : Maybe a
    , error : Maybe StringOrDict
    }


bresult : JD.Decoder a -> JD.Decoder (BResult a)
bresult decoder =
    JD.field "success" JD.bool
        |> JD.andThen
            (\success ->
                if success then
                    JD.map3 BResult
                        (JD.succeed True)
                        (JD.field "result" decoder |> JD.map Just)
                        (JD.succeed Nothing)

                else
                    JD.map3 BResult
                        (JD.succeed False)
                        (JD.succeed Nothing)
                        (JD.field "error"
                            (JD.oneOf
                                [ JD.map AString JD.string
                                , JD.map ADict (JD.dict JD.string)
                                ]
                                |> JD.map Just
                            )
                        )
            )


try : Result Http.Error (BResult a) -> ApiData a
try res =
    (case res of
        Ok b ->
            if b.success then
                case b.result of
                    Just c ->
                        Ok c

                    Nothing ->
                        Err (Error "Got success with no result.")

            else
                case b.error of
                    Just (AString s) ->
                        Err (Error s)

                    Just (ADict d) ->
                        Err (FieldErrors d)

                    Nothing ->
                        Err (Error "success false, but no error")

        Err e ->
            Err (HttpError e)
    )
        |> RD.fromResult


type alias ApiData a =
    RD.RemoteData Error a


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
