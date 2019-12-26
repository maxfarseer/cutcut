export interface IPortMsg {
  action: string,
  payload: any,
}

export interface IElmApp {
  ports: {
    msgForElm: {
      send: ({ action, payload }: IPortMsg) => void,
    },
    msgForJs: {
      subscribe: Function,
      unsubscribe: Function,
    }
  }
}
