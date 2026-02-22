function initHomeSwiper() {
  const popularEl = document.getElementById("cardSwiperCarouselBig");

  if (popularEl) {
    if (popularEl.swiper) popularEl.swiper.destroy(true, true);

    const id = popularEl.id;

    new Swiper(`#${id}`, {
      rewind: true,
      speed: 1500,

      autoplay: {
        delay: 7000,
        disableOnInteraction: false,
        pauseOnMouseEnter: true,
      },

      navigation: {
        nextEl: `#${id}Next`,
        prevEl: `#${id}Prev`,
      },

      pagination: {
        el: `#${id}Pagination`,
        clickable: true,
      },

      keyboard: { enabled: true },

      on: {
        click: function (swiper, event) {
          const target = event.target || event.srcElement;

          if (target.closest(`#${id}Prev, #${id}Next, #${id}Pagination`)) {
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

  const recentEl = document.getElementById("cardSwiperCarousel");

  if (recentEl) {
    if (recentEl.swiper) recentEl.swiper.destroy(true, true);

    const id = recentEl.id;

    new Swiper(`#${id}`, {
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
        nextEl: `#${id}Next`,
        prevEl: `#${id}Prev`,
      },

      pagination: {
        el: `#${id}Pagination`,
        clickable: true,
        dynamicBullets: true,
      },

      keyboard: { enabled: true },
    });
  }
}

// ==============================================
// TRADITIONAL CONTROLLER
// ==============================================

document.addEventListener("DOMContentLoaded", initHomeSwiper);

// ==============================================
// LIVEVIEW (LIVEVIEW NAVIGATION)
// ==============================================

document.addEventListener("phx:page-loading-stop", initHomeSwiper);
