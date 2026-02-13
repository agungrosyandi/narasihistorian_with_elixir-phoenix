// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks as colocatedHooks } from "phoenix-colocated/narasihistorian";
import topbar from "../vendor/topbar";

import Hooks from "./hooks";

import Chart from "chart.js/auto";
import { DashboardHooks } from "./dashboard_hooks";

import Swiper from "swiper/bundle";
import "swiper/css/bundle";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { ...colocatedHooks, ...Hooks, ...DashboardHooks },
});

window.Chart = Chart;

// Show progress bar on live navigation and form submits

topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page

liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()

window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//

if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (_e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );

      window.liveReloader = reloader;
    },
  );
}

// ======================================
// CURSOR BASED WITH INFINITY SCROOL UI
// ======================================

async function loadMore(btn) {
  const nextCursor = btn.dataset.nextCursor;
  const url = btn.dataset.url;
  const targetId = btn.dataset.target || "articles-grid";
  const search = btn.dataset.search || "";
  const category = btn.dataset.category || "";

  // Show loading state on the button

  btn.disabled = true;
  btn.innerHTML =
    '<span class="loading loading-spinner loading-sm"></span> Memuat...';

  try {
    // Build the fetch URL
    const params = new URLSearchParams({ cursor: nextCursor });
    if (search) params.set("q", search);
    if (category) params.set("category", category);

    const res = await fetch(`${url}?${params.toString()}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);

    const html = await res.text();

    // Parse the returned HTML fragment

    const parser = new DOMParser();
    const doc = parser.parseFromString(html, "text/html");
    const batch = doc.getElementById("new-articles-batch");
    const newBtnContainer = doc.getElementById("new-load-more-container");

    // Append new cards into the grid

    const grid = document.getElementById(targetId);
    if (grid && batch) {
      // Move each card child into the grid (skip the wrapper div)

      while (batch.firstChild) {
        grid.appendChild(batch.firstChild);
      }
    }

    // Replace the old load-more-container with the new one
    const oldContainer = document.getElementById("load-more-container");
    if (oldContainer && newBtnContainer) {
      // Copy classes from old container
      newBtnContainer.id = "load-more-container";
      newBtnContainer.className = oldContainer.className;
      oldContainer.replaceWith(newBtnContainer);
    }
  } catch (err) {
    console.error("Load more failed:", err);
    // Restore button on error so user can retry
    btn.disabled = false;
    btn.innerHTML = "Muat Lebih Banyak";
  }
}

window.loadMore = loadMore;

window.Swiper = Swiper;
