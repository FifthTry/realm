module L exposing (main)

import Realm
import Browser
import Html as H exposing (..)
import Html.Attributes as H exposing (..)
import Json.Encode as JE
import Html.Events exposing (onInput)




type alias Config = {
    body: Realm.WidgetSpec
    -- ,footer: Realm.WidgetSpec
    -- header: WidgetSpec,

  }




main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view

    }


type alias Model =
  { name : String
  , password : String
  , passwordAgain : String
  , config: Config
  }

init : Config -> ( Model, Cmd Msg )
init config =
    ( Model "" "" "" config
     , Realm.loadWidget
        (
                JE.object
                    [ ( "uid", JE.string config.body.uid )
                    , ( "id", JE.string config.body.id )
                    , ( "config", config.body.config)
                    ]

        )

    )



-- UPDATE


type Msg
  = Name String
  | Password String
  | PasswordAgain String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Name name ->
      ({ model | name = name }, Cmd.none)

    Password password ->
      ({ model | password = password }, Cmd.none)

    PasswordAgain password ->
      ({ model | passwordAgain = password }, Cmd.none)















-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none





-- VIEW


view : Model  -> Html Msg
view model=
  div [ H.id "main" ]
    [ Realm.child model.config.body
    -- , Realm.child model.config.footer
    , (div
        [H.id "child3"]
        [ viewInput "text" "Name" model.name Name
            , viewInput "password" "Password" model.password Password
            , viewInput "password" "Re-enter Password" model.passwordAgain PasswordAgain
            , viewValidation model
        ]
      )
    ]

viewInput : String -> String -> String -> (String -> msg) -> Html msg
viewInput t p v toMsg =
  input [ type_ t, placeholder p, value v, onInput toMsg ] []


viewValidation : Model -> Html msg
viewValidation model =
  if model.password /= model.passwordAgain then
    div [ style "color" "red" ] [ text "Passwords do not match!" ]
  else if String.length model.password < 8 then
    div [ style "color" "red" ] [ text "Passwords' minimum length is 8" ]
  else
    div [ style "color" "green" ] [ text "OK" ]

