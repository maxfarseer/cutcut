module Custom exposing (customCropper)

import Html.Styled exposing (..)


customCropper : List (Attribute a) -> List (Html a) -> Html a
customCropper attributes children =
    node "custom-cropper" attributes children
