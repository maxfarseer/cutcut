# CutCut

Make your own stickers to telegram with easy-peasy process.

![how-it-work-gif](https://uc7fbbf6740778ca49fcc7f92103.previews.dropboxusercontent.com/p/orig/AAyIcs6s10lLymGXhXQ-DU-eb0B2HoIhyCx4Qf74lhfsE6lqVfVodk08qU2P_elzBAPI2TeEs57Fzws7a1UMYtQMN1KmgmGw-rteoohagDwT-anJG2sLgFlFTmap-ILZR20BEEiFXWvbyOblKJUEPukk8-uDiesvxXQVYpRa0A9QRL4UK7ddyUryH-HSUVUyT4wDpVqSFJA6N7C5jOLTR9ssw99fyPHBoZndDJ_AurVvD78WZkC41KwsfACa_tnNoSEQd-sPFmO-tBcQCXYFYfAX1fGsI6RXf5HsvdZm6nrf0c1l0IjXynpKmpo4q7Y-7xajrU6PUhAZ-a9T-UsBXbSel1vBE7BRacvc0aIv_kg9Sg/p.gif?fv_content=true&size_mode=5)

([youtube demo link](https://youtu.be/aBbs5pRoJXQ))

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
npm install
node_modules/.bin/elm install
npm start
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

### Attention to parcel bundler

Somehow parcel can be broken with cache(?). If you have strange behaviour of elm compiler or whatever else, try to restart your project.

Also, this version of parcel doesn't work as expected with `"elm/browser": "1.0.2",`, because of it, I use 1.0.1 version of elm/browser here. It may work for you (on your machine), try it!