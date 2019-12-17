import { Elm } from './Main.elm'

console.log("hello world!!");

const errorLogger = error => console.error(`App Error: ${error}`);
const node = document.querySelector('#app');

// add flags here
const flags = {}
try {
  const app = Elm.Main.init({ node, flags });

  // ports
  const handlePortMsg = async ({ action, payload }) => {
    switch (action) {
      case 'DrawSquare': {
        drawSqaure(payload);
        break;
      }
      case 'CropImage': {
        cropImage(payload);
        break;
      }
      case 'PrepareForErase': {
        prepareForErase();
        break;
      }
      case 'RequestCroppedData': {
        requestCroppedData();
        break;
      }
      default:
        throw new Error(`Received unknown message ${action} from Elm.`);
    }
  };

  app.ports.msgForJs.subscribe(handlePortMsg);
  // end ports

} catch (e) {
  errorLogger(e);
  node.textContent = 'An error occurred while initializing the app';
}
