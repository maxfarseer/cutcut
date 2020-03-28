module Editor exposing (Model, Msg, init, subscriptions, update, view)

import AddImg
import Css exposing (block, border3, display, height, px, rgb, solid, width)
import Custom exposing (customCanvas)
import Html.Styled exposing (Html, button, div, h1, h2, map, section, text)
import Html.Styled.Attributes exposing (class, css, disabled)
import Html.Styled.Events exposing (onClick)
import Ports exposing (IncomingMsg(..), OutgoingMsg(..), listenToJs, sendToJs)


type alias Model =
    { addImg : AddImg.Model
    , uploadingStickerInProgress : Bool
    }


init : ( Model, Cmd Msg )
init =
    ( { addImg = AddImg.init
      , uploadingStickerInProgress = False
      }
    , Cmd.none
    )


type Msg
    = FromAddImg AddImg.Msg
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

        FromJS incomingMsg ->
            case incomingMsg of
                ImageSaved base64 ->
                    let
                        ( updatedAddImg, addImgCmd ) =
                            AddImg.setRemoveBgOrNotStep model.addImg base64
                    in
                    ( { model | addImg = updatedAddImg }, addImgCmd |> Cmd.map FromAddImg )

                ImageAddedToFabric ->
                    let
                        updatedAddImg =
                            AddImg.closeModal model.addImg
                    in
                    ( { model | addImg = updatedAddImg }, Cmd.none )

                StickerUploadedSuccess ->
                    ( { model | uploadingStickerInProgress = False }, Cmd.none )

                UnknownIncomingMessage str ->
                    -- TODO: show error message for user
                    let
                        _ =
                            Debug.log "unknown message" str
                    in
                    ( model, Cmd.none )

        FromJSDecodeError err ->
            let
                _ =
                    Debug.log "update IncomingDecoderError" err
            in
            ( model, Cmd.none )

        ClickedDownloadSticker ->
            ( model, sendToJs <| DownloadSticker )

        ClickedUploadToPack ->
            ( { model | uploadingStickerInProgress = True }, sendToJs <| RequestUploadToPack )


view : Model -> Html Msg
view model =
    section []
        [ div [ class "container" ]
            [ h1 [ class "title" ] [ text "Editor" ]
            , h2 [ class "subtitle" ] [ text "Upload photo and make fun" ]
            , div [ class "level" ]
                [ div [ class "level-left" ]
                    [ div [ class "level-item" ]
                        [ renderCustomCanvas
                        ]
                    ]
                ]
            , div [ class "level" ]
                [ div [ class "level-left" ]
                    [ div [ class "level-item" ]
                        [ map FromAddImg (AddImg.view model.addImg)
                        ]
                    , div [ class "level-item" ]
                        [ renderSaveImgBtn
                        ]
                    , div [ class "level-item" ]
                        [ renderUploadImgToStickerSetBtn model.uploadingStickerInProgress ]
                    ]
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


renderSaveImgBtn : Html Msg
renderSaveImgBtn =
    button [ class "button is-info", onClick ClickedDownloadSticker ]
        [ text "Download sticker" ]



-- TODO: preloader on button (check bulma)


renderUploadImgToStickerSetBtn : Bool -> Html Msg
renderUploadImgToStickerSetBtn inprogress =
    button [ class "button is-info", onClick ClickedUploadToPack, disabled inprogress ]
        [ text "Upload to pack" ]


subscriptions : a -> Sub Msg
subscriptions =
    \_ -> listenToJs FromJS FromJSDecodeError
