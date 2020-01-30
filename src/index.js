import { Elm } from "./Main.elm";

if (module.hot) {
  module.hot.dispose(() => {
    window.location.reload();
  });
}

const flags = {};
console.log(Elm);
const app = Elm.Main.init({ flags });
