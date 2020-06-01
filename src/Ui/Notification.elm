module Ui.Notification exposing (showError)

import Html.Styled exposing (Html, button, div, text)
import Html.Styled.Attributes exposing (class)
import Html.Styled.Events exposing (onClick)


type alias ViewConfig msg =
    { text : String
    , closeMsg : msg
    }


showError : ViewConfig msg -> Html msg
showError config =
    div [ class "custom-notification" ]
        [ div [ class "columns" ]
            [ div [ class "notification is-danger column is-5" ]
                [ button
                    [ class "delete"
                    , onClick config.closeMsg
                    ]
                    []
                , text config.text
                ]
            ]
        ]
