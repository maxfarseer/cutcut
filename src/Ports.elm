port module Ports exposing (IncomingMsg(..), OutgoingMsg(..), StickerUploadError, listenToJs, sendToJs)

import Base64 exposing (Base64ImgUrl)
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
    = CropImage Base64ImgUrl
    | PrepareForErase Base64ImgUrl
    | AddImgFinish
    | SaveCroppedImage
    | DownloadSticker
    | RequestUploadToPack
    | AddText String


type IncomingMsg
    = ImageSaved String
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
            CropImage base64 ->
                { action = "CropImage", payload = Encode.string base64 }

            PrepareForErase base64img ->
                { action = "PrepareForErase"
                , payload =
                    Encode.string base64img
                }

            AddImgFinish ->
                { action = "AddImgFinish", payload = Encode.null }

            AddText text ->
                { action = "AddText", payload = Encode.string text }

            SaveCroppedImage ->
                { action = "SaveCroppedImage", payload = Encode.null }

            DownloadSticker ->
                { action = "DownloadSticker", payload = Encode.null }

            RequestUploadToPack ->
                { action = "RequestUploadToPack", payload = Encode.null }



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
                    "ImageSaved" ->
                        -- Decode.map ImageSaved (payloadDecoder Decode.string) is equal to
                        Decode.string
                            |> payloadDecoder
                            |> Decode.map ImageSaved

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
                    let
                        _ =
                            Debug.log "error listenToJs" str
                    in
                    decodeErrorTag "TODO: better decoder error"
