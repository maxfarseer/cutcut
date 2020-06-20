port module Tracking exposing (trackEvent)

import Json.Encode as JE


type alias PortData =
    { action : String
    , payload : JE.Value
    }


type OutgoingMsg
    = TrackEvent String



-- To JS


port msgForJsTracking : PortData -> Cmd msg


track : OutgoingMsg -> Cmd msg
track outgoingMsg =
    msgForJsTracking <|
        case outgoingMsg of
            -- TODO: payload as object not supported yet
            TrackEvent eventName ->
                { action = "TrackEvent", payload = JE.string eventName }


trackEvent : String -> Cmd msg
trackEvent eventName =
    track (TrackEvent eventName)
