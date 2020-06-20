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
import Tracking exposing (OutgoingMsg(..), track)
import Ui.Modal


type alias Model =
    { step : Step
    , removeBgApiKey : RemoveBgApiKey
    }


type Step
    = Add
    | Crop
    | RemoveBgOrNot UploadStatus Base64ImgUrl
    | Erase


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


type Msg
    = GotFiles (List File)
    | GotFileUrl String
    | GotRemoveBgResponse Base64ImgUrl (Result ErrorDetailed ( Http.Metadata, String ))
    | ClickedCloseModal
    | ClickedEraseFinish
    | ClickedCropFinish
    | ClickedRemoveBg Base64ImgUrl
    | ClickedNotRemoveBg Base64ImgUrl


init : RemoveBgApiKey -> Model
init removeBgApiKey =
    { step = Add, removeBgApiKey = removeBgApiKey }



-- DECODERS


filesDecoder : JD.Decoder (List File)
filesDecoder =
    JD.at [ "target", "files" ] (JD.list File.decoder)


setRemoveBgOrNotStep : Model -> Base64ImgUrl -> ( Model, Cmd Msg )
setRemoveBgOrNotStep model imgUrl =
    ( RemoveBgOrNot NotAsked imgUrl
        |> setStep model
    , Cmd.none
    )


closeModal : Model -> Model
closeModal model =
    { model | step = Add }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotFiles files ->
            case List.head files of
                Nothing ->
                    ( model, track <| TrackEvent "GotFiles Nothing" )

                Just file ->
                    ( model
                    , Cmd.batch
                        [ Task.perform GotFileUrl <| File.toUrl file
                        , track <| TrackEvent "GotFiles"
                        ]
                    )

        GotFileUrl base64 ->
            ( { model | step = Crop }, sendToJs <| CropImageInit (fromString base64) )

        ClickedCloseModal ->
            ( { model | step = Add }, Cmd.none )

        ClickedCropFinish ->
            ( model
            , Cmd.batch
                [ sendToJs <| CropImage
                , track <| TrackEvent "ClickedCropFinish"
                ]
            )

        ClickedRemoveBg imgUrl ->
            ( { model | step = RemoveBgOrNot Loading imgUrl }
            , Cmd.batch
                [ Http.request
                    { url = "https://api.remove.bg/v1.0/removebg"
                    , headers =
                        [ Http.header "X-Api-Key" model.removeBgApiKey
                        , Http.header "Accept" "application/json"
                        ]
                    , method = "POST"
                    , timeout = Nothing
                    , tracker = Nothing
                    , body = Http.jsonBody <| removeBgRequestEncoder imgUrl
                    , expect = expectStringDetailed (GotRemoveBgResponse imgUrl)
                    }
                , track <| TrackEvent "ClickedRemoveBg"
                ]
            )

        GotRemoveBgResponse imgUrl result ->
            case result of
                Err err ->
                    ( RemoveBgOrNot (Errored err) imgUrl
                        |> setStep model
                    , track <| TrackEvent "GotRemoveBgResponse Err"
                    )

                Ok ( metadata, body ) ->
                    case removeBgResponseDecoder body of
                        Ok base64ImgUrl ->
                            ( { model | step = Erase }, sendToJs <| PrepareForErase base64ImgUrl )

                        Err _ ->
                            ( RemoveBgOrNot JsonResponseError imgUrl
                                |> setStep model
                            , Cmd.none
                            )

        ClickedNotRemoveBg imgUrl ->
            ( { model | step = Erase }
            , Cmd.batch
                [ sendToJs <| PrepareForErase imgUrl
                , track <| TrackEvent "ClickedNotRemoveBg"
                ]
            )

        ClickedEraseFinish ->
            ( { model | step = Erase }
            , Cmd.batch
                [ sendToJs <| AddImgFinish
                , track <| TrackEvent "ClickedEraseFinish"
                ]
            )



-- UTILS


setStep : Model -> Step -> Model
setStep model step =
    { model | step = step }



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

        RemoveBgOrNot status imgUrl ->
            Ui.Modal.view
                { title = "Add image: Background"
                , open = True
                , closeMsg = ClickedCloseModal
                , confirmMsg = Nothing
                , confirmText = Nothing
                }
                []
                [ viewRemoveBgQuestion status imgUrl
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


viewRemoveBgQuestion : UploadStatus -> Base64ImgUrl -> Html Msg
viewRemoveBgQuestion status imgUrl =
    let
        confirmBtn =
            case status of
                Loading ->
                    viewRemoveBgConfirmBtn ( True, False, imgUrl )

                NotAsked ->
                    viewRemoveBgConfirmBtn ( False, False, imgUrl )

                Errored _ ->
                    viewRemoveBgConfirmBtn ( False, True, imgUrl )

                JsonResponseError ->
                    viewRemoveBgConfirmBtn ( False, True, imgUrl )
    in
    div []
        [ div [ class "columns" ]
            [ div [ class "column" ]
                [ p []
                    [ text "If you like, background will be removed automatically (with help of "
                    , a
                        [ href "https://www.remove.bg/", target "_blank" ]
                        [ text "remove.bg" ]
                    , text
                        " service)."
                    ]
                , p []
                    [ text "Don't forget to setup your settings variables with "
                    , a
                        [ href "https://www.remove.bg/api", target "_blank" ]
                        [ text "API key" ]
                    , text
                        ". You can find settings page "
                    , a [ href "/settings" ] [ text "here" ]
                    , text "."
                    ]
                ]
            ]
        , div [ class "columns is-centered" ]
            [ div [ class "column is-3" ]
                [ confirmBtn ]
            , div [ class "column is-3" ]
                [ button [ class "button is-small", onClick (ClickedNotRemoveBg imgUrl) ] [ text "No, do not remove" ]
                ]
            ]
        , viewRemoveBgErrorBlock status
        ]


viewRemoveBgConfirmBtn : ( Bool, Bool, Base64ImgUrl ) -> Html Msg
viewRemoveBgConfirmBtn ( isLoading, isError, imgUrl ) =
    button
        [ classList
            [ ( "button is-small", True )
            , ( "is-info", True )
            , ( "is-loading", isLoading == True )
            ]
        , onClick (ClickedRemoveBg imgUrl)
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
