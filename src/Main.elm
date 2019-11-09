module Main exposing (main)

import Browser
import File exposing (File)
import Html exposing (Html, button, div, form, i, input, label, span, text)
import Html.Attributes as Attr exposing (class, multiple, name, type_)
import Html.Events as Events exposing (on)
import Http as Http
import Json.Decode as D
import Json.Encode as E


type alias Model =
    { links : List String }


initialModel : ( Model, Cmd Msg )
initialModel =
    ( { links = [] }, Cmd.none )


type alias FileIoResponse =
    { success : Bool
    , key : String
    , link : String
    , expiry : String
    }


type Msg
    = GotFiles (List File)
    | GotFileIo (Result Http.Error FileIoResponse)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotFiles files ->
            case List.head files of
                Nothing ->
                    ( model, Cmd.none )

                Just file ->
                    ( model
                    , Http.request
                        { url = "https://file.io/?expires=1w"
                        , method = "POST"
                        , headers =
                            []
                        , body = Http.multipartBody [ Http.filePart "file" file ]
                        , expect = Http.expectJson GotFileIo fileIoDecoder
                        , timeout = Nothing
                        , tracker = Nothing
                        }
                    )

        GotFileIo _ ->
            ( model, Cmd.none )


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
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> initialModel
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


filesDecoder : D.Decoder (List File)
filesDecoder =
    D.at [ "target", "files" ] (D.list File.decoder)



-- {"success":true,"key":"2ojE41","link":"https://file.io/2ojE41","expiry":"14 days"}


fileIoDecoder : D.Decoder FileIoResponse
fileIoDecoder =
    D.map4 FileIoResponse
        (D.field "success" D.bool)
        (D.field "key" D.string)
        (D.field "link" D.string)
        (D.field "expiry" D.string)
