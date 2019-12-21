class CustomEraser extends HTMLElement {

  connectedCallback() {
    console.log('custom-eraser connected');
    const div = document.createElement('div');
    const canvas = document.createElement('canvas');

    div.appendChild(canvas);
    this.appendChild(div);

    let emptyImg = new Image();
    this.initEraseCanvas(emptyImg);
  }

  initEraseCanvas = (imgNode: HTMLImageElement) => {
    const { width, height } = imgNode;
    const canvas = document.createElement('canvas');
    canvas.id = 'erase-canvas';
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');

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
}

window.customElements.define('custom-eraser', CustomEraser);
