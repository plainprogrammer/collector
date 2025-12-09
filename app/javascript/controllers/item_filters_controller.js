import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "panel", "toggleButton", "activeCount"]
  static values = {
    expanded: { type: Boolean, default: false }
  }

  connect() {
    this.updateActiveFiltersDisplay()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    this.panelTarget.classList.toggle("hidden", !this.expandedValue)

    // Update aria-expanded
    if (this.hasToggleButtonTarget) {
      this.toggleButtonTarget.setAttribute("aria-expanded", this.expandedValue)
    }
  }

  filter() {
    // Auto-submit on change
    this.formTarget.requestSubmit()
  }

  clearAll(event) {
    event.preventDefault()

    // Clear all select elements
    this.formTarget.querySelectorAll("select").forEach(select => {
      select.value = ""
    })

    // Reset sort to default
    const sortSelect = this.formTarget.querySelector("select[name='sort']")
    if (sortSelect) {
      sortSelect.value = "date_desc"
    }

    this.formTarget.requestSubmit()
  }

  updateActiveFiltersDisplay() {
    if (!this.hasActiveCountTarget) return

    // Count non-empty selects (excluding sort)
    let active = 0
    this.formTarget.querySelectorAll("select").forEach(select => {
      if (select.name !== "sort" && select.value) active++
    })

    if (active > 0) {
      this.activeCountTarget.textContent = `(${active})`
      this.activeCountTarget.classList.remove("hidden")
    } else {
      this.activeCountTarget.classList.add("hidden")
    }
  }
}
