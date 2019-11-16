module Main exposing (main)

import Browser
import File exposing (File)
import Html exposing (..)
import Html.Attributes as Attr exposing (class, multiple, name, type_)
import Html.Events exposing (on)
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


type Msg
    = GotFiles (List File)
    | GotRemoveBgResponse (Result Http.Error Base64)


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
            ul [] (List.map renderImage model.list)

        Errored _ ->
            li [] [ text "Loading error" ]


renderImage : Base64 -> Html Msg
renderImage base64str =
    li []
        [ img [ Attr.src ("data:image/png;base64, " ++ base64str) ] []
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



{-
   {
     "data": {
       "result_b64": "iVBORw0KGgoAAAANSUhEUgAAAIsAAACFC..."
     }
   }
-}


fileBgDecoder : D.Decoder Base64
fileBgDecoder =
    D.field "data" (D.field "result_b64" D.string)
