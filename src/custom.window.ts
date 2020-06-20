import { IElmApp } from './js/ports/types';
import { Client } from '@sentry/types';

// https://stackoverflow.com/a/45352250/1916578

// https://developers.google.com/analytics/devguides/collection/gtagjs/events#send_events
type GtagEventParams = Partial<{
  event_category: string,
  event_label: string,
  value: string,
}>;

type GtagType = (
  event: string,
  eventName: string,
  eventParams?: GtagEventParams
) => void;

export interface CustomWindow extends Window {
  elmApp: IElmApp;
  pica: any; // https://github.com/nodeca/pica
  Sentry: Client;
  gtag: GtagType;
}
