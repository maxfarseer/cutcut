module Main exposing (main)

import Browser
import File exposing (File)
import Html exposing (..)
import Html.Attributes as Attr exposing (class, multiple, name, type_)
import Html.Events exposing (on)
import Http as Http
import Json.Decode as D


type alias Model =
    { list : List FileIoResponse
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
                    ( { model | uploadStatus = Loading }
                    , Http.post
                        { url = "https://file.io/?expires=1w"
                        , body = Http.multipartBody [ Http.filePart "file" file ]
                        , expect = Http.expectJson GotFileIo fileIoDecoder
                        }
                    )

        GotFileIo result ->
            case result of
                Err err ->
                    ( { model | uploadStatus = Errored err }, Cmd.none )

                Ok response ->
                    ( { model
                        | list = response :: model.list
                        , uploadStatus = Loaded
                      }
                    , Cmd.none
                    )


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
        , h2 [] [ text "Uploaded files:" ]
        , renderLinksList model
        ]


renderLinksList : Model -> Html Msg
renderLinksList model =
    case model.uploadStatus of
        NotAsked ->
            li [] [ text "Not asked yet" ]

        Loading ->
            li [] [ text "Loading..." ]

        Loaded ->
            ul [] (List.map renderLink model.list)

        Errored _ ->
            li [] [ text "Loading error" ]


renderLink : FileIoResponse -> Html Msg
renderLink fileIo =
    li []
        [ a [ Attr.href fileIo.link, Attr.target "_blank" ] [ text fileIo.link ]
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
subscriptions _ =
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
