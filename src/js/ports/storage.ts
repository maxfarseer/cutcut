export type UserEnvSettings = {
  telegramBotToken : string
  telegramUserId : string
  telegramBotId : string
  removeBgApiKey : string
}

export const saveSettingsToLS = (payload: UserEnvSettings) => {
  localStorage.setItem('cutcut.settings', JSON.stringify(payload));
}