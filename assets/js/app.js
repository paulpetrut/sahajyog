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

import {
  GSAPHero,
  GSAPScrollReveal,
  GSAPCard3D,
  GSAPMagnetic,
  GSAPSpotlight,
  GSAPTextReveal,
  GSAPCounter,
} from "./hooks/gsap_animations"

const Hooks = {}

Hooks.GSAPHero = GSAPHero
Hooks.GSAPScrollReveal = GSAPScrollReveal
Hooks.GSAPCard3D = GSAPCard3D
Hooks.GSAPMagnetic = GSAPMagnetic
Hooks.GSAPSpotlight = GSAPSpotlight
Hooks.GSAPTextReveal = GSAPTextReveal
Hooks.GSAPCounter = GSAPCounter

// Snowfall auto-stop hook - fades out snowfall after animation completes
Hooks.SnowfallStop = {
  mounted() {
    // The CSS animation handles the fadeout after 30s
    // This hook can be used for additional cleanup if needed
    this.timeout = setTimeout(() => {
      if (this.el) {
        this.el.style.display = "none"
      }
    }, 31000) // 30s animation + 1s buffer
  },
  destroyed() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  },
}

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
      onEnd: function () {
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

  destroyed() {
    // handleEvent is cleaned up automatically by LiveView
    // but including destroyed() for consistency and future-proofing
  },
}

Hooks.LocaleSelector = {
  mounted() {
    this.clickHandler = () => {
      const locale = this.el.dataset.locale
      if (locale) {
        // Reload the page with the new locale parameter
        const url = new URL(window.location)
        url.searchParams.set("locale", locale)
        window.location.href = url.toString()
      }
    }
    this.el.addEventListener("click", this.clickHandler)
  },

  destroyed() {
    if (this.clickHandler) {
      this.el.removeEventListener("click", this.clickHandler)
    }
  },
}

Hooks.PreviewHandler = {
  mounted() {
    this.handleEvent("open_preview", ({ url }) => {
      window.open(url, "_blank")
    })
  },

  destroyed() {
    // handleEvent is cleaned up automatically by LiveView
    // but including destroyed() for consistency and future-proofing
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

    // Fade Christmas tree on scroll
    const christmasTree = this.el.querySelector(".christmas-tree")
    if (christmasTree) {
      this.scrollHandler = () => {
        const scrollY = window.scrollY
        const fadeStart = 100
        const fadeEnd = 400

        if (scrollY <= fadeStart) {
          christmasTree.style.opacity = "0.15"
        } else if (scrollY >= fadeEnd) {
          christmasTree.style.opacity = "0"
        } else {
          const fadeProgress = (scrollY - fadeStart) / (fadeEnd - fadeStart)
          christmasTree.style.opacity = (0.15 * (1 - fadeProgress)).toString()
        }
      }

      window.addEventListener("scroll", this.scrollHandler, { passive: true })
    }

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
    this.inputHandler = () => {
      this.hasChanges = true
    }

    // Track form submission
    this.submitHandler = () => {
      this.formSubmitting = true
    }

    this.el.addEventListener("input", this.inputHandler)
    this.el.addEventListener("submit", this.submitHandler)

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

    // Warn on LiveView navigation
    this.pageLoadingHandler = (e) => {
      if (this.hasChanges && !this.formSubmitting) {
        const confirmed = window.confirm("You have unsaved changes. Are you sure you want to leave?")
        if (!confirmed) {
          e.preventDefault()
          e.stopImmediatePropagation()
        }
      }
    }

    window.addEventListener("phx:page-loading-start", this.pageLoadingHandler)
  },

  destroyed() {
    // Remove form event listeners
    if (this.inputHandler) {
      this.el.removeEventListener("input", this.inputHandler)
    }
    if (this.submitHandler) {
      this.el.removeEventListener("submit", this.submitHandler)
    }
    // Remove window event listeners
    window.removeEventListener("beforeunload", this.beforeUnloadHandler)
    window.removeEventListener("phx:page-loading-start", this.pageLoadingHandler)
  },
}

// Auto-dismiss flash messages after a delay
Hooks.AutoDismissFlash = {
  mounted() {
    const delay = parseInt(this.el.dataset.autoDismiss || "5000", 10)
    this.innerTimeout = null

    this.timeout = setTimeout(() => {
      // Fade out animation
      this.el.style.transition = "opacity 0.3s ease-out"
      this.el.style.opacity = "0"

      // Remove after animation
      this.innerTimeout = setTimeout(() => {
        if (this.el && this.el.parentNode) {
          this.el.remove()
        }
      }, 300)
    }, delay)
  },

  destroyed() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    if (this.innerTimeout) {
      clearTimeout(this.innerTimeout)
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
    this.clickHandler = () => {
      // Find the next section after the hero
      const heroSection = document.getElementById("hero-section")
      if (heroSection) {
        const nextSection = heroSection.parentElement.querySelector("section.scroll-reveal, section.py-16")
        if (nextSection) {
          nextSection.scrollIntoView({ behavior: "smooth", block: "start" })
        }
      }
    }

    this.el.addEventListener("click", this.clickHandler)

    // Hide on scroll
    this.ticking = false

    this.scrollHandler = () => {
      if (!this.ticking) {
        window.requestAnimationFrame(() => {
          if (window.scrollY > 100) {
            this.el.classList.add("is-hidden")
          } else {
            this.el.classList.remove("is-hidden")
          }
          this.ticking = false
        })
        this.ticking = true
      }
    }

    window.addEventListener("scroll", this.scrollHandler, { passive: true })
  },

  destroyed() {
    if (this.clickHandler) {
      this.el.removeEventListener("click", this.clickHandler)
    }
    if (this.scrollHandler) {
      window.removeEventListener("scroll", this.scrollHandler)
    }
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
    // Track animation frames for cleanup
    this.animationFrames = this.animationFrames || []

    this.counterElements.forEach((el) => {
      const target = parseInt(el.dataset.counter, 10)
      const duration = 2000
      const step = target / (duration / 16)
      let current = 0

      const updateCounter = () => {
        current += step
        if (current < target) {
          el.textContent = Math.floor(current)
          const frameId = requestAnimationFrame(updateCounter)
          this.animationFrames.push(frameId)
        } else {
          el.textContent = target
        }
      }

      updateCounter()
    })
  },

  destroyed() {
    // Cancel any running counter animations
    if (this.animationFrames) {
      this.animationFrames.forEach((id) => cancelAnimationFrame(id))
      this.animationFrames = []
    }

    window.removeEventListener("scroll", this.handleScroll)

    // Fixed: was this.observer, should be this.revealObserver
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
    this.resizeTimeout = null

    // Only enable on mobile/tablet (< 1024px)
    const isMobile = window.innerWidth < 1024

    if (isMobile) {
      this.setupObserver()
    }

    // Debounced resize handler
    this.resizeHandler = () => {
      clearTimeout(this.resizeTimeout)
      this.resizeTimeout = setTimeout(() => {
        const nowMobile = window.innerWidth < 1024
        if (nowMobile && !this.observer) {
          this.setupObserver()
        } else if (!nowMobile && this.observer) {
          this.observer.disconnect()
          this.observer = null
        }
      }, 150)
    }

    window.addEventListener("resize", this.resizeHandler)

    // Handle loading state from server
    this.handleEvent("loading_more", () => {
      this.pending = true
    })

    this.handleEvent("loaded_more", () => {
      // Small delay before allowing next load to prevent rapid firing
      setTimeout(() => {
        this.pending = false
      }, 100)
    })
  },

  setupObserver() {
    // Smaller rootMargin for tablet to prevent aggressive loading
    const rootMargin = window.innerWidth < 640 ? "300px" : "150px"

    const options = {
      root: null,
      rootMargin: rootMargin,
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
    if (this.resizeHandler) {
      window.removeEventListener("resize", this.resizeHandler)
    }
    clearTimeout(this.resizeTimeout)
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

    // Store handlers for cleanup
    this.nextBtnHandler = () => {
      this.stopAutoSlide()
      this.nextSlide()
      this.startAutoSlide()
    }

    this.prevBtnHandler = () => {
      this.stopAutoSlide()
      this.prevSlide()
      this.startAutoSlide()
    }

    this.mouseEnterHandler = () => {
      this.stopAutoSlide()
    }

    this.mouseLeaveHandler = () => {
      this.startAutoSlide()
    }

    // Store indicator handlers
    this.indicatorHandlers = []
    this.indicators.forEach((indicator, index) => {
      const handler = () => {
        this.stopAutoSlide()
        this.goToSlide(index)
        this.startAutoSlide()
      }
      this.indicatorHandlers.push({ indicator, handler })
      indicator.addEventListener("click", handler)
    })

    // Event listeners
    this.nextBtn.addEventListener("click", this.nextBtnHandler)
    this.prevBtn.addEventListener("click", this.prevBtnHandler)
    this.el.addEventListener("mouseenter", this.mouseEnterHandler)
    this.el.addEventListener("mouseleave", this.mouseLeaveHandler)

    // Initialize
    this.updateSlide()
    this.startAutoSlide()
  },

  destroyed() {
    this.stopAutoSlide()

    // Clean up event listeners
    if (this.nextBtn && this.nextBtnHandler) {
      this.nextBtn.removeEventListener("click", this.nextBtnHandler)
    }
    if (this.prevBtn && this.prevBtnHandler) {
      this.prevBtn.removeEventListener("click", this.prevBtnHandler)
    }
    if (this.mouseEnterHandler) {
      this.el.removeEventListener("mouseenter", this.mouseEnterHandler)
    }
    if (this.mouseLeaveHandler) {
      this.el.removeEventListener("mouseleave", this.mouseLeaveHandler)
    }
    if (this.indicatorHandlers) {
      this.indicatorHandlers.forEach(({ indicator, handler }) => {
        indicator.removeEventListener("click", handler)
      })
    }
  },
}

// Lazy YouTube video loading hook - improves page load performance
// and prevents loading spinner on return visits
Hooks.LazyYouTube = {
  mounted() {
    const container = this.el
    const videoId = container.dataset.videoId
    const locale = container.dataset.locale || "en"
    let iframeLoaded = false

    // Check if iframe was already loaded in this session
    const sessionKey = `youtube_loaded_${videoId}`
    if (sessionStorage.getItem(sessionKey) === "true") {
      // Video was loaded before, hide placeholder immediately and reload iframe silently
      const placeholder = container.querySelector('.absolute.inset-0')
      if (placeholder) {
        placeholder.style.display = 'none'
      }
      this.loadIframe(videoId, locale, false) // Pass false to skip spinner
      iframeLoaded = true
      return
    }

    // Load iframe on click (for immediate user interaction)
    const clickHandler = () => {
      if (!iframeLoaded) {
        this.showLoadingSpinner()
        this.loadIframe(videoId, locale, true) // Pass true to show spinner
        sessionStorage.setItem(sessionKey, "true")
        iframeLoaded = true
      }
    }
    container.addEventListener("click", clickHandler, { once: true })
    this.clickHandler = clickHandler

    // Use Intersection Observer to auto-load when scrolled into view
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !iframeLoaded) {
            this.showLoadingSpinner()
            this.loadIframe(videoId, locale, true) // Pass true to show spinner
            sessionStorage.setItem(sessionKey, "true")
            iframeLoaded = true
            observer.disconnect()
          }
        })
      },
      { rootMargin: "100px" } // Start loading 100px before video is visible
    )

    observer.observe(container)
    this.observer = observer
  },

  showLoadingSpinner() {
    const container = this.el
    
    // Create loading spinner overlay
    const spinner = document.createElement("div")
    spinner.className = "absolute inset-0 flex items-center justify-center bg-black z-20"
    spinner.id = "youtube-loading-spinner"
    
    // Spinner SVG (YouTube-style)
    spinner.innerHTML = `
      <div class="flex flex-col items-center gap-3">
        <svg class="animate-spin h-12 w-12 text-red-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <p class="text-white/60 text-sm">Loading video...</p>
      </div>
    `
    
    container.appendChild(spinner)
    this.spinner = spinner
  },

  loadIframe(videoId, locale, showSpinner = true) {
    const container = this.el
    const embedUrl = `https://www.youtube.com/embed/${videoId}?hl=${locale}&cc_lang_pref=${locale}&cc_load_policy=1`

    // Create iframe element
    const iframe = document.createElement("iframe")
    iframe.id = `welcome-video-iframe-${videoId}`
    iframe.src = embedUrl
    iframe.className = "absolute inset-0 w-full h-full z-10 opacity-0 transition-opacity duration-300"
    iframe.frameBorder = "0"
    iframe.allow = "autoplay; fullscreen; picture-in-picture; clipboard-write; encrypted-media; web-share"
    iframe.allowFullscreen = true
    iframe.referrerPolicy = "strict-origin-when-cross-origin"
    iframe.title = "Video player"

    // Store reference to placeholder for cleanup
    const placeholder = container.querySelector('.absolute.inset-0')

    // Handle iframe load event
    iframe.addEventListener("load", () => {
      // Fade in iframe
      setTimeout(() => {
        iframe.style.opacity = "1"
      }, 100)
      
      // Remove placeholder/spinner after iframe is visible
      setTimeout(() => {
        // Remove placeholder if it exists
        if (placeholder && placeholder.parentNode) {
          placeholder.remove()
        }
        
        // Remove spinner if it exists
        if (showSpinner && this.spinner && this.spinner.parentNode) {
          this.spinner.remove()
          this.spinner = null
        }
      }, 400)
    })

    // Append iframe to container (alongside existing placeholder)
    container.appendChild(iframe)
    
    // Store iframe reference for cleanup
    this.iframe = iframe
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.clickHandler) {
      this.el.removeEventListener("click", this.clickHandler)
    }
    if (this.spinner && this.spinner.parentNode) {
      this.spinner.remove()
    }
  },
}


const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
// Only show for actual page navigation, not for background events like infinite scroll
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })

let topbarTimeout = null
let topbarSafetyTimeout = null
let pageLoadingStopped = false

window.addEventListener("phx:page-loading-start", (info) => {
  pageLoadingStopped = false

  // Only show topbar for navigation events (kind: "initial" or "redirect")
  // Don't show for patch events or background loading
  if (info.detail && (info.detail.kind === "initial" || info.detail.kind === "redirect")) {
    // Delay showing topbar by 500ms - only show if page takes longer to load
    topbarTimeout = setTimeout(() => {
      // Only show if page hasn't already stopped loading
      if (!pageLoadingStopped) {
        topbar.show()
      }
    }, 500)

    // Safety timeout - force hide after 10 seconds if stop event never fires
    topbarSafetyTimeout = setTimeout(() => {
      topbar.hide()
      pageLoadingStopped = true
    }, 10000)
  }
})

window.addEventListener("phx:page-loading-stop", (_info) => {
  pageLoadingStopped = true

  if (topbarTimeout) {
    clearTimeout(topbarTimeout)
    topbarTimeout = null
  }
  if (topbarSafetyTimeout) {
    clearTimeout(topbarSafetyTimeout)
    topbarSafetyTimeout = null
  }
  topbar.hide()
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// Global handler for welcome video loaders
window.welcomeVideoLoaded = window.welcomeVideoLoaded || {}

function handleWelcomeVideoLoaders() {
  const loaders = document.querySelectorAll(".welcome-video-loader")

  loaders.forEach((loader) => {
    const videoId = loader.dataset.videoId
    if (!videoId) return

    const iframe = document.querySelector(`.welcome-video-iframe[data-video-id="${videoId}"]`)
    if (!iframe) return

    // Check if already loaded in this session
    if (window.welcomeVideoLoaded[videoId]) {
      loader.style.display = "none"
      return
    }

    const hideLoader = () => {
      loader.style.opacity = "0"
      setTimeout(() => {
        loader.style.display = "none"
      }, 300)
      window.welcomeVideoLoaded[videoId] = true
    }

    // Listen for iframe load
    iframe.addEventListener("load", hideLoader, { once: true })

    // Fallback timeout
    setTimeout(hideLoader, 2000)
  })
}

// Run on initial page load
document.addEventListener("DOMContentLoaded", handleWelcomeVideoLoaders)

// Run on LiveView page transitions
window.addEventListener("phx:page-loading-stop", handleWelcomeVideoLoaders)

// ===== Theme Management =====
// Moved from inline script in root.html.heex for AGENTS.md compliance
const setTheme = (theme) => {
  if (theme === "system") {
    localStorage.removeItem("phx:theme")
    document.documentElement.removeAttribute("data-theme")
  } else {
    localStorage.setItem("phx:theme", theme)
    document.documentElement.setAttribute("data-theme", theme)
  }
}

// Initialize theme on page load
if (!document.documentElement.hasAttribute("data-theme")) {
  setTheme(localStorage.getItem("phx:theme") || "dark")
}

// Listen for theme changes from other tabs
window.addEventListener("storage", (e) => {
  if (e.key === "phx:theme") setTheme(e.newValue || "dark")
})

// Listen for theme changes from LiveView
window.addEventListener("phx:set-theme", (e) => {
  setTheme(e.target.dataset.phxTheme)
})

// ===== Navigation Utilities =====
// Moved from inline script in root.html.heex for AGENTS.md compliance

// Ensure page always loads at the top
if ("scrollRestoration" in history) {
  history.scrollRestoration = "manual"
}
window.scrollTo(0, 0)

// Update home icon visibility based on current path
const updateHomeIconVisibility = () => {
  const homeIcon = document.querySelector(".home-icon")
  if (homeIcon) {
    homeIcon.style.visibility = window.location.pathname !== "/" ? "visible" : "hidden"
  }
}

// Update active nav link styling
const updateActiveNavLink = () => {
  const currentPath = window.location.pathname
  document.querySelectorAll(".nav-link").forEach((link) => {
    const navPath = link.dataset.navPath
    if (navPath && currentPath.startsWith(navPath)) {
      link.classList.add("text-base-content", "border-b-2", "border-primary")
      link.classList.remove("text-base-content/70")
    } else {
      link.classList.remove("text-base-content", "border-b-2", "border-primary")
    }
  })
}

// Update footer nav links - hide current page link
const updateFooterNavLinks = () => {
  const currentPath = window.location.pathname
  document.querySelectorAll(".footer-nav-link").forEach((link) => {
    const footerPath = link.dataset.footerPath
    if (footerPath === "/" && currentPath === "/") {
      link.style.display = "none"
    } else if (footerPath !== "/" && currentPath.startsWith(footerPath)) {
      link.style.display = "none"
    } else {
      link.style.display = ""
    }
  })
}

// Mobile menu toggle functionality
// Mobile menu toggle functionality (DaisyUI Drawer)
const initMobileMenu = () => {
  const drawerCheckbox = document.getElementById("mobile-drawer")
  if (!drawerCheckbox) return

  // Close drawer when a link inside the drawer is clicked
  const closeDrawer = () => {
    if (drawerCheckbox.checked) {
      drawerCheckbox.checked = false
    }
  }

  const menuLinks = document.querySelectorAll(".drawer-side a")
  menuLinks.forEach((link) => {
    link.addEventListener("click", closeDrawer)
  })
}

// Run on initial load
updateHomeIconVisibility()
updateActiveNavLink()
updateFooterNavLinks()
initMobileMenu()

// Run on LiveView navigation
window.addEventListener("phx:page-loading-stop", () => {
  window.scrollTo(0, 0)
  updateHomeIconVisibility()
  updateActiveNavLink()
  updateFooterNavLinks()
  initMobileMenu()
})
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
    window.addEventListener("keydown", (event) => (keyDown = event.key))
    window.addEventListener("keyup", () => (keyDown = null))
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

// Service Worker Registration for PWA
if ("serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker
      .register("/sw.js")
      .then((registration) => {
        console.log("Service Worker registered with scope:", registration.scope)
      })
      .catch((error) => {
        console.error("Service Worker registration failed:", error)
      })
  })
}
