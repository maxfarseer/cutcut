port module EnvSettings exposing
    ( IncomingMsg(..)
    , Model
    , OutgoingMsg(..)
    , empty
    , listenToJs
    , msgFromJsToEnvSettings
    , sendToStoragePort
    , settingsDecoder
    , settingsEncoder
    )

import Json.Decode as JD
import Json.Encode as JE



-- TODO: check duplicate code in Ports, reduce it


type alias PortData =
    { action : String
    , payload : JE.Value
    }


type alias Model =
    { telegramBotToken : String
    , telegramUserId : String
    , telegramBotId : String
    , removeBgApiKey : String
    }


type IncomingMsg
    = EnvSettingsUnknownIncomingMessage String
    | LoadedSettingsFromLS (Maybe Model)
    | SettingsSavedSuccessfully


type OutgoingMsg
    = AskForSettingsFromLS
    | SaveSettingsToLS Model


empty : Model
empty =
    { telegramBotToken = ""
    , telegramUserId = ""
    , telegramBotId = ""
    , removeBgApiKey = ""
    }


settingsEncoder : Model -> JE.Value
settingsEncoder settings =
    JE.object
        [ ( "telegramBotToken", JE.string settings.telegramBotToken )
        , ( "telegramUserId", JE.string settings.telegramUserId )
        , ( "telegramBotId", JE.string settings.telegramBotId )
        , ( "removeBgApiKey", JE.string settings.removeBgApiKey )
        ]


payloadDecoder : JD.Decoder value -> JD.Decoder value
payloadDecoder decoder =
    JD.field "payload" decoder


incomingMsgDecoder : JD.Decoder IncomingMsg
incomingMsgDecoder =
    JD.field "action" JD.string
        |> JD.andThen
            (\action ->
                case action of
                    "LoadedSettingsFromLS" ->
                        settingsDecoder
                            |> payloadDecoder
                            |> JD.map LoadedSettingsFromLS

                    "SettingsSavedSuccessfully" ->
                        JD.succeed SettingsSavedSuccessfully

                    _ ->
                        JD.succeed <|
                            EnvSettingsUnknownIncomingMessage
                                ("Decoder for incoming messages (EnvSettings) failed, because of unknown action name " ++ action)
            )


settingsDecoder : JD.Decoder (Maybe Model)
settingsDecoder =
    JD.map4 Model
        (JD.field "telegramBotToken" JD.string)
        (JD.field "telegramUserId" JD.string)
        (JD.field "telegramBotId" JD.string)
        (JD.field "removeBgApiKey" JD.string)
        |> JD.nullable



-- To JS


port msgForJsStorage : PortData -> Cmd msg


sendToStoragePort : OutgoingMsg -> Cmd msg
sendToStoragePort outgoingMsg =
    msgForJsStorage <|
        case outgoingMsg of
            SaveSettingsToLS settings ->
                { action = "SaveSettingsToLS", payload = settingsEncoder settings }

            AskForSettingsFromLS ->
                { action = "AskForSettingsFromLS", payload = JE.null }



-- From JS


port msgFromJsToEnvSettings : (JD.Value -> msg) -> Sub msg


listenToJs : (IncomingMsg -> msg) -> (String -> msg) -> Sub msg
listenToJs decodeSuccessTag decodeErrorTag =
    msgFromJsToEnvSettings <|
        \dataToDecode ->
            case JD.decodeValue incomingMsgDecoder dataToDecode of
                Ok incomingMsg ->
                    decodeSuccessTag incomingMsg

                Err str ->
                    decodeErrorTag "Error code #2001: Decode json error. Refresh the page and try again. If it doesn't help, ask developer"
