module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Editor
import EnvSettings exposing (IncomingMsg(..))
import Html.Styled exposing (Html, a, br, button, div, footer, h1, h2, iframe, img, nav, p, section, span, strong, text, toUnstyled)
import Html.Styled.Attributes exposing (attribute, class, href, id, src, target)
import Json.Decode as JD
import Route exposing (Route(..))
import Settings
import Ui.Notification
import Url


type alias Flags =
    { buildDate : Int
    }



-- MAIN


main : Program JD.Value Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type Page
    = WelcomePage
    | EditorPage Editor.Model
    | SettingsPage Settings.Model
    | NotFoundPage


type Notification
    = None
    | GenericError String
    | UnknownDecoderMessage String
    | SettingsSaved


type alias Model =
    { key : Nav.Key
    , page : Page
    , flags : Flags
    , notification : Notification
    }


init : JD.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    case JD.decodeValue flagsDecoder flags of
        Ok decodedFlags ->
            updateUrl url
                { page = NotFoundPage
                , key = key
                , flags = decodedFlags
                , notification = None
                }

        Err _ ->
            updateUrl url
                { page = NotFoundPage
                , key = key
                , flags = { buildDate = 0 }
                , notification = None
                }



-- DECODERS


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map Flags
        (JD.field "buildDate" JD.int)



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotEditorMsg Editor.Msg
    | GotSettingsMsg Settings.Msg
    | FromStorageSuccess EnvSettings.IncomingMsg
    | FromStorageError String
    | CloseNotification


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External url ->
                    ( model, Nav.load url )

        UrlChanged url ->
            updateUrl url model

        GotSettingsMsg settingsMsg ->
            case model.page of
                SettingsPage settingsModel ->
                    toSettings model (Settings.update settingsMsg settingsModel)

                _ ->
                    ( model, Cmd.none )

        GotEditorMsg editorMsg ->
            case model.page of
                EditorPage editorModel ->
                    toEditor model (Editor.update editorMsg editorModel)

                _ ->
                    ( model, Cmd.none )

        FromStorageSuccess incomingMsg ->
            case incomingMsg of
                LoadedSettingsFromLS data ->
                    let
                        newPageModel =
                            updateSettings data model.page
                    in
                    ( { model | page = newPageModel }, Cmd.none )

                EnvSettingsUnknownIncomingMessage str ->
                    ( { model | notification = UnknownDecoderMessage str }, Cmd.none )

                SettingsSavedSuccessfully ->
                    ( { model | notification = SettingsSaved }, Cmd.none )

        FromStorageError str ->
            ( { model | notification = GenericError str }, Cmd.none )

        CloseNotification ->
            ( { model | notification = None }, Cmd.none )


updateSettings : Maybe EnvSettings.Model -> Page -> Page
updateSettings settings page =
    case settings of
        Just settingsData ->
            case page of
                SettingsPage _ ->
                    SettingsPage settingsData

                EditorPage _ ->
                    let
                        newModel =
                            Editor.init settingsData.removeBgApiKey
                                |> Tuple.first
                    in
                    EditorPage newModel

                WelcomePage ->
                    WelcomePage

                NotFoundPage ->
                    NotFoundPage

        Nothing ->
            page


updateUrl : Url.Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Route.fromUrl url of
        Welcome ->
            ( { model | page = WelcomePage }, Cmd.none )

        -- TODO: use Nothing here for removeBgApiKey or think about better solution
        Editor ->
            Editor.init "TODO:fake-remove-bg-api-key" |> toEditor model

        Settings ->
            Settings.init () |> toSettings model

        NotFound ->
            ( { model | page = NotFoundPage }, Cmd.none )


toEditor : Model -> ( Editor.Model, Cmd Editor.Msg ) -> ( Model, Cmd Msg )
toEditor model ( editorModel, editorCmd ) =
    ( { model | page = EditorPage editorModel }
    , Cmd.map GotEditorMsg editorCmd
    )


toSettings : Model -> ( Settings.Model, Cmd Settings.Msg ) -> ( Model, Cmd Msg )
toSettings model ( settingsModel, settingsCmd ) =
    ( { model | page = SettingsPage settingsModel }
    , Cmd.map GotSettingsMsg settingsCmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        subscriptionForPageOnly =
            case model.page of
                WelcomePage ->
                    Sub.none

                SettingsPage _ ->
                    Settings.subscriptions
                        |> Sub.map GotSettingsMsg

                EditorPage _ ->
                    Editor.subscriptions ()
                        |> Sub.map GotEditorMsg

                NotFoundPage ->
                    Sub.none
    in
    Sub.batch
        [ subscriptionForPageOnly
        , EnvSettings.listenToJs FromStorageSuccess FromStorageError
        ]



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "CutCut"
    , body =
        [ body model |> div [] |> toUnstyled ]
    }


body : Model -> List (Html Msg)
body model =
    case model.page of
        NotFoundPage ->
            [ viewHeader model.notification
            , div [] [ text "Not found" ]
            ]

        SettingsPage settingsModel ->
            [ viewHeader model.notification
            , Settings.view settingsModel |> Html.Styled.map GotSettingsMsg
            ]

        EditorPage editorModel ->
            [ viewHeader model.notification
            , Editor.view editorModel |> Html.Styled.map GotEditorMsg
            ]

        WelcomePage ->
            [ section [ class "hero is-fullheight" ]
                [ div [ class "hero-head" ]
                    [ viewHeader model.notification
                    ]
                , div [ class "hero-body" ]
                    [ viewWelcomePage ]
                , div [ class "hero-foot" ]
                    [ viewFooter
                    ]
                ]
            ]


viewHeader : Notification -> Html Msg
viewHeader notificationData =
    nav [ attribute "aria-label" "main navigation", class "navbar", attribute "role" "navigation" ]
        [ viewNotification notificationData
        , div [ class "container" ]
            [ div [ class "navbar-brand" ]
                [ a [ class "navbar-item", href "/" ]
                    [ img [ attribute "height" "28", src "https://i.imgur.com/OquiVkC.png", attribute "width" "96" ]
                        []
                    ]
                , a
                    [ attribute "aria-expanded" "false"
                    , attribute "aria-label" "menu"
                    , class "navbar-burger burger"
                    , attribute "data-target" "navbarBasicExample"
                    , attribute "role" "button"
                    ]
                    [ span [ attribute "aria-hidden" "true" ]
                        []
                    , span [ attribute "aria-hidden" "true" ]
                        []
                    , span [ attribute "aria-hidden" "true" ]
                        []
                    ]
                ]
            , div [ class "navbar-menu", id "navbarBasicExample" ]
                [ div [ class "navbar-start" ]
                    [ a [ class "navbar-item", href "/" ]
                        [ text "Home" ]
                    , a [ class "navbar-item", href "/editor" ]
                        [ text "Editor" ]
                    , a [ class "navbar-item", href "/settings" ]
                        [ text "Settings" ]
                    ]
                , div [ class "navbar-end" ]
                    [ div [ class "navbar-item" ]
                        [ div [ class "buttons" ]
                            [ button [ class "button is-light" ]
                                [ text "v 1.0.0" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


viewNotification : Notification -> Html Msg
viewNotification notification =
    case notification of
        GenericError err ->
            { text = err
            , closeMsg = CloseNotification
            }
                |> Ui.Notification.showError

        UnknownDecoderMessage err ->
            { text = err
            , closeMsg = CloseNotification
            }
                |> Ui.Notification.showError

        SettingsSaved ->
            { text = "Your settings have been saved. Now you should be able to use the editor. Welcome!"
            , closeMsg = CloseNotification
            }
                |> Ui.Notification.showSuccess

        None ->
            text ""


viewWelcomePage : Html msg
viewWelcomePage =
    div [ class "container" ]
        [ h1
            [ class "title" ]
            [ text "Hello there" ]
        , h2 [ class "subtitle" ]
            [ text "This is a hobby project built with Elm (plus javascript)"
            ]
        , p []
            [ text "First off, you have to set your "
            , a [ href "/settings" ] [ text "variables" ]
            , text ", then you can go to "
            , a [ href "/editor" ] [ text "/editor" ]
            , text "."
            ]
        , p []
            [ text "It may take from 30 mins to 3 hours until your sticker becomes available in Telegram." ]
        , br [] []
        , h2 [ class "subtitle" ]
            [ text "How it works"
            ]
        , iframe
            [ attribute "allow" "accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
            , attribute "allowfullscreen" ""
            , attribute "frameborder" "0"
            , attribute "height" "315"
            , src "https://www.youtube.com/embed/aBbs5pRoJXQ"
            , attribute "width" "560"
            ]
            []
        ]


viewFooter : Html msg
viewFooter =
    footer [ class "footer" ]
        [ div [ class "content has-text-centered" ]
            [ div [ class "container" ]
                [ p []
                    [ strong []
                        [ text "CutCut" ]
                    , text " by "
                    , a
                        [ href "https://maxpfrontend.ru"
                        , target "_blank"
                        ]
                        [ text "Max Frontend" ]
                    , text ". The source code on "
                    , a
                        [ href "https://github.com/maxfarseer/cutcut/"
                        , target "_blank"
                        ]
                        [ text "github" ]
                    , text ". Munich, 2020"
                    ]
                ]
            ]
        ]
