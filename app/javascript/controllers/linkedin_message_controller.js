import { Controller } from "@hotwired/stimulus"

// Drives the "Draft LinkedIn Message" modal. The AI suggestion (rendered by
// a Turbo Stream response into the preview area) never touches the editable
// message textarea on its own -- only this explicit "Apply Suggestion"
// click copies it across, matching the same suggest-then-apply pattern used
// by the Email Templates AI assistant.
export default class extends Controller {
  static targets = ["prompt", "message", "suggestion"]

  apply() {
    this.messageTarget.value = this.suggestionTarget.textContent.trim()
  }

  // Cancel / ✕: empties the modal frame directly in the browser, no server
  // round-trip. Closing used to work by navigating the frame to the show
  // page just to extract its (empty) placeholder frame from the response --
  // that depended on Turbo finding exactly one matching #modal frame in a
  // full-layout response, which is fragile and could surface as Turbo's own
  // "Content missing" placeholder text. This can't fail the same way.
  close() {
    document.getElementById("modal").innerHTML = ""
  }
}
