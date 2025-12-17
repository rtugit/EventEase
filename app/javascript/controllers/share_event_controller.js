import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["label"]

  copy(event) {
    event.preventDefault()
    const url = this.urlValue || window.location.href

    const onSuccess = () => {
      const label = this.labelTarget
      label.dataset.originalText ||= label.textContent
      label.textContent = "Copied!"
      this.element.classList.add("copied")
      setTimeout(() => {
        label.textContent = label.dataset.originalText
        this.element.classList.remove("copied")
      }, 1500)
    }

    const onError = (err) => {
      console.warn("Clipboard copy failed", err)
      // Fallback prompt so the user can still copy.
      window.prompt("Press Ctrl+C (Cmd+C on Mac) to copy the URL", url)
    }

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(url).then(onSuccess).catch(onError)
    } else {
      // Fallback for older browsers
      const textarea = document.createElement("textarea")
      textarea.value = url
      textarea.setAttribute("readonly", "")
      textarea.style.position = "fixed"
      textarea.style.left = "-9999px"
      document.body.appendChild(textarea)
      textarea.select()
      try {
        document.execCommand("copy")
        onSuccess()
      } catch (err) {
        onError(err)
      } finally {
        document.body.removeChild(textarea)
      }
    }
  }
}
