import { Scope, Severity } from '@sentry/types';
import { CustomWindow } from '../custom.window';

declare let window: CustomWindow;

const isLocalhost = (): boolean => {
  return window.location.hostname === 'localhost';
};

const logError = (e: Error | string) => {
  let error = null;
  if (e instanceof Error) {
    error = e;
  } else {
    error = new Error(e);
  }

  if (isLocalhost()) {
    console.error(error);
  } else {
    window.Sentry.captureException(error);
  }
};

const logMessage = (msg: string) => {
  if (isLocalhost()) {
    console.info(msg);
  } else {
    // @ts-ignore
    window.Sentry.withScope((scope: Scope) => {
      scope.setLevel(Severity.Info);
      window.Sentry.captureMessage(msg);
    });
  }
};

export { logError, logMessage };
