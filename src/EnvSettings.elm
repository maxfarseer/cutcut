port module EnvSettings exposing
    ( IncomingMsg(..)
    , Model
    , OutgoingMsg(..)
    , empty
    , msgForEnvSettings
    , sendToStoragePort
    , settingsDecoder
    , settingsEncoder
    , update
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
    = LoadedSettingsFromLS JD.Value


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


incomingMsgDecoder : JD.Decoder String
incomingMsgDecoder =
    JD.field "action" JD.string


settingsDecoder : JD.Decoder Model
settingsDecoder =
    JD.map4 Model
        (JD.field "telegramBotToken" JD.string)
        (JD.field "telegramUserId" JD.string)
        (JD.field "telegramBotId" JD.string)
        (JD.field "removeBgApiKey" JD.string)
        |> JD.field "payload"



-- To JS


port msgForStorage : PortData -> Cmd msg


sendToStoragePort : OutgoingMsg -> Cmd msg
sendToStoragePort outgoingMsg =
    msgForStorage <|
        case outgoingMsg of
            SaveSettingsToLS settings ->
                { action = "SaveSettingsToLS", payload = settingsEncoder settings }

            AskForSettingsFromLS ->
                { action = "AskForSettingsFromLS", payload = JE.null }



-- From JS


port msgForEnvSettings : (JD.Value -> msg) -> Sub msg


update : JD.Value -> Model
update json =
    case JD.decodeValue incomingMsgDecoder json of
        Ok incomingMsg ->
            case incomingMsg of
                "LoadedSettingsFromLS" ->
                    case JD.decodeValue settingsDecoder json of
                        Ok data ->
                            data

                        Err err ->
                            let
                                _ =
                                    Debug.log "Decode settings error" err
                            in
                            empty

                _ ->
                    let
                        _ =
                            Debug.log "unsupported message" incomingMsg
                    in
                    empty

        Err err ->
            let
                _ =
                    Debug.todo "Add error message to the user"
            in
            empty
