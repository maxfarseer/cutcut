port module Main exposing (main)

import AddImg
import Browser
import Css exposing (..)
import File exposing (File)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (class, css, multiple, name, src, type_)
import Html.Styled.Events exposing (on, onClick)
import Http as Http
import Json.Decode as D


type alias Model =
    { list : List Base64
    , uploadStatus : UploadStatus
    , addImg : AddImg.Model
    }


type UploadStatus
    = NotAsked
    | Loading
    | Loaded
    | Errored Http.Error


initialModel : ( Model, Cmd Msg )
initialModel =
    ( { list = []
      , uploadStatus = NotAsked
      , addImg = AddImg.init
      }
    , Cmd.none
    )


type alias Base64 =
    String


type ToJSmsg
    = DrawSquare


type Msg
    = GotFiles (List File)
    | GotRemoveBgResponse (Result Http.Error Base64)
    | ToJS ToJSmsg
    | FromAddImg AddImg.Msg


customCanvas : List (Attribute a) -> List (Html a) -> Html a
customCanvas attributes children =
    node "custom-canvas" attributes children


removeBgApiUrl : String
removeBgApiUrl =
    "https://api.remove.bg/v1.0"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromAddImg addImgMsg ->
            let
                ( updatedAddImg, addImgCmd ) =
                    AddImg.update addImgMsg model.addImg
            in
            ( { model | addImg = updatedAddImg }, addImgCmd |> Cmd.map FromAddImg )

        GotFiles files ->
            case List.head files of
                Nothing ->
                    ( model, Cmd.none )

                Just file ->
                    ( { model | uploadStatus = Loading }
                    , Http.request
                        { url = removeBgApiUrl ++ "/removebg"
                        , headers =
                            [ Http.header "X-Api-Key" "Ge5HqmTYvcD1UzadQ7MPVPVi"
                            , Http.header "Accept" "application/json"
                            ]
                        , method = "POST"
                        , timeout = Nothing
                        , tracker = Nothing
                        , body = Http.multipartBody [ Http.filePart "image_file" file ]
                        , expect = Http.expectJson GotRemoveBgResponse fileBgDecoder
                        }
                    )

        GotRemoveBgResponse result ->
            case result of
                Err err ->
                    ( { model | uploadStatus = Errored err }, Cmd.none )

                Ok response ->
                    ( { model
                        | list = response :: model.list
                        , uploadStatus = Loaded
                      }
                    , sendDataToJs response
                    )

        ToJS msgToJs ->
            case msgToJs of
                DrawSquare ->
                    ( model, sendDataToJs "iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAARUlEQVR42u3PMREAAAgEoLd/AtNqBlcPGlDJdB4oEREREREREREREREREREREREREREREREREREREREREREREREREZGLBddNT+MQpgCuAAAAAElFTkSuQmCC" )


port sendDataToJs : String -> Cmd msg


view : Model -> Html Msg
view model =
    div []
        [ AddImg.view model.addImg
        , form []
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
                            [ text "Choose a file… " ]
                        ]
                    ]
                ]
            ]
        , renderCustomCanvas
        , button [ onClick (ToJS DrawSquare) ] [ text "Draw square" ]
        , button [ onClick (FromAddImg AddImg.ClickedAddImg) ] [ text "Add image" ]
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


filesDecoder : D.Decoder (List File)
filesDecoder =
    D.at [ "target", "files" ] (D.list File.decoder)


fileBgDecoder : D.Decoder Base64
fileBgDecoder =
    D.field "data" (D.field "result_b64" D.string)
