import { Controller } from "@hotwired/stimulus"

// A <select> whose options are full URLs -- navigates to whichever is chosen.
// Used for the "jump to page" pagination selector.
export default class extends Controller {
  go(event) {
    Turbo.visit(event.target.value)
  }
}
