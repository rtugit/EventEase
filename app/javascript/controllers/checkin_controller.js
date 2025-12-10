import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="checkin"
export default class extends Controller {
  static targets = ["button"]

  connect() {
    console.log("Check-in controller connected")
  }

  confirm(event) {
    // Optional: Add a confirmation dialog
    if (!confirm("Are you sure you want to check in this attendee?")) {
      event.preventDefault()
      return
    }

    // Change button state to indicate loading
    this.buttonTarget.innerText = "Checking in..."
    this.buttonTarget.setAttribute("disabled", "")
    
    // The form submission continues automatically via Turbo/Rails ujs
  }
}
