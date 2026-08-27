import { Controller } from "@hotwired/stimulus"

// Drives the contact email composer: picking a template prefills the visible
// subject/body fields directly (unlike the AI assistant's suggest-then-apply
// flow -- the requirement here is a direct pre-fill), and the datetime-local
// "Deliver at" input is converted to a real UTC ISO timestamp before submit
// so scheduling is correct regardless of the app server's time zone.
export default class extends Controller {
  static targets = [
    "templateSelect", "templateId", "subjectField", "bodyField",
    "localScheduledAt", "scheduledAt"
  ]

  applyTemplate() {
    const option = this.templateSelectTarget.selectedOptions[0]

    this.templateIdTarget.value = option?.value || ""
    if (!option || !option.value) return

    this.subjectFieldTarget.value = option.dataset.subject || ""
    this.bodyFieldTarget.value = option.dataset.body || ""
  }

  syncScheduledAt() {
    if (!this.localScheduledAtTarget.value) {
      this.scheduledAtTarget.value = ""
      return
    }

    this.scheduledAtTarget.value = new Date(this.localScheduledAtTarget.value).toISOString()
  }
}
