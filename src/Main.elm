port module Main exposing (main)

import AddImg
import Browser
import Css exposing (block, border3, display, height, px, rgb, solid, width)
import Custom exposing (customCanvas)
import Html.Styled exposing (Html, div, h2, map, text, toUnstyled)
import Html.Styled.Attributes exposing (css)


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
    | FromJS String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromAddImg addImgMsg ->
            let
                ( updatedAddImg, addImgCmd ) =
                    AddImg.update addImgMsg model.addImg
            in
            ( { model | addImg = updatedAddImg }, addImgCmd |> Cmd.map FromAddImg )

        FromJS _ ->
            let
                ( updatedAddImg, addImgCmd ) =
                    AddImg.callForErase model.addImg
            in
            ( { model | addImg = updatedAddImg }, addImgCmd |> Cmd.map FromAddImg )


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


port modeChosen : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions _ =
    modeChosen FromJS
