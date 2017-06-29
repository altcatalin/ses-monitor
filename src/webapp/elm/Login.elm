module Login exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Navigation exposing (..)
import Ports


-- MODEL


type alias Model =
    { title : String
    , username : String
    , password : String
    , error : Maybe String
    , submit : Bool
    }


initModel : Model
initModel =
    { title = "Log in"
    , username = ""
    , password = ""
    , error = Nothing
    , submit = False
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



-- MESSAGES


type Msg
    = UsernameInput String
    | PasswordInput String
    | Submit
    | LoginError String
    | LoginSuccess String



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg, Maybe String )
update msg model =
    case msg of
        UsernameInput username ->
            ( { model
                | username = username
                , error = Nothing
              }
            , Cmd.none
            , Nothing
            )

        PasswordInput password ->
            ( { model
                | password = password
                , error = Nothing
              }
            , Cmd.none
            , Nothing
            )

        Submit ->
            ( { model
                | submit = True
              }
            , Ports.loginPort
                { username = model.username
                , password = model.password
                }
            , Nothing
            )

        LoginError msg ->
            ( { model
                | error = Just msg
                , submit = False
              }
            , Cmd.none
            , Nothing
            )

        LoginSuccess name ->
            ( initModel
            , Navigation.newUrl "#/"
            , Just name
            )



-- VIEW


view : Model -> Html Msg
view model =
    div
        []
        [ case model.error of
            Nothing ->
                text ""

            Just message ->
                div
                    [ class "alert alert-danger" ]
                    [ text message ]
        , Html.form
            [ class "form-monitor col-xs-4", onSubmit Submit ]
            [ div
                [ class "form-group" ]
                [ label
                    [ for "username" ]
                    [ text "Username" ]
                , input
                    [ type_ "text"
                    , class "form-control"
                    , name "username"
                    , placeholder "Username"
                    , value model.username
                    , onInput UsernameInput
                    ]
                    []
                ]
            , div
                [ class "form-group" ]
                [ label
                    [ for "password" ]
                    [ text "Password" ]
                , input
                    [ type_ "password"
                    , class "form-control"
                    , name "password"
                    , placeholder "Password"
                    , value model.password
                    , onInput PasswordInput
                    ]
                    []
                ]
            , div
                [ class "form-group" ]
                [ button
                    [ type_ "submit", class "btn btn-info", disabled model.submit ]
                    [ text "Log in" ]
                ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.loginErrorPort LoginError
        , Ports.loginSuccessPort LoginSuccess
        ]
