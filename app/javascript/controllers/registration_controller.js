import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="registration"
export default class extends Controller {
  // We define 'targets' to easily access elements inside our controller
  static targets = ["submitButton"]

  connect() {
    // This runs when the controller is connected to the DOM
    console.log("Registration controller connected!")
  }

  // This method will be called when the form is submitted
  disable(event) {
    // 'event' is the submit event. We don't need to stop it, let the form submit.

    // Change the button text
    this.submitButtonTarget.innerText = "Joining..."

    // Disable the button to prevent double clicks
    this.submitButtonTarget.setAttribute("disabled", "")
  }
}
