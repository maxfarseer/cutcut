import { IPortSettingsMsg } from './types';
import { CustomWindow } from '../../custom.window';

declare let window: CustomWindow;

const key = 'cutcut.settings';

export type UserEnvSettings = {
  telegramBotToken: string,
  telegramUserId: string,
  telegramBotId: string,
  telegramBotStickerPackName: string,
  removeBgApiKey: string,
};

export type SettingsFromLS = UserEnvSettings | null;

const saveSettingsToLS = (payload: UserEnvSettings) => {
  localStorage.setItem(key, JSON.stringify(payload));
  sendToEnvSettings({
    action: 'SettingsSavedSuccessfully',
    payload: null,
  });
};

export const getSettingsFromLS = (): SettingsFromLS => {
  if (localStorage.getItem(key)) {
    return JSON.parse(localStorage.getItem(key) as string);
  }
  return null;
};

const askForSettingsFromLS = (): void => {
  sendToEnvSettings({
    action: 'LoadedSettingsFromLS',
    payload: getSettingsFromLS(),
  });
};

export const handlePortStorageMsg = async ({ action, payload }: IPortSettingsMsg) => {
  switch (action) {
    case 'SaveSettingsToLS': {
      saveSettingsToLS(payload);
      break;
    }
    case 'AskForSettingsFromLS': {
      askForSettingsFromLS();
      return;
    }

    default:
      throw new Error(
        `Received unknown message ${action} for Storage port from Elm.`
      );
  }
};

export const sendToEnvSettings = ({ action, payload }: IPortSettingsMsg) => {
  window.elmApp.ports.msgFromJsToEnvSettings.send({ action, payload })
}
