module AddImg exposing (Model, Msg, closeModal, init, setRemoveBgOrNotStep, update, view)

import Base64 exposing (Base64ImgUrl)
import Custom exposing (customCropper, customEraser)
import File exposing (File)
import Html.Styled exposing (Html, a, button, div, form, i, input, label, p, span, text)
import Html.Styled.Attributes exposing (class, href, multiple, name, target, type_)
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
                , confirmMsg = Just ClickedCropFinish
                , confirmText = Just "Crop"
                }
                []
                [ viewCustomCropper
                ]

        RemoveBgOrNot ->
            Ui.Modal.view
                { title = "Add image: Background"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = Nothing
                , confirmText = Nothing
                }
                []
                [ viewRemoveBgQuestion
                ]

        Erase ->
            Ui.Modal.view
                { title = "Add image: Erase (beta)"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = Just ClickedEraseFinish
                , confirmText = Just "Finish"
                }
                []
                [ viewEraseStep
                ]

        Error ->
            case model.error of
                Just err ->
                    Ui.Modal.view
                        { title = "Add image: Error"
                        , open = True
                        , closeMsg = ClickedCloseModal
                        , confirmMsg = Nothing
                        , confirmText = Nothing
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
    form []
        [ div [ class "file" ]
            [ label [ class "file-label" ]
                [ input
                    [ class "file-input"
                    , name "upload-pic"
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
        [ div [ class "columns" ]
            [ div [ class "column" ]
                [ p []
                    [ text "You can remove background automatically ("
                    , a
                        [ href "https://www.remove.bg/", target "_blank" ]
                        [ text "remove.bg " ]
                    , text
                        "API is using)"
                    ]
                , p []
                    [ text "Don't forget to setup environment variables with "
                    , a
                        [ href "https://www.remove.bg/api", target "_blank" ]
                        [ text "API key" ]
                    , text
                        ". See example "
                    , a [ href "https://github.com/maxfarseer/cutcut/blob/master/.env.example", target "_blank" ] [ text "here" ]
                    , text "."
                    ]
                ]
            ]
        , div [ class "columns is-centered" ]
            [ div [ class "column is-3" ]
                [ button [ class "button is-small is-info", onClick ClickedRemoveBg ] [ text "Yes, please remove" ]
                ]
            , div [ class "column is-3" ]
                [ button [ class "button is-small", onClick ClickedNotRemoveBg ] [ text "No, do not remove" ]
                ]
            ]
        ]


viewEraseStep : Html Msg
viewEraseStep =
    div []
        [ div [ class "columns" ]
            [ div [ class "column" ]
                [ p []
                    [ text "Use your mouse to erase unnecessary. But, ouch! Erase tool is crazy ;)"
                    ]
                ]
            ]
        , viewCustomEraser
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
