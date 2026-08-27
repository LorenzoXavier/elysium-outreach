import { Controller } from "@hotwired/stimulus"

// Drives the bulk-actions toolbar above a selectable contact list: syncing the
// "select all" checkbox with individual row checkboxes, enabling the ellipsis
// menu button only once at least one row is selected, and keeping the bulk
// action's confirm-dialog message in sync with how many are selected.
export default class extends Controller {
  static targets = ["checkbox", "selectAll", "menuButton", "submitButton"]

  connect() {
    this.refresh()
  }

  toggleAll() {
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = this.selectAllTarget.checked })
    this.refresh()
  }

  refresh() {
    const total = this.checkboxTargets.length
    const selected = this.checkboxTargets.filter((checkbox) => checkbox.checked).length

    if (this.hasMenuButtonTarget) {
      this.menuButtonTarget.disabled = selected === 0
    }

    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = total > 0 && selected === total
      this.selectAllTarget.indeterminate = selected > 0 && selected < total
    }

    if (this.hasSubmitButtonTarget) {
      const noun = selected === 1 ? "contact" : "contacts"
      this.submitButtonTarget.dataset.turboConfirm =
        `Mark ${selected} selected ${noun} as LinkedIn outreached? This records today's date and sets each one's email follow-up due in 1 week.`
    }
  }
}
