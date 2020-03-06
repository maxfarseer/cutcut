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
    // TODO: make canvas with propper width/heght + exif info (not rotated)
    const expected = 1024;
    const { width, height } = img;

    const newHeight = height / width * expected;

    const canvas = document.createElement('canvas');
    canvas.style.width = expected + 'px';
    canvas.style.height = newHeight + 'px';
    const ctx = canvas.getContext('2d');
    ctx!.drawImage(img, 0, 0, expected, newHeight);

    document.body.appendChild(canvas);

    const from = img;
    const to = canvas;

    return window.pica().resize(from, to, {
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
