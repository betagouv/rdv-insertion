import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  clear() {
    this.element.querySelector("input[type=\"text\"]").value = "";
  }
}
