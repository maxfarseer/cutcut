module Settings exposing (Model, Msg, init, subscriptions, update, view)

import Data.Settings
import Html.Styled exposing (Html, button, div, h1, h2, input, label, section, text)
import Html.Styled.Attributes exposing (class, placeholder, type_, value)
import Html.Styled.Events exposing (onClick, onInput)
import Ports exposing (IncomingMsg(..), OutgoingMsg(..), listenToJs, sendToJs)


type alias Model =
    Data.Settings.Model


type Msg
    = TelegramBotTokenChanged String
    | TelegramUserIdChanged String
    | TelegramBotIdChanged String
    | RemoveBgApiKeyChanged String
    | ClickedSave
    | FromJS IncomingMsg
    | FromJSDecodeError String


type InputName
    = TelegramBotToken
    | TelegramUserId
    | TelegramBotId
    | RemoveBgApiKey


init : ( Model, Cmd Msg )
init =
    let
        _ =
            Debug.log "Settings init" "1"
    in
    ( Data.Settings.empty, sendToJs <| AskForSettingsFromLS )


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

        FromJS incomingMsg ->
            let
                _ =
                    Debug.log "settings incoming msg" msg
            in
            case incomingMsg of
                LoadedSettingsFromLS settings ->
                    let
                        _ =
                            Debug.log "settings" settings
                    in
                    ( settings, Cmd.none )

                -- TODO: how can I avoid it here?
                _ ->
                    ( model, Cmd.none )

        FromJSDecodeError err ->
            -- TODO: show error message to user (refactor(?), because we have same in Editor.elm)
            let
                _ =
                    Debug.log "Settings: FromJSDecodeError" err
            in
            ( model, Cmd.none )


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


subscriptions : a -> Sub Msg
subscriptions =
    \_ -> listenToJs FromJS FromJSDecodeError
