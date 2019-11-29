port module Main exposing (main)

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


customCanvas : List (Attribute a) -> List (Html a) -> Html a
customCanvas attributes children =
    node "custom-canvas" attributes children


removeBgApiUrl : String
removeBgApiUrl =
    "https://api.remove.bg/v1.0"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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
                    ( model, sendDataToJs "123" )


port sendDataToJs : String -> Cmd msg


view : Model -> Html Msg
view model =
    div []
        [ form []
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
