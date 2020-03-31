module Ui.Modal exposing (view)

import Html.Styled exposing (Html, button, div, footer, header, p, section, text)
import Html.Styled.Attributes exposing (attribute, class)
import Html.Styled.Events exposing (onClick)


type alias ViewConfig msg =
    { closeMsg : msg
    , confirmMsg : Maybe msg
    , confirmText : Maybe String
    , open : Bool
    , title : String
    }


view : ViewConfig msg -> List (Html.Styled.Attribute msg) -> List (Html msg) -> Html msg
view config attrs body =
    if config.open then
        let
            confirmBtn =
                case config.confirmMsg of
                    Just msg ->
                        button [ onClick msg, class "button is-info" ]
                            [ text <| Maybe.withDefault "Save changes" config.confirmText ]

                    Nothing ->
                        text ""
        in
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
                    [ confirmBtn
                    , button [ onClick config.closeMsg, class "button" ]
                        [ text "Cancel" ]
                    ]
                ]
            ]

    else
        text ""
