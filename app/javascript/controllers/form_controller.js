import { Controller } from "@hotwired/stimulus"

// General form utilities
export default class extends Controller {
  cancel(event) {
    event.preventDefault()

    // If this form is inside a turbo frame, clear the frame
    const turboFrame = this.element.closest("turbo-frame")
    if (turboFrame) {
      turboFrame.innerHTML = ""
    }
  }
}
