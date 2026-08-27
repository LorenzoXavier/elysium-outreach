import { Controller } from "@hotwired/stimulus"

// Keeps the hidden "publish" form's email_body in sync with the visible
// draft textarea, so either the "Save Draft" or "Publish / Send Email"
// button submits whatever is currently typed.
export default class extends Controller {
  static targets = ["source", "target"]

  connect() {
    this.sync()
  }

  sync() {
    this.targetTarget.value = this.sourceTarget.value
  }
}
