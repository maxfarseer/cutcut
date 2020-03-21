import { sendToElm } from "../ports";
import { IPrepareForEraseArgs } from "../ports/types";

const ERASE_CANVAS_ID = 'erase-canvas';
const ERASE_CANVAS_DIV_ID = 'erase-canvas-wrapper';

class CustomEraser extends HTMLElement {

  connectedCallback() {
    const div = document.createElement('div');
    div.id = ERASE_CANVAS_DIV_ID;

    this.appendChild(div);

    this.addEventListener(
      'prepare-for-erase',
      this.prepareForErase,
      false
    );

    this.addEventListener(
      'add-img-finish',
      this.addImgFinish,
      false
    );
  }

  initEraseCanvas = (imgNode: HTMLImageElement) => {
    const { width, height } = imgNode;
    const canvas = document.createElement('canvas');
    canvas.id = ERASE_CANVAS_ID;
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

    const wrapper = document.getElementById(ERASE_CANVAS_DIV_ID);

    if (wrapper) {
      wrapper.appendChild(canvas);
    } else {
      console.warn('canvas parent div not found, check CustomEraser')
    }

    if (ctx) {
      ctx.drawImage(imgNode, 0, 0);
      this.initEraseTool(canvas, ctx);
    } else {
      console.warn('canvas context doesn\'t exist, check CustomEraser')
    }
  };

  initEraseTool = (canvas: HTMLCanvasElement, ctx: CanvasRenderingContext2D) => {
    let isPress = false;
    let old: { x: number, y: number } | null = null;

    canvas.addEventListener('mousedown', function (e) {
      isPress = true;
      old = { x: e.offsetX, y: e.offsetY };
    });

    canvas.addEventListener('mousemove', function (e) {
      if (isPress) {
        let x = e.offsetX;
        let y = e.offsetY;
        ctx.globalCompositeOperation = 'destination-out';

        ctx.beginPath();
        ctx.arc(x, y, 10, 0, 2 * Math.PI);
        ctx.fill();

        ctx.lineWidth = 20;
        ctx.beginPath();
        ctx.moveTo(old!.x, old!.y);
        ctx.lineTo(x, y);
        ctx.stroke();

        old = { x: x, y: y };
      }
    });

    canvas.addEventListener('mouseup', function (e) {
      isPress = false;
    });
  };

  prepareForErase = (event: Event) => {
    // https://github.com/microsoft/TypeScript/issues/28357
    // https://stackoverflow.com/questions/47166369/argument-of-type-e-customevent-void-is-not-assignable-to-parameter-of-ty?rq=1
    const { removeBg, base64img }: IPrepareForEraseArgs = (event as CustomEvent).detail;

    if (removeBg) {
      this.sendImageToRemoveBg(base64img);
    } else {
      const img = new Image();
      img.crossOrigin = 'Anonymous';

      img.onload = () => {
        this.initEraseCanvas(img);
      };

      img.src = base64img;
    }
  };

  sendImageToRemoveBg = (imgBase64: string) => {
    const formData = new FormData();
    formData.append('image_file_b64', imgBase64);

    // show preloader;

    const headers = new Headers({
      Accept: 'application/json',
      'X-Api-Key': 'Ge5HqmTYvcD1UzadQ7MPVPVi',
    });

    // https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
    const requestOptions = {
      method: 'POST',
      headers,
      mode: <RequestMode>'cors',
      cache: <RequestCache>'default',
      body: formData,
    };

    const myRequest = new Request(
      'https://api.remove.bg/v1.0/removebg',
      requestOptions
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
  };

  addImgFinish = () => {
    const customEraser = document.getElementById(ERASE_CANVAS_ID);

    if (customEraser) {
      const imageBase64 = (customEraser as HTMLCanvasElement).toDataURL();

      const event = new CustomEvent('recieved-cropped-data', {
        bubbles: true,
        cancelable: true,
        detail: imageBase64,
      });

      // TODO: is it possible to not use it here?
      // Now cropper has a knowledge (or not?) about custom-canvas
      const customCanvas = document.getElementsByTagName('custom-canvas')[0];
      customCanvas.dispatchEvent(event);
      sendToElm({ action: 'ImageAddedToFabric', payload: null });
    }
  };
}

window.customElements.define('custom-eraser', CustomEraser);
