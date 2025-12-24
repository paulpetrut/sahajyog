import gsap from "gsap"
import ScrollTrigger from "gsap/ScrollTrigger"

gsap.registerPlugin(ScrollTrigger)

const GSAPHero = {
  mounted() {
    this.initAnimations()
  },
  updated() {
    this.initAnimations()
  },
  initAnimations() {
    // Check if we've already initialized the hero for this element
    if (this.el.dataset.gsapInit) return
    this.el.dataset.gsapInit = "true"

    const tl = gsap.timeline()
    
    // Initial state setup is handled by the animation timeline below
    // Set visibility immediately to avoid flash
    gsap.set(this.el.querySelectorAll(".hero-element"), { autoAlpha: 0, y: 50 })
    
    // Sequence
    tl.to(this.el.querySelectorAll(".hero-element"), {
      y: 0,
      autoAlpha: 1,
      duration: 1,
      stagger: 0.2,
      ease: "power3.out"
    })
    
    // Floating orbs with mouse parallax
    const orbs = this.el.querySelectorAll(".hero-orb")
    
    // Base floating animation
    gsap.to(orbs, {
      y: -20,
      duration: 3,
      repeat: -1,
      yoyo: true,
      ease: "sine.inOut",
      stagger: 1
    })

    // Remove existing event listener if any (though updated shouldn't duplicate if we guard init)
    // Ideally we should store the handler to remove it, but given the single-element nature, 
    // we can rely on init guard. 
    this.el.addEventListener("mousemove", (e) => {
      const x = (e.clientX / window.innerWidth - 0.5) * 40
      const y = (e.clientY / window.innerHeight - 0.5) * 40
      
      gsap.to(orbs, {
        x: x, 
        y: y, 
        duration: 1, 
        ease: "power2.out", 
        stagger: 0.1
      })
    })
  }
}

const GSAPScrollReveal = {
  mounted() {
    this.initAnimations()
  },
  updated() {
    this.initAnimations()
  },
  initAnimations() {
    const elements = this.el.querySelectorAll(".gsap-reveal")
    
    elements.forEach(el => {
      // Avoid double initialization
      if (el.dataset.gsapInit) return
      el.dataset.gsapInit = "true"

      // Parse delay from data attribute if present (e.g., data-delay="0.1")
      let delay = parseFloat(el.dataset.delay || 0)
      
      // Parse toggleActions from data attribute, default to stable "play none none none"
      let toggleActions = el.dataset.toggleActions || "play none none none"

      gsap.fromTo(el, 
        { y: 30, autoAlpha: 0 },
        {
          y: 0,
          autoAlpha: 1,
          duration: 0.8,
          delay: delay, // Apply the parsed delay
          ease: "power2.out", 
          scrollTrigger: {
            trigger: el,
            start: "top 85%",
            toggleActions: toggleActions 
          }
        }
      )
    })
    
    // Refresh ScrollTrigger to ensure positions are correct immediately after updates
    ScrollTrigger.refresh()
  }
}

const GSAPCard3D = {
  mounted() {
    this.initAnimations()
  },
  updated() {
    this.initAnimations()
  },
  initAnimations() {
    const cards = this.el.querySelectorAll(".gsap-3d-card")
    
    cards.forEach(card => {
      if (card.dataset.gsapInit) return
      card.dataset.gsapInit = "true"

      card.addEventListener("mousemove", (e) => {
        // Disabled for demo3 themed cards if needed via a class
        if (card.classList.contains("disabled-gsap-3d")) return;

        const rect = card.getBoundingClientRect()
        const x = e.clientX - rect.left
        const y = e.clientY - rect.top
        
        const centerX = rect.width / 2
        const centerY = rect.height / 2
        
        const rotateX = ((y - centerY) / centerY) * -5 // Max 5 deg
        const rotateY = ((x - centerX) / centerX) * 5  // Max 5 deg
        
        gsap.to(card, {
          rotateX: rotateX,
          rotateY: rotateY,
          duration: 0.5,
          ease: "power1.out",
          transformPerspective: 1000,
          transformStyle: "preserve-3d"
        })
      })
      
      card.addEventListener("mouseleave", () => {
        gsap.to(card, {
          rotateX: 0,
          rotateY: 0,
          duration: 0.5,
          ease: "power1.out"
        })
      })
    })
  }
}

const GSAPMagnetic = {
  mounted() {
    this.initAnimations()
  },
  updated() {
    this.initAnimations()
  },
  initAnimations() {
    // Apply to children with class .magnetic-btn, or the element itself if it has the class
    const buttons = this.el.classList.contains("magnetic-btn") 
      ? [this.el] 
      : this.el.querySelectorAll(".magnetic-btn")

    buttons.forEach(btn => {
      if (btn.dataset.gsapInit) return
      btn.dataset.gsapInit = "true"

      btn.addEventListener("mousemove", (e) => {
        const rect = btn.getBoundingClientRect()
        const x = e.clientX - rect.left - rect.width / 2
        const y = e.clientY - rect.top - rect.height / 2
        
        // Move button towards mouse (magnetic fill)
        gsap.to(btn, {
          x: x * 0.3, // Resistance factor
          y: y * 0.3, 
          duration: 0.3,
          ease: "power2.out"
        })
      })

      btn.addEventListener("mouseleave", () => {
        gsap.to(btn, {
          x: 0,
          y: 0,
          duration: 0.5,
          ease: "elastic.out(1, 0.3)" // Elastic snap back
        })
      })
    })
  }
}

const GSAPSpotlight = {
  mounted() {
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
      this.el.addEventListener("mousemove", (e) => {
        const cards = this.el.querySelectorAll(".spotlight-card")
        cards.forEach(card => {
          const rect = card.getBoundingClientRect()
          const x = e.clientX - rect.left
          const y = e.clientY - rect.top
  
          card.style.setProperty("--mouse-x", `${x}px`)
          card.style.setProperty("--mouse-y", `${y}px`)
        })
      })
    }
  }
}

const GSAPTextReveal = {
  mounted() {
    // Split text into characters manually since specific plugin is paid
    const element = this.el
    const text = element.innerText
    const chars = text.split("").map(char => {
      return `<span style="display:inline-block; opacity:0; transform:translateY(20px);">${char === " " ? "&nbsp;" : char}</span>`
    }).join("")
    
    element.innerHTML = chars
    
    gsap.to(element.children, {
      opacity: 1,
      y: 0,
      duration: 1,
      stagger: 0.03,
      ease: "back.out(1.7)"
    })
  }
}

const GSAPCounter = {
  mounted() {
    const target = parseInt(this.el.dataset.counter, 10)
    const obj = { val: 0 }
    
    gsap.to(obj, {
      val: target,
      duration: 2,
      ease: "power2.out",
      scrollTrigger: {
        trigger: this.el,
        start: "top 85%",
        toggleActions: "play none none none",
        once: true
      },
      onUpdate: () => {
        this.el.innerText = Math.floor(obj.val)
      }
    })
  }
}

export { GSAPHero, GSAPScrollReveal, GSAPCard3D, GSAPMagnetic, GSAPSpotlight, GSAPTextReveal, GSAPCounter }
