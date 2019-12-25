const IMG_NAME = 'cutcut.img'

export const getImageBase64 = () => {
  return sessionStorage.getItem(IMG_NAME);
}

export const saveImageBase64 = (base64: string) => {
  return sessionStorage.setItem(IMG_NAME, base64);
}
