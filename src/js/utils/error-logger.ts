import { Scope, Severity } from '@sentry/types';
import { CustomWindow } from '../../custom.window';
import { isDevMode } from './index';

declare let window: CustomWindow;

const logError = (e: Error | string) => {
  let error = null;
  if (e instanceof Error) {
    error = e;
  } else {
    error = new Error(e);
  }

  if (isDevMode()) {
    console.error(error);
  } else {
    window.Sentry.captureException(error);
  }
};

const logMessage = (msg: string) => {
  if (isDevMode()) {
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
