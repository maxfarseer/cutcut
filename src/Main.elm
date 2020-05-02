module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Data.Settings as DS
import Editor
import Html.Styled exposing (Html, a, div, footer, h1, h2, img, nav, p, section, span, strong, text, toUnstyled)
import Html.Styled.Attributes exposing (attribute, class, href, id, src, target)
import Json.Decode as JD
import Route exposing (Route(..))
import Settings
import Url


type alias Flags =
    { env : Maybe DS.Model
    , buildDate : Int
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


type alias Model =
    { key : Nav.Key
    , page : Page
    , flags : Flags
    }


init : JD.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    case JD.decodeValue flagsDecoder flags of
        Ok decodedFlags ->
            updateUrl url { page = NotFoundPage, key = key, flags = decodedFlags }

        Err err ->
            updateUrl url
                { page = NotFoundPage
                , key = key
                , flags = { env = Nothing, buildDate = 0 }
                }



-- DECODERS


flagsDecoder : JD.Decoder Flags
flagsDecoder =
    JD.map2 Flags
        (JD.field "env" flagsEnvDecoder |> JD.nullable)
        (JD.field "buildDate" JD.int)


flagsEnvDecoder : JD.Decoder DS.Model
flagsEnvDecoder =
    JD.map4 DS.Model
        (JD.field "telegramBotToken" JD.string)
        (JD.field "telegramUserId" JD.string)
        (JD.field "telegramBotId" JD.string)
        (JD.field "removeBgApiKey" JD.string)



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotEditorMsg Editor.Msg
    | GotSettingsMsg Settings.Msg


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

        GotEditorMsg editorMsg ->
            case model.page of
                EditorPage editorModel ->
                    toEditor model (Editor.update editorMsg editorModel)

                _ ->
                    ( model, Cmd.none )

        GotSettingsMsg settingsMsg ->
            case model.page of
                SettingsPage settingsModel ->
                    toSettings model (Settings.update settingsMsg settingsModel)

                _ ->
                    ( model, Cmd.none )


updateUrl : Url.Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Route.fromUrl url of
        Welcome ->
            ( { model | page = WelcomePage }, Cmd.none )

        Editor ->
            Editor.init |> toEditor model

        Settings ->
            Settings.init |> toSettings model

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
    case model.page of
        WelcomePage ->
            Sub.none

        EditorPage _ ->
            Editor.subscriptions ()
                |> Sub.map GotEditorMsg

        NotFoundPage ->
            Sub.none

        SettingsPage _ ->
            Settings.subscriptions ()
                |> Sub.map GotSettingsMsg



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
            [ viewHeader
            , div [] [ text "Not found" ]
            ]

        SettingsPage settingsModel ->
            [ viewHeader
            , Settings.view settingsModel |> Html.Styled.map GotSettingsMsg
            ]

        EditorPage editorModel ->
            [ viewHeader
            , Editor.view editorModel |> Html.Styled.map GotEditorMsg
            ]

        WelcomePage ->
            [ section [ class "hero is-fullheight" ]
                [ div [ class "hero-head" ]
                    [ viewHeader
                    ]
                , div [ class "hero-body" ]
                    [ viewWelcomePage ]
                , div [ class "hero-foot" ]
                    [ viewFooter
                    ]
                ]
            ]


viewHeader : Html msg
viewHeader =
    nav [ attribute "aria-label" "main navigation", class "navbar", attribute "role" "navigation" ]
        [ div [ class "container" ]
            [ div [ class "navbar-brand" ]
                [ a [ class "navbar-item", href "/" ]
                    [ img [ attribute "height" "28", src "https://i.imgur.com/OquiVkC.png", attribute "width" "96" ]
                        []
                    ]
                , a [ attribute "aria-expanded" "false", attribute "aria-label" "menu", class "navbar-burger burger", attribute "data-target" "navbarBasicExample", attribute "role" "button" ]
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
                            [ a
                                [ class "button is-info"
                                , href "https://github.com/maxfarseer/cutcut/"
                                , target "_blank"
                                ]
                                [ strong []
                                    [ text "Fork me" ]
                                ]
                            , a [ class "button is-light" ]
                                [ text "v. 1.0.0" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


viewWelcomePage : Html msg
viewWelcomePage =
    div [ class "container" ]
        [ h1
            [ class "title" ]
            [ text "Hello there" ]
        , h2 [ class "subtitle" ]
            [ text "That hobby project built with Elm & Typescript"
            ]
        , p []
            [ text "At first you have to setup user and bot ids, and you can go to "
            , a [ href "/edit" ] [ text "/edit" ]
            , text " then."
            ]
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
                    , a [ href "https://maxpfrontend.ru" ]
                        [ text "Max Frontend" ]
                    , text ". The source code on "
                    , a [ href "https://github.com/maxfarseer/cutcut/" ]
                        [ text "github" ]
                    , text ". Munich, 2020"
                    ]
                ]
            ]
        ]
