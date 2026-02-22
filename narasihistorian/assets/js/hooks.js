import Quill from "quill";

let Hooks = {};

//===================================================================
// QUILL EDITOR
//===================================================================

Hooks.QuillEditor = {
  mounted() {
    const editorContainer = this.el.querySelector(".quill-editor");

    if (!editorContainer) return;

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

    // Load initial content from data attribute

    const initialContent = this.el.dataset.content;
    if (initialContent && initialContent.trim() !== "") {
      quill.root.innerHTML = initialContent;
    }

    // Sync to hidden input OUTSIDE this ignored div

    quill.on("text-change", () => {
      const hiddenInput = document.getElementById("article_content");
      if (hiddenInput) {
        hiddenInput.value = quill.root.innerHTML;
      }
    });

    this.quill = quill;
  },

  destroyed() {
    this.quill = null;
  },
};

//===================================================================
// TAG INPUT
//===================================================================

Hooks.TagInput = {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      if (e.key === "Enter") {
        e.preventDefault();
        const tag = this.el.value.trim();

        if (tag) {
          const target = this.el.dataset.target;
          if (target) {
            this.pushEventTo(target, "add_tag", { tag: tag });
          } else {
            this.pushEvent("add_tag", { tag: tag });
          }
          this.el.value = "";
        }
      }
    });
  },
};

export default Hooks;
