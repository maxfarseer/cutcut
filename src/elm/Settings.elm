module Settings exposing (Model, Msg, init, subscriptions, update, view)

import EnvSettings exposing (IncomingMsg(..), OutgoingMsg(..), sendToStoragePort)
import Html.Styled exposing (Html, a, button, div, h1, h2, header, input, label, li, p, section, span, text, ul)
import Html.Styled.Attributes exposing (class, href, placeholder, target, type_, value)
import Html.Styled.Events exposing (onClick, onInput)


type alias Model =
    EnvSettings.Model


type Msg
    = TelegramBotTokenChanged String
    | TelegramUserIdChanged String
    | TelegramBotIdChanged String
    | TelegramBotStickerPackNameChanged String
    | RemoveBgApiKeyChanged String
    | ClickedSave


type InputName
    = TelegramBotToken
    | TelegramUserId
    | TelegramBotId
    | TelegramBotStickerPackName
    | RemoveBgApiKey


init : () -> ( Model, Cmd Msg )
init _ =
    ( EnvSettings.empty, sendToStoragePort <| AskForSettingsFromLS )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TelegramBotTokenChanged value ->
            ( { model | telegramBotToken = value }, Cmd.none )

        TelegramUserIdChanged value ->
            ( { model | telegramUserId = value }, Cmd.none )

        TelegramBotIdChanged value ->
            ( { model | telegramBotId = value }, Cmd.none )

        TelegramBotStickerPackNameChanged value ->
            ( { model | telegramBotStickerPackName = value }, Cmd.none )

        RemoveBgApiKeyChanged value ->
            ( { model | removeBgApiKey = value }, Cmd.none )

        ClickedSave ->
            ( model, sendToStoragePort <| SaveSettingsToLS model )


view : Model -> Html Msg
view model =
    section []
        [ div [ class "container" ]
            [ h1 [ class "title" ] [ text "Settings" ]
            , h2 [ class "subtitle" ] [ text "Apply your settings" ]
            , div [ class "columns" ]
                [ div [ class "column is-5" ]
                    [ div [ class "columns" ]
                        [ div [ class "column" ]
                            [ viewInput TelegramBotTokenChanged TelegramBotToken model
                            , viewInput TelegramUserIdChanged TelegramUserId model
                            , viewInput TelegramBotIdChanged TelegramBotId model
                            , viewInput TelegramBotStickerPackNameChanged TelegramBotStickerPackName model
                            , viewInput RemoveBgApiKeyChanged RemoveBgApiKey model
                            ]
                        ]
                    ]
                , div [ class "column" ]
                    [ div [ class "columns" ]
                        [ div [ class "column" ]
                            [ div
                                [ class "card" ]
                                [ header [ class "card-header" ]
                                    [ p [ class "card-header-title" ]
                                        [ text "Where can I find settings?" ]
                                    ]
                                , div [ class "card-content" ]
                                    [ div [ class "content" ]
                                        [ viewCardContent
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            , div [ class "columns" ]
                [ div [ class "column" ]
                    [ button
                        [ class "button is-info"
                        , onClick ClickedSave
                        ]
                        [ text "Save" ]
                    ]
                ]
            ]
        ]


viewInput : (String -> Msg) -> InputName -> Model -> Html Msg
viewInput onChange inputName model =
    div [ class "field" ]
        [ label
            [ class "label" ]
            [ text (returnPlaceholder inputName) ]
        , div [ class "control" ]
            [ input
                [ class "input"
                , type_ "password"
                , onInput onChange
                , placeholder ("Enter " ++ returnPlaceholder inputName)
                , value (returnValue model inputName)
                ]
                []
            ]
        ]


viewCardContent : Html Msg
viewCardContent =
    ul []
        [ li []
            [ text "TELEGRAM_BOT_TOKEN, read "
            , a
                [ href "https://core.telegram.org/bots/api#authorizing-your-bot"
                , target "_blank"
                ]
                [ text "documentation" ]
            , text " chapter"
            ]
        , li
            []
            [ text "TELEGRAM_BOT_ID, same link as before" ]
        , li
            []
            [ text "TELEGRAM_BOT_STICKER_PACK_NAME, same link as before" ]
        , li
            []
            [ text "TELEGRAM_USER_ID, use "
            , span [ class "has-background-info-light" ] [ text "@jsondumpbot" ]
            , text " in Telegram"
            ]
        , li
            []
            [ text "REMOVE_BG_API_KEY, you can find the key "
            , a
                [ href "https://www.remove.bg/profile#api-key"
                , target "_blank"
                ]
                [ text "here" ]
            , text " after registration"
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

        TelegramBotStickerPackName ->
            "telegramBotStickerPackName"

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

        TelegramBotStickerPackName ->
            model.telegramBotStickerPackName

        RemoveBgApiKey ->
            model.removeBgApiKey


subscriptions : Sub Msg
subscriptions =
    Sub.none
