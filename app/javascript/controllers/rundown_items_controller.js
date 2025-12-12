import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rundown-items"
export default class extends Controller {
  static targets = ["container", "template", "item", "destroyField"]

  connect() {
    console.log("Rundown items controller connected!")
  }

  addItem(event) {
    event.preventDefault()
    
    const template = this.templateTarget
    const container = this.containerTarget
    
    // Generate a unique index based on current time
    const newIndex = Date.now()
    
    // Get the template HTML and replace NEW_INDEX with the actual index
    const templateHTML = template.innerHTML.replace(/NEW_INDEX/g, newIndex)
    
    // Create a temporary container to parse the HTML
    const tempDiv = document.createElement("div")
    tempDiv.innerHTML = templateHTML
    
    // Get the first child (the rundown item)
    const newItem = tempDiv.firstElementChild
    
    // Append to container
    container.appendChild(newItem)
  }

  removeItem(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    const item = button.closest("[data-rundown-items-target='item']")
    const destroyField = item.querySelector("[data-rundown-items-target='destroyField']")
    
    if (destroyField) {
      // If the item has an ID (existing item), mark it for destruction
      const idField = item.querySelector('input[name*="[id]"]')
      if (idField && idField.value) {
        destroyField.value = "1"
        item.style.display = "none"
      } else {
        // If it's a new item (no ID), just remove it from the DOM
        item.remove()
      }
    } else {
      // Fallback: just remove the item
      item.remove()
    }
  }
}

