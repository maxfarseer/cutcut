module AddImg exposing (Model, Msg, closeModal, init, setRemoveBgOrNotStep, update, view)

import Base64 exposing (Base64ImgUrl)
import Custom exposing (customCropper, customEraser)
import File exposing (File)
import Html.Styled exposing (Html, button, div, form, i, input, label, p, span, text)
import Html.Styled.Attributes exposing (class, multiple, name, type_)
import Html.Styled.Events exposing (on, onClick)
import Http as Http
import Json.Decode as D
import Ports exposing (OutgoingMsg(..), sendToJs)
import Task
import Ui.Modal


type alias Model =
    { step : Step
    , base64image : Maybe Base64ImgUrl
    , uploadStatus : UploadStatus
    , error : Maybe String
    }


type UploadStatus
    = NotAsked
    | Loading
    | Errored Http.Error


type Step
    = Add
    | Crop
    | RemoveBgOrNot
    | Erase
    | Error


type Msg
    = GotFiles (List File)
    | GotFileUrl String
    | ClickedCloseModal
    | ClickedEraseFinish
    | ClickedCropFinish
    | ClickedRemoveBg
    | ClickedNotRemoveBg


init : Model
init =
    { step = Add
    , base64image = Nothing
    , uploadStatus = NotAsked
    , error = Nothing
    }



-- DECODERS


filesDecoder : D.Decoder (List File)
filesDecoder =
    D.at [ "target", "files" ] (D.list File.decoder)


setRemoveBgOrNotStep : Model -> Base64ImgUrl -> ( Model, Cmd Msg )
setRemoveBgOrNotStep model img =
    ( { model | step = RemoveBgOrNot, base64image = Just img }, Cmd.none )


closeModal : Model -> Model
closeModal model =
    { model | step = Add }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotFiles files ->
            case List.head files of
                Nothing ->
                    ( model, Cmd.none )

                Just file ->
                    ( model, Task.perform GotFileUrl <| File.toUrl file )

        GotFileUrl base64 ->
            ( { model | step = Crop }, sendToJs <| CropImage base64 )

        ClickedCloseModal ->
            ( { model | step = Add }, Cmd.none )

        ClickedCropFinish ->
            ( model, sendToJs <| SaveCroppedImage )

        ClickedRemoveBg ->
            case model.base64image of
                Just base64string ->
                    ( { model | step = Erase }, sendToJs <| PrepareForErase True base64string )

                Nothing ->
                    ( { model | step = Error, error = Just "Problem with image..." }, Cmd.none )

        ClickedNotRemoveBg ->
            case model.base64image of
                Just base64string ->
                    ( { model | step = Erase }, sendToJs <| PrepareForErase False base64string )

                Nothing ->
                    ( { model | step = Error, error = Just "Problem with image..." }, Cmd.none )

        ClickedEraseFinish ->
            ( { model | step = Erase }, sendToJs <| AddImgFinish )


view : Model -> Html Msg
view model =
    case model.step of
        Add ->
            viewUploadFileBtn

        Crop ->
            Ui.Modal.view
                { title = "Add image: Crop"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = ClickedCropFinish
                , confirmText = Just "Crop"
                }
                []
                [ viewCustomCropper
                ]

        RemoveBgOrNot ->
            Ui.Modal.view
                { title = "Remove background?"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = ClickedCropFinish
                , confirmText = Nothing
                }
                []
                [ viewRemoveBgQuestion
                ]

        Erase ->
            Ui.Modal.view
                { title = "Add image: Erase"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = ClickedEraseFinish
                , confirmText = Just "Finish"
                }
                []
                [ viewCustomEraser
                ]

        Error ->
            case model.error of
                Just err ->
                    Ui.Modal.view
                        { title = "Add image: Error"
                        , open = True
                        , closeMsg = ClickedCloseModal
                        , confirmMsg = ClickedCloseModal
                        , confirmText = Just "Close & try again"
                        }
                        []
                        [ viewError err
                        ]

                Nothing ->
                    let
                        _ =
                            Debug.log "impossible case, check AddImg module"
                    in
                    text ""


viewUploadFileBtn : Html Msg
viewUploadFileBtn =
    form [ class "column is-2" ]
        [ div [ class "file" ]
            [ label [ class "file-label" ]
                [ input
                    [ class "file-input"
                    , name "resume"
                    , type_ "file"
                    , multiple False
                    , on "change" (D.map GotFiles filesDecoder)
                    ]
                    []
                , span [ class "file-cta" ]
                    [ span [ class "file-icon" ]
                        [ i [ class "fas fa-upload" ]
                            []
                        ]
                    , span [ class "file-label" ]
                        [ text "Add image" ]
                    ]
                ]
            ]
        ]


viewCustomCropper : Html Msg
viewCustomCropper =
    customCropper
        []
        []


viewRemoveBgQuestion : Html Msg
viewRemoveBgQuestion =
    div []
        [ button [ onClick ClickedRemoveBg ] [ text "Yes, please remove" ]
        , button [ onClick ClickedNotRemoveBg ] [ text "No, do not remove" ]
        ]


viewCustomEraser : Html Msg
viewCustomEraser =
    customEraser
        []
        []


viewError : String -> Html Msg
viewError errorStr =
    div []
        [ p [] [ text errorStr ]
        ]
