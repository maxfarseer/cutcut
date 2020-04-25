module Base64 exposing (Base64ImgUrl, fromString, toString)


type Base64ImgUrl
    = Base64ImgUrl String


toString : Base64ImgUrl -> String
toString (Base64ImgUrl str) =
    str


fromString : String -> Base64ImgUrl
fromString str =
    Base64ImgUrl str
