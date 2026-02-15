// import Swiper from 'swiper/bundle';
// import 'swiper/css/bundle';

// document.addEventListener('DOMContentLoaded', () => {

//   // ── Hero / Popular Swiper ──────────────────────

//   const heroSwiper = new Swiper('#heroSwiper', {
//     loop: true,
//     speed: 800,
//     autoplay: {
//       delay: 5000,
//       disableOnInteraction: false,
//       pauseOnMouseEnter: true,
//     },
//     effect: 'fade',          // cinematic cross-fade
//     fadeEffect: {
//       crossFade: true,
//     },
//     navigation: {
//       nextEl: '.hero-nav-next',
//       prevEl: '.hero-nav-prev',
//     },
//     pagination: {
//       el: '.hero-pagination',
//       clickable: true,
//     },
//     keyboard: { enabled: true },
//     a11y: { prevSlideMessage: 'Previous', nextSlideMessage: 'Next' },
//   });

//   // ── Latest Articles Swiper ─────────────────────

//   const latestSwiper = new Swiper('#latestSwiper', {
//     loop: false,
//     speed: 600,
//     spaceBetween: 24,
//     grabCursor: true,
//     // Responsive breakpoints
//     breakpoints: {
//       320:  { slidesPerView: 1.2 },
//       640:  { slidesPerView: 2.1 },
//       1024: { slidesPerView: 3.1 },
//       1280: { slidesPerView: 4 },
//     },
//     pagination: {
//       el: '.latest-pagination',
//       clickable: true,
//       dynamicBullets: true,
//     },
//     keyboard: { enabled: true },
//   });

// });

// ============================================================
// home_swiper.js
// Initialises the Popular (hero) and Recent (card scroll)
// swipers on the articles index page.
//
// IMPORTANT — why we do NOT use loop:true on the hero swiper:
//   loop:true makes Swiper clone every slide in the DOM.
//   Those clones are plain HTML copies, so data-href on a clone
//   always points to whichever article happened to be rendered
//   first by Phoenix. rewind:true gives the same wrap-around
//   feel with zero DOM cloning.
//
// IMPORTANT — why we use Swiper's on.click instead of a DOM listener:
//   The fade effect stacks ALL slides at the same DOM position and
//   only toggles opacity. A DOM click listener with closest() always
//   hits the topmost element in the stack (always slide 0 = first
//   article). Swiper's own click callback receives the swiper
//   instance, so swiper.realIndex is the truly active slide index —
//   completely independent of how the DOM is stacked.
// ============================================================

function initHomeSwiper() {
  // ── Popular / Hero Swiper ─────────────────────────────────

  const popularEl = document.getElementById("popularSwiper");
  if (popularEl) {
    // Destroy any previous instance (e.g. after LiveView patch)

    if (popularEl.swiper) popularEl.swiper.destroy(true, true);

    new Swiper("#popularSwiper", {
      // rewind = wrap-around without cloning slides

      rewind: true,
      speed: 1500,
      autoplay: {
        delay: 7000,
        disableOnInteraction: false,
        pauseOnMouseEnter: true,
      },
      navigation: {
        nextEl: "#popularNext",
        prevEl: "#popularPrev",
      },
      pagination: {
        el: "#popularPagination",
        clickable: true,
      },
      keyboard: { enabled: true },
      on: {
        click: function (swiper, event) {
          const target = event.target || event.srcElement;
          // Ignore clicks on nav buttons and pagination dots
          if (
            target.closest("#popularPrev, #popularNext, #popularPagination")
          ) {
            return;
          }
          const activeSlide = swiper.slides[swiper.realIndex];
          if (!activeSlide) return;

          const href = activeSlide.dataset.href;
          if (href) window.location.href = href;
        },
      },
    });
  }

  // ── Recent Articles Swiper ────────────────────────────────

  const recentEl = document.getElementById("recentSwiper");
  if (recentEl) {
    if (recentEl.swiper) recentEl.swiper.destroy(true, true);

    new Swiper("#recentSwiper", {
      loop: false,
      speed: 600,
      grabCursor: true,
      slidesOffsetAfter: 32,
      breakpoints: {
        320: { slidesPerView: 1.2, spaceBetween: 12 },
        480: { slidesPerView: 1.6, spaceBetween: 14 },
        640: { slidesPerView: 2.2, spaceBetween: 16 },
        1024: { slidesPerView: 3.2, spaceBetween: 16 },
        1280: { slidesPerView: 4.1, spaceBetween: 20 },
      },
      navigation: {
        nextEl: "#recentNext",
        prevEl: "#recentPrev",
      },
      pagination: {
        el: "#recentPagination",
        clickable: true,
        dynamicBullets: true,
      },
      keyboard: { enabled: true },
    });
  }
}

// Run on normal page load
document.addEventListener("DOMContentLoaded", initHomeSwiper);

// Re-run after LiveView navigations (liveviw navigation)
document.addEventListener("phx:page-loading-stop", initHomeSwiper);
