port module Tracking exposing (trackEvent, trackWithPayload)

import Json.Encode as JE


type alias PortData =
    { action : String
    , payload : JE.Value
    }


type alias Event =
    { name : String
    , category : String
    , label : String
    , value : String
    }



-- TODO: change String to EventName type and lock possible event name values


type OutgoingMsg
    = TrackEvent String
    | TrackEventWithPayload Event



-- Encoders


eventEncoder : Event -> JE.Value
eventEncoder event =
    JE.object
        [ ( "name", JE.string event.name )
        , ( "category", JE.string event.category )
        , ( "label", JE.string event.label )
        , ( "value", JE.string event.value )
        ]



-- To JS


port msgForJsTracking : PortData -> Cmd msg


track : OutgoingMsg -> Cmd msg
track outgoingMsg =
    msgForJsTracking <|
        case outgoingMsg of
            TrackEvent eventName ->
                { action = "TrackEvent", payload = JE.string eventName }

            TrackEventWithPayload event ->
                { action = "TrackEvent", payload = eventEncoder event }


trackEvent : String -> Cmd msg
trackEvent eventName =
    track (TrackEvent eventName)


trackWithPayload : Event -> Cmd msg
trackWithPayload event =
    track (TrackEventWithPayload event)
