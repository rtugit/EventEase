import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="tabs"
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    console.log("Tabs controller connected!")
  }

  switchTab(event) {
    event.preventDefault()
    
    const clickedTab = event.currentTarget
    const tabName = clickedTab.dataset.tab
    
    // Update all tabs
    this.tabTargets.forEach(tab => {
      const isActive = tab === clickedTab
      if (isActive) {
        tab.classList.add("active")
        tab.setAttribute("aria-selected", "true")
      } else {
        tab.classList.remove("active")
        tab.setAttribute("aria-selected", "false")
      }
    })
    
    // Update all panels
    this.panelTargets.forEach(panel => {
      const isActive = panel.dataset.panel === tabName
      if (isActive) {
        panel.classList.add("active")
        panel.removeAttribute("aria-hidden")
      } else {
        panel.classList.remove("active")
        panel.setAttribute("aria-hidden", "true")
      }
    })
  }
}

