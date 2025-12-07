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
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import QuillEditor from "./quill_editor"
import Sortable from "sortablejs"
import LocalTime from "./hooks/local_time"

const Hooks = {}

Hooks.LocalTime = LocalTime
Hooks.QuillEditor = QuillEditor

// Pool Sortable hook for drag-and-drop reordering of Welcome pool videos
Hooks.PoolSortable = {
  mounted() {
    const el = this.el
    const hook = this

    this.sortable = new Sortable(el, {
      animation: 150,
      ghostClass: "opacity-50",
      dragClass: "shadow-lg",
      handle: ".cursor-grab",
      onEnd: function (evt) {
        // Get all video IDs in the new order
        const ids = Array.from(el.children).map((child) => child.dataset.id)
        hook.pushEvent("reorder_pool", { ids: ids })
      },
    })
  },

  destroyed() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  },
}

Hooks.WatchedVideos = {
  mounted() {
    // Check if user is logged in by looking for user menu in the DOM
    const isLoggedIn = document.querySelector('a[href="/users/log-out"]') !== null

    // Only load from localStorage if user is NOT logged in
    if (!isLoggedIn) {
      const stored = localStorage.getItem("watched_videos")
      if (stored) {
        try {
          const watchedIds = JSON.parse(stored)
          this.pushEvent("load_watched", { ids: watchedIds })
        } catch (e) {
          console.error("Failed to parse watched videos:", e)
        }
      }
    } else {
      // Clear localStorage for logged-in users to prevent confusion
      localStorage.removeItem("watched_videos")
    }

    // Listen for updates from the server (only for non-logged-in users)
    this.handleEvent("update_storage", ({ ids }) => {
      if (!isLoggedIn) {
        localStorage.setItem("watched_videos", JSON.stringify(ids))
      }
    })
  },
}

Hooks.LocaleSelector = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      const locale = this.el.dataset.locale
      if (locale) {
        // Reload the page with the new locale parameter
        const url = new URL(window.location)
        url.searchParams.set("locale", locale)
        window.location.href = url.toString()
      }
    })
  },
}

Hooks.PreviewHandler = {
  mounted() {
    this.handleEvent("open_preview", ({ url }) => {
      window.open(url, "_blank")
    })
  },
}

// Apple-style scroll animations hook
Hooks.AppleAnimations = {
  mounted() {
    // Find all elements with Apple animation classes
    const animatedElements = this.el.querySelectorAll(
      ".apple-reveal, .apple-scale, .apple-parallax, .apple-reveal-stagger"
    )

    if (!animatedElements.length) return

    // Create IntersectionObserver with Apple-like timing
    const options = {
      root: null,
      rootMargin: "0px 0px -100px 0px", // Trigger slightly before element is fully in view
      threshold: 0.1,
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          // Add revealed class to trigger animation
          entry.target.classList.add("revealed")

          // Also reveal stagger children if present
          const staggerChildren = entry.target.querySelectorAll(".apple-reveal-stagger")
          staggerChildren.forEach((child) => child.classList.add("revealed"))
        } else {
          // Reset animation when element leaves viewport (for replay)
          entry.target.classList.remove("revealed")

          // Also reset stagger children
          const staggerChildren = entry.target.querySelectorAll(".apple-reveal-stagger")
          staggerChildren.forEach((child) => child.classList.remove("revealed"))
        }
      })
    }, options)

    // Observe all animated elements
    animatedElements.forEach((el) => {
      this.observer.observe(el)
    })

    // Immediately reveal elements already in viewport
    requestAnimationFrame(() => {
      animatedElements.forEach((el) => {
        const rect = el.getBoundingClientRect()
        if (rect.top < window.innerHeight && rect.bottom > 0) {
          el.classList.add("revealed")
          const staggerChildren = el.querySelectorAll(".apple-reveal-stagger")
          staggerChildren.forEach((child) => child.classList.add("revealed"))
        }
      })
    })

    // Hide scroll indicator when video section is 50% visible
    const scrollIndicator = this.el.querySelector("#scroll-indicator")
    const videoSection = this.el.querySelector("#video")

    if (scrollIndicator && videoSection) {
      const videoObserver = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            // Hide when video section is 50% visible (intersectionRatio >= 0.5)
            if (entry.intersectionRatio >= 0.5) {
              scrollIndicator.classList.add("hidden")
            } else {
              scrollIndicator.classList.remove("hidden")
            }
          })
        },
        {
          threshold: [0, 0.5, 1], // Trigger at 0%, 50%, and 100% visibility
        }
      )

      videoObserver.observe(videoSection)
      this.videoObserver = videoObserver
    }
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.videoObserver) {
      this.videoObserver.disconnect()
    }
    if (this.scrollHandler) {
      window.removeEventListener("scroll", this.scrollHandler)
    }
  },
}

// Unsaved changes warning hook
Hooks.UnsavedChanges = {
  mounted() {
    this.hasChanges = false
    this.formSubmitting = false

    // Track form changes
    this.el.addEventListener("input", () => {
      this.hasChanges = true
    })

    // Track form submission
    this.el.addEventListener("submit", () => {
      this.formSubmitting = true
    })

    // Warn before leaving page
    this.beforeUnloadHandler = (e) => {
      if (this.hasChanges && !this.formSubmitting) {
        e.preventDefault()
        e.returnValue = ""
        return ""
      }
    }

    window.addEventListener("beforeunload", this.beforeUnloadHandler)

    // Handle LiveView navigation
    this.handleEvent("changes_saved", () => {
      this.hasChanges = false
    })

    // Listen for phx:page-loading-start to check if we should warn
    this.pageLoadingHandler = (e) => {
      if (this.hasChanges && !this.formSubmitting) {
        const confirmed = window.confirm("You have unsaved changes. Are you sure you want to leave?")
        if (!confirmed) {
          e.preventDefault()
          e.stopImmediatePropagation()
          window.liveSocket.replaceMain = () => {} // Prevent navigation
        }
      }
    }
  },

  destroyed() {
    window.removeEventListener("beforeunload", this.beforeUnloadHandler)
  },
}

// Auto-dismiss flash messages after a delay
Hooks.AutoDismissFlash = {
  mounted() {
    const delay = parseInt(this.el.dataset.autoDismiss || "5000", 10)

    this.timeout = setTimeout(() => {
      // Fade out animation
      this.el.style.transition = "opacity 0.3s ease-out"
      this.el.style.opacity = "0"

      // Remove after animation
      setTimeout(() => {
        this.el.remove()
      }, 300)
    }, delay)
  },

  destroyed() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  },
}

Hooks.ScheduleNotification = {
  mounted() {
    const key = this.el.dataset.key
    const permanentlyDismissed = localStorage.getItem(`${key}_dismissed`)
    const hasSeen = sessionStorage.getItem(key)

    // Don't show if permanently dismissed
    if (permanentlyDismissed) {
      return
    }

    if (!hasSeen) {
      this.pushEvent("show_notification", {})
      sessionStorage.setItem(key, "true")
    } else {
    }

    // Listen for dismiss event from server
    this.handleEvent("permanently_dismiss", () => {
      localStorage.setItem(`${key}_dismissed`, "true")
    })
  },
}

// Interactive scroll indicator - smooth scroll to next section and hide on scroll
Hooks.ScrollIndicator = {
  mounted() {
    this.el.addEventListener("click", () => {
      // Find the next section after the hero
      const heroSection = document.getElementById("hero-section")
      if (heroSection) {
        const nextSection = heroSection.parentElement.querySelector("section.scroll-reveal, section.py-16")
        if (nextSection) {
          nextSection.scrollIntoView({ behavior: "smooth", block: "start" })
        }
      }
    })

    // Hide on scroll
    let lastScrollY = window.scrollY
    let ticking = false

    const updateIndicator = () => {
      if (window.scrollY > 100) {
        this.el.classList.add("is-hidden")
      } else {
        this.el.classList.remove("is-hidden")
      }
      ticking = false
    }

    window.addEventListener(
      "scroll",
      () => {
        if (!ticking) {
          window.requestAnimationFrame(updateIndicator)
          ticking = true
        }
      },
      { passive: true }
    )
  },
}

// Welcome page scroll animations and effects
Hooks.WelcomeAnimations = {
  mounted() {
    // Scroll progress bar
    this.progressBar = document.getElementById("scroll-progress")

    // Scroll indicator
    this.scrollIndicator = document.getElementById("scroll-indicator")

    // Sticky CTA
    this.stickyCta = document.getElementById("sticky-cta")
    this.heroSection = document.getElementById("hero-section")

    // Counter elements for stats section
    this.counterElements = document.querySelectorAll("[data-counter]")
    this.countersAnimated = false

    // Setup scroll reveal observer
    this.setupScrollRevealObserver()

    // Setup scroll listener for progress bar and sticky CTA
    this.handleScroll = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.handleScroll, { passive: true })

    // Initial scroll to position video at top with scroll indicator visible
    requestAnimationFrame(() => {
      const heroSection = document.getElementById("hero-section")
      if (heroSection) {
        const targetY = heroSection.offsetTop
        window.scrollTo({ top: targetY, behavior: "instant" })
      }
    })

    // Initial check
    this.handleScroll()
  },

  setupScrollRevealObserver() {
    const revealElements = document.querySelectorAll(
      ".scroll-reveal, .scroll-reveal-left, .scroll-reveal-right, .scroll-reveal-scale"
    )
    if (!revealElements.length) return

    // Only hide elements that are BELOW the viewport
    // Elements already visible on page load stay visible (better UX)
    revealElements.forEach((el) => {
      const rect = el.getBoundingClientRect()
      // Only prepare (hide) elements that are below the viewport
      if (rect.top >= window.innerHeight) {
        el.classList.add("prepare-reveal")
      }
    })

    const options = {
      root: null,
      rootMargin: "0px 0px -50px 0px", // Trigger when element is slightly in view
      threshold: 0.1,
    }

    this.revealObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          // Remove preparation class and add revealed class
          entry.target.classList.remove("prepare-reveal")
          entry.target.classList.add("revealed")

          // Trigger stats animation if this is the stats section
          if (entry.target.id === "stats-section" && !this.countersAnimated) {
            this.animateCounters()
            this.countersAnimated = true
          }

          // We do NOT unobserve here. Keeping the observer active ensures that
          // if the DOM is patched by LiveView and classes are lost,
          // the observer will re-apply the 'revealed' class when the element is in view.
          // this.revealObserver.unobserve(entry.target)
        } else {
          // Element left the view. Reset it so it can animate again.
          entry.target.classList.remove("revealed")
          entry.target.classList.add("prepare-reveal")

          // Reset stats animation if this is the stats section
          if (entry.target.id === "stats-section") {
            this.countersAnimated = false
          }
        }
      })
    }, options)

    revealElements.forEach((el) => {
      this.revealObserver.observe(el)
    })
  },

  handleScroll() {
    const scrollTop = window.scrollY

    // Update scroll progress bar
    if (this.progressBar) {
      const docHeight = document.documentElement.scrollHeight - window.innerHeight
      const progress = (scrollTop / docHeight) * 100
      this.progressBar.style.width = `${progress}%`
    }

    // Fade out scroll indicator when user starts scrolling
    if (this.scrollIndicator) {
      if (scrollTop > 50) {
        this.scrollIndicator.style.opacity = "0"
        this.scrollIndicator.style.pointerEvents = "none"
      } else {
        this.scrollIndicator.style.opacity = "1"
        this.scrollIndicator.style.pointerEvents = "auto"
      }
    }

    // Toggle sticky CTA visibility
    if (this.stickyCta && this.heroSection) {
      const heroBottom = this.heroSection.getBoundingClientRect().bottom
      if (heroBottom < 0) {
        this.stickyCta.classList.add("is-visible")
      } else {
        this.stickyCta.classList.remove("is-visible")
      }
    }
  },

  animateCounters() {
    this.counterElements.forEach((el) => {
      const target = parseInt(el.dataset.counter, 10)
      const duration = 2000
      const step = target / (duration / 16)
      let current = 0

      const updateCounter = () => {
        current += step
        if (current < target) {
          el.textContent = Math.floor(current)
          requestAnimationFrame(updateCounter)
        } else {
          el.textContent = target
        }
      }

      updateCounter()
    })
  },

  destroyed() {
    window.removeEventListener("scroll", this.handleScroll)
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.revealObserver) {
      this.revealObserver.disconnect()
    }
  },
}

// Infinite scroll hook for mobile talks page
Hooks.InfiniteScroll = {
  mounted() {
    this.observer = null
    this.pending = false

    // Only enable on mobile/tablet
    const isMobile = window.innerWidth < 1024

    if (isMobile) {
      this.setupObserver()
    }

    // Re-check on resize
    window.addEventListener("resize", () => {
      const nowMobile = window.innerWidth < 1024
      if (nowMobile && !this.observer) {
        this.setupObserver()
      } else if (!nowMobile && this.observer) {
        this.observer.disconnect()
        this.observer = null
      }
    })

    // Handle loading state from server
    this.handleEvent("loading_more", () => {
      this.pending = true
    })

    this.handleEvent("loaded_more", () => {
      this.pending = false
    })
  },

  setupObserver() {
    const options = {
      root: null,
      rootMargin: "400px",
      threshold: 0,
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting && !this.pending) {
          this.pending = true
          this.pushEvent("load_more", {})
        }
      })
    }, options)

    // Observe the sentinel element
    const sentinel = document.getElementById("infinite-scroll-sentinel")
    if (sentinel) {
      this.observer.observe(sentinel)
    }
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
  },
}

Hooks.QuotesCarousel = {
  mounted() {
    this.currentSlide = 0
    this.totalSlides = 3
    this.autoSlideInterval = null

    this.track = this.el.querySelector(".carousel-track")
    this.indicators = this.el.querySelectorAll(".carousel-indicator")
    this.prevBtn = this.el.querySelector(".carousel-prev")
    this.nextBtn = this.el.querySelector(".carousel-next")

    // Update slide position
    this.updateSlide = () => {
      this.track.style.transform = `translateX(-${this.currentSlide * 100}%)`

      // Update indicators
      this.indicators.forEach((indicator, index) => {
        if (index === this.currentSlide) {
          indicator.classList.add("bg-primary", "w-8")
          indicator.classList.remove("bg-base-content/30", "w-3")
        } else {
          indicator.classList.remove("bg-primary", "w-8")
          indicator.classList.add("bg-base-content/30", "w-3")
        }
      })
    }

    // Next slide
    this.nextSlide = () => {
      this.currentSlide = (this.currentSlide + 1) % this.totalSlides
      this.updateSlide()
    }

    // Previous slide
    this.prevSlide = () => {
      this.currentSlide = (this.currentSlide - 1 + this.totalSlides) % this.totalSlides
      this.updateSlide()
    }

    // Go to specific slide
    this.goToSlide = (index) => {
      this.currentSlide = index
      this.updateSlide()
    }

    // Start auto-slide
    this.startAutoSlide = () => {
      this.autoSlideInterval = setInterval(() => {
        this.nextSlide()
      }, 15000) // Change slide every 15 seconds
    }

    // Stop auto-slide
    this.stopAutoSlide = () => {
      if (this.autoSlideInterval) {
        clearInterval(this.autoSlideInterval)
        this.autoSlideInterval = null
      }
    }

    // Event listeners
    this.nextBtn.addEventListener("click", () => {
      this.stopAutoSlide()
      this.nextSlide()
      this.startAutoSlide()
    })

    this.prevBtn.addEventListener("click", () => {
      this.stopAutoSlide()
      this.prevSlide()
      this.startAutoSlide()
    })

    this.indicators.forEach((indicator, index) => {
      indicator.addEventListener("click", () => {
        this.stopAutoSlide()
        this.goToSlide(index)
        this.startAutoSlide()
      })
    })

    // Pause on hover
    this.el.addEventListener("mouseenter", () => {
      this.stopAutoSlide()
    })

    this.el.addEventListener("mouseleave", () => {
      this.startAutoSlide()
    })

    // Initialize
    this.updateSlide()
    this.startAutoSlide()
  },

  destroyed() {
    this.stopAutoSlide()
  },
}

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300))
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
// Check if we're in development mode by looking for Phoenix LiveReload
if (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1") {
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", (e) => (keyDown = e.key))
    window.addEventListener("keyup", (e) => (keyDown = null))
    window.addEventListener(
      "click",
      (e) => {
        if (keyDown === "c") {
          e.preventDefault()
          e.stopImmediatePropagation()
          reloader.openEditorAtCaller(e.target)
        } else if (keyDown === "d") {
          e.preventDefault()
          e.stopImmediatePropagation()
          reloader.openEditorAtDef(e.target)
        }
      },
      true
    )

    window.liveReloader = reloader
  })
}
