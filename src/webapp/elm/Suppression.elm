module Suppression exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Date exposing (..)
import Date.Format exposing (..)
import Ports


-- MODEL


type alias Item =
    { r : String
    , m : String
    , t : String
    }


type alias Model =
    { title : String
    , error : Maybe String
    , loading : Bool
    , items : List Item
    , previousItem : Maybe String
    , nextItem : Maybe String
    }


initModel : Model
initModel =
    { title = "Suppression List"
    , error = Nothing
    , loading = True
    , items = []
    , previousItem = Nothing
    , nextItem = Nothing
    }


init : ( Model, Cmd Msg )
init =
    ( initModel, Cmd.none )



-- MESSAGES


type Msg
    = LoadingMsg
    | ErrorMsg String
    | SuccessMsg (List Item)



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadingMsg ->
            ( { model
                | items = []
                , loading = True
              }
            , Ports.suppressionPort ()
            )

        ErrorMsg msg ->
            ( { model
                | items = []
                , error = Just msg
                , loading = False
              }
            , Cmd.none
            )

        SuccessMsg items ->
            ( { model
                | items = items
                , loading = False
              }
            , Cmd.none
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
        , p
            []
            [ text "Reference list. Recipients can be removed from AWS Suppression List only through AWS Console - "
            , a
                [ href "https://docs.aws.amazon.com/ses/latest/DeveloperGuide/remove-from-suppression-list.html"
                , target "_blank"
                ]
                [ text "details"
                ]
            ]
        , table
            [ class "table table-hover table-monitor" ]
            [ thead
                []
                [ tr
                    []
                    [ th [] [ text "#" ]
                    , th [ class "col-xs-9" ] [ text "Recipient" ]
                    , th [] [ text "Added On" ]
                    ]
                ]
            , tbody [] (List.indexedMap viewItem model.items)
            ]
        , if model.loading then
            div
                [ class "row preloader" ]
                [ img
                    [ src "ajax-loader.gif" ]
                    []
                ]
          else if List.length model.items == 0 then
            text "Hurrah!"
          else
            text ""
        ]


viewItem : Int -> Item -> Html Msg
viewItem index item =
    tr
        []
        [ td [] [ text (toString (index + 1)) ]
        , td [] [ text item.r ]
        , td [] [ text (viewDate item.t) ]
        ]


viewDate : String -> String
viewDate input =
    case Date.fromString input of
        Err msg ->
            "n/a"

        Ok date ->
            Date.Format.format "%Y-%m-%d %H:%M:%S" date



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.suppressionErrorPort ErrorMsg
        , Ports.suppressionSuccessPort (decodeItems >> SuccessMsg)
        ]



-- DECODERS


itemsDecoder : Json.Decode.Decoder (List Item)
itemsDecoder =
    Json.Decode.list itemDecoder


itemDecoder : Json.Decode.Decoder Item
itemDecoder =
    Json.Decode.Pipeline.decode Item
        |> Json.Decode.Pipeline.required "r" (string)
        |> Json.Decode.Pipeline.required "m" (string)
        |> Json.Decode.Pipeline.required "t" (string)


decodeItems : Json.Decode.Value -> List Item
decodeItems input =
    case Json.Decode.decodeValue itemsDecoder input of
        Err msg ->
            []

        Ok items ->
            items
