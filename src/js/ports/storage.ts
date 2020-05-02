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

export const getSettingsFromLS = (): string | null => {
  if (localStorage.getItem(key)) {
    return JSON.parse(localStorage.getItem(key) as string);
  }
  return JSON.stringify(null); 
}