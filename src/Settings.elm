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
    = InputChanged String


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
        InputChanged value ->
            ( { model | telegramBotId = value }, Cmd.none )


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
                            [ input
                                [ class "input"
                                , onInput InputChanged
                                , placeholder "Enter telegramBotId"
                                , value model.telegramBotId
                                ]
                                []
                            ]
                        ]
                    ]
                , div [ class "column" ] []
                ]
            ]
        ]
