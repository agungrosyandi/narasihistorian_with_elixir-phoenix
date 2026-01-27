import Quill from "quill";

// quil text editor -----------------------------------------------------

let Hooks = {};

Hooks.QuillEditor = {
  mounted() {
    console.log("QuillEditor hook mounted");
    console.log("Element:", this.el);

    const editorContainer = this.el.querySelector(".quill-editor");
    console.log("Editor container:", editorContainer);

    if (!editorContainer) {
      console.error("Quill editor container not found");
      return;
    }

    try {
      const quill = new Quill(editorContainer, {
        theme: "snow",
        modules: {
          toolbar: [
            [{ header: [1, 2, 3, false] }],
            ["bold", "italic", "underline", "strike"],
            [{ list: "ordered" }, { list: "bullet" }],
            [{ align: [] }],
            ["link", "image"],
            ["clean"],
          ],
        },
        placeholder: "Tulis Konten Artikelmu .....",
      });

      console.log("Quill initialized:", quill);

      // Load content from data attribute

      const initialContent = this.el.dataset.content;
      console.log("Initial content:", initialContent);

      if (initialContent && initialContent.trim() !== "") {
        quill.root.innerHTML = initialContent;
      }

      // Update hidden input when content changes

      quill.on("text-change", () => {
        const content = quill.root.innerHTML;
        const hiddenInput = this.el.querySelector('input[type="hidden"]');
        if (hiddenInput) {
          hiddenInput.value = content;
        }
      });

      this.quill = quill;
    } catch (error) {
      console.error("Error initializing Quill:", error);
    }
  },

  destroyed() {
    console.log("QuillEditor hook destroyed");
    if (this.quill) {
      this.quill = null;
    }
  },
};

export default Hooks;
