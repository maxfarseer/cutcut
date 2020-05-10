port module Ports exposing (IncomingMsg(..), OutgoingMsg(..), StickerUploadError, listenToJs, sendToJs)

import Base64 exposing (Base64ImgUrl, decoderStringToBase64ImgUrl, toString)
import EnvSettings exposing (settingsEncoder)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type alias PortData =
    { action : String
    , payload : Encode.Value
    }


type alias StickerUploadError =
    { code : Int
    , description : String
    }


type OutgoingMsg
    = CropImageInit Base64ImgUrl
    | PrepareForErase Base64ImgUrl
    | AddImgFinish
    | CropImage
    | DownloadSticker
    | RequestUploadToPack
    | AddText String
    | SaveSettingsToLS EnvSettings.Model
    | AskForSettingsFromLS


type IncomingMsg
    = ImageCropped Base64ImgUrl
    | ImageAddedToFabric
    | UnknownIncomingMessage String
    | StickerUploadedSuccess
    | StickerUploadedFailure StickerUploadError


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
            CropImageInit base64 ->
                { action = "CropImageInit", payload = Encode.string (toString base64) }

            PrepareForErase base64img ->
                { action = "PrepareForErase"
                , payload =
                    Encode.string (toString base64img)
                }

            AddImgFinish ->
                { action = "AddImgFinish", payload = Encode.null }

            AddText text ->
                { action = "AddText", payload = Encode.string text }

            CropImage ->
                { action = "CropImage", payload = Encode.null }

            DownloadSticker ->
                { action = "DownloadSticker", payload = Encode.null }

            RequestUploadToPack ->
                { action = "RequestUploadToPack", payload = Encode.null }

            SaveSettingsToLS settings ->
                { action = "SaveSettingsToLS", payload = settingsEncoder settings }

            AskForSettingsFromLS ->
                { action = "AskForSettingsFromLS", payload = Encode.null }



-- DECODERS


payloadDecoder : Decoder value -> Decoder value
payloadDecoder decoder =
    Decode.field "payload" decoder


stickerUploadFailureDecoder : Decoder StickerUploadError
stickerUploadFailureDecoder =
    Decode.map2 StickerUploadError
        (Decode.field "code" Decode.int)
        (Decode.field "description" Decode.string)



-- SUBSCRIPTION


incomingMsgDecoder : Decoder IncomingMsg
incomingMsgDecoder =
    Decode.field "action" Decode.string
        |> Decode.andThen
            (\action ->
                case action of
                    "ImageCropped" ->
                        -- Decode.map ImageCropped (payloadDecoder Decode.string) is equal to
                        decoderStringToBase64ImgUrl
                            |> payloadDecoder
                            |> Decode.map ImageCropped

                    "ImageAddedToFabric" ->
                        Decode.succeed ImageAddedToFabric

                    "StickerUploadedSuccess" ->
                        Decode.succeed StickerUploadedSuccess

                    "StickerUploadedFailure" ->
                        stickerUploadFailureDecoder
                            |> payloadDecoder
                            |> Decode.map StickerUploadedFailure

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

                Err str ->
                    decodeErrorTag "TODO: better decoder error"
