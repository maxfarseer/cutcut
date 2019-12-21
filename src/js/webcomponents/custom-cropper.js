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
    console.log('connect custom-cropper');
    const div = document.createElement('div');
    div.id = 'img-wrapper';
    this._wrapperDiv = div;

    this.appendChild(this._wrapperDiv);

    this.addEventListener('crop-image-init', this.initImage, false);
    this.addEventListener(
      'prepare-for-erase',
      this.fakeSendImageToRemoveBg,
      // this.sendImageToRemoveBg,
      false
    );
    this.addEventListener(
      'request-cropped-data',
      this.requestCroppedData,
      false
    );
  }

  disconnectedCallback() {
    console.log('disconnectedCallback');
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

  fakeSendImageToRemoveBg = () => {
    const dataUrl = sessionStorage.getItem('cutcut.img');
    const img = new Image();
    img.crossOrigin = 'Anonymous';

    img.onload = () => {
      this.initEraseCanvas(img);
    };

    //img.src = `data:image/png;base64, ${testImg}`;
    img.src = dataUrl;
  };

  sendImageToRemoveBg = () => {
    // https://github.com/fengyuanchen/cropperjs#getcroppedcanvasoptions
    this._cropper.getCroppedCanvas().toBlob(blob => {
      const formData = new FormData();
      formData.append('image_file', blob);

      // show preloader;

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

        const img = new Image();
        img.crossOrigin = 'Anonymous';

        img.onload = () => {
          this.initEraseCanvas(img);
        };
        img.src = imgUrl;
      });
    });
  };

  saveCroppedDataToStore = () => {
    customCropper._cropper.getCroppedCanvas().toDataURL(dataUrl => {
      console.log(dataUrl.length);
      sessionStorage.setItem('cutcut.img', dataUrl);
    });
  };

  requestCroppedData = () => {
    const eraseCanvas = document.getElementById('erase-canvas');
    const imageBase64 = eraseCanvas.toDataURL();

    const event = new CustomEvent('recieved-cropped-data', {
      bubbles: true,
      cancelable: true,
      detail: imageBase64,
    });

    // TODO: is it possible to not use it here?
    // Now cropper has a knowledge (or not?) about custom-canvas
    const customCanvas = document.getElementsByTagName('custom-canvas')[0];
    customCanvas.dispatchEvent(event);
  };
}

window.customElements.define('custom-cropper', CustomCropper);
