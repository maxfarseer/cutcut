import { fabric } from 'fabric'
import { sendToElm } from '../ports';

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

    this.addEventListener('recieved-cropped-data', this.drawImage, false);
    this.addEventListener('download-sticker', this.downloadSticker, false);
    this.addEventListener('request-upload-to-pack', this.requestUploadToPack, false);
  }

  initFabric() {
    this._cf = new fabric.Canvas('cus');
  }

  getDpr() {
    return window.devicePixelRatio || 1;
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
    try {
      if (!this._cf) {
        throw new Error('fabric instance does not exist');
      }
      this._cf.discardActiveObject();
      this._cf.requestRenderAll();

      window.requestAnimationFrame(() => {
        if (!this._canvas) {
          throw new Error('canvas node does not exist');
        }
        const dpr = this.getDpr();
        const dataUrl = this._canvas.toDataURL();
        const img = document.createElement('img');
        img.onload = () => {
          const WIDTH = img.width / dpr;
          const HEIGHT = img.height / dpr;

          img.width = WIDTH;
          img.height = HEIGHT;

          const tempCanvas = document.createElement('canvas');
          tempCanvas.width = WIDTH;
          tempCanvas.height = HEIGHT;
          const tempCanvasCtx = tempCanvas.getContext('2d');
          tempCanvasCtx!.drawImage(img, 0, 0, WIDTH, HEIGHT);

          /* https://stackoverflow.com/a/44487883/1916578 */
          const link = document.createElement('a');
          link.setAttribute('download', 'cutcut-sticker.png');
          link.setAttribute('href', tempCanvas.toDataURL("image/png").replace("image/png", "image/octet-stream"));
          link.click();
        }
        img.src = dataUrl;
      })
    } catch (err) {
      console.warn(err);
    }
  }

  requestUploadToPack = () => {
    try {
      // this doesn't work for process.env
      // const { TELEGRAM_BOT_TOKEN, TELEGRAM_BOT_ID } = process.env;
      if (!process.env.TELEGRAM_BOT_TOKEN || !process.env.TELEGRAM_BOT_ID) {
        throw new Error('Your forgot to set up environment variables. Please check your .env file. https://parceljs.org/env.html')
      }

      if (!this._cf) {
        throw new Error('fabric instance does not exist');
      }
      this._cf.discardActiveObject();
      this._cf.requestRenderAll();

      window.requestAnimationFrame(() => {
        if (!this._canvas) {
          throw new Error('this._canvas does not exist, check CustomCanvas component');
        }

        const dpr = this.getDpr();
        const dataUrl = this._canvas.toDataURL();
        const img = document.createElement('img');
        img.onload = () => {
          const WIDTH = img.width / dpr;
          const HEIGHT = img.height / dpr;

          img.width = WIDTH;
          img.height = HEIGHT;

          const tempCanvas = document.createElement('canvas');
          tempCanvas.width = WIDTH;
          tempCanvas.height = HEIGHT;
          const tempCanvasCtx = tempCanvas.getContext('2d');
          tempCanvasCtx!.drawImage(img, 0, 0, WIDTH, HEIGHT);

          this.uploadToStickerPack(tempCanvas, '💍')
        }
        img.src = dataUrl;
      })
    } catch (err) {
      console.warn(err);
    }
  }

  uploadToStickerPack(tempCanvas: HTMLCanvasElement, emoji: string) {
    tempCanvas.toBlob((blob) => {
      if (blob) {
        const formData = new FormData();
        formData.append('user_id', process.env.TELEGRAM_BOT_ID as string); // bot id here
        formData.append('name', 'firstpack_by_cutcutelm_bot');
        formData.append('png_sticker', blob);
        formData.append('emojis', emoji);

        const options = {
          method: 'POST',
          body: formData,
        };

        fetch(`https://api.telegram.org/bot${process.env.TELEGRAM_BOT_TOKEN as string}/addStickerToSet`, options)
          .then(r => r.json())
          .then(json => {
            if (json.ok) {
              sendToElm({ action: 'StickerUploadedSuccess', payload: null });
            } else {
              // TODO: error action + notification on elm side
              console.log('ERROR')
            }
          })
      } else {
        console.log('blob is null')
      }
    })
  }
}

window.customElements.define('custom-canvas', CustomCanvas);
