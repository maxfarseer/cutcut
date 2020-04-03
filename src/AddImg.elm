module AddImg exposing (Model, Msg, closeModal, init, setRemoveBgOrNotStep, update, view)

import Base64 exposing (Base64ImgUrl)
import Custom exposing (customCropper, customEraser)
import EnvAliases exposing (RemoveBgApiKey)
import File exposing (File)
import Html.Styled exposing (Html, a, button, div, form, i, input, label, p, span, text)
import Html.Styled.Attributes exposing (class, classList, disabled, href, multiple, name, target, type_)
import Html.Styled.Events exposing (on, onClick)
import Http as Http
import Json.Decode as JD
import Json.Encode as JE
import Ports exposing (OutgoingMsg(..), sendToJs)
import Task
import Ui.Modal


type alias Model =
    { step : Step
    , base64image : Maybe Base64ImgUrl
    , uploadStatus : UploadStatus
    , error : Maybe String
    , removeBgApiKey : RemoveBgApiKey
    }


type UploadStatus
    = NotAsked
    | Loading
    | Errored Http.Error


type Step
    = Add
    | Crop
    | RemoveBgOrNot UploadStatus
    | Erase
    | Error


type Msg
    = GotFiles (List File)
    | GotFileUrl String
    | GotRemoveBgResponse (Result Http.Error Base64ImgUrl)
    | ClickedCloseModal
    | ClickedEraseFinish
    | ClickedCropFinish
    | ClickedRemoveBg
    | ClickedNotRemoveBg


init : RemoveBgApiKey -> Model
init removeBgApiKey =
    { step = Add
    , base64image = Nothing
    , uploadStatus = NotAsked
    , error = Nothing
    , removeBgApiKey = removeBgApiKey
    }



-- DECODERS


filesDecoder : JD.Decoder (List File)
filesDecoder =
    JD.at [ "target", "files" ] (JD.list File.decoder)


setRemoveBgOrNotStep : Model -> Base64ImgUrl -> ( Model, Cmd Msg )
setRemoveBgOrNotStep model img =
    ( { model | step = RemoveBgOrNot NotAsked, base64image = Just img }, Cmd.none )


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
                    ( { model | step = RemoveBgOrNot Loading }
                    , Http.request
                        { url = "https://api.remove.bg/v1.0/removebg"
                        , headers =
                            [ Http.header "X-Api-Key" model.removeBgApiKey
                            , Http.header "Accept" "application/json"
                            ]
                        , method = "POST"
                        , timeout = Nothing
                        , tracker = Nothing
                        , body = Http.jsonBody <| removeBgRequestEncoder base64string
                        , expect = Http.expectJson GotRemoveBgResponse fileBgDecoder
                        }
                    )

                Nothing ->
                    ( { model | step = Error, error = Just "Problem with image..." }, Cmd.none )

        GotRemoveBgResponse result ->
            case result of
                Err err ->
                    ( { model | step = RemoveBgOrNot <| Errored err }, Cmd.none )

                Ok base64data ->
                    let
                        base64imgUrl =
                            "data:image/png;base64, " ++ base64data
                    in
                    ( { model | step = Erase }, sendToJs <| PrepareForErase base64imgUrl )

        ClickedNotRemoveBg ->
            case model.base64image of
                Just base64imgUrl ->
                    ( { model | step = Erase }, sendToJs <| PrepareForErase base64imgUrl )

                Nothing ->
                    ( { model | step = Error, error = Just "Problem with image..." }, Cmd.none )

        ClickedEraseFinish ->
            ( { model | step = Erase }, sendToJs <| AddImgFinish )



-- ENCODERS


removeBgRequestEncoder : Base64ImgUrl -> JE.Value
removeBgRequestEncoder imgUrl =
    JE.object
        [ ( "image_file_b64", JE.string imgUrl )
        ]



-- DECODERS


fileBgDecoder : JD.Decoder Base64ImgUrl
fileBgDecoder =
    JD.field "data" (JD.field "result_b64" JD.string)



-- VIEW


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

        RemoveBgOrNot status ->
            Ui.Modal.view
                { title = "Add image: Background"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = Nothing
                , confirmText = Nothing
                }
                []
                [ viewRemoveBgQuestion status
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
                    , on "change" (JD.map GotFiles filesDecoder)
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


viewRemoveBgQuestion : UploadStatus -> Html Msg
viewRemoveBgQuestion status =
    let
        confirmBtnOrError =
            case status of
                Loading ->
                    viewRemoveBgConfirmBtn True

                NotAsked ->
                    viewRemoveBgConfirmBtn False

                Errored err ->
                    viewRemoveBgErrorBlock err
    in
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
                [ confirmBtnOrError ]
            , div [ class "column is-3" ]
                [ button [ class "button is-small", onClick ClickedNotRemoveBg ] [ text "No, do not remove" ]
                ]
            ]
        ]


viewRemoveBgConfirmBtn : Bool -> Html Msg
viewRemoveBgConfirmBtn isLoading =
    button
        [ classList
            [ ( "button is-small", True )
            , ( "is-info", True )
            , ( "is-loading", isLoading == True )
            ]
        , onClick ClickedRemoveBg
        , disabled isLoading
        ]
        [ text "Yes, please remove" ]


viewRemoveBgErrorBlock : Http.Error -> Html Msg
viewRemoveBgErrorBlock err =
    -- TODO: better err markup (case of + text )
    p []
        [ text "Error with auto remove background" ]


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
