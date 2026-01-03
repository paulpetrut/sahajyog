import gsap from "gsap"
import ScrollTrigger from "gsap/ScrollTrigger"

// Register ScrollTrigger plugin
gsap.registerPlugin(ScrollTrigger)

// Simple debounce utility for performance
const debounce = (func, wait) => {
  let timeout
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout)
      func(...args)
    }
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
  }
}

const GSAPHero = {
  mounted() {
    this.animatedElements = []
    this.mouseMoveHandler = null

    // Wait for LiveView to settle before initializing
    requestAnimationFrame(() => {
      this.initAnimations()
    })
  },
  updated() {
    this.initAnimations()
  },
  initAnimations() {
    // Check if we've already initialized the hero for this element
    if (this.el.dataset.gsapInit) return
    this.el.dataset.gsapInit = "true"

    const heroElements = this.el.querySelectorAll(".hero-element")
    const orbs = this.el.querySelectorAll(".hero-orb")

    if (heroElements.length === 0) {
      console.warn("[GSAPHero] No .hero-element found, skipping animation")
      return
    }

    // Track animated elements for cleanup
    this.animatedElements = [...heroElements, ...orbs]

    // Use fromTo for more reliable animation - sets initial AND animates to final
    this.heroTween = gsap.fromTo(
      heroElements,
      { autoAlpha: 0, y: 50 },
      {
        y: 0,
        autoAlpha: 1,
        duration: 1,
        stagger: 0.2,
        ease: "power3.out",
      }
    )

    // Floating orbs with mouse parallax
    if (orbs.length > 0) {
      this.orbFloatTween = gsap.to(orbs, {
        y: -20,
        duration: 3,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut",
        stagger: 1,
      })

      this.mouseMoveHandler = (e) => {
        const x = (e.clientX / window.innerWidth - 0.5) * 40
        const y = (e.clientY / window.innerHeight - 0.5) * 40

        gsap.to(orbs, {
          x: x,
          y: y,
          duration: 1,
          ease: "power2.out",
          stagger: 0.1,
        })
      }
      this.el.addEventListener("mousemove", this.mouseMoveHandler)
    }
  },
  destroyed() {
    // Remove event listener
    if (this.mouseMoveHandler) {
      this.el.removeEventListener("mousemove", this.mouseMoveHandler)
    }

    // Kill main tweens
    if (this.heroTween) this.heroTween.kill()
    if (this.orbFloatTween) this.orbFloatTween.kill()

    // Kill any potentially running mouse movement tweens
    if (this.animatedElements && this.animatedElements.length > 0) {
      gsap.killTweensOf(this.animatedElements)
    }

    delete this.el.dataset.gsapInit
  },
}

const GSAPScrollReveal = {
  mounted() {
    this.scrollTriggers = []
    this.tweens = []
    this.revealElements = []

    // Debounced refresh for performance (prevents excessive refresh calls)
    this.debouncedRefresh = debounce(() => ScrollTrigger.refresh(), 100)

    // ResizeObserver for layout changes (better than window resize)
    // Catches content changes, image loads, accordion opens, etc.
    this.resizeObserver = new ResizeObserver(() => {
      this.debouncedRefresh()
    })
    this.resizeObserver.observe(this.el)

    // Wait for LiveView to settle before initializing
    requestAnimationFrame(() => {
      this.initAnimations()
    })
  },
  updated() {
    // Refresh existing triggers before creating new ones
    this.debouncedRefresh()
    this.initAnimations()
  },
  initAnimations() {
    const elements = this.el.querySelectorAll(".gsap-reveal")

    elements.forEach((el, index) => {
      // Avoid double initialization
      if (el.dataset.gsapInit) return
      el.dataset.gsapInit = "true"

      // Track elements for cleanup
      this.revealElements.push(el)

      // Parse delay from data attribute if present (e.g., data-delay="0.1")
      let delay = parseFloat(el.dataset.delay || 0)

      // Parse toggleActions from data attribute
      // Default: "play none none reverse" (plays on enter, reverses on leave)
      let toggleActions = el.dataset.toggleActions || "play none none reverse"

      const tween = gsap.fromTo(
        el,
        { y: 30, autoAlpha: 0 },
        {
          y: 0,
          autoAlpha: 1,
          duration: 0.8,
          delay: delay,
          ease: "power2.out",
          scrollTrigger: {
            id: `reveal-${this.el.id || "unknown"}-${index}`, // Better debugging
            trigger: el,
            start: "top 85%",
            toggleActions: toggleActions,
            markers: false, // Set to true in development for visual debugging
          },
        }
      )

      // Track tween instance
      this.tweens.push(tween)

      // Track ScrollTrigger for cleanup
      if (tween.scrollTrigger) {
        this.scrollTriggers.push(tween.scrollTrigger)
      }
    })
  },
  destroyed() {
    // Disconnect ResizeObserver
    if (this.resizeObserver) {
      this.resizeObserver.disconnect()
      this.resizeObserver = null
    }

    // Kill all ScrollTrigger instances created by this hook
    this.scrollTriggers.forEach((trigger) => trigger.kill())
    this.scrollTriggers = []

    // Kill tracked Tweens
    this.tweens.forEach((t) => t.kill())
    this.tweens = []

    // Kill tweens on reveal elements (cleanup dataset)
    if (this.revealElements.length > 0) {
      gsap.killTweensOf(this.revealElements)
      this.revealElements.forEach((el) => delete el.dataset.gsapInit)
    }
    this.revealElements = []
  },
}

const GSAPCard3D = {
  mounted() {
    this.cardHandlers = []

    // Wait for LiveView to settle
    requestAnimationFrame(() => {
      this.initAnimations()
    })
  },
  updated() {
    this.initAnimations()
  },
  initAnimations() {
    const cards = this.el.querySelectorAll(".gsap-3d-card")

    cards.forEach((card) => {
      if (card.dataset.gsapInit) return
      card.dataset.gsapInit = "true"

      // Variables to store active tweens for this card
      let moveTween = null
      let returnTween = null

      const mouseMoveHandler = (e) => {
        // Disabled for demo3 themed cards if needed via a class
        if (card.classList.contains("disabled-gsap-3d")) return

        const rect = card.getBoundingClientRect()
        const x = e.clientX - rect.left
        const y = e.clientY - rect.top

        const centerX = rect.width / 2
        const centerY = rect.height / 2

        const rotateX = ((y - centerY) / centerY) * -5 // Max 5 deg
        const rotateY = ((x - centerX) / centerX) * 5 // Max 5 deg

        // Kill return tween if mouse moves back in
        if (returnTween) returnTween.kill()
        moveTween = gsap.to(card, {
          rotateX: rotateX,
          rotateY: rotateY,
          duration: 0.5,
          ease: "power1.out",
          transformPerspective: 1000,
          transformStyle: "preserve-3d",
        })
      }

      const mouseLeaveHandler = () => {
        // Kill move tween when mouse leaves
        if (moveTween) moveTween.kill()
        returnTween = gsap.to(card, {
          rotateX: 0,
          rotateY: 0,
          duration: 0.5,
          ease: "power1.out",
        })
      }

      card.addEventListener("mousemove", mouseMoveHandler)
      card.addEventListener("mouseleave", mouseLeaveHandler)

      // Track handlers for cleanup
      this.cardHandlers.push({ card, mouseMoveHandler, mouseLeaveHandler, moveTween, returnTween })
    })
  },
  destroyed() {
    // Remove all event listeners and kill tweens
    this.cardHandlers.forEach(({ card, mouseMoveHandler, mouseLeaveHandler, moveTween, returnTween }) => {
      card.removeEventListener("mousemove", mouseMoveHandler)
      card.removeEventListener("mouseleave", mouseLeaveHandler)
      if (moveTween) moveTween.kill()
      if (returnTween) returnTween.kill()
      gsap.killTweensOf(card) // Backup cleanup
      delete card.dataset.gsapInit
    })
    this.cardHandlers = []
  },
}

const GSAPMagnetic = {
  mounted() {
    this.buttonHandlers = []

    // Wait for LiveView to settle
    requestAnimationFrame(() => {
      this.initAnimations()
    })
  },
  updated() {
    this.initAnimations()
  },
  initAnimations() {
    // Apply to children with class .magnetic-btn, or the element itself if it has the class
    const buttons = this.el.classList.contains("magnetic-btn") ? [this.el] : this.el.querySelectorAll(".magnetic-btn")

    buttons.forEach((btn) => {
      if (btn.dataset.gsapInit) return
      btn.dataset.gsapInit = "true"

      let moveTween = null
      let returnTween = null

      const mouseMoveHandler = (e) => {
        const rect = btn.getBoundingClientRect()
        const x = e.clientX - rect.left - rect.width / 2
        const y = e.clientY - rect.top - rect.height / 2

        // Move button towards mouse (magnetic fill)
        if (returnTween) returnTween.kill()
        moveTween = gsap.to(btn, {
          x: x * 0.3, // Resistance factor
          y: y * 0.3,
          duration: 0.3,
          ease: "power2.out",
        })
      }

      const mouseLeaveHandler = () => {
        if (moveTween) moveTween.kill()
        returnTween = gsap.to(btn, {
          x: 0,
          y: 0,
          duration: 0.5,
          ease: "elastic.out(1, 0.3)", // Elastic snap back
        })
      }

      btn.addEventListener("mousemove", mouseMoveHandler)
      btn.addEventListener("mouseleave", mouseLeaveHandler)

      // Track handlers for cleanup
      this.buttonHandlers.push({ btn, mouseMoveHandler, mouseLeaveHandler, moveTween, returnTween })
    })
  },
  destroyed() {
    // Remove all event listeners and kill tweens
    this.buttonHandlers.forEach(({ btn, mouseMoveHandler, mouseLeaveHandler, moveTween, returnTween }) => {
      btn.removeEventListener("mousemove", mouseMoveHandler)
      btn.removeEventListener("mouseleave", mouseLeaveHandler)
      if (moveTween) moveTween.kill()
      if (returnTween) returnTween.kill()
      gsap.killTweensOf(btn)
      delete btn.dataset.gsapInit
    })
    this.buttonHandlers = []
  },
}

const GSAPSpotlight = {
  mounted() {
    this.mouseMoveHandler = null
    this.initAnimations()
  },
  updated() {
    this.initAnimations()
  },
  initAnimations() {
    // If the container itself is updated, re-attach listener?
    // Usually container is stable. But let's check.
    if (!this.el.dataset.gsapInit) {
      this.el.dataset.gsapInit = "true"
      this.mouseMoveHandler = (e) => {
        const cards = this.el.querySelectorAll(".spotlight-card")
        cards.forEach((card) => {
          const rect = card.getBoundingClientRect()
          const x = e.clientX - rect.left
          const y = e.clientY - rect.top

          card.style.setProperty("--mouse-x", `${x}px`)
          card.style.setProperty("--mouse-y", `${y}px`)
        })
      }
      this.el.addEventListener("mousemove", this.mouseMoveHandler)
    }
  },
  destroyed() {
    if (this.mouseMoveHandler) {
      this.el.removeEventListener("mousemove", this.mouseMoveHandler)
    }
    delete this.el.dataset.gsapInit
  },
}

const GSAPTextReveal = {
  mounted() {
    // Wait for LiveView to fully render content before initializing
    // Use a small timeout to ensure DOM is fully populated
    this.initTimeout = setTimeout(() => {
      this.initAnimation()
    }, 50) // 50ms delay gives LiveView time to render
  },
  initAnimation() {
    const element = this.el
    const text = element.innerText

    // If no text yet, retry once more after a brief delay
    if (!text || text.trim().length === 0) {
      if (!this.retried) {
        this.retried = true
        this.retryTimeout = setTimeout(() => {
          this.initAnimation()
        }, 100)
      }
      // Silent return - no need to warn if we're retrying
      return
    }

    // Store original text for potential restoration
    this.originalText = text

    // Split text into characters manually since SplitText plugin is paid
    const chars = text
      .split("")
      .map((char) => {
        return `<span style="display:inline-block; opacity:0; transform:translateY(20px);">${
          char === " " ? "&nbsp;" : char
        }</span>`
      })
      .join("")

    element.innerHTML = chars

    this.revealTween = gsap.to(element.children, {
      opacity: 1,
      y: 0,
      duration: 1,
      stagger: 0.03,
      ease: "back.out(1.7)",
    })
  },
  destroyed() {
    // Clear any pending timeouts
    if (this.initTimeout) {
      clearTimeout(this.initTimeout)
    }
    if (this.retryTimeout) {
      clearTimeout(this.retryTimeout)
    }
    
    if (this.revealTween) {
      this.revealTween.kill()
    }
    // Fallback cleanup
    if (this.el && this.el.children) {
      gsap.killTweensOf(this.el.children)
    }
  },
}

const GSAPCounter = {
  mounted() {
    const target = parseInt(this.el.dataset.counter, 10)
    this.counterObj = { val: 0 }

    this.counterTween = gsap.to(this.counterObj, {
      val: target,
      duration: 2,
      ease: "power2.out",
      scrollTrigger: {
        id: `counter-${this.el.id || "unknown"}`, // Better debugging
        trigger: this.el,
        start: "top 85%",
        once: true, // Only animate once when entering viewport
        // Note: toggleActions is redundant when once: true is set
      },
      onUpdate: () => {
        this.el.innerText = Math.floor(this.counterObj.val)
      },
    })

    if (this.counterTween.scrollTrigger) {
      this.scrollTrigger = this.counterTween.scrollTrigger
    }
  },
  destroyed() {
    if (this.scrollTrigger) {
      this.scrollTrigger.kill()
    }
    if (this.counterTween) {
      this.counterTween.kill()
    }
    gsap.killTweensOf(this.counterObj)
  },
}

export { GSAPHero, GSAPScrollReveal, GSAPCard3D, GSAPMagnetic, GSAPSpotlight, GSAPTextReveal, GSAPCounter }
