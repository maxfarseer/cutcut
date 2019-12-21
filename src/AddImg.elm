module AddImg exposing (Model, Msg, init, update, view)

import Css exposing (..)
import Custom exposing (customCropper)
import File exposing (File)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, multiple, name, type_)
import Html.Styled.Events exposing (on, onClick)
import Http as Http
import Json.Decode as D
import Ports exposing (OutgoingMsg(..), sendToJs)
import Task
import Ui.Modal


type alias Model =
    { step : Step
    , uploadStatus : UploadStatus
    }


type alias Base64 =
    String


type UploadStatus
    = NotAsked
    | Loading
    | Errored Http.Error


type Step
    = Add
    | Crop
    | Erase


type Msg
    = ClickedAddImg
    | GotFiles (List File)
    | GotFileUrl Base64
    | ClickedCloseModal
    | ClickedEraseFinish
    | ClickedCropFinish


init : Model
init =
    { step = Add
    , uploadStatus = NotAsked
    }



-- DECODERS


filesDecoder : D.Decoder (List File)
filesDecoder =
    D.at [ "target", "files" ] (D.list File.decoder)


fileBgDecoder : D.Decoder Base64
fileBgDecoder =
    D.field "data" (D.field "result_b64" D.string)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedAddImg ->
            ( model, Cmd.none )

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
            ( { model | step = Erase }, sendToJs <| PrepareForErase )

        ClickedEraseFinish ->
            ( { model | step = Add }, sendToJs <| RequestCroppedData )


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

        Erase ->
            Ui.Modal.view
                { title = "Add image: Erase"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = ClickedEraseFinish
                , confirmText = Just "Finish"
                }
                []
                [ viewCustomCropper
                ]


viewUploadFileBtn : Html Msg
viewUploadFileBtn =
    form []
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
        [ css
            [ border3 (px 1) solid (rgb 45 0 45)
            , width (px 514)
            , height (px 514)
            , display block
            ]
        ]
        []
