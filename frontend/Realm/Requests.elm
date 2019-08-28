module Realm.Requests exposing (ApiData, Error(..), bresult, try)

import Http
import Json.Decode as JD
import RemoteData as RD


type Error
    = HttpError Http.Error
      -- | FieldErrors (Dict String String)
    | Error String


error : JD.Decoder Error
error =
    JD.map Error (JD.field "error" JD.string)


type alias BResult a =
    { success : Bool
    , result : Maybe a
    , error : Maybe String
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
                        (JD.field "error" JD.string |> JD.map Just)
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
                b.error
                    |> Maybe.withDefault "success false, but no error"
                    |> Error
                    |> Err

        Err e ->
            Err (HttpError e)
    )
        |> RD.fromResult


type alias ApiData a =
    RD.RemoteData Error a
