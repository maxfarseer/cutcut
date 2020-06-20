module Custom exposing (customCanvas, customCropper, customEraser)

import Html.Styled exposing (Attribute, Html, node)


customCropper : List (Attribute a) -> List (Html a) -> Html a
customCropper attributes children =
    node "custom-cropper" attributes children


customCanvas : List (Attribute a) -> List (Html a) -> Html a
customCanvas attributes children =
    node "custom-canvas" attributes children


customEraser : List (Attribute a) -> List (Html a) -> Html a
customEraser attributes children =
    node "custom-eraser" attributes children
