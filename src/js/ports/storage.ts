import { sendToElm } from './index'

const key = 'cutcut.settings';

export type UserEnvSettings = {
  telegramBotToken : string
  telegramUserId : string
  telegramBotId : string
  removeBgApiKey : string
}

export const saveSettingsToLS = (payload: UserEnvSettings) => {
  localStorage.setItem(key, JSON.stringify(payload));
}

const getSettingsFromLS = (): string | null => {
  if (localStorage.getItem(key)) {
    return JSON.parse(localStorage.getItem(key) as string);
  }
  return JSON.stringify(null); 
}

export const askForSettingsFromLS = (): void => {
  console.log('askForSettingsFromLS', getSettingsFromLS())
  sendToElm({
    action: 'LoadedSettingsFromLS',
    payload: getSettingsFromLS(),
  });
}