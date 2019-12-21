module Ui.Modal exposing (view)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (attribute, class, css, disabled, id, multiple, name, src, type_)
import Html.Styled.Events exposing (on, onClick)


type alias ViewConfig msg =
    { closeMsg : msg
    , open : Bool
    , title : String
    }


view : ViewConfig msg -> List (Html.Styled.Attribute msg) -> List (Html msg) -> Html msg
view config attrs body =
    if config.open then
        div (class "modal is-active" :: attrs)
            [ div [ class "modal-background", onClick config.closeMsg ]
                []
            , div [ class "modal-card" ]
                [ header [ class "modal-card-head" ]
                    [ p [ class "modal-card-title" ]
                        [ text config.title ]
                    , button [ onClick config.closeMsg, attribute "aria-label" "close", class "delete" ]
                        []
                    ]
                , section [ class "modal-card-body" ]
                    body
                , footer [ class "modal-card-foot" ]
                    [ button [ class "button is-success" ]
                        [ text "Save changes" ]
                    , button [ onClick config.closeMsg, class "button" ]
                        [ text "Cancel" ]
                    ]
                ]
            ]

    else
        text ""
