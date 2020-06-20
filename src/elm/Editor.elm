module Editor exposing (Model, Msg, init, subscriptions, update, view)

import AddImg
import AddText
import Css exposing (block, border3, display, height, px, rgb, solid, width)
import Custom exposing (customCanvas)
import EnvAliases exposing (RemoveBgApiKey)
import EnvSettings exposing (OutgoingMsg(..), sendToStoragePort)
import Html.Styled exposing (Html, button, div, h1, h2, map, p, section, text)
import Html.Styled.Attributes exposing (class, css, disabled)
import Html.Styled.Events exposing (onClick)
import Ports exposing (IncomingMsg(..), OutgoingMsg(..), StickerUploadError, listenToJs, sendToJs)
import Tracking exposing (trackEvent)
import Ui.Notification


type UploadStickerStatus
    = NotAsked
    | Loading
    | Errored StickerUploadError
    | Success


type Notification
    = None
    | UnknownIncomingMessageFromJs String
    | DecodeErrorFromJsEditor String
    | SettingsNotExist
    | SettingsForTelegramMissing
    | UploadedSticker


type alias Model =
    { addImg : AddImg.Model
    , addText : AddText.Model
    , uploadStickerStatus : UploadStickerStatus
    , notification : Notification
    }


init : RemoveBgApiKey -> ( Model, Cmd Msg )
init removeBgApiKey =
    ( { addImg = AddImg.init removeBgApiKey
      , addText = AddText.init
      , uploadStickerStatus = NotAsked
      , notification = None
      }
    , sendToStoragePort <| AskForSettingsFromLS
    )


type Msg
    = FromAddImg AddImg.Msg
    | FromAddText AddText.Msg
    | FromJsEditor IncomingMsg
    | FromJsEditorDecodeError String
    | ClickedDownloadSticker
    | ClickedUploadToPack
    | ClickedCloseNotification


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromAddImg addImgMsg ->
            let
                ( updatedAddImg, addImgCmd ) =
                    AddImg.update addImgMsg model.addImg
            in
            ( { model | addImg = updatedAddImg }, addImgCmd |> Cmd.map FromAddImg )

        FromAddText addTextMsg ->
            let
                ( updatedAddText, addTextCmd ) =
                    AddText.update addTextMsg model.addText
            in
            ( { model | addText = updatedAddText }, addTextCmd |> Cmd.map FromAddText )

        FromJsEditor incomingMsg ->
            case incomingMsg of
                ImageCropped base64ImgUrl ->
                    let
                        ( updatedAddImg, addImgCmd ) =
                            AddImg.setRemoveBgOrNotStep model.addImg base64ImgUrl
                    in
                    ( { model | addImg = updatedAddImg }, addImgCmd |> Cmd.map FromAddImg )

                ImageAddedToFabric ->
                    let
                        updatedAddImg =
                            AddImg.closeModal model.addImg
                    in
                    ( { model | addImg = updatedAddImg }, Cmd.none )

                StickerUploadedSuccess ->
                    ( { model
                        | uploadStickerStatus = Success
                        , notification = UploadedSticker
                      }
                    , Cmd.none
                    )

                StickerUploadedFailure err ->
                    ( { model | uploadStickerStatus = Errored err }, Cmd.none )

                StickerUploadedFailureNoSettings ->
                    ( { model | notification = SettingsNotExist }, Cmd.none )

                StickerUploadedFailureNoTelegramSettings ->
                    ( { model | notification = SettingsForTelegramMissing }, Cmd.none )

                UnknownIncomingMessage str ->
                    ( { model | notification = UnknownIncomingMessageFromJs str }, Cmd.none )

        FromJsEditorDecodeError err ->
            ( { model | notification = DecodeErrorFromJsEditor err }, Cmd.none )

        ClickedDownloadSticker ->
            ( model
            , Cmd.batch
                [ sendToJs <| DownloadSticker
                , trackEvent "ClickedDownloadSticker"
                ]
            )

        ClickedUploadToPack ->
            ( { model | uploadStickerStatus = Loading }
            , Cmd.batch
                [ sendToJs <| RequestUploadToPack
                , trackEvent "ClickedUploadToPack"
                ]
            )

        ClickedCloseNotification ->
            ( { model | notification = None }, Cmd.none )


view : Model -> Html Msg
view model =
    section []
        [ div [ class "container" ]
            [ renderNotification model.notification
            , h1 [ class "title" ] [ text "Editor" ]
            , h2 [ class "subtitle" ] [ text "Upload photo and make fun" ]
            , div [ class "columns" ]
                [ div [ class "column is-7" ]
                    [ div [ class "columns" ]
                        [ div [ class "column is-8" ]
                            [ renderCustomCanvas
                            ]
                        , div [ class "column" ]
                            (renderEditorBtns model.addText)
                        ]
                    ]
                , div [ class "column" ] []
                ]
            , div [ class "columns" ]
                [ div [ class "column" ]
                    [ div [ class "columns" ]
                        [ div [ class "column" ]
                            [ map FromAddImg (AddImg.view model.addImg)
                            ]
                        , div [ class "column" ]
                            [ renderSaveImgBtn
                            ]
                        , div [ class "column" ]
                            [ renderUploadImgToStickerSetBtn model.uploadStickerStatus ]
                        ]
                    ]
                , div [ class "column is-7" ] []
                ]
            ]
        ]


renderCustomCanvas : Html Msg
renderCustomCanvas =
    customCanvas
        [ css
            [ border3 (px 1) solid (rgb 0 0 0)
            , width (px 514)
            , height (px 514)
            , display block
            ]
        ]
        []


renderEditorBtns : AddText.Model -> List (Html Msg)
renderEditorBtns addTextModel =
    [ div [ class "columns" ]
        [ div [ class "column" ]
            [ map FromAddText (AddText.view addTextModel)
            ]
        ]
    ]


renderSaveImgBtn : Html Msg
renderSaveImgBtn =
    button [ class "button is-info", onClick ClickedDownloadSticker ]
        [ text "Download sticker" ]


renderUploadImgToStickerSetBtn : UploadStickerStatus -> Html Msg
renderUploadImgToStickerSetBtn status =
    let
        ( loadingStatus, disabledStatus ) =
            case status of
                NotAsked ->
                    ( "", False )

                Success ->
                    ( "", False )

                Loading ->
                    ( "is-loading", True )

                Errored _ ->
                    ( "", False )
    in
    div [ class "columns" ]
        [ div [ class "column" ]
            [ button
                [ class (String.concat [ "button is-info ", loadingStatus ])
                , onClick ClickedUploadToPack
                , disabled disabledStatus
                ]
                [ text "Upload to pack" ]
            , renderErrorMessage status
            ]
        ]


renderErrorMessage : UploadStickerStatus -> Html Msg
renderErrorMessage status =
    case status of
        NotAsked ->
            text ""

        Loading ->
            text ""

        Errored err ->
            div [ class "column" ]
                [ p [ class "has-text-danger" ]
                    [ text "Upload sticker error" ]
                , p [ class "has-text-danger" ]
                    [ text (String.fromInt err.code ++ ": " ++ err.description) ]
                ]

        Success ->
            text ""


renderNotification : Notification -> Html Msg
renderNotification notification =
    case notification of
        None ->
            text ""

        UnknownIncomingMessageFromJs str ->
            { text = str
            , closeMsg = ClickedCloseNotification
            }
                |> Ui.Notification.showError

        DecodeErrorFromJsEditor str ->
            { text = str
            , closeMsg = ClickedCloseNotification
            }
                |> Ui.Notification.showError

        SettingsNotExist ->
            { text = "You forgot to setup settings. Check settings page"
            , closeMsg = ClickedCloseNotification
            }
                |> Ui.Notification.showError

        SettingsForTelegramMissing ->
            { text = "You forgot to setup Telegram settings. Check settings page"
            , closeMsg = ClickedCloseNotification
            }
                |> Ui.Notification.showError

        UploadedSticker ->
            { text = "Your sticker was uploaded. It will appear in telegram in period of 30min - 3 hours"
            , closeMsg = ClickedCloseNotification
            }
                |> Ui.Notification.showSuccess


subscriptions : a -> Sub Msg
subscriptions =
    \_ ->
        listenToJs FromJsEditor FromJsEditorDecodeError
