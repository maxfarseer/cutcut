// TODO:
// split IPortMsg to groups (Edtitor and EnvSettings)
// add typeof action
export interface IPortMsg {
  action: string,
  payload: any,
}

export interface IElmApp {
  ports: {
    msgForElm: {
      send: ({ action, payload }: IPortMsg) => void,
    },
    msgForEnvSettings: {
      send: ({ action, payload }: IPortMsg) => void,
    },
    msgForJs: {
      subscribe: Function,
      unsubscribe: Function,
    },
    msgForStorage: {
      subscribe: Function,
      unsubscribe: Function,
    }
  }
}
