import { Controller } from "@hotwired/stimulus"

// Handles expandable/collapsible sections like nested storage units
export default class extends Controller {
  static targets = ["content", "button", "icon"]
  static values = {
    open: { type: Boolean, default: false }
  }

  connect() {
    this.updateState()
  }

  toggle() {
    this.openValue = !this.openValue
    this.updateState()
  }

  updateState() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle("hidden", !this.openValue)
    }

    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", this.openValue)
    }

    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("rotate-90", this.openValue)
    }
  }
}
