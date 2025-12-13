import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["avatar", "modal", "video", "canvas", "preview", "status", "captureBtn", "saveBtn", "photoInput"]

  async openCamera() {
    console.log("openCamera gestartet")
    this.modalTarget.classList.add("open")
    this.previewTarget.classList.add("hidden")
    this.videoTarget.classList.remove("hidden")
    this.captureBtnTarget.classList.remove("hidden")
    this.saveBtnTarget.classList.add("hidden")

    this.statusTarget.textContent = "Lade Modelle..."

    const MODEL_URL = 'https://cdn.jsdelivr.net/npm/@vladmandic/face-api/model'
    await faceapi.nets.tinyFaceDetector.loadFromUri(MODEL_URL)

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "user" } })
      this.videoTarget.srcObject = stream
      this.stream = stream
      this.statusTarget.textContent = ""
      this.detectFace()
    } catch (error) {
      console.error(error)
      this.statusTarget.textContent = "Kamera-Zugriff verweigert"
    }
  }

  async detectFace() {
    if (!this.stream) return

    const detection = await faceapi.detectSingleFace(
      this.videoTarget,
      new faceapi.TinyFaceDetectorOptions({ inputSize: 320, scoreThreshold: 0.5 })
    )

    this.faceDetected = !!detection
    this.captureBtnTarget.disabled = !this.faceDetected
    this.statusTarget.textContent = this.faceDetected ? "✅ Gesicht erkannt" : "Bitte Gesicht zeigen..."

    requestAnimationFrame(() => this.detectFace())
  }

  capture() {
    if (!this.faceDetected) return

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
    this.statusTarget.textContent = "Foto aufgenommen!"

    this.stopCamera()
  }

  retake() {
    this.openCamera()
  }

  save() {
    this.photoInputTarget.value = this.photoData
    if (this.hasAvatarTarget) {
      this.avatarTarget.src = this.photoData
    }
    this.closeModal()
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
