# CutCut

Make your own stickers to telegram with easy-peasy process.

### For start project

Setup your environment variables, by copying env file first:

```
cp .env.example .env
```

Fullfill .env file with next variables:

- TELEGRAM_BOT_TOKEN, read [documentation](https://core.telegram.org/bots/api#authorizing-your-bot) chapter
- TELEGRAM_BOT_ID, same link as before
- TELEGRAM_USER_ID, use `@jsondumpbot` in telegram
- REMOVE_BG_API_KEY, you can find the key [here](https://www.remove.bg/profile#api-key) after registration

Now you can start project as usual:

```
yarn install
node_modules/.bin/elm install
yarn start
```

For VS code users

_.vscode/settings.json_

```json
{
  "elm.compiler": "./node_modules/.bin/elm",
  "elm.makeCommand": "./node_modules/.bin/elm-make",
  "elm.formatCommand": "./node_modules/.bin/elm-format"
}
```
