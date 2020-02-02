module Main exposing (main)

import Browser
import Browser.Navigation as Nav
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


type alias Model =
    { key : Nav.Key
    , route : Route.Route
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        route =
            Route.fromUrl url
    in
    ( { key = key
      , route = route
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( model
            , Cmd.none
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
    case model.route of
        NotFound ->
            [ header [] [ text "Cut cut" ]
            , div [] [ text "Not found" ]
            ]

        Editor ->
            [ viewHeader
            , div [] [ text "editor" ]
            ]

        Welcome ->
            [ header [] [ text "Cut cut" ]
            , div [] [ text "welcome" ]
            ]


viewHeader : Html msg
viewHeader =
    nav [ attribute "aria-label" "main navigation", class "navbar", attribute "role" "navigation" ]
        [ div [ class "navbar-brand" ]
            [ a [ class "navbar-item", href "https://bulma.io" ]
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
                [ a [ class "navbar-item" ]
                    [ text "Home" ]
                , a [ class "navbar-item" ]
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
