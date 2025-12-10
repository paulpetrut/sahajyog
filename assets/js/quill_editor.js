import Quill from "quill"
import ImageResize from "quill-image-resize"

// Register the image resize module
Quill.register("modules/imageResize", ImageResize)

const QuillEditor = {
  mounted() {
    const input = this.el.querySelector("input[type=hidden], textarea")
    const editorContainer = this.el.querySelector(".quill-editor")

    if (!input || !editorContainer) {
      console.error("Quill editor: missing input or container")
      return
    }

    // Initialize Quill
    this.quill = new Quill(editorContainer, {
      theme: "snow",
      modules: {
        toolbar: [
          [{ header: [1, 2, 3, 4, 5, 6, false] }],
          [{ size: ["small", false, "large", "huge"] }],
          ["bold", "italic", "underline", "strike"],
          [{ color: [] }, { background: [] }],
          [{ align: [] }],
          [{ list: "ordered" }, { list: "bullet" }],
          [{ indent: "-1" }, { indent: "+1" }],
          ["blockquote", "code-block"],
          ["link", "image"],
          ["clean"],
        ],
        imageResize: {
          displaySize: true,
          modules: ["Resize", "DisplaySize"],
        },
      },
      placeholder: input.placeholder || "Write your content here...",
    })

    // Setup image alignment toolbar
    this.setupImageAlignmentToolbar(editorContainer)

    // Set initial content
    if (input.value) {
      this.quill.root.innerHTML = input.value
    }

    // Update hidden input on text change
    this.quill.on("text-change", () => {
      const html = this.quill.root.innerHTML
      input.value = html

      // Trigger change event for LiveView
      input.dispatchEvent(new Event("input", { bubbles: true }))
    })

    // Handle image uploads
    const toolbar = this.quill.getModule("toolbar")
    toolbar.addHandler("image", () => {
      this.selectLocalImage()
    })
  },

  selectLocalImage() {
    const input = document.createElement("input")
    input.setAttribute("type", "file")
    input.setAttribute("accept", "image/*")
    input.click()

    input.onchange = () => {
      const file = input.files[0]

      if (/^image\//.test(file.type)) {
        this.saveImageToServer(file)
      } else {
        console.warn("You can only upload images.")
      }
    }
  },

  saveImageToServer(file) {
    const reader = new FileReader()

    reader.onload = (e) => {
      const base64 = e.target.result
      const range = this.quill.getSelection()

      // Insert image as base64 (for now)
      // In production, you'd upload to a server and get a URL
      this.quill.insertEmbed(range.index, "image", base64)
    }

    reader.readAsDataURL(file)
  },

  setupImageAlignmentToolbar(editorContainer) {
    // Create alignment toolbar
    const toolbar = document.createElement("div")
    toolbar.className = "image-align-toolbar"
    toolbar.innerHTML = `
      <button type="button" data-align="left" title="Float Left">◀</button>
      <button type="button" data-align="center" title="Center">▬</button>
      <button type="button" data-align="right" title="Float Right">▶</button>
    `
    toolbar.style.display = "none"
    editorContainer.appendChild(toolbar)
    this.imageToolbar = toolbar

    // Store handlers for cleanup
    this.toolbarButtonHandlers = []

    // Handle alignment button clicks
    toolbar.querySelectorAll("button").forEach((btn) => {
      const handler = (e) => {
        e.preventDefault()
        e.stopPropagation()
        if (this.selectedImage) {
          const align = btn.dataset.align
          this.applyImageAlignment(this.selectedImage, align)
          this.updateToolbarPosition()
          this.triggerChange()
        }
      }
      this.toolbarButtonHandlers.push({ btn, handler })
      btn.addEventListener("click", handler)
    })

    // Handle image selection
    this.editorClickHandler = (e) => {
      if (e.target.tagName === "IMG") {
        this.selectImage(e.target)
      } else if (!toolbar.contains(e.target)) {
        this.deselectImage()
      }
    }
    editorContainer.addEventListener("click", this.editorClickHandler)
    this.editorContainer = editorContainer

    // Hide toolbar when clicking outside
    this.documentClickHandler = (e) => {
      if (!editorContainer.contains(e.target) && !toolbar.contains(e.target)) {
        this.deselectImage()
      }
    }
    document.addEventListener("click", this.documentClickHandler)
  },

  selectImage(img) {
    this.deselectImage()
    this.selectedImage = img
    img.classList.add("ql-selected")
    this.imageToolbar.style.display = "flex"
    this.updateToolbarPosition()
  },

  deselectImage() {
    if (this.selectedImage) {
      this.selectedImage.classList.remove("ql-selected")
      this.selectedImage = null
    }
    if (this.imageToolbar) {
      this.imageToolbar.style.display = "none"
    }
  },

  updateToolbarPosition() {
    if (!this.selectedImage || !this.imageToolbar) return
    const imgRect = this.selectedImage.getBoundingClientRect()
    const containerRect = this.el.querySelector(".quill-editor").getBoundingClientRect()
    this.imageToolbar.style.top = `${imgRect.top - containerRect.top - 40}px`
    this.imageToolbar.style.left = `${imgRect.left - containerRect.left + imgRect.width / 2 - 60}px`
  },

  applyImageAlignment(img, align) {
    // Remove existing alignment classes and styles
    img.classList.remove("ql-align-left", "ql-align-center", "ql-align-right")
    img.style.float = ""
    img.style.display = ""
    img.style.margin = ""

    // Apply new alignment with inline styles for reliability
    img.classList.add(`ql-align-${align}`)

    if (align === "left") {
      img.style.float = "left"
      img.style.margin = "0.5em 1em 0.5em 0"
    } else if (align === "right") {
      img.style.float = "right"
      img.style.margin = "0.5em 0 0.5em 1em"
    } else {
      img.style.display = "block"
      img.style.margin = "1em auto"
    }

    // For left/right alignment, position cursor for text wrapping
    if (align === "left" || align === "right") {
      this.positionCursorForTextWrap(img)
    }
  },

  positionCursorForTextWrap(img) {
    // Find the image's position in Quill
    const blot = Quill.find(img)
    if (!blot) return

    const index = this.quill.getIndex(blot)

    // Check if there's already text after the image in the same paragraph
    const parent = img.parentElement
    const nextSibling = img.nextSibling

    // If no text after image, insert a space to start typing
    if (!nextSibling || (nextSibling.nodeType === 3 && nextSibling.textContent.trim() === "")) {
      // Insert a non-breaking space after the image and position cursor there
      this.quill.insertText(index + 1, " ", "user")
      this.quill.setSelection(index + 2, 0)
    } else {
      // Position cursor right after the image
      this.quill.setSelection(index + 1, 0)
    }

    // Focus the editor
    this.quill.focus()
    this.deselectImage()
  },

  triggerChange() {
    const input = this.el.querySelector("input[type=hidden], textarea")
    if (input) {
      input.value = this.quill.root.innerHTML
      input.dispatchEvent(new Event("input", { bubbles: true }))
    }
  },

  destroyed() {
    // Clean up event listeners
    if (this.documentClickHandler) {
      document.removeEventListener("click", this.documentClickHandler)
    }
    if (this.editorContainer && this.editorClickHandler) {
      this.editorContainer.removeEventListener("click", this.editorClickHandler)
    }
    if (this.toolbarButtonHandlers) {
      this.toolbarButtonHandlers.forEach(({ btn, handler }) => {
        btn.removeEventListener("click", handler)
      })
    }

    if (this.quill) {
      this.quill = null
    }
    this.deselectImage()
  },
}

export default QuillEditor
