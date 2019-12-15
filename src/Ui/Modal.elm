module Ui.Modal exposing (view)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, disabled, id, multiple, name, src, type_)
import Html.Styled.Events exposing (on, onClick)


type alias ViewConfig msg =
    { closeMsg : msg
    , open : Bool
    , title : String
    }


view : ViewConfig msg -> List (Html.Styled.Attribute msg) -> List (Html msg) -> Html msg
view config attrs body =
    if config.open then
        div [ class "modal-wrapper" ]
            [ div
                [ class "modal-page-background"
                , onClick config.closeMsg
                ]
                []
            , div (class "modal-content" :: attrs)
                [ div [] [ text <| "modal title: " ++ config.title ]
                , button [ onClick config.closeMsg ] [ text "x icon" ]
                , div [] [ text "modal content" ]
                , div [] body
                ]
            ]

    else
        text ""
