const testImg =
  'iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAARUlEQVR42u3PMREAAAgEoLd/AtNqBlcPGlDJdB4oEREREREREREREREREREREREREREREREREREREREREREREREREZGLBddNT+MQpgCuAAAAAElFTkSuQmCC';

class CustomCropper extends HTMLElement {
  constructor() {
    const self = super();
    self._cropper = null;
    self._wrapperDiv = null;
    self._imageData = null;
    return self;
  }
  connectedCallback() {
    const div = document.createElement('div');
    div.id = 'img-wrapper';
    this._wrapperDiv = div;

    this.appendChild(this._wrapperDiv);
    this.addEventListener('crop-image-init', this.initImage, false);
    this.addEventListener('save-cropped-image', this.saveCroppedImage, false);
  }

  initImage = e => {
    const imgUrl = e.detail.imgUrl;
    this.loadImage(imgUrl, this.initCropper);
    // this.initCropper();
  };

  initCropper = () => {
    // https://github.com/fengyuanchen/cropperjs#options
    const image = document.getElementById('cropper-image');
    const self = this;

    const cropper = new Cropper(image, {
      crop(event) {
        // coordinates & more
      },
      ready() {
        self._cropper = cropper;
      },
    });
  };

  loadImage = (imgUrl, cb) => {
    const img = new Image();
    img.id = 'cropper-image';
    img.onload = cb;
    this._wrapperDiv.appendChild(img);

    img.src = imgUrl;
  };

  saveCroppedImage = () => {
    const dataUrl = this._cropper.getCroppedCanvas().toDataURL();
    // TODO: make image optimised small
    // it's not worth to keep big for 512px sticker
    sessionStorage.setItem('cutcut.img', dataUrl);
    window.elmApp.ports.modeChosen.send('1');
  };
}

window.customElements.define('custom-cropper', CustomCropper);
