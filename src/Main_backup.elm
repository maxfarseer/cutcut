module Main_backup exposing (main)

import Browser exposing (Document, UrlRequest)
import Browser.Navigation as Nav
import Editor as EditorPage
import Html.Styled as Html exposing (Html, div, h1, text, toUnstyled)
import Route
import Url exposing (Url)


type Page
    = Main
    | Editor EditorPage.Model
    | NotFound


type alias Model =
    { page : Page
    , route : Route.Route
    , navKey : Nav.Key
    }



-- init


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        model =
            { route = Route.parseUrl url
            , page = NotFound
            , navKey = navKey
            }
    in
    initCurrentPage ( model, Cmd.none )


initCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
initCurrentPage ( model, existingCmds ) =
    let
        ( currentPage, mappedPageCmds ) =
            case model.route of
                Route.NotFound ->
                    ( NotFound, Cmd.none )

                Route.Editor ->
                    let
                        ( pageModel, pageCmds ) =
                            EditorPage.init
                    in
                    ( Editor pageModel, Cmd.map GotEditorMsg pageCmds )

                _ ->
                    ( NotFound, Cmd.none )
    in
    ( { model | page = currentPage }
    , Cmd.batch [ existingCmds, mappedPageCmds ]
    )



-- update


type Msg
    = GotEditorMsg EditorPage.Msg
    | LinkClicked UrlRequest
    | UrlChanged Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( GotEditorMsg subMsg, Editor pageModel ) ->
            let
                ( updatedPageModel, updatedCmd ) =
                    EditorPage.update subMsg pageModel
            in
            ( { model | page = Editor updatedPageModel }
            , Cmd.map GotEditorMsg updatedCmd
            )

        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                Browser.External url ->
                    ( model
                    , Nav.load url
                    )

        ( UrlChanged url, _ ) ->
            let
                newRoute =
                    Route.parseUrl url
            in
            ( { model | route = newRoute }, Cmd.none )
                |> initCurrentPage

        ( _, _ ) ->
            ( model, Cmd.none )



-- view


view : Model -> Document Msg
view model =
    { title = "CutCut"

    --, body = [ toUnstyled (currentView model) ]
    , body = [ toUnstyled (div [] [ text "hello" ]) ]
    }


currentView : Model -> Html Msg
currentView model =
    case model.page of
        NotFound ->
            notFoundView

        Editor pageModel ->
            EditorPage.view pageModel
                |> Html.map GotEditorMsg

        _ ->
            notFoundView


notFoundView : Html msg
notFoundView =
    h1 [] [ text "Oops! The page you requested was not found!" ]


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
