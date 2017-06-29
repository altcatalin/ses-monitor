port module Ports exposing (..)

import Json.Decode exposing (..)


type alias LoginData =
    { username : String
    , password : String
    }


port loginPort : LoginData -> Cmd msg


port loginErrorPort : (String -> msg) -> Sub msg


port loginSuccessPort : (String -> msg) -> Sub msg


port logoutPort : () -> Cmd msg


port suppressionPort : () -> Cmd msg


port suppressionErrorPort : (String -> msg) -> Sub msg


port suppressionSuccessPort : (Value -> msg) -> Sub msg
