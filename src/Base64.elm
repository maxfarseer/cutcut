module Base64 exposing (Base64ImgUrl, fromString, toString)

import String exposing (startsWith)


type Base64ImgUrl
    = Base64ImgUrl String


toString : Base64ImgUrl -> String
toString (Base64ImgUrl str) =
    if startsWith "data:image" str then
        str

    else
        "data:image/png;base64, " ++ str


fromString : String -> Base64ImgUrl
fromString str =
    Base64ImgUrl str
