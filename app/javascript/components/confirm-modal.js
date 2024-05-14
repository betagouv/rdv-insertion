import { Modal } from "bootstrap";

class ConfirmModal {
  constructor() {
    this.modalPartial = document.querySelector("#confirm-modal");
    window.Turbo.setConfirmMethod(this.confirm.bind(this));
  }

  confirm(message, triggerElement) {
    const modalContent = this.modalPartial.cloneNode(true);
    const sourceLink = this.getSourceLinkFrom(message, triggerElement)

    if (sourceLink.getAttribute("data-turbo-confirm-template")) {
      modalContent.querySelector(".modal-content").innerHTML = sourceLink.getAttribute("data-turbo-confirm-template");
    } else {
      modalContent.querySelector(".modal-title").textContent = message;
      modalContent.querySelector("#custom-body").innerHTML = sourceLink.getAttribute("data-turbo-confirm-text-content") || message;
      modalContent.querySelector("#confirm-button").innerHTML = sourceLink.getAttribute("data-turbo-confirm-text-action") || "Confirmer";
    }

    this.modal = new Modal(modalContent);
    this.modal.show();

    return new Promise((resolve) => {
      modalContent.querySelector("#confirm-button").addEventListener("click", () => {
        resolve(true);
      });
    });
  }

  getSourceLinkFrom(message, triggerElement) {
    if (triggerElement.tagName !== "FORM") return triggerElement;
    
    // When using Turbo, trigger can be a form autogenerated, not the source link 
    // If it is the case we try to find the source link to get the list of data attributes
    const formData = new FormData(triggerElement);
    const serializedParams = new URLSearchParams(formData).toString();
    let pathName = new URL(triggerElement.getAttribute("action")).pathname
    
    if (serializedParams.length > 0) pathName += `?${serializedParams}`;

    return document.querySelector(`a[href="${pathName}"][data-turbo-confirm="${message}"]`);
  }
}

export default ConfirmModal;