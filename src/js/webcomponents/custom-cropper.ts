import Cropper from 'cropperjs';
import { CustomWindow } from '../../custom.window';
import { sendToElm } from '../ports'

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
    this.addEventListener('save-cropped-image', this.saveCroppedImage, false);
  }

  initImage = (e: Event) => {
    const imgUrl = (e as CustomEvent).detail.imgUrl;
    this.loadImage(imgUrl);
  };

  initCropper = (img: HTMLCanvasElement) => {
    // https://github.com/fengyuanchen/cropperjs#options
    const self = this;

    const cropper = new Cropper(img, {
      crop(event) {
        // coordinates & more
      },
      ready() {
        self._cropper = cropper;
      },
    });
  };

  loadImage = (imgUrl: string) => {
    const img = new Image();

    img.onload = () => {
      this.resizeImg(img)
        .then((canvas: HTMLCanvasElement) => {
          if (this._wrapperDiv) {
            this._wrapperDiv.appendChild(canvas);
          } else {
            console.warn('parent div for crop-image canvas element not found');
          }
          this.initCropper(canvas);
        });
    }

    img.src = imgUrl;
  };

  resizeImg = (img: HTMLImageElement) => {
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
  }

  saveCroppedImage = () => {
    if (this._cropper) {
      const dataUrl = this._cropper.getCroppedCanvas().toDataURL();
      sendToElm({ action: 'ImageSaved', payload: dataUrl });
    } else {
      console.warn('instance of cropper not found');
    }
  };
}

window.customElements.define('custom-cropper', CustomCropper);
