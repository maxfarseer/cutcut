module Data.Settings exposing (Model)


type alias Model =
    { telegramBotToken : String
    , telegramUserId : String
    , telegramBotId : String
    , removeBgApiKey : String
    }
