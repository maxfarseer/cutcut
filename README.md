# CutCut

Make your own stickers to telegram with easy-peasy process.

![how-it-work-gif](https://maxpfrontend.ru/wp-content/uploads/2020/06/lana-sticker-process.gif)

([youtube demo link](https://youtu.be/aBbs5pRoJXQ))

Presentation (slides) about learning Elm and working on this project:
- English (todo)
- [На русском](https://docs.google.com/presentation/d/1__TGf1rlomeTtJ5gq5dxd9fu_Q4g8Zfyalu5wQKLnTM/edit?usp=sharing)

### Run project

```
npm install
node_modules/.bin/elm install
npm start
```

### Settings variables

Paste your variables at `/settings` page

- TELEGRAM_BOT_TOKEN, read [documentation](https://core.telegram.org/bots/api#authorizing-your-bot) chapter
- TELEGRAM_BOT_ID, same link as before
- TELEGRAM_USER_ID, use `@jsondumpbot` in telegram
- REMOVE_BG_API_KEY, you can find the key [here](https://www.remove.bg/profile#api-key) after registration

### Other info

For VS code users

_.vscode/settings.json_

```json
{
  "elm.compiler": "./node_modules/.bin/elm",
  "elm.makeCommand": "./node_modules/.bin/elm-make",
  "elm.formatCommand": "./node_modules/.bin/elm-format"
}
```

### Attention to parcel bundler

Somehow parcel can be broken with cache(?). If you have strange behaviour of elm compiler or whatever else:
- try to restart your project;
- try to delete `.cache` folder. If it doesn't help, delete `.dist`, `.elm-stuff`, `node_modules` and reinstall the dependencies.

Also, this version of parcel doesn't work as expected with `"elm/browser": "1.0.2",` sometimes. If you will have strange error, try to change dependency to `"elm/browser": "1.0.1",`.
