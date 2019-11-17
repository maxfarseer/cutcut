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

    this.initFabric();

    this.addEventListener('draw-square', e => {
      console.log(e);
      this.drawImage(e.detail);
    });
  }

  initFabric() {
    this._cf = new fabric.Canvas('cus');
  }

  drawImage(base64path) {
    const url = `data:image/png;base64, ${base64path}`;

    fabric.Image.fromURL(url, oImg => {
      this._cf.add(oImg);
    });
  }
}

// https://github.com/github/image-crop-element/blob/master/index.js#L245
if (!window.customElements.get('custom-canvas')) {
  window.CustomCanvas = CustomCanvas;
  window.customElements.define('custom-canvas', CustomCanvas);
}
