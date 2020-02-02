import { fabric } from 'fabric'

type CustomCanvasOptions = {
  strokeWidth: number;
}

class CustomCanvas extends HTMLElement {
  private _canvas: HTMLCanvasElement | null;
  private _ctx: CanvasRenderingContext2D | null;
  private _cf: any;
  private _options: CustomCanvasOptions;

  constructor() {
    super();
    this._canvas = null;
    this._ctx = null;
    this._cf = null; // cf = canvas fabric instance
    this._options = {
      strokeWidth: 3,
    };
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
    this.addEventListener('recieved-cropped-data', this.drawImage, false);
    this.addEventListener('download-sticker', this.downloadSticker, false);
  }

  initFabric() {
    this._cf = new fabric.Canvas('cus');
  }

  drawFabricImage(imgUrl: string) {
    // TODO: oImg is fabric object img
    fabric.Image.fromURL(imgUrl, (oImg: any) => {
      this._cf.add(oImg);
    });
  }

  drawImage(e: Event) {
    const imgUrl = (e as CustomEvent).detail;
    const img = new Image();
    img.crossOrigin = 'Anonymous';

    img.onload = () => {
      const base64image = this.addStroke(img);
      this.drawFabricImage(base64image);
    };

    img.src = imgUrl;
  }

  // not used
  clearCanvas(ctx: CanvasRenderingContext2D) {
    ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    ctx.beginPath();
  }

  addStroke(img: HTMLImageElement) {
    const { width, height } = img;

    const tempCanvas = document.createElement('canvas');
    tempCanvas.id = 'temp-cus';
    tempCanvas.width = width + 20;
    tempCanvas.height = height + 20;

    const ctx = tempCanvas.getContext('2d')!;
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

  downloadSticker = () => {
    if (this._canvas) {
      /* https://stackoverflow.com/a/44487883/1916578 */
      const link = document.createElement('a');
      link.setAttribute('download', 'cutcut-sticker.png');
      link.setAttribute('href', this._canvas.toDataURL("image/png").replace("image/png", "image/octet-stream"));
      link.click();
    } else {
      console.warn('this._canvas not exist, check CustomCanvas component');
    }
  }
}

window.customElements.define('custom-canvas', CustomCanvas);
