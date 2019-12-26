// @ts-ignore
import { Elm } from './Main.elm'
import { handlePortMsg } from './js/ports'
import { CustomWindow } from './custom.window';
import { IElmApp } from './js/ports/types';

// https://stackoverflow.com/questions/12709074/how-do-you-explicitly-set-a-new-property-on-window-in-typescript
declare let window: CustomWindow;

const errorLogger = (error: string) => console.error(`App Error: ${error}`);
const node = document.querySelector('#app');

// add flags here
const flags = {}
try {
  const app: IElmApp = Elm.Main.init({ node, flags });

  // ports
  app.ports.msgForJs.subscribe(handlePortMsg);
  // end ports

  // TODO or NOT:
  // make a parent class, which will take app as argument
  // and will have a sendToElm method
  // other webcomponents can inherit from it
  window.elmApp = app;

} catch (e) {
  errorLogger(e);
  node!.textContent = 'An error occurred while initializing the app';
} // here was a typecript error: Cannot find global value 'Promise'.ts(2468)
// fixed by this: https://github.com/facebook/create-react-app/issues/5683#issuecomment-435360932
