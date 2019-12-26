import { IElmApp } from "./js/ports/types";

// https://stackoverflow.com/a/45352250/1916578

export interface CustomWindow extends Window {
  elmApp: IElmApp
}
