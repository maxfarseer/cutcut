class CustomCanvas extends HTMLElement {
  constructor() {
    const self = super();
    self._canvas = null;
    self._ctx = null;
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

    this.addEventListener('draw-square', e => {
      console.log('listen');
      this.drawRedSquare();
    });
  }

  drawRedSquare() {
    this._ctx.fillStyle = '#FF0000';
    this._ctx.fillRect(20, 20, 150, 75);
  }
}

// https://github.com/github/image-crop-element/blob/master/index.js#L245
if (!window.customElements.get('custom-canvas')) {
  window.CustomCanvas = CustomCanvas;
  window.customElements.define('custom-canvas', CustomCanvas);
}
