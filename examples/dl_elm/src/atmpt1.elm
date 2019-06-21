port module Main exposing (main)
import Browser
import Html exposing (Html, text, pre)
import Http

import Json.Encode as E
import Json.Decode as JD
import Json.Decode exposing (Decoder, map2, field, string, int)


-- MAIN


main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

decoder : JD.Decoder Flag
decoder =
    map2 Flag
      (field "i" int)
      (field "flag_s" string)



-- MODEL
type Mode = Failure
  | Loading
  | Success String
type alias Model
  = {
    mode: Mode,
    flag_i: Int,
    flag_s: String
  }

type alias Flag
   = {
      i: Int,
      s: String
   }

port hello : E.Value -> Cmd msg


init : Flag -> (Model, Cmd Msg)
init flag =
  ( {
    mode = Loading,
    flag_i = flag.i,
    flag_s = flag.s
  },
   Http.get
      { url = "https://elm-lang.org/assets/public-opinion.txt"
      , expect = Http.expectString GotText
      }

  )



-- UPDATE


type Msg
  = GotText (Result Http.Error String)

myInfo: E.Value
myInfo = E.object
        [ ( "name", E.string "Tom" )
        , ( "age", E.int 42 )
        ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    GotText result ->
      case result of
        Ok fullText ->
          ({model| mode = Success fullText}, hello myInfo )

        Err _ ->
          ({model| mode = Failure}, Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


view : Model -> Html Msg
view model =
  case model.mode of
    Failure ->
      text "I was unable to load your book."

    Loading->
      text ("Loading..." ++ model.flag_s ++ String.fromInt model.flag_i)

    Success fullText ->
      pre [] [ text fullText ]


