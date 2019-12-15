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

  getCroppedData = () => {
    return this._cropper.getCroppedCanvas().toDataURL();
  };

  fakeSendImageToRemoveBg = () => {
    this.destroyCropper();

    const img = new Image();
    img.crossOrigin = 'Anonymous';

    img.onload = () => {
      this.initEraseCanvas(img);
    };

    img.src = `data:image/png;base64, ${testImg}`;
  };

  sendImageToRemoveBg = () => {
    // https://github.com/fengyuanchen/cropperjs#getcroppedcanvasoptions
    this._cropper.getCroppedCanvas().toBlob(blob => {
      const formData = new FormData();
      formData.append('image_file', blob);

      this.destroyCropper();

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

  destroyCropper = () => {
    this._cropper.destroy();
    this._cropper = null;
    this._wrapperDiv.removeChild(document.getElementById('cropper-image'));
  };

  initEraseCanvas = imgNode => {
    const { width, height } = imgNode;
    const canvas = document.createElement('canvas');
    canvas.id = 'erase-canvas';
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    ctx.drawImage(imgNode, 0, 0);

    this._wrapperDiv.appendChild(canvas);
    this.initEraseTool(canvas);
  };

  initEraseTool = canvas => {
    let isPress = false;
    let old = null;

    const ctx = canvas.getContext('2d');

    canvas.addEventListener('mousedown', function(e) {
      isPress = true;
      old = { x: e.offsetX, y: e.offsetY };
    });
    canvas.addEventListener('mousemove', function(e) {
      if (isPress) {
        let x = e.offsetX;
        let y = e.offsetY;
        ctx.globalCompositeOperation = 'destination-out';

        ctx.beginPath();
        ctx.arc(x, y, 10, 0, 2 * Math.PI);
        ctx.fill();

        ctx.lineWidth = 20;
        ctx.beginPath();
        ctx.moveTo(old.x, old.y);
        ctx.lineTo(x, y);
        ctx.stroke();

        old = { x: x, y: y };
      }
    });
    canvas.addEventListener('mouseup', function(e) {
      isPress = false;
    });
  };

  requestCroppedData = () => {
    const eraseCanvas = document.getElementById('erase-canvas');
    const imageBase64 = eraseCanvas.toDataURL();

    const event = new CustomEvent('recieved-cropped-data', {
      bubbles: true,
      cancelable: true,
      composed: true, // https://developers.google.com/web/fundamentals/web-components/shadowdom#customevents
      detail: imageBase64,
    });

    // TODO: is it possible to not use it here?
    // Now cropper has a knowledge (or not?) about custom-canvas
    const customCanvas = document.getElementsByTagName('custom-canvas')[0];
    customCanvas.dispatchEvent(event);
  };
}

if (!window.customElements.get('custom-cropper')) {
  window.CustomCropper = CustomCropper;
  window.customElements.define('custom-cropper', CustomCropper);
}
