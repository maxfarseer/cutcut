module AddImg exposing (Model, Msg, closeModal, init, setRemoveBgOrNotStep, update, view)

import Base64 exposing (Base64ImgUrl, decoderStringToBase64ImgUrl, fromString, toString)
import Custom exposing (customCropper, customEraser)
import EnvAliases exposing (RemoveBgApiKey)
import File exposing (File)
import Html.Styled exposing (Html, a, button, div, form, i, input, label, p, span, text)
import Html.Styled.Attributes exposing (accept, class, classList, disabled, href, multiple, name, target, type_)
import Html.Styled.Events exposing (on, onClick)
import Http as Http
import Json.Decode as JD
import Json.Encode as JE
import Ports exposing (OutgoingMsg(..), sendToJs)
import Task
import Ui.Modal


type alias Model =
    { step : Step
    , base64image : Maybe Base64ImgUrl
    , error : Maybe String
    , removeBgApiKey : RemoveBgApiKey
    }


type alias RemoveBgDetailedBadStatus =
    { title : String
    , code : String
    }


type ErrorDetailed
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata String
    | BadBody String


type UploadStatus
    = NotAsked
    | Loading
    | Errored ErrorDetailed
    | JsonResponseError


type Step
    = Add
    | Crop
    | RemoveBgOrNot UploadStatus
    | Erase
    | Error


type Msg
    = GotFiles (List File)
    | GotFileUrl String
    | GotRemoveBgResponse (Result ErrorDetailed ( Http.Metadata, String ))
    | ClickedCloseModal
    | ClickedEraseFinish
    | ClickedCropFinish
    | ClickedRemoveBg
    | ClickedNotRemoveBg


init : RemoveBgApiKey -> Model
init removeBgApiKey =
    { step = Add
    , base64image = Nothing
    , error = Nothing
    , removeBgApiKey = removeBgApiKey
    }



-- DECODERS


filesDecoder : JD.Decoder (List File)
filesDecoder =
    JD.at [ "target", "files" ] (JD.list File.decoder)


setRemoveBgOrNotStep : Model -> Base64ImgUrl -> ( Model, Cmd Msg )
setRemoveBgOrNotStep model img =
    ( { model | step = RemoveBgOrNot NotAsked, base64image = Just img }, Cmd.none )


closeModal : Model -> Model
closeModal model =
    { model | step = Add }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotFiles files ->
            case List.head files of
                Nothing ->
                    ( model, Cmd.none )

                Just file ->
                    ( model, Task.perform GotFileUrl <| File.toUrl file )

        GotFileUrl base64 ->
            ( { model | step = Crop }, sendToJs <| CropImage (fromString base64) )

        ClickedCloseModal ->
            ( { model | step = Add }, Cmd.none )

        ClickedCropFinish ->
            ( model, sendToJs <| SaveCroppedImage )

        ClickedRemoveBg ->
            case model.base64image of
                Just base64string ->
                    ( { model | step = RemoveBgOrNot Loading }
                    , Http.request
                        { url = "https://api.remove.bg/v1.0/removebg"
                        , headers =
                            [ Http.header "X-Api-Key" model.removeBgApiKey
                            , Http.header "Accept" "application/json"
                            ]
                        , method = "POST"
                        , timeout = Nothing
                        , tracker = Nothing
                        , body = Http.jsonBody <| removeBgRequestEncoder base64string
                        , expect = expectStringDetailed GotRemoveBgResponse
                        }
                    )

                Nothing ->
                    ( { model | step = Error, error = Just "Problem with image..." }, Cmd.none )

        GotRemoveBgResponse result ->
            case result of
                Err err ->
                    ( { model | step = RemoveBgOrNot <| Errored err }, Cmd.none )

                Ok ( metadata, body ) ->
                    case removeBgResponseDecoder body of
                        Ok base64ImgUrl ->
                            ( { model | step = Erase }, sendToJs <| PrepareForErase base64ImgUrl )

                        Err _ ->
                            ( { model | step = RemoveBgOrNot <| JsonResponseError }, Cmd.none )

        ClickedNotRemoveBg ->
            case model.base64image of
                Just base64imgUrl ->
                    ( { model | step = Erase }, sendToJs <| PrepareForErase base64imgUrl )

                Nothing ->
                    ( { model | step = Error, error = Just "Problem with image..." }, Cmd.none )

        ClickedEraseFinish ->
            ( { model | step = Erase }, sendToJs <| AddImgFinish )



-- ENCODERS


removeBgRequestEncoder : Base64ImgUrl -> JE.Value
removeBgRequestEncoder imgUrl =
    JE.object
        [ ( "image_file_b64", JE.string <| toString imgUrl )
        ]



-- DECODERS


removeBgBadStatusBodyItemDecoder : JD.Decoder RemoveBgDetailedBadStatus
removeBgBadStatusBodyItemDecoder =
    JD.map2 RemoveBgDetailedBadStatus
        (JD.field "title" JD.string)
        (JD.field "code" JD.string)


removeBgBadStatusBodyDecoder : String -> Result JD.Error (List RemoveBgDetailedBadStatus)
removeBgBadStatusBodyDecoder =
    JD.field "errors" (JD.list removeBgBadStatusBodyItemDecoder)
        |> JD.decodeString


removeBgResponseDecoder : String -> Result JD.Error Base64ImgUrl
removeBgResponseDecoder =
    JD.field "data" (JD.field "result_b64" decoderStringToBase64ImgUrl)
        |> JD.decodeString



-- Http detailed (https://medium.com/@jzxhuang/going-beyond-200-ok-a-guide-to-detailed-http-responses-in-elm-6ddd02322e)


expectStringDetailed : (Result ErrorDetailed ( Http.Metadata, String ) -> msg) -> Http.Expect msg
expectStringDetailed msg =
    Http.expectStringResponse msg convertResponseString


convertResponseString : Http.Response String -> Result ErrorDetailed ( Http.Metadata, String )
convertResponseString httpResponse =
    case httpResponse of
        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata body ->
            Err (BadStatus metadata body)

        Http.GoodStatus_ metadata body ->
            Ok ( metadata, body )



-- VIEW


view : Model -> Html Msg
view model =
    case model.step of
        Add ->
            viewUploadFileBtn

        Crop ->
            Ui.Modal.view
                { title = "Add image: Crop"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = Just ClickedCropFinish
                , confirmText = Just "Crop"
                }
                []
                [ viewCustomCropper
                ]

        RemoveBgOrNot status ->
            Ui.Modal.view
                { title = "Add image: Background"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = Nothing
                , confirmText = Nothing
                }
                []
                [ viewRemoveBgQuestion status
                ]

        Erase ->
            Ui.Modal.view
                { title = "Add image: Erase (beta)"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = Just ClickedEraseFinish
                , confirmText = Just "Finish"
                }
                []
                [ viewEraseStep
                ]

        Error ->
            case model.error of
                Just err ->
                    Ui.Modal.view
                        { title = "Add image: Error"
                        , open = True
                        , closeMsg = ClickedCloseModal
                        , confirmMsg = Nothing
                        , confirmText = Nothing
                        }
                        []
                        [ viewError err
                        ]

                Nothing ->
                    -- impossible case
                    text ""


viewUploadFileBtn : Html Msg
viewUploadFileBtn =
    form []
        [ div [ class "file" ]
            [ label [ class "file-label" ]
                [ input
                    [ class "file-input"
                    , name "upload-pic"
                    , type_ "file"
                    , accept "image/*"
                    , multiple False
                    , on "change" (JD.map GotFiles filesDecoder)
                    ]
                    []
                , span [ class "file-cta" ]
                    [ span [ class "file-icon" ]
                        [ i [ class "fas fa-upload" ]
                            []
                        ]
                    , span [ class "file-label" ]
                        [ text "Add image" ]
                    ]
                ]
            ]
        ]


viewCustomCropper : Html Msg
viewCustomCropper =
    customCropper
        []
        []


viewRemoveBgQuestion : UploadStatus -> Html Msg
viewRemoveBgQuestion status =
    let
        confirmBtn =
            case status of
                Loading ->
                    viewRemoveBgConfirmBtn ( True, False )

                NotAsked ->
                    viewRemoveBgConfirmBtn ( False, False )

                Errored _ ->
                    viewRemoveBgConfirmBtn ( False, True )

                JsonResponseError ->
                    viewRemoveBgConfirmBtn ( False, True )
    in
    div []
        [ div [ class "columns" ]
            [ div [ class "column" ]
                [ p []
                    [ text "You can remove background automatically ("
                    , a
                        [ href "https://www.remove.bg/", target "_blank" ]
                        [ text "remove.bg " ]
                    , text
                        "API is using)"
                    ]
                , p []
                    [ text "Don't forget to setup environment variables with "
                    , a
                        [ href "https://www.remove.bg/api", target "_blank" ]
                        [ text "API key" ]
                    , text
                        ". See example "
                    , a [ href "https://github.com/maxfarseer/cutcut/blob/master/.env.example", target "_blank" ] [ text "here" ]
                    , text "."
                    ]
                ]
            ]
        , div [ class "columns is-centered" ]
            [ div [ class "column is-3" ]
                [ confirmBtn ]
            , div [ class "column is-3" ]
                [ button [ class "button is-small", onClick ClickedNotRemoveBg ] [ text "No, do not remove" ]
                ]
            ]
        , viewRemoveBgErrorBlock status
        ]


viewRemoveBgConfirmBtn : ( Bool, Bool ) -> Html Msg
viewRemoveBgConfirmBtn ( isLoading, isError ) =
    button
        [ classList
            [ ( "button is-small", True )
            , ( "is-info", True )
            , ( "is-loading", isLoading == True )
            ]
        , onClick ClickedRemoveBg
        , disabled (isLoading || isError)
        ]
        [ text "Yes, please remove" ]


viewRemoveBgErrorBlock : UploadStatus -> Html Msg
viewRemoveBgErrorBlock status =
    let
        errorText =
            case status of
                NotAsked ->
                    text ""

                Loading ->
                    text ""

                Errored err ->
                    case err of
                        BadUrl str ->
                            text ("Request url is wrong: " ++ str)

                        Timeout ->
                            text "Request takes too much time. Refresh page and try again"

                        NetworkError ->
                            text "Network error. Check your internet connection, refresh page and try again"

                        -- TODO: can we use better/shorter syntax here.
                        BadStatus metadata body ->
                            case removeBgBadStatusBodyDecoder body of
                                Ok errorDescription ->
                                    case List.head errorDescription of
                                        Just decodedErr ->
                                            text ("Bad status: " ++ decodedErr.title)

                                        Nothing ->
                                            text "Bad status: unknown problem"

                                Err _ ->
                                    text "Bad status: unknown problem"

                        BadBody str ->
                            text str

                JsonResponseError ->
                    text "Looks like remove.bg team has changed API Schema"
    in
    div [ class "columns" ]
        [ div [ class "column" ]
            [ p [ class "has-text-danger" ] [ errorText ]
            ]
        ]


viewEraseStep : Html Msg
viewEraseStep =
    div []
        [ div [ class "columns" ]
            [ div [ class "column" ]
                [ p []
                    [ text "Use your mouse to erase unnecessary. But, ouch! Erase tool is crazy ;)"
                    ]
                ]
            ]
        , viewCustomEraser
        ]


viewCustomEraser : Html Msg
viewCustomEraser =
    customEraser
        []
        []


viewError : String -> Html Msg
viewError errorStr =
    div []
        [ p [] [ text errorStr ]
        ]
