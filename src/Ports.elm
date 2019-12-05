port module Ports exposing (OutgoingMsg(..), sendToJs)

import Json.Encode as Encode


type alias PortData =
    { action : String
    , payload : Encode.Value
    }


type alias Base64 =
    String


type OutgoingMsg
    = DrawSquare Base64


{-| Send messages to JS
-}
port msgForJs : PortData -> Cmd msg


sendToJs : OutgoingMsg -> Cmd msg
sendToJs outgoingMsg =
    msgForJs <|
        case outgoingMsg of
            DrawSquare base64 ->
                { action = "DrawSquare", payload = Encode.string base64 }
