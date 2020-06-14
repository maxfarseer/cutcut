import { trackEvent, AnalyticsEvent } from '../utils/analytics';

// TODO: what about PageView action? Add if needed.
type PortTrackingMsg = {
  action: 'TrackEvent',
  payload: AnalyticsEvent,
};

export const handlePortTrackingMsg = async ({
  action,
  payload,
}: PortTrackingMsg) => {
  switch (action) {
    case 'TrackEvent': {
      trackEvent(payload);
      break;
    }

    default:
      throw new Error(
        `Received unknown message ${action} for Tracking port from Elm.`
      );
  }
};
