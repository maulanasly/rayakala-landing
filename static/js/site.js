// rayakala-landing — tiny enhancements, no framework.
(function () {
  // Footer year.
  var year = document.getElementById("year");
  if (year) year.textContent = String(new Date().getFullYear());

  // Active nav highlighting.
  var links = Array.prototype.slice.call(
    document.querySelectorAll(".site-nav a[href^='#']")
  );
  var sections = links
    .map(function (a) {
      return document.querySelector(a.getAttribute("href"));
    })
    .filter(Boolean);

  if ("IntersectionObserver" in window && sections.length) {
    var byId = {};
    links.forEach(function (a) {
      byId[a.getAttribute("href").slice(1)] = a;
    });
    var obs = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting && byId[e.target.id]) {
            links.forEach(function (a) {
              a.classList.remove("active");
            });
            byId[e.target.id].classList.add("active");
          }
        });
      },
      { rootMargin: "-40% 0px -55% 0px" }
    );
    sections.forEach(function (s) {
      obs.observe(s);
    });
  }

  // Subtle reveal (disabled for reduced motion via CSS).
  var revealEls = document.querySelectorAll(".section, .hero .lede");
  if ("IntersectionObserver" in window) {
    revealEls.forEach(function (el) {
      el.classList.add("reveal");
    });
    var ro = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) {
            e.target.classList.add("visible");
            ro.unobserve(e.target);
          }
        });
      },
      { threshold: 0.08 }
    );
    revealEls.forEach(function (el) {
      ro.observe(el);
    });
  }
})();
