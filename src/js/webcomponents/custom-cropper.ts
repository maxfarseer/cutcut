import Cropper from 'cropperjs';
import { CustomWindow } from '../../custom.window';
import { sendToElmFromEditor } from '../ports/editor';
import { logError, logMessage } from '../error-logger';

declare let window: CustomWindow;

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
    this._wrapperDiv = div;

    this.appendChild(this._wrapperDiv);
    this.addEventListener('crop-image-init', this.initImage, false);
    this.addEventListener('crop-image', this.cropImage, false);
  }

  initImage = (e: Event) => {
    const imgUrl = (e as CustomEvent).detail.imgUrl;
    this.loadImage(imgUrl);
  };

  initCropper = (img: HTMLCanvasElement) => {
    // https://github.com/fengyuanchen/cropperjs#options
    try {
      const self = this;

      const cropper = new Cropper(img, {
        crop(event) {
          // coordinates & more
        },
        ready() {
          self._cropper = cropper;
        },
      });
    } catch (err) {
      logError(err);
    }
  };

  loadImage = (imgUrl: string) => {
    try {
      const img = new Image();

      img.onload = () => {
        this.resizeImg(img)
          .then((canvas: HTMLCanvasElement) => {
            if (this._wrapperDiv) {
              this._wrapperDiv.appendChild(canvas);
            } else {
              throw new Error('loadImage: parent div for crop-image canvas element not found');
            }
            this.initCropper(canvas);
          });
      }

      img.src = imgUrl;
    } catch (err) {
      logError(err);
    }
  };

  resizeImg = (img: HTMLImageElement) => {
    try {
      const expected = 640;
      const { width, height } = img;

      const newHeight = height * expected / width;

      const canvas = document.createElement('canvas');
      canvas.width = expected;
      canvas.height = newHeight;

      const from = img;
      const to = canvas;

      return window.pica().resize(from, to, {
        alpha: true,
        unsharpAmount: 80,
        unsharpRadius: 0.6,
        unsharpThreshold: 2
      });
    } catch (err) {
      logError(err);
    }
  }

  cropImage = () => {
    try {
      if (!this._cropper) {
        throw new Error('cropImage: instance of cropper not found')
      }
      const dataUrl = this._cropper.getCroppedCanvas().toDataURL();
      sendToElmFromEditor({ action: 'ImageCropped', payload: dataUrl });
    } catch (err) {
      logError(err)
    }
  };
}

window.customElements.define('custom-cropper', CustomCropper);
