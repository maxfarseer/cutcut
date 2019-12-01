module AddImg exposing (Model, Msg(..), init, update, view)

import Accessibility.Modal as Modal
import Css exposing (..)
import Dict exposing (Dict)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, id, multiple, name, src, type_)
import Html.Styled.Events exposing (on, onClick)


type alias Model =
    { modal : Dict Int Modal.Model
    , step : StepModel
    }


type StepModel
    = AddImgStep
    | CropImgStep
    | EraseImtStep


type Msg
    = ClickedAddImg
    | ModalMsg Int Modal.Msg


init : Model
init =
    { modal = Dict.fromList [ ( 0, Modal.init ) ]
    , step = AddImgStep
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedAddImg ->
            ( model, Cmd.none )

        ModalMsg modalId modalMsg ->
            case Dict.get modalId model.modal of
                Just modal ->
                    let
                        ( newModalState, modalCmd ) =
                            Modal.update
                                { dismissOnEscAndOverlayClick = True }
                                modalMsg
                                modal
                    in
                    ( { model | modal = Dict.insert modalId newModalState model.modal }
                    , Cmd.map (ModalMsg modalId) modalCmd
                    )

                Nothing ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    case Dict.get 0 model.modal of
        Just modal ->
            section []
                [ viewModalOpener 0
                , Modal.view (ModalMsg 0)
                    "Add image"
                    [ Modal.overlayColor (rgba 128 0 128 0.7)
                    , Modal.onlyFocusableElementView
                        (\onlyFocusableElement ->
                            div [ css [ displayFlex, justifyContent spaceBetween ] ]
                                [ text "Modal content"
                                , button
                                    (onClick (ModalMsg 0 Modal.close)
                                        :: onlyFocusableElement
                                    )
                                    [ text "Close Modal" ]
                                ]
                        )
                    ]
                    modal
                ]

        Nothing ->
            text ""


viewModalOpener : Int -> Html Msg
viewModalOpener uniqueId =
    let
        elementId =
            "modal__launch-element-" ++ String.fromInt uniqueId
    in
    button
        [ id elementId
        , onClick (ModalMsg uniqueId (Modal.open elementId))
        ]
        [ text "Add image" ]
