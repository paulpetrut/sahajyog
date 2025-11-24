import Quill from "quill"

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
      },
      placeholder: input.placeholder || "Write your content here...",
    })

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

  destroyed() {
    if (this.quill) {
      this.quill = null
    }
  },
}

export default QuillEditor
