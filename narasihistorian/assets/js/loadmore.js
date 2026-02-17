// ======================================
// CURSOR BASED WITH INFINITY SCROOL UI
// ======================================

// ======================================
// INFINITY SCROOL HOME
// ======================================

async function loadMore(btn) {
  const nextCursor = btn.dataset.nextCursor;
  const url = btn.dataset.url;
  const targetId = btn.dataset.target || "articles-grid";
  const search = btn.dataset.search || "";
  const category = btn.dataset.category || "";

  // SHOW LOADING STATE BUTTON

  btn.disabled = true;
  btn.innerHTML =
    '<span class="loading loading-spinner loading-sm"></span> Memuat...';

  try {
    const params = new URLSearchParams({ cursor: nextCursor });
    if (search) params.set("q", search);
    if (category) params.set("category", category);

    const res = await fetch(`${url}?${params.toString()}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);

    const html = await res.text();

    // PARSER HTML FRAGMENT

    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");
    const batch = doc.getElementById("new-articles-batch");
    const newBtnContainer = doc.getElementById("new-load-more-container");

    // Append new cards into the grid

    const grid = document.getElementById(targetId);
    if (grid && batch) {
      while (batch.firstChild) {
        grid.appendChild(batch.firstChild);
      }
    }

    const oldContainer = document.getElementById("load-more-container");

    if (oldContainer && newBtnContainer) {
      newBtnContainer.id = "load-more-container";
      newBtnContainer.className = oldContainer.className;
      oldContainer.replaceWith(newBtnContainer);
    }
  } catch (err) {
    console.error("Load more failed:", err);
    btn.disabled = false;
    btn.innerHTML = "Muat Lebih Banyak";
  }
}

// ======================================
// INFINITY SCROOL COMMENTS
// ======================================

async function loadMoreComments(btn) {
  const nextPage = btn.dataset.nextPage;
  const articleId = btn.dataset.articleId;

  btn.disabled = true;
  btn.innerHTML =
    '<span class="loading loading-spinner loading-sm"></span> Memuat...';

  try {
    const res = await fetch(
      `/articles/${articleId}/comments/more?page=${nextPage}`,
      { headers: { Accept: "text/html" } },
    );

    if (!res.ok) throw new Error("fetch failed");

    const html = await res.text();
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");

    const list = document.getElementById("comments-list");
    doc.querySelectorAll(".comment-card").forEach((el) => {
      list.appendChild(document.importNode(el, true));
    });

    const meta = doc.getElementById("comments-meta");
    if (meta && meta.dataset.hasMore === "true") {
      btn.dataset.nextPage = meta.dataset.nextPage;
      btn.disabled = false;
      btn.innerHTML = `
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none"
              viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round"
                d="M12 4.5v15m0 0l6.75-6.75M12 19.5l-6.75-6.75" />
            </svg>
            Muat Lebih Banyak Komentar
          `;
    } else {
      document.getElementById("load-more-container").remove();
    }
  } catch (err) {
    console.error("Load more error:", err);
    btn.disabled = false;
    btn.innerHTML = "Gagal memuat, coba lagi";
  }
}

window.loadMore = loadMore;
window.loadMoreComments = loadMoreComments;
