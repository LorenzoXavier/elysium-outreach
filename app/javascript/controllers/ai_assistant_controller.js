import { Controller } from "@hotwired/stimulus"

// Wires the "AI Assistant" drawer used on email template and email composer
// forms. The AI's suggestion is rendered read-only by a Turbo Stream response
// (see EmailTemplatesController#ai_draft) and never touches the real
// subject/body fields on its own -- only these explicit "Use this ..."
// button clicks copy it across.
export default class extends Controller {
  static targets = [
    "subjectField", "bodyField",
    "contextSubject", "contextBody",
    "suggestedSubject", "suggestedBody"
  ]

  // Copies the live subject/body draft into the AI-assist form's hidden
  // fields right before it submits, so Gemini gets the current context.
  syncContext() {
    if (this.hasContextSubjectTarget && this.hasSubjectFieldTarget) {
      this.contextSubjectTarget.value = this.subjectFieldTarget.value
    }
    if (this.hasContextBodyTarget && this.hasBodyFieldTarget) {
      this.contextBodyTarget.value = this.bodyFieldTarget.value
    }
  }

  applySubject() {
    this.subjectFieldTarget.value = this.suggestedSubjectTarget.textContent.trim()
  }

  applyBody() {
    this.bodyFieldTarget.value = this.suggestedBodyTarget.textContent.trim()
  }

  applyBoth() {
    this.applySubject()
    this.applyBody()
  }
}
