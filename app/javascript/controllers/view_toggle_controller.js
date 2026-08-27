import { Controller } from "@hotwired/stimulus"

// Toggles the "Needs Action" list between card and table layouts, remembering
// the choice per-browser. Both layouts stay in the DOM at all times (so
// switching is instant) but only the visible one's checkboxes are enabled --
// the hidden layout's checkboxes are disabled so they don't also submit.
export default class extends Controller {
  static targets = ["cardView", "tableView", "cardButton", "tableButton"]
  static values = { storageKey: { type: String, default: "outreach:contact-list-view" } }

  static ACTIVE_CLASSES = ["bg-slate-900", "text-white"]
  static INACTIVE_CLASSES = ["text-slate-600", "hover:bg-slate-50"]

  connect() {
    this.show(this.storedMode() === "table" ? "table" : "cards")
  }

  showCards() {
    this.show("cards")
  }

  showTable() {
    this.show("table")
  }

  show(mode) {
    const isTable = mode === "table"

    this.tableViewTarget.classList.toggle("hidden", !isTable)
    this.cardViewTarget.classList.toggle("hidden", isTable)
    this.setDisabled(this.tableViewTarget, !isTable)
    this.setDisabled(this.cardViewTarget, isTable)

    this.style(this.cardButtonTarget, !isTable)
    this.style(this.tableButtonTarget, isTable)

    this.storeMode(mode)
  }

  setDisabled(container, disabled) {
    container.querySelectorAll("input[type=checkbox]").forEach((checkbox) => { checkbox.disabled = disabled })
  }

  style(button, active) {
    button.setAttribute("aria-pressed", String(active))
    this.constructor.ACTIVE_CLASSES.forEach((name) => button.classList.toggle(name, active))
    this.constructor.INACTIVE_CLASSES.forEach((name) => button.classList.toggle(name, !active))
  }

  storedMode() {
    try {
      return localStorage.getItem(this.storageKeyValue)
    } catch {
      return null
    }
  }

  storeMode(mode) {
    try {
      localStorage.setItem(this.storageKeyValue, mode)
    } catch {
      // ignore (private browsing, storage disabled, etc.)
    }
  }
}
