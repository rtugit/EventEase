import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["avatar", "modal", "video", "canvas", "preview", "status", "captureBtn", "saveBtn", "retakeBtn", "photoInput"]

  async openCamera() {
    console.log("openCamera started")
    this.modalTarget.classList.add("open")
    this.previewTarget.classList.add("hidden")
    this.videoTarget.classList.remove("hidden")
    this.captureBtnTarget.classList.remove("hidden")
    this.captureBtnTarget.disabled = true
    this.saveBtnTarget.classList.add("hidden")
    if (this.hasRetakeBtnTarget) {
      this.retakeBtnTarget.classList.add("hidden")
    }

    this.statusTarget.textContent = "Loading camera..."

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "user" } })
      this.videoTarget.srcObject = stream
      this.stream = stream
      this.statusTarget.textContent = "Loading face detection..."

      // Try to load face detection
      try {
        const MODEL_URL = 'https://cdn.jsdelivr.net/npm/@vladmandic/face-api/model'
        await faceapi.nets.tinyFaceDetector.loadFromUri(MODEL_URL)
        this.statusTarget.textContent = ""
        this.detectFace()
      } catch (faceError) {
        // Face detection failed, enable button anyway after short delay
        console.warn("Face detection not available:", faceError)
        this.statusTarget.textContent = "Camera ready"
        this.captureBtnTarget.disabled = false
      }

      // Fallback: Enable button after 3 seconds regardless of face detection
      setTimeout(() => {
        if (this.captureBtnTarget.disabled) {
          this.captureBtnTarget.disabled = false
          this.statusTarget.textContent = "Camera ready"
        }
      }, 3000)

    } catch (error) {
      console.error(error)
      this.statusTarget.textContent = "Camera access denied"
    }
  }

  async detectFace() {
    if (!this.stream) return

    try {
      const detection = await faceapi.detectSingleFace(
        this.videoTarget,
        new faceapi.TinyFaceDetectorOptions({ inputSize: 320, scoreThreshold: 0.5 })
      )

      this.faceDetected = !!detection
      this.captureBtnTarget.disabled = !this.faceDetected
      this.statusTarget.textContent = this.faceDetected ? "✅ Face detected" : "Please show your face..."

      requestAnimationFrame(() => this.detectFace())
    } catch (error) {
      console.warn("Face detection error:", error)
      // If face detection fails, just enable the button
      this.captureBtnTarget.disabled = false
      this.statusTarget.textContent = "Camera ready"
    }
  }

  capture() {
    const canvas = this.canvasTarget
    canvas.width = this.videoTarget.videoWidth
    canvas.height = this.videoTarget.videoHeight
    canvas.getContext('2d').drawImage(this.videoTarget, 0, 0)

    this.photoData = canvas.toDataURL('image/jpeg', 0.8)
    this.previewTarget.src = this.photoData
    this.previewTarget.classList.remove("hidden")
    this.videoTarget.classList.add("hidden")
    this.captureBtnTarget.classList.add("hidden")
    this.saveBtnTarget.classList.remove("hidden")
    if (this.hasRetakeBtnTarget) {
      this.retakeBtnTarget.classList.remove("hidden")
    }
    this.statusTarget.textContent = "Photo captured!"

    this.stopCamera()
  }

  retake() {
    this.openCamera()
  }

  save() {
    if (this.hasPhotoInputTarget && this.photoData) {
      this.photoInputTarget.value = this.photoData
    }
    if (this.hasAvatarTarget && this.photoData) {
      this.avatarTarget.src = this.photoData
      this.avatarTarget.classList.remove("hidden")
    }
    this.statusTarget.textContent = "Photo saved!"

    // Submit the form after a short delay
    setTimeout(() => {
      this.closeModal()
      // Find and submit the form
      const form = this.photoInputTarget?.closest('form')
      if (form) {
        form.requestSubmit()
      }
    }, 500)
  }

  closeModal() {
    this.modalTarget.classList.remove("open")
    this.stopCamera()
  }

  stopCamera() {
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop())
      this.stream = null
    }
  }

  disconnect() {
    this.stopCamera()
  }
}
