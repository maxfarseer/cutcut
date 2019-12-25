import Cropper from 'cropperjs';
import { CustomWindow } from '../../custom.window';

declare let window: CustomWindow;

const testImg =
  'iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAARUlEQVR42u3PMREAAAgEoLd/AtNqBlcPGlDJdB4oEREREREREREREREREREREREREREREREREREREREREREREREREZGLBddNT+MQpgCuAAAAAElFTkSuQmCC';

class CustomCropper extends HTMLElement {
  private _cropper: Cropper | null;
  private _wrapperDiv: HTMLDivElement | null;

  constructor() {
    super();
    this._cropper = null;
    this._wrapperDiv = null;
  }

  connectedCallback() {
    const div = document.createElement('div');
    div.id = 'img-wrapper';
    this._wrapperDiv = div;

    this.appendChild(this._wrapperDiv);
    this.addEventListener('crop-image-init', this.initImage, false);
    this.addEventListener('save-cropped-image', this.saveCroppedImage, false);
  }

  initImage = (e: Event) => {
    const imgUrl = (e as CustomEvent).detail.imgUrl;
    this.loadImage(imgUrl, this.initCropper);
  };

  initCropper = () => {
    // https://github.com/fengyuanchen/cropperjs#options
    const image = document.getElementById('cropper-image');
    const self = this;

    if (image) {
      const cropper = new Cropper((image as HTMLImageElement), {
        crop(event) {
          // coordinates & more
        },
        ready() {
          self._cropper = cropper;
        },
      });
    } else {
      console.warn('#cropper-image element not found')
    }
  };

  loadImage = (imgUrl: string, cb: () => void) => {
    const img = new Image();
    img.id = 'cropper-image';
    img.onload = cb;

    if (this._wrapperDiv) {
      this._wrapperDiv.appendChild(img);
    } else {
      console.warn('parent div for crop-image not found');
    }

    img.src = imgUrl;
  };

  saveCroppedImage = () => {
    if (this._cropper) {
      const dataUrl = this._cropper.getCroppedCanvas().toDataURL();
      // TODO: make image optimised small
      // it's not worth to keep big for 512px sticker
      sessionStorage.setItem('cutcut.img', dataUrl);
      window.elmApp.ports.modeChosen.send('1');
    } else {
      console.warn('instance of cropper not found');
    }
  };
}

window.customElements.define('custom-cropper', CustomCropper);
