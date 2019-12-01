module AddImg exposing (Model, Msg(..), init, update, view)

import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, multiple, name, src, type_)
import Html.Styled.Events exposing (on, onClick)


type Model
    = Closed
    | Step StepModel


type StepModel
    = AddImgStep
    | CropImgStep
    | EraseImtStep


type Msg
    = ClickedAddImg


init : Model
init =
    Closed



{- ClickedAddImg ->
   ( { model | addImg = AddImg.update AddImg.ShowAddImgModal }, Cmd.none )
-}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedAddImg ->
            ( Step AddImgStep, Cmd.none )


view : Model -> Html msg
view model =
    case model of
        Closed ->
            div [] []

        Step _ ->
            renderModalStep


renderModalStep : Html msg
renderModalStep =
    div [] [ text "modal here" ]
