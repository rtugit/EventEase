import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="category-dropdown"
export default class extends Controller {
  static targets = ["menu", "button"]

  toggle() {
    this.menuTarget.classList.toggle("active")
    this.buttonTarget.classList.toggle("active")
  }

  close() {
    this.menuTarget.classList.remove("active")
    this.buttonTarget.classList.remove("active")
  }

  closeOnOutsideClick(event) {
    // Close dropdown if clicking outside
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  connect() {
    // Close dropdown when clicking outside
    this.boundCloseOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.boundCloseOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnOutsideClick)
  }
}

