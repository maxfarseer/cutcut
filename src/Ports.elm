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
    | CropImage Base64
    | PrepareForErase Bool
    | AddImgFinish
    | SaveCroppedImage


{-| Send messages to JS
-}
port msgForJs : PortData -> Cmd msg


sendToJs : OutgoingMsg -> Cmd msg
sendToJs outgoingMsg =
    msgForJs <|
        case outgoingMsg of
            DrawSquare base64 ->
                { action = "DrawSquare", payload = Encode.string base64 }

            CropImage base64 ->
                { action = "CropImage", payload = Encode.string base64 }

            PrepareForErase answer ->
                { action = "PrepareForErase", payload = Encode.bool answer }

            AddImgFinish ->
                { action = "AddImgFinish", payload = Encode.null }

            SaveCroppedImage ->
                { action = "SaveCroppedImage", payload = Encode.null }
