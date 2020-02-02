import { IPortMsg } from "./types";

const getCustomCropper = (): Node => {
  return document.getElementsByTagName('custom-cropper')[0];
}

const getCustomEraser = (): Node => {
  return document.getElementsByTagName('custom-eraser')[0];
}

const getCustomCanvas = (): Node => {
  return document.getElementsByTagName('custom-canvas')[0]
}

const drawSqaure = (base64path: string) => {
  const event = new CustomEvent('draw-image', { detail: { base64path } });
  const customCanvas = getCustomCanvas();
  customCanvas.dispatchEvent(event);
};

const cropImage = (imgUrl: string) => {
  const event = new CustomEvent('crop-image-init', { detail: { imgUrl } });
  window.requestAnimationFrame(() => {
    const customCropper = getCustomCropper();
    customCropper.dispatchEvent(event);
  });
};

const prepareForErase = (removeBg: boolean) => {
  const event = new CustomEvent('prepare-for-erase', { detail: { removeBg } });
  window.requestAnimationFrame(() => {
    const customEraser = getCustomEraser();
    customEraser.dispatchEvent(event);
  });
};

/* TODO: doesn't work in Chrome, customEraser is undefined */
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

const handlePortMsg = async ({ action, payload }: IPortMsg) => {
  switch (action) {
    case 'DrawSquare': {
      drawSqaure(payload);
      break;
    }
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

    default:
      throw new Error(`Received unknown message ${action} from Elm.`);
  }
};

export { handlePortMsg };
