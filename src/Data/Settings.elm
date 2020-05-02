module Data.Settings exposing (Model, empty, settingsDecoder, settingsEncoder)

import Json.Decode as JD
import Json.Encode as JE


type alias Model =
    { telegramBotToken : String
    , telegramUserId : String
    , telegramBotId : String
    , removeBgApiKey : String
    }


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


settingsDecoder : JD.Decoder Model
settingsDecoder =
    JD.map4 Model
        (JD.field "telegramBotToken" JD.string)
        (JD.field "telegramUserId" JD.string)
        (JD.field "telegramBotId" JD.string)
        (JD.field "removeBgApiKey" JD.string)
