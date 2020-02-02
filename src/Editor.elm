module Editor exposing (Model, Msg, init, subscriptions, update, view)

import AddImg
import Css exposing (block, border3, display, height, px, rgb, solid, width)
import Custom exposing (customCanvas)
import Html.Styled exposing (Html, button, div, h2, map, text)
import Html.Styled.Attributes exposing (class, css)
import Html.Styled.Events exposing (onClick)
import Ports exposing (IncomingMsg(..), OutgoingMsg(..), listenToJs, sendToJs)


type alias Model =
    { addImg : AddImg.Model
    }


init : ( Model, Cmd Msg )
init =
    ( { addImg = AddImg.init
      }
    , Cmd.none
    )


type Msg
    = FromAddImg AddImg.Msg
    | FromJS IncomingMsg
    | FromJSDecodeError String
    | ClickedDownloadSticker


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
                ImageSaved ->
                    let
                        ( updatedAddImg, addImgCmd ) =
                            AddImg.setRemoveBgOrNotStep model.addImg
                    in
                    ( { model | addImg = updatedAddImg }, addImgCmd |> Cmd.map FromAddImg )

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


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "CutCut" ]
        , renderCustomCanvas
        , div [ class "columns" ]
            [ map FromAddImg (AddImg.view model.addImg)
            , renderSaveImgBtn
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
    div [ class "column is-2" ]
        [ button [ class "button is-info", onClick ClickedDownloadSticker ]
            [ text "Download sticker" ]
        ]


subscriptions : a -> Sub Msg
subscriptions =
    \_ -> listenToJs FromJS FromJSDecodeError
