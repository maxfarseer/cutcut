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
    this.addEventListener('request-cropped-data', this.getCroppedData, false);
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
        /* console.log(event.detail.x);
        console.log(event.detail.y);
        console.log(event.detail.width);
        console.log(event.detail.height);
        console.log(event.detail.rotate);
        console.log(event.detail.scaleX);
        console.log(event.detail.scaleY); */
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
    this._div.appendChild(img);

    img.src = imgUrl;
  };

  getCroppedData = () => {
    return this._cropper.getCroppedCanvas().toDataURL();
  };

  /* sendImageToRemoveBg = () => {
    // https://github.com/fengyuanchen/cropperjs#getcroppedcanvasoptions
    this._cropper.getCroppedCanvas().toBlob(blob => {
      const formData = new FormData();
      formData.append('image_file', blob);

      const myHeaders = new Headers({
        Accept: 'application/json',
        'X-Api-Key': 'Ge5HqmTYvcD1UzadQ7MPVPVi',
      });

      // https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
      const myInit = {
        method: 'POST',
        headers: myHeaders,
        mode: 'cors',
        cache: 'default',
        body: formData,
      };

      const myRequest = new Request(
        'https://api.remove.bg/v1.0/removebg',
        myInit
      );
      fetch(myRequest).then(async response => {
        const json = await response.json();
        const imgUrl = `data:image/png;base64, ${json.data.result_b64}`;
        const img = document.getElementById('after-remove');
        img.src = imgUrl;
      });
    });
  }; */
}

if (!window.customElements.get('custom-cropper')) {
  window.CustomCropper = CustomCropper;
  window.customElements.define('custom-cropper', CustomCropper);
}
