module Route exposing (Route(..), fromUrl)

import Url exposing (Url)
import Url.Parser exposing (Parser, map, oneOf, parse, s, top)


type Route
    = NotFound
    | Welcome
    | Editor


matchRoute : Parser (Route -> a) a
matchRoute =
    oneOf
        [ map Welcome top
        , map Welcome (s "index.html")
        , map Editor (s "editor")
        ]


fromUrl : Url -> Route
fromUrl url =
    parse matchRoute url
        |> Maybe.withDefault NotFound
