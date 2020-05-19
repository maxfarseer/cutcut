// @ts-ignore
import { Elm } from './Main.elm';
import { handlePortEditorMsg } from './js/ports/editor';
import { handlePortStorageMsg } from './js/ports/storage';
import { CustomWindow } from './custom.window';
import { IElmApp } from './js/ports/types';

// https://stackoverflow.com/questions/12709074/how-do-you-explicitly-set-a-new-property-on-window-in-typescript
declare let window: CustomWindow;

const errorLogger = (error: string) => console.error(`App Error: ${error}`);
const node = document.querySelector('#app');

try {
  if (!process.env.REMOVE_BG_API_KEY) {
    throw new Error(
      'You forgot to set up REMOVE_BG_API_KEY in .env, check README for project',
    );
  }

  const flags = {
    buildDate: +new Date(),
  };

  const app: IElmApp = Elm.Main.init({ node, flags });

  // ports
  app.ports.msgForJsEditor.subscribe(handlePortEditorMsg);
  app.ports.msgForJsStorage.subscribe(handlePortStorageMsg);
  // end ports

  window.elmApp = app;
} catch (e) {
  errorLogger(e);
  node!.textContent = 'An error occurred while initializing the app';
}
// here was a typecript error: Cannot find global value 'Promise'.ts(2468)
// fixed by this: https://github.com/facebook/create-react-app/issues/5683#issuecomment-435360932
