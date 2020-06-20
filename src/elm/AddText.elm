module AddText exposing (Model, Msg, init, update, view)

import Html.Styled exposing (Html, button, input, text)
import Html.Styled.Attributes exposing (class, placeholder, value)
import Html.Styled.Events exposing (onClick, onInput)
import Ports exposing (OutgoingMsg(..), sendToJs)
import Tracking exposing (trackWithPayload)
import Ui.Modal


type alias TextConfig =
    { text : String }


type Model
    = ModalOpen TextConfig
    | ModalClosed


init : Model
init =
    ModalClosed


type Msg
    = InputChanged String
    | ClickedCloseModal
    | ClickedOpenAddTextModal
    | ClickedAddText


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedCloseModal ->
            ( ModalClosed, Cmd.none )

        ClickedOpenAddTextModal ->
            ( ModalOpen { text = "" }, Cmd.none )

        InputChanged value ->
            ( ModalOpen { text = value }, Cmd.none )

        ClickedAddText ->
            case model of
                ModalOpen config ->
                    let
                        trackTextEvent =
                            { name = "ClickedAddText"
                            , category = "Editor"
                            , label = "Add text"
                            , value = config.text
                            }
                    in
                    ( ModalClosed
                    , Cmd.batch
                        [ sendToJs <| AddText config.text
                        , trackWithPayload trackTextEvent
                        ]
                    )

                ModalClosed ->
                    -- impossible case
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case model of
        ModalClosed ->
            viewAddTextBtn

        ModalOpen config ->
            Ui.Modal.view
                { title = "Add text"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = Just ClickedAddText
                , confirmText = Just "Add"
                }
                []
                [ viewAddTextModalBody config
                ]


viewAddTextBtn : Html Msg
viewAddTextBtn =
    button [ class "button is-info", onClick ClickedOpenAddTextModal ]
        [ text "Add text" ]


viewAddTextModalBody : TextConfig -> Html Msg
viewAddTextModalBody config =
    input
        [ class "input"
        , onInput InputChanged
        , placeholder "Enter the text..."
        , value config.text
        ]
        []
