import { IPortMsg } from "./types";
import { CustomWindow } from '../../custom.window';
declare let window: CustomWindow;

const getCustomCropper = (): Node => {
  return document.getElementsByTagName('custom-cropper')[0];
}

const getCustomEraser = (): Node => {
  return document.getElementsByTagName('custom-eraser')[0];
}

const getCustomCanvas = (): Node => {
  return document.getElementsByTagName('custom-canvas')[0]
}

const cropImage = (imgUrl: string) => {
  const event = new CustomEvent('crop-image-init', { detail: { imgUrl } });
  window.requestAnimationFrame(() => {
    const customCropper = getCustomCropper();
    customCropper.dispatchEvent(event);
  });
};

const prepareForErase = (imgUrl: string) => {
  const event = new CustomEvent('prepare-for-erase', { detail: imgUrl });
  window.requestAnimationFrame(() => {
    const customEraser = getCustomEraser();
    customEraser.dispatchEvent(event);
  });
};

const addImgFinish = () => {
  const event = new CustomEvent('add-img-finish');
  const customEraser = getCustomEraser();
  customEraser.dispatchEvent(event);
};

const saveCroppedImage = () => {
  const event = new CustomEvent('save-cropped-image');
  const customCropper = getCustomCropper();
  customCropper.dispatchEvent(event);
}

const downloadSticker = () => {
  const event = new CustomEvent('download-sticker');
  const customCanvas = getCustomCanvas();
  customCanvas.dispatchEvent(event);
}

const requestUploadToPack = () => {
  const event = new CustomEvent('request-upload-to-pack');
  getCustomCanvas().dispatchEvent(event);
}

const addText = (payload: string) => {
  const event = new CustomEvent('add-text', { detail: payload });
  getCustomCanvas().dispatchEvent(event);
}

const handlePortMsg = async ({ action, payload }: IPortMsg) => {
  switch (action) {
    case 'CropImage': {
      cropImage(payload);
      break;
    }
    case 'PrepareForErase': {
      prepareForErase(payload);
      break;
    }
    case 'AddImgFinish': {
      addImgFinish();
      break;
    }
    case 'SaveCroppedImage': {
      saveCroppedImage();
      break;
    }
    case 'DownloadSticker': {
      downloadSticker();
      break;
    }

    case 'RequestUploadToPack': {
      requestUploadToPack();
      break;
    }

    case 'AddText': {
      addText(payload);
      break;
    }

    default:
      throw new Error(`Received unknown message ${action} from Elm.`);
  }
};

const sendToElm = ({ action, payload }: IPortMsg) => {
  window.elmApp.ports.msgForElm.send({ action, payload })
}

export { handlePortMsg, sendToElm };
