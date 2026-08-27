import { Controller } from "@hotwired/stimulus"

// Replaces Turbo's default window.confirm() with this app's styled <dialog>.
// Any element with data-turbo-confirm="..." (links, buttons, form submits)
// automatically uses this instead -- no extra wiring needed per-element.
export default class extends Controller {
  static targets = ["message"]

  connect() {
    Turbo.setConfirmMethod((message) => {
      this.messageTarget.textContent = message
      this.element.showModal()

      return new Promise((resolve) => {
        this.element.addEventListener(
          "close",
          () => resolve(this.element.returnValue === "confirm"),
          { once: true }
        )
      })
    })
  }
}
