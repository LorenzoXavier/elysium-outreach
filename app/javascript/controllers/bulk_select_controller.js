import { Controller } from "@hotwired/stimulus"

// Drives the bulk-actions toolbar above a selectable contact list: syncing the
// "select all" checkbox with individual row checkboxes, enabling the ellipsis
// menu button only once at least one row is selected, keeping the bulk
// action's confirm-dialog message in sync with how many are selected, and
// mirroring checked state between the card and table views of the same
// contact (only one view's checkboxes are enabled/counted at a time -- see
// view_toggle_controller -- but both stay visually in sync).
export default class extends Controller {
  static targets = ["checkbox", "selectAll", "menuButton", "submitButton"]

  connect() {
    this.refresh()
  }

  // Fired when a single row checkbox changes: mirrors its checked state to
  // any other checkbox target for the same contact (i.e. its twin in the
  // other view), then refreshes the toolbar.
  sync(event) {
    const { contactId } = event.target.dataset
    const checked = event.target.checked

    this.checkboxTargets.forEach((checkbox) => {
      if (checkbox.dataset.contactId === contactId) checkbox.checked = checked
    })

    this.refresh()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = checked })
    this.refresh()
  }

  refresh() {
    const active = this.checkboxTargets.filter((checkbox) => !checkbox.disabled)
    const total = active.length
    const selected = active.filter((checkbox) => checkbox.checked).length

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
