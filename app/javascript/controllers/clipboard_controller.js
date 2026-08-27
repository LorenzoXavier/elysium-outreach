import { Controller } from "@hotwired/stimulus"

// Generic "copy this text to the clipboard" button. Works against either a
// form field (reads .value) or plain text content (reads .textContent).
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    const text = "value" in this.sourceTarget ? this.sourceTarget.value : this.sourceTarget.textContent

    try {
      await navigator.clipboard.writeText(text.trim())
      this.flash("Copied!")
    } catch {
      this.flash("Copy failed")
    }
  }

  flash(message) {
    if (!this.hasButtonTarget) return

    const original = this.buttonTarget.textContent
    this.buttonTarget.textContent = message
    setTimeout(() => { this.buttonTarget.textContent = original }, 1500)
  }
}
