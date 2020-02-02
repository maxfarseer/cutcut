module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Editor
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Route exposing (Route(..))
import Url



-- MAIN


main : Program () Model Msg
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
    | NotFoundPage


type alias Model =
    { key : Nav.Key
    , page : Page
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        route =
            Route.fromUrl url
    in
    ( { key = key
      , page = WelcomePage
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | GotEditorMsg Editor.Msg


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


updateUrl : Url.Url -> Model -> ( Model, Cmd Msg )
updateUrl url model =
    case Route.fromUrl url of
        Welcome ->
            ( { model | page = WelcomePage }, Cmd.none )

        Editor ->
            Editor.init |> toEditor model

        NotFound ->
            ( { model | page = NotFoundPage }, Cmd.none )


toEditor : Model -> ( Editor.Model, Cmd Editor.Msg ) -> ( Model, Cmd Msg )
toEditor model ( editorModel, editorCmd ) =
    ( { model | page = EditorPage editorModel }
    , Cmd.map GotEditorMsg editorCmd
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



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

        EditorPage editorModel ->
            [ viewHeader
            , Editor.view editorModel |> Html.Styled.map GotEditorMsg
            ]

        WelcomePage ->
            [ viewHeader
            , div [] [ text "welcome" ]
            ]


viewHeader : Html msg
viewHeader =
    nav [ attribute "aria-label" "main navigation", class "navbar", attribute "role" "navigation" ]
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
                ]
            , div [ class "navbar-end" ]
                [ div [ class "navbar-item" ]
                    [ div [ class "buttons" ]
                        [ a [ class "button is-info" ]
                            [ strong []
                                [ text "Learn elm" ]
                            ]
                        , a [ class "button is-light" ]
                            [ text "v. 0.0.1" ]
                        ]
                    ]
                ]
            ]
        ]
