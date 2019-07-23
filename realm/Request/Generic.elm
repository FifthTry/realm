module Request.Generic exposing (api, callLR, externalGetApi, fetchLayout, getApi, layout)

import Backend as B exposing (ApiData, BError, BResult, bresult, try)
import Data.Engine exposing (LayoutOutput, layoutOutput)
import Helpers.Http as Http
import Helpers.Utils as Utils
import Http exposing (toTask)
import Json.Decode as JD
import Json.Encode as JE
import Task exposing (Task)



api :
    String
    -> JD.Decoder a
    -> (Result BError a -> msg)
    -> JE.Value
    -> Cmd msg
api name dec msg val =
    Http.post (Utils.api2 name []) (Http.jsonBody val) (bresult dec)
        |> Http.fetch (try >> msg)


getApi :
    String
    -> JD.Decoder a
    -> (Result BError a -> msg)
    -> List ( String, String )
    -> Cmd msg
getApi name dec msg val =
    let
        url =
            Utils.api2 name val
    in
    Http.get url (bresult dec)
        |> Http.fetch (try >> msg)


externalGetApi :
    String
    -> JD.Decoder a
    -> (Result Http.Error a -> msg)
    -> Cmd msg
externalGetApi name dec msg =
    Http.get name dec
        |> Http.fetch msg


layout :
    List String
    -> List ( String, JE.Value )
    -> Task Http.Error (BResult LayoutOutput)
layout deps params =
    Http.post (Utils.api2 "layout" [])
        (Http.jsonBody
            (JE.object
                ([ ( "cache", JE.list (List.map JE.string deps) )
                 , ( "data", JE.object [] )
                 ]
                    ++ params
                )
            )
        )
        (bresult layoutOutput)
        |> toTask


fetchLayout :
    (B.BR LayoutOutput -> msg)
    -> Task Http.Error (BResult LayoutOutput)
    -> Cmd msg
fetchLayout msg task =
    Task.attempt (try >> msg) task


callLR :
    (B.BR LayoutOutput -> msg)
    -> Maybe (List String -> Task Http.Error (BResult LayoutOutput))
    -> Cmd msg
callLR msg lr =
    case lr of
        Just lr ->
            fetchLayout msg (lr [])

        Nothing ->
            Cmd.none
