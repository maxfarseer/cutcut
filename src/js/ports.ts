const drawSqaure = (base64path: string) => {
  const event = new CustomEvent('draw-image', { detail: { base64path } });
  const customCanvas = document.getElementsByTagName('custom-canvas')[0];
  customCanvas.dispatchEvent(event);
};

const cropImage = (imgUrl: string) => {
  const event = new CustomEvent('crop-image-init', { detail: { imgUrl } });
  window.requestAnimationFrame(() => {
    const customCropper = document.getElementsByTagName('custom-cropper')[0];
    customCropper.dispatchEvent(event);
  });
};

const prepareForErase = () => {
  const event = new CustomEvent('prepare-for-erase');
  const customCropper = document.getElementsByTagName('custom-cropper')[0];
  customCropper.dispatchEvent(event);
};

const requestCroppedData = () => {
  const event = new CustomEvent('request-cropped-data');
  const customCropper = document.getElementsByTagName('custom-cropper')[0];
  customCropper.dispatchEvent(event);
};

type PortMsg = {
  action: string,
  payload: any,
}

const handlePortMsg = async ({ action, payload }: PortMsg) => {
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
      prepareForErase();
      break;
    }
    case 'RequestCroppedData': {
      requestCroppedData();
      break;
    }
    default:
      throw new Error(`Received unknown message ${action} from Elm.`);
  }
};

export { handlePortMsg };
