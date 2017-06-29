module Dashboard exposing (..)

import Html exposing (..)


-- MODEL


type alias Model =
    { title : String
    }


initModel : Model
initModel =
    { title = "Dashboard"
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



-- MESSAGES


type Msg
    = InitMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitMsg ->
            ( model
            , Cmd.none
            )



-- VIEW


view : Model -> Html Msg
view model =
    div
        []
        []
