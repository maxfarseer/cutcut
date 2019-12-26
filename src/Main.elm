module Main exposing (main)

import AddImg
import Browser
import Css exposing (block, border3, display, height, px, rgb, solid, width)
import Custom exposing (customCanvas)
import Html.Styled exposing (Html, div, h2, map, text, toUnstyled)
import Html.Styled.Attributes exposing (css)
import Ports exposing (IncomingMsg(..), listenToJs)


type alias Model =
    { addImg : AddImg.Model
    }


initialModel : ( Model, Cmd Msg )
initialModel =
    ( { addImg = AddImg.init
      }
    , Cmd.none
    )


type Msg
    = FromAddImg AddImg.Msg
    | FromJS IncomingMsg
    | FromJSDecodeError String


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


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "CutCut" ]
        , renderCustomCanvas
        , map FromAddImg (AddImg.view model.addImg)
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


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> initialModel
        , view = view >> toUnstyled
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : a -> Sub Msg
subscriptions =
    \_ -> listenToJs FromJS FromJSDecodeError
