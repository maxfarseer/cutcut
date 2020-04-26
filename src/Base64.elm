module Base64 exposing (Base64ImgUrl, decoderStringToBase64ImgUrl, fromString, toString)

import Json.Decode as JD
import String exposing (startsWith)


type Base64ImgUrl
    = Base64ImgUrl String


toString : Base64ImgUrl -> String
toString (Base64ImgUrl str) =
    str


fromString : String -> Base64ImgUrl
fromString str =
    if startsWith "data:image" str then
        Base64ImgUrl str

    else
        Base64ImgUrl ("data:image/png;base64, " ++ str)



-- Decoders


decoderStringToBase64ImgUrl : JD.Decoder Base64ImgUrl
decoderStringToBase64ImgUrl =
    JD.map fromString JD.string
