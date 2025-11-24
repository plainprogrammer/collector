import { Controller } from "@hotwired/stimulus"

// Storage unit form specific behavior
export default class extends Controller {
  static targets = ["typeSelect"]

  typeChanged() {
    // Future: Add dynamic behavior based on storage type selection
    // For example, showing/hiding certain fields based on type
  }
}
