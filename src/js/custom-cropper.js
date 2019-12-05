class CustomCropper extends HTMLElement {
  constructor() {
    const self = super();
    return self;
  }
  connectedCallback() {
    console.log('cropper connected');
  }
}

if (!window.customElements.get('custom-cropper')) {
  window.CustomCropper = CustomCropper;
  window.customElements.define('custom-cropper', CustomCropper);
}
