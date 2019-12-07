class CustomCropper extends HTMLElement {
  constructor() {
    const self = super();
    self._div = null;
    self._cropper = null;
    return self;
  }
  connectedCallback() {
    const div = document.createElement('div');
    div.id = 'cropper-div';
    this._div = div;

    const img = document.createElement('img');
    img.id = 'cropper-image';

    const fragment = document.createDocumentFragment();
    fragment.appendChild(div);

    this.appendChild(fragment);

    this.addEventListener('crop-image-init', this.initImage, false);
  }

  initImage = e => {
    const imgUrl = e.detail.imgUrl;
    this.loadImage(imgUrl, this.initCropper);
    // this.initCropper();
  };

  initCropper = () => {
    // https://github.com/fengyuanchen/cropperjs#options
    const image = document.getElementById('cropper-image');

    const cropper = new Cropper(image, {
      aspectRatio: 16 / 9,
      crop(event) {
        console.log(event.detail.x);
        console.log(event.detail.y);
        console.log(event.detail.width);
        console.log(event.detail.height);
        console.log(event.detail.rotate);
        console.log(event.detail.scaleX);
        console.log(event.detail.scaleY);
      },
      ready() {
        console.log('ready to crop');
      },
    });

    this._cropper = cropper;
  };

  loadImage = (imgUrl, cb) => {
    const img = new Image();
    img.id = 'cropper-image';
    img.onload = cb;
    this._div.appendChild(img);

    img.src = imgUrl;
  };
}

if (!window.customElements.get('custom-cropper')) {
  window.CustomCropper = CustomCropper;
  window.customElements.define('custom-cropper', CustomCropper);
}
