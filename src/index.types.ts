interface IElmApp {
  ports: {
    modeChosen: {
      send: Function,
    },
    msgForJs: {
      subscribe: Function,
      unsubscribe: Function,
    }
  }
}
