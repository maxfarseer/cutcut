module Main exposing (main)

import AddImg
import Browser
import Css exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, id, multiple, name, src, type_)
import Html.Styled.Events exposing (on, onClick)


type alias Model =
    { addImg : AddImg.Model
    }


initialModel : ( Model, Cmd Msg )
initialModel =
    ( { addImg = AddImg.init
      }
    , Cmd.none
    )


type ToJSmsg
    = DrawSquare


type Msg
    = ToJS ToJSmsg
    | FromAddImg AddImg.Msg


customCanvas : List (Attribute a) -> List (Html a) -> Html a
customCanvas attributes children =
    node "custom-canvas" attributes children


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromAddImg addImgMsg ->
            let
                ( updatedAddImg, addImgCmd ) =
                    AddImg.update addImgMsg model.addImg
            in
            ( { model | addImg = updatedAddImg }, addImgCmd |> Cmd.map FromAddImg )

        ToJS msgToJs ->
            case msgToJs of
                DrawSquare ->
                    ( model, Cmd.none )



--                DrawSquare ->
--                    ( model, sendDataToJs "iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAARUlEQVR42u3PMREAAAgEoLd/AtNqBlcPGlDJdB4oEREREREREREREREREREREREREREREREREREREREREREREREREZGLBddNT+MQpgCuAAAAAElFTkSuQmCC" )


view : Model -> Html Msg
view model =
    div []
        [ h2 [] [ text "CutCut" ]
        , renderCustomCanvas
        , button [ onClick (ToJS DrawSquare) ] [ text "Draw square" ]
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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
