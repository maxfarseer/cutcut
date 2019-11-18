class CustomCanvas extends HTMLElement {
  constructor() {
    const self = super();
    self._canvas = null;
    self._ctx = null;
    self._cf = null; // cf = canvas fabric instance
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

    this.addEventListener('draw-square', e => {
      console.log(e.detail);
      this.drawImage(e.detail);
    });
  }

  initFabric() {
    this._cf = new fabric.Canvas('cus');
  }

  /* drawImage(imgUrl) {
    // const url = `data:image/png;base64, ${base64path}`;
    const url = imgUrl;

    fabric.Image.fromURL(url, oImg => {
      oImg.set({
        stroke: 'rgba(34,177,76,1)',
        strokeWidth: 5,
      });
      this._cf.add(oImg);
    });
  } */

  drawImage(imgUrl) {
    const img = new Image();
    img.crossOrigin = 'Anonymous';

    img.onload = () => {
      this._ctx.shadowColor = '#fff'; // green for demo purposes
      this._ctx.shadowBlur = 5;
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
      this._ctx.shadowBlur = 10;
      this._ctx.shadowOffsetX = 0;
      this._ctx.shadowOffsetY = 0;
      this._ctx.drawImage(this._canvas, 0, 0);
    };

    img.src = 'https://file.io/ecHGkF';
    // img.src =
    //   'https://cdn.glitch.com/4c9ebeb9-8b9a-4adc-ad0a-238d9ae00bb5%2Fmdn_logo-only_color.svg?1535749917189';
  }
}

// https://github.com/github/image-crop-element/blob/master/index.js#L245
if (!window.customElements.get('custom-canvas')) {
  window.CustomCanvas = CustomCanvas;
  window.customElements.define('custom-canvas', CustomCanvas);
}
