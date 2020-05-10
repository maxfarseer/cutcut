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


type UploadStickerStatus
    = NotAsked
    | Loading
    | Errored StickerUploadError
    | Success


type alias Model =
    { addImg : AddImg.Model
    , addText : AddText.Model
    , uploadStickerStatus : UploadStickerStatus
    }


init : RemoveBgApiKey -> ( Model, Cmd Msg )
init removeBgApiKey =
    ( { addImg = AddImg.init removeBgApiKey
      , addText = AddText.init
      , uploadStickerStatus = NotAsked
      }
    , sendToStoragePort <| AskForSettingsFromLS
    )


type Msg
    = FromAddImg AddImg.Msg
    | FromAddText AddText.Msg
    | FromJS IncomingMsg
    | FromJSDecodeError String
    | ClickedDownloadSticker
    | ClickedUploadToPack


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

        FromJS incomingMsg ->
            let
                _ =
                    Debug.log "Editor FromJS incomingMsg" incomingMsg
            in
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
                    ( { model | uploadStickerStatus = Success }, Cmd.none )

                StickerUploadedFailure err ->
                    ( { model | uploadStickerStatus = Errored err }, Cmd.none )

                UnknownIncomingMessage str ->
                    -- TODO: show error message to user
                    ( model, Cmd.none )

        FromJSDecodeError err ->
            -- TODO: show error message to user
            let
                _ =
                    Debug.log "Editor: FromJSDecodeError" err
            in
            ( model, Cmd.none )

        ClickedDownloadSticker ->
            ( model, sendToJs <| DownloadSticker )

        ClickedUploadToPack ->
            ( { model | uploadStickerStatus = Loading }, sendToJs <| RequestUploadToPack )


view : Model -> Html Msg
view model =
    section []
        [ div [ class "container" ]
            [ h1 [ class "title" ] [ text "Editor" ]
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
        Errored err ->
            div [ class "column" ]
                [ p [ class "has-text-danger" ]
                    [ text "Upload sticker error" ]
                , p [ class "has-text-danger" ]
                    [ text (String.fromInt err.code ++ ": " ++ err.description) ]
                ]

        -- TODO: question: is "_" ok in this situation?
        _ ->
            text ""


subscriptions : a -> Sub Msg
subscriptions =
    \_ ->
        Sub.batch
            [ listenToJs FromJS FromJSDecodeError
            ]
