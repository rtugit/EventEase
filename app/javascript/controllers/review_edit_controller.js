import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="review-edit"
export default class extends Controller {
  static targets = ["display", "editForm"]

  connect() {
    console.log("Review edit controller connected!")
  }

  showEdit(event) {
    event.preventDefault()
    this.displayTarget.style.display = "none"
    this.editFormTarget.style.display = "block"
  }

  hideEdit(event) {
    event.preventDefault()
    this.displayTarget.style.display = "block"
    this.editFormTarget.style.display = "none"
  }
}

