// @ts-ignore
import { Elm } from './elm/Main.elm';
import { handlePortEditorMsg } from './js/ports/editor';
import { handlePortStorageMsg } from './js/ports/storage';
import { handlePortTrackingMsg } from './js/ports/tracking';
import { CustomWindow } from './custom.window';
import { IElmApp } from './js/ports/types';
import { logError } from './js/utils/error-logger';

// https://stackoverflow.com/questions/12709074/how-do-you-explicitly-set-a-new-property-on-window-in-typescript
declare let window: CustomWindow;

const node = document.querySelector('#app');

try {
  const flags = {
    buildDate: +new Date(),
  };

  const app: IElmApp = Elm.Main.init({ node, flags });

  // ports
  app.ports.msgForJsEditor.subscribe(handlePortEditorMsg);
  app.ports.msgForJsStorage.subscribe(handlePortStorageMsg);
  app.ports.msgForJsTracking.subscribe(handlePortTrackingMsg);
  // end ports

  window.elmApp = app;
} catch (e) {
  logError(e)
  node!.textContent = 'An error occurred while initializing the app';
}
// here was a typecript error: Cannot find global value 'Promise'.ts(2468)
// fixed by this: https://github.com/facebook/create-react-app/issues/5683#issuecomment-435360932
