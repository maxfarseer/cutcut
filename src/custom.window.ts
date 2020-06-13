import { IElmApp } from './js/ports/types';
import { Client } from '@sentry/types';

// https://stackoverflow.com/a/45352250/1916578

export interface CustomWindow extends Window {
  elmApp: IElmApp;
  pica: any; // https://github.com/nodeca/pica
  Sentry: Client;
}
