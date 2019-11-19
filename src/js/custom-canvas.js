class CustomCanvas extends HTMLElement {
  constructor() {
    const self = super();
    self._canvas = null;
    self._ctx = null;
    self._cf = null; // cf = canvas fabric instance
    self._image = null;
    self._options = {
      strokeWidth: 3,
    };
    return self;
  }
  connectedCallback() {
    const canvas = document.createElement('canvas');
    canvas.id = 'cus';
    canvas.width = 298;
    canvas.height = 298;

    this._canvas = canvas;
    this._ctx = canvas.getContext('2d');
    this.appendChild(canvas);

    // this.initFabric();

    this.addEventListener('draw-square', this.drawImage, false);
  }

  initFabric() {
    this._cf = new fabric.Canvas('cus');
  }

  drawFabricImage(imgUrl) {
    // const url = `data:image/png;base64, ${base64path}`;
    const url = imgUrl;

    fabric.Image.fromURL(url, oImg => {
      this._cf.add(oImg);
    });
  }

  drawImage(e) {
    const imgUrl = e.detail;
    const img = new Image();
    img.crossOrigin = 'Anonymous';
    img.width = 120;
    img.height = 100;

    img.onload = () => {
      const strokeWidth = this._options.strokeWidth;

      this._ctx.shadowColor = '#fff';
      this._ctx.shadowBlur = strokeWidth;
      this._ctx.shadowOffsetX = 0;
      this._ctx.shadowOffsetY = 0;
      this._ctx.drawImage(img, 30, 30, img.width, img.height);

      // get contents of blurry bordered image
      const imgData = this._ctx.getImageData(
        0,
        0,
        this._ctx.canvas.width - 1,
        this._ctx.canvas.height - 1
      );

      const opaqueAlpha = 255;

      // turn all non-transparent pixels to full opacity
      for (let i = imgData.data.length; i > 0; i -= 4) {
        if (imgData.data[i + 3] > 0) {
          imgData.data[i + 3] = opaqueAlpha;
        }
      }

      // write transformed opaque pixels back to image
      this._ctx.putImageData(imgData, 0, 0);

      this._ctx.shadowColor = '#aaa';
      this._ctx.shadowBlur = strokeWidth;
      this._ctx.shadowOffsetX = 0;
      this._ctx.shadowOffsetY = 0;
      this._ctx.drawImage(this._canvas, 0, 0);

      this._image = this._canvas.toDataURL();

      this.clearCanvas();
      this.initFabric();
      this.drawFabricImage(this._image);
    };
    img.src =
      'https://github.githubassets.com/images/modules/logos_page/Octocat.png';
    // img.src =
    //   'https://cdn.glitch.com/4c9ebeb9-8b9a-4adc-ad0a-238d9ae00bb5%2Fmdn_logo-only_color.svg?1535749917189';
  }

  clearCanvas() {
    this._ctx.clearRect(0, 0, this._ctx.canvas.width, this._ctx.canvas.height);
    this._ctx.beginPath();
  }
}

// https://github.com/github/image-crop-element/blob/master/index.js#L245
if (!window.customElements.get('custom-canvas')) {
  window.CustomCanvas = CustomCanvas;
  window.customElements.define('custom-canvas', CustomCanvas);
}
