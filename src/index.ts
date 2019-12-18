// @ts-ignore
import { Elm } from './Main.elm'
import { handlePortMsg } from './js/ports'

const errorLogger = (error: string) => console.error(`App Error: ${error}`);
const node = document.querySelector('#app');

// add flags here
const flags = {}
try {
  const app = Elm.Main.init({ node, flags });

  // ports
  app.ports.msgForJs.subscribe(handlePortMsg);
  // end ports

} catch (e) {
  errorLogger(e);
  node!.textContent = 'An error occurred while initializing the app';
} // here was a typecript error: Cannot find global value 'Promise'.ts(2468)
// fixed by this: https://github.com/facebook/create-react-app/issues/5683#issuecomment-435360932
