module Settings exposing (Model, Msg, init, update, view)

import Html.Styled exposing (Html, div, h1, h2, input, section, text)
import Html.Styled.Attributes exposing (class, placeholder, value)
import Html.Styled.Events exposing (onInput)


type alias Model =
    { telegramBotToken : String
    , telegramUserId : String
    , telegramBotId : String
    , removeBgApiKey : String
    }


type Msg
    = TelegramBotTokenChanged String
    | TelegramUserIdChanged String
    | TelegramBotIdChanged String
    | RemoveBgApiKeyChanged String


type InputName
    = TelegramBotToken
    | TelegramUserId
    | TelegramBotId
    | RemoveBgApiKey


init : Model
init =
    { telegramBotToken = ""
    , telegramUserId = ""
    , telegramBotId = ""
    , removeBgApiKey = ""
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TelegramBotTokenChanged value ->
            ( { model | telegramBotToken = value }, Cmd.none )

        TelegramUserIdChanged value ->
            ( { model | telegramUserId = value }, Cmd.none )

        TelegramBotIdChanged value ->
            ( { model | telegramBotId = value }, Cmd.none )

        RemoveBgApiKeyChanged value ->
            ( { model | removeBgApiKey = value }, Cmd.none )


view : Model -> Html Msg
view model =
    section []
        [ div [ class "container" ]
            [ h1 [ class "title" ] [ text "Settings" ]
            , h2 [ class "subtitle" ] [ text "Apply your settings" ]
            , div [ class "columns" ]
                [ div [ class "column is-7" ]
                    [ div [ class "columns" ]
                        [ div [ class "column is-8" ]
                            [ viewInput TelegramBotTokenChanged TelegramBotToken model
                            , viewInput TelegramUserIdChanged TelegramUserId model
                            , viewInput TelegramBotIdChanged TelegramBotId model
                            , viewInput RemoveBgApiKeyChanged RemoveBgApiKey model
                            ]
                        ]
                    ]
                , div [ class "column" ] []
                ]
            ]
        ]


viewInput : (String -> Msg) -> InputName -> Model -> Html Msg
viewInput onChange inputName model =
    div [ class "field" ]
        [ div [ class "control" ]
            [ input
                [ class "input"
                , onInput onChange
                , placeholder ("Enter " ++ returnPlaceholder inputName)
                , value (returnValue model inputName)
                ]
                []
            ]
        ]


returnPlaceholder : InputName -> String
returnPlaceholder inputName =
    case inputName of
        TelegramBotToken ->
            "telegramBotToken"

        TelegramUserId ->
            "telegramUserId"

        TelegramBotId ->
            "telegramBotId"

        RemoveBgApiKey ->
            "removeBgApiKey"


returnValue : Model -> InputName -> String
returnValue model inputName =
    case inputName of
        TelegramBotToken ->
            model.telegramBotToken

        TelegramUserId ->
            model.telegramUserId

        TelegramBotId ->
            model.telegramBotId

        RemoveBgApiKey ->
            model.removeBgApiKey
