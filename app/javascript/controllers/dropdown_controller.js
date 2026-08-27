import { Controller } from "@hotwired/stimulus"

// Generic click-to-toggle dropdown menu that closes when clicking outside it.
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundOutsideClick = this.outsideClick.bind(this)
    document.addEventListener("click", this.boundOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOutsideClick)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  hide() {
    this.menuTarget.classList.add("hidden")
  }

  outsideClick(event) {
    if (!this.element.contains(event.target)) this.hide()
  }
}
