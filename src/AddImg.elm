port module AddImg exposing (Model, Msg(..), init, update, view)

import Accessibility.Modal as Modal
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


type alias Model =
    { modal : Dict Int Modal.Model
    , step : StepModel
    , uploadStatus : UploadStatus
    }


type alias Base64 =
    String


type UploadStatus
    = NotAsked
    | Loading
    | Errored Http.Error


type StepModel
    = AddImgStep
    | CropImgStep Base64
    | EraseImgStep


type Msg
    = ClickedAddImg
    | ModalMsg Int Modal.Msg
    | GotFiles (List File)
    | GotPreview Base64
    | GotRemoveBgResponse (Result Http.Error Base64)
    | CropBtnClicked Base64


init : Model
init =
    { modal = Dict.fromList [ ( 0, Modal.init ) ]
    , step = AddImgStep
    , uploadStatus = NotAsked
    }



-- CONST


removeBgApiUrl : String
removeBgApiUrl =
    "https://api.remove.bg/v1.0"



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

        ModalMsg modalId modalMsg ->
            case Dict.get modalId model.modal of
                Just modal ->
                    let
                        ( newModalState, modalCmd ) =
                            Modal.update
                                { dismissOnEscAndOverlayClick = True }
                                modalMsg
                                modal

                        _ =
                            Debug.log "modalMsg" modalMsg
                    in
                    ( { model | modal = Dict.insert modalId newModalState model.modal }
                    , Cmd.map (ModalMsg modalId) modalCmd
                    )

                Nothing ->
                    ( model, Cmd.none )

        GotFiles files ->
            case List.head files of
                Nothing ->
                    ( model, Cmd.none )

                --                Just file ->
                --                    ( { model | uploadStatus = Loading }
                --                    , Http.request
                --                        { url = removeBgApiUrl ++ "/removebg"
                --                        , headers =
                --                            [ Http.header "X-Api-Key" "Ge5HqmTYvcD1UzadQ7MPVPVi"
                --                            , Http.header "Accept" "application/json"
                --                            ]
                --                        , method = "POST"
                --                        , timeout = Nothing
                --                        , tracker = Nothing
                --                        , body = Http.multipartBody [ Http.filePart "image_file" file ]
                --                        , expect = Http.expectJson GotRemoveBgResponse fileBgDecoder
                --                        }
                --                    )
                Just file ->
                    ( model, Task.perform GotPreview <| File.toUrl file )

        GotPreview base64 ->
            ( { model | step = CropImgStep base64 }, Cmd.none )

        CropBtnClicked base64 ->
            ( model, sendToJs (CropImage base64) )

        GotRemoveBgResponse result ->
            case result of
                Err err ->
                    ( { model | uploadStatus = Errored err }, Cmd.none )

                Ok response ->
                    ( model, Cmd.none )



{- Ok response ->
   ( { model
       | step = CropImgStep response
     }
   , sendDataToJs response
   )
-}


view : Model -> Html Msg
view model =
    case Dict.get 0 model.modal of
        Just modal ->
            section []
                [ viewModalOpener 0
                , Modal.view (ModalMsg 0)
                    ""
                    [ Modal.overlayColor (rgba 0 0 0 0.7)
                    , Modal.onlyFocusableElementView
                        (\onlyFocusableElement ->
                            div []
                                [ viewModalBody model
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


viewModalBody : Model -> Html Msg
viewModalBody model =
    case model.step of
        AddImgStep ->
            viewAddImgStep model.uploadStatus

        CropImgStep base64 ->
            viewCropImage base64

        EraseImgStep ->
            div []
                [ text "Erase image" ]


viewAddImgStep : UploadStatus -> Html Msg
viewAddImgStep uploadStatus =
    case uploadStatus of
        NotAsked ->
            div []
                [ viewUploadFileBtn "Remove background" True
                , viewUploadFileBtn "Upload as is (INACTIVE)" False
                ]

        Loading ->
            div []
                [ text "Loading ..." ]

        Errored err ->
            div []
                [ text "Error!" ]


viewCropImage : Base64 -> Html Msg
viewCropImage imgUrl =
    div []
        [ h2 []
            [ text "Crop image" ]
        , button [ onClick <| CropBtnClicked imgUrl ] [ text "Crop init (refactor)" ]
        , viewCustomCropper
        ]


viewUploadFileBtn : String -> Bool -> Html Msg
viewUploadFileBtn btnLabel isActive =
    form []
        [ div [ class "file" ]
            [ label [ class "file-label" ]
                [ input
                    [ class "file-input"
                    , name "resume"
                    , type_ "file"
                    , multiple False
                    , on "change" (D.map GotFiles filesDecoder)
                    , Html.Styled.Attributes.disabled (not isActive)
                    ]
                    []
                , span [ class "file-cta" ]
                    [ span [ class "file-icon" ]
                        [ i [ class "fas fa-upload" ]
                            []
                        ]
                    , span [ class "file-label" ]
                        [ text <| btnLabel ]
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



-- PORTS


port sendDataToJs : String -> Cmd msg
