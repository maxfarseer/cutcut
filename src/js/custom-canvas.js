class CustomCanvas extends HTMLElement {
  connectedCallback() {
    const canvas = document.createElement('canvas');
    this.appendChild(canvas);
  }
}

window.customElements.define('custom-canvas', CustomCanvas);