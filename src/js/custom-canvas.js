class CustomCanvas extends HTMLElement {
  constructor() {
    const self = super();
    self._canvas = null;
    self._ctx = null;
    self._cf = null; // cf = canvas fabric instance
    self._options = {
      strokeWidth: 3,
    };
    return self;
  }
  connectedCallback() {
    const canvas = document.createElement('canvas');
    canvas.id = 'cus';
    canvas.width = 512;
    canvas.height = 512;

    this._canvas = canvas;
    this._ctx = canvas.getContext('2d');
    this.appendChild(canvas);

    this.initFabric();

    this.addEventListener('draw-image', this.drawImage, false);
  }

  initFabric() {
    this._cf = new fabric.Canvas('cus');
  }

  drawFabricImage(imgUrl) {
    fabric.Image.fromURL(imgUrl, oImg => {
      this._cf.add(oImg);
    });
  }

  drawImage(e) {
    console.log('drawImage', e);
    const imgUrl = `data:image/png;base64, ${e.detail.base64path}`;
    const img = new Image();
    img.crossOrigin = 'Anonymous';

    img.onload = () => {
      const base64image = this.prepareImageForFabric(img);
      this.drawFabricImage(base64image);
    };

    // remove.bg - uncomment for usage
    img.src = imgUrl;
    // img.src = 'https://i.imgur.com/KetXuTZ.png';
  }

  clearCanvas() {
    this._ctx.clearRect(0, 0, this._ctx.canvas.width, this._ctx.canvas.height);
    this._ctx.beginPath();
  }

  prepareImageForFabric(img) {
    const { width, height } = img;
    console.log(img.width, img.height);

    const tempCanvas = document.createElement('canvas');
    tempCanvas.id = 'temp-cus';
    tempCanvas.width = width + 20;
    tempCanvas.height = height + 20;

    const ctx = tempCanvas.getContext('2d');
    tempCanvas.style.display = 'none';
    document.body.appendChild(tempCanvas);

    const strokeWidth = this._options.strokeWidth;

    ctx.shadowColor = '#fff';
    ctx.shadowBlur = strokeWidth;
    ctx.shadowOffsetX = 0;
    ctx.shadowOffsetY = 0;
    ctx.drawImage(img, 10, 10, img.width, img.height);

    // get contents of blurry bordered image
    const imgData = ctx.getImageData(
      0,
      0,
      ctx.canvas.width - 1,
      ctx.canvas.height - 1
    );

    const opaqueAlpha = 255;

    // turn all non-transparent pixels to full opacity
    for (let i = imgData.data.length; i > 0; i -= 4) {
      if (imgData.data[i + 3] > 0) {
        imgData.data[i + 3] = opaqueAlpha;
      }
    }

    // write transformed opaque pixels back to image
    ctx.putImageData(imgData, 0, 0);
    ctx.shadowColor = '#aaa';
    ctx.shadowBlur = strokeWidth;
    ctx.shadowOffsetX = 0;
    ctx.shadowOffsetY = 0;
    ctx.drawImage(tempCanvas, 0, 0);

    const base64image = tempCanvas.toDataURL();
    document.body.removeChild(tempCanvas);
    return base64image;
  }
}

// https://github.com/github/image-crop-element/blob/master/index.js#L245
if (!window.customElements.get('custom-canvas')) {
  window.CustomCanvas = CustomCanvas;
  window.customElements.define('custom-canvas', CustomCanvas);
}
