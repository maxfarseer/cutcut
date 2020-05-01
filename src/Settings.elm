module Settings exposing (Model, Msg, init, update, view)

import Data.Settings
import Html.Styled exposing (Html, button, div, h1, h2, input, label, section, text)
import Html.Styled.Attributes exposing (class, placeholder, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Ports exposing (IncomingMsg(..), OutgoingMsg(..), sendToJs)


type alias Model =
    Data.Settings.Model


type Msg
    = TelegramBotTokenChanged String
    | TelegramUserIdChanged String
    | TelegramBotIdChanged String
    | RemoveBgApiKeyChanged String
    | ClickedSave


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

        ClickedSave ->
            ( model, sendToJs <| SaveSettingsToLS model )


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
