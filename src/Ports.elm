port module Ports exposing (IncomingMsg(..), OutgoingMsg(..), listenToJs, sendToJs)

import Json.Decode as Decode exposing (Decoder)
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
    | DownloadSticker


type IncomingMsg
    = ImageSaved
    | ImageAddedToFabric
    | UnknownIncomingMessage String


{-| Send messages to JS
-}
port msgForJs : PortData -> Cmd msg


{-| Listen to messages from JS
-}
port msgForElm : (Decode.Value -> msg) -> Sub msg


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

            DownloadSticker ->
                { action = "DownloadSticker", payload = Encode.null }



-- SUBSCRIPTION


incomingMsgDecoder : Decoder IncomingMsg
incomingMsgDecoder =
    Decode.field "action" Decode.string
        |> Decode.andThen
            (\action ->
                case action of
                    "ImageSaved" ->
                        Decode.succeed ImageSaved

                    "ImageAddedToFabric" ->
                        Decode.succeed ImageAddedToFabric

                    _ ->
                        Decode.succeed <|
                            UnknownIncomingMessage
                                ("Decoder for incoming messages failed, because of unknown action name " ++ action)
            )


listenToJs : (IncomingMsg -> msg) -> (String -> msg) -> Sub msg
listenToJs decodeSuccessTag decodeErrorTag =
    msgForElm <|
        \dataToDecode ->
            case Decode.decodeValue incomingMsgDecoder dataToDecode of
                Ok incomingMsg ->
                    decodeSuccessTag incomingMsg

                Err _ ->
                    decodeErrorTag "TODO: better decoder error"
