// TODO: action type as union
export interface IPortEditorMsg {
  action: string,
  payload: any,
}

export interface IPortSettingsMsg {
  action: string,
  payload: any,
}

export interface IElmApp {
  ports: {
    msgFromJsToEditor: {
      send: ({ action, payload }: IPortEditorMsg) => void,
    },
    msgFromJsToEnvSettings: {
      send: ({ action, payload }: IPortSettingsMsg) => void,
    },
    msgForJsEditor: {
      subscribe: Function,
      unsubscribe: Function,
    },
    msgForJsStorage: {
      subscribe: Function,
      unsubscribe: Function,
    }
  }
}
