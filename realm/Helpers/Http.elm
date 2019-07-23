module Helpers.Http exposing (fetch, loadScript, toTask)

import Http
import Native.Http
import RealmApi.Platform as Platform
import Task exposing (Task)


fetch : (Result Http.Error a -> msg) -> Http.Request a -> Cmd msg
fetch resultToMessage request =
    case Platform.os of
        Platform.Native _ ->
            Task.attempt resultToMessage (toTask request)

        Platform.Web _ ->
            Http.send resultToMessage request


toTask : Http.Request a -> Task Http.Error a
toTask request =
    Native.Http.toTask request Nothing


loadScript : String -> Task Http.Error ()
loadScript =
    Native.Http.loadScript
