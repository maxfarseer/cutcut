import { isDevMode } from './index';
import { CustomWindow } from '../../custom.window';

declare let window: CustomWindow;

type EventWithParams = {
  name: string,
} & Partial<{
  category: string,
  label: string,
  value: string,
}>;

export type AnalyticsEvent = string | EventWithParams;

export const trackEvent = (event: AnalyticsEvent) => {
  if (isDevMode()) {
    console.info('--- track event (dev mode) ---');
    console.info(event);
    console.info('---');
  } else {
    if (typeof event === 'string') {
      window.gtag('event', event);
    }
    if (typeof event === 'object') {
      window.gtag('event', event.name, {
        event_category: event.category,
        event_label: event.label,
        value: event.value,
      });
    }
  }
};
