module AddImgV2 exposing (..)

import Css exposing (..)
import Custom exposing (customCropper)
import Dict exposing (Dict)
import File exposing (File)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, disabled, id, multiple, name, src, type_)
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
    | Crop Base64
    | Erase


type Msg
    = ClickedAddImg
    | GotFiles (List File)
    | GotFileUrl Base64
    | ClickedCloseModal


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
            ( { model | step = Crop base64 }, sendToJs <| CropImage base64 )

        ClickedCloseModal ->
            ( { model | step = Add }, Cmd.none )


view : Model -> Html Msg
view model =
    case model.step of
        Add ->
            viewUploadFileBtn

        Crop base64 ->
            Ui.Modal.view
                { title = "Add image"
                , open = True
                , closeMsg = ClickedCloseModal
                }
                []
                [ viewCustomCropper ]

        Erase ->
            div []
                [ text "Erase image" ]


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
