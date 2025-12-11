import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rundown-collapse"
export default class extends Controller {
  static targets = ["item", "header", "content", "arrow"]

  connect() {
    console.log("Rundown collapse controller connected!")
    // Initialize all items as collapsed
    this.contentTargets.forEach((content, index) => {
      content.setAttribute("aria-hidden", "true")
      this.headerTargets[index].setAttribute("aria-expanded", "false")
    })
  }

  toggle(event) {
    const clickedHeader = event.currentTarget
    const item = clickedHeader.closest("[data-rundown-collapse-target='item']")
    const content = item.querySelector("[data-rundown-collapse-target='content']")
    const arrow = clickedHeader.querySelector("[data-rundown-collapse-target='arrow']")
    
    const isExpanded = clickedHeader.getAttribute("aria-expanded") === "true"
    
    if (isExpanded) {
      // Collapse
      clickedHeader.setAttribute("aria-expanded", "false")
      content.setAttribute("aria-hidden", "true")
    } else {
      // Expand
      clickedHeader.setAttribute("aria-expanded", "true")
      content.setAttribute("aria-hidden", "false")
    }
  }
}

