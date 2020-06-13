import { Scope, Severity } from '@sentry/types';
import { CustomWindow } from '../custom.window';

declare let window: CustomWindow;

const logError = (e: Error | string) => {
  let error = null;
  if (e instanceof Error) {
    error = e;
  } else {
    error = new Error(e);
  }

  window.Sentry.captureException(error);
};

const logMessage = (msg: string) => {
  // @ts-ignore
  window.Sentry.withScope((scope: Scope) => {
    scope.setLevel(Severity.Info);
    window.Sentry.captureMessage(msg);
  });
};

export { logError, logMessage };
