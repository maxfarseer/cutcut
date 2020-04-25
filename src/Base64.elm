module Base64 exposing (Base64ImgUrl, decoderStringToBase64ImgUrl, fromString, toString)

import Json.Decode as JD
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



-- Decoders


decoderStringToBase64ImgUrl : JD.Decoder Base64ImgUrl
decoderStringToBase64ImgUrl =
    JD.map Base64ImgUrl JD.string
