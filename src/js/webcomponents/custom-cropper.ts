import Cropper from 'cropperjs';
import { CustomWindow } from '../../custom.window';
import { saveImageBase64 } from '../storage';
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
    this.loadImage(imgUrl, this.initCropper);
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

  loadImage = (imgUrl: string, cb: (img: HTMLCanvasElement) => void) => {
    const img = new Image();

    img.onload = () => {
      this.resizeImg(img)
        .then((canvas: HTMLCanvasElement) => {
          if (this._wrapperDiv) {

            /**
             * TODO: double check this.
             * we need this style, according to cropper.js documentation
             * https://github.com/fengyuanchen/cropperjs#usage
             */
            canvas.id = 'cropper-image';

            this._wrapperDiv.appendChild(canvas);
          } else {
            console.warn('parent div for crop-image canvas element not found');
          }
          cb(canvas);
        });
    }

    img.src = imgUrl;
  };

  resizeImg = (img: HTMLImageElement) => {
    // TODO: make canvas with propper width/heght + exif info (not rotated)

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    ctx!.drawImage(img, 0, 0, img.width, img.height);

    const from = img;
    const to = canvas;

    return pica().resize(from, to, {
      unsharpAmount: 80,
      unsharpRadius: 0.6,
      unsharpThreshold: 2
    });
  }

  saveCroppedImage = () => {
    if (this._cropper) {
      const dataUrl = this._cropper.getCroppedCanvas().toDataURL();
      const img = new Image();
      img.onload = () => {
        console.log(img.width, img.height)
      }
      img.src = dataUrl;

      // TODO: why save in storage? Try send to Elm in payload and use it in next event
      saveImageBase64(dataUrl);
      sendToElm({ action: 'ImageSaved', payload: null });
    } else {
      console.warn('instance of cropper not found');
    }
  };
}

window.customElements.define('custom-cropper', CustomCropper);
