# JavaScript Hooks — Professional Patterns

This document outlines best practices for writing Phoenix LiveView JavaScript hooks that are production-ready, memory-safe, and maintainable.

---

## ✅ Production Readiness Checklist

Before considering a hook production-ready, ensure all of the following:

| Requirement                                         | Description                                                                                 |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| ✅ **Proper `destroyed()` cleanup in all hooks**    | Every hook must have a `destroyed()` callback that cleans up all resources                  |
| ✅ **Event listeners stored and removed**           | All `addEventListener` calls must have corresponding `removeEventListener` in `destroyed()` |
| ✅ **FileReader/async operations properly aborted** | Any pending async operations (FileReader, fetch, etc.) must be aborted on cleanup           |
| ✅ **DOM elements cleaned up**                      | Dynamically created DOM elements must be removed from the document                          |
| ✅ **References nulled for garbage collection**     | All stored references (`this.handler`, `this.observer`, etc.) should be set to `null`       |
| ✅ **No memory leaks**                              | Test by navigating away and back — no orphaned listeners or growing memory                  |

### Quick Self-Check

```javascript
destroyed() {
  // ✅ 1. Event listeners removed?
  // ✅ 2. Window/document listeners removed?
  // ✅ 3. Observers disconnected?
  // ✅ 4. Timeouts/intervals cleared?
  // ✅ 5. Animation frames canceled?
  // ✅ 6. Async operations aborted?
  // ✅ 7. GSAP tweens/ScrollTriggers killed?
  // ✅ 8. Dynamic DOM elements removed?
  // ✅ 9. All references nulled?
}
```

---

## Table of Contents

1. [Hook Lifecycle](#hook-lifecycle)
2. [Event Listener Management](#event-listener-management)
3. [Cleanup in destroyed()](#cleanup-in-destroyed)
4. [ScrollTrigger & GSAP Patterns](#scrolltrigger--gsap-patterns)
5. [Async Operations](#async-operations)
6. [DOM Element Cleanup](#dom-element-cleanup)
7. [Common Anti-Patterns](#common-anti-patterns)
8. [Reference Examples](#reference-examples)

---

## Hook Lifecycle

Every Phoenix LiveView hook has three main lifecycle callbacks:

```javascript
const MyHook = {
  mounted() {
    // Called when element is added to the DOM
    // Initialize here, set up event listeners
  },
  updated() {
    // Called when element's data changes
    // Re-initialize if needed, but avoid duplicates
  },
  destroyed() {
    // Called when element is removed from the DOM
    // CRITICAL: Clean up everything here
  },
};
```

### Best Practice: Use `requestAnimationFrame` for Initialization

Wait for LiveView to settle before initializing animations:

```javascript
mounted() {
  requestAnimationFrame(() => {
    this.initAnimations()
  })
}
```

---

## Event Listener Management

### ❌ Bad: Anonymous Functions

```javascript
// BAD: Cannot be removed later
this.el.addEventListener("click", () => {
  this.doSomething();
});
```

### ✅ Good: Named Handlers

```javascript
// GOOD: Store handler for cleanup
mounted() {
  this.clickHandler = () => {
    this.doSomething()
  }
  this.el.addEventListener("click", this.clickHandler)
}

destroyed() {
  this.el.removeEventListener("click", this.clickHandler)
}
```

### ✅ Good: Multiple Handlers Pattern

```javascript
mounted() {
  this.handlers = []

  this.el.querySelectorAll(".item").forEach((item, index) => {
    const handler = () => this.handleClick(index)
    this.handlers.push({ item, handler })
    item.addEventListener("click", handler)
  })
}

destroyed() {
  this.handlers.forEach(({ item, handler }) => {
    item.removeEventListener("click", handler)
  })
  this.handlers = []
}
```

### Window/Document Listeners

Always clean up global listeners:

```javascript
mounted() {
  this.scrollHandler = () => {
    // Handle scroll
  }
  window.addEventListener("scroll", this.scrollHandler, { passive: true })
}

destroyed() {
  window.removeEventListener("scroll", this.scrollHandler)
}
```

---

## Cleanup in destroyed()

The `destroyed()` callback is **critical** for preventing memory leaks. Follow this checklist:

### Cleanup Checklist

```javascript
destroyed() {
  // 1. Remove event listeners from this.el
  if (this.clickHandler) {
    this.el.removeEventListener("click", this.clickHandler)
  }

  // 2. Remove event listeners from window/document
  if (this.scrollHandler) {
    window.removeEventListener("scroll", this.scrollHandler)
  }

  // 3. Disconnect observers
  if (this.observer) {
    this.observer.disconnect()
  }
  if (this.resizeObserver) {
    this.resizeObserver.disconnect()
  }

  // 4. Clear timeouts and intervals
  if (this.timeout) {
    clearTimeout(this.timeout)
  }
  if (this.interval) {
    clearInterval(this.interval)
  }

  // 5. Cancel animation frames
  if (this.animationFrameId) {
    cancelAnimationFrame(this.animationFrameId)
  }

  // 6. Abort async operations
  if (this.fileReader) {
    this.fileReader.abort()
  }

  // 7. Kill GSAP tweens/ScrollTriggers
  if (this.tween) {
    this.tween.kill()
  }
  if (this.scrollTrigger) {
    this.scrollTrigger.kill()
  }

  // 8. Remove dynamically created DOM elements
  if (this.tooltip && this.tooltip.parentNode) {
    this.tooltip.parentNode.removeChild(this.tooltip)
  }

  // 9. Null out references for garbage collection
  this.el = null
  this.handlers = null
}
```

---

## ScrollTrigger & GSAP Patterns

### Proper GSAP Initialization

```javascript
import gsap from "gsap";
import ScrollTrigger from "gsap/ScrollTrigger";

// Register once at module level
gsap.registerPlugin(ScrollTrigger);

const GSAPScrollReveal = {
  mounted() {
    this.scrollTriggers = [];
    this.tweens = [];

    // Debounced refresh for performance
    this.debouncedRefresh = debounce(() => ScrollTrigger.refresh(), 100);

    // ResizeObserver for layout changes
    this.resizeObserver = new ResizeObserver(() => {
      this.debouncedRefresh();
    });
    this.resizeObserver.observe(this.el);

    requestAnimationFrame(() => {
      this.initAnimations();
    });
  },

  initAnimations() {
    const elements = this.el.querySelectorAll(".gsap-reveal");

    elements.forEach((el, index) => {
      // Prevent double initialization
      if (el.dataset.gsapInit) return;
      el.dataset.gsapInit = "true";

      const tween = gsap.fromTo(
        el,
        { y: 30, autoAlpha: 0 },
        {
          y: 0,
          autoAlpha: 1,
          duration: 0.8,
          scrollTrigger: {
            id: `reveal-${index}`, // For debugging
            trigger: el,
            start: "top 85%",
            toggleActions: "play none none reverse",
          },
        }
      );

      this.tweens.push(tween);
      if (tween.scrollTrigger) {
        this.scrollTriggers.push(tween.scrollTrigger);
      }
    });
  },

  destroyed() {
    // Disconnect resize observer
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
    }

    // Kill all ScrollTriggers
    this.scrollTriggers.forEach((trigger) => trigger.kill());
    this.scrollTriggers = [];

    // Kill all tweens
    this.tweens.forEach((tween) => tween.kill());
    this.tweens = [];
  },
};
```

### Debounce Utility

```javascript
const debounce = (func, wait) => {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
};
```

---

## Async Operations

### FileReader Pattern

```javascript
saveImage(file) {
  const reader = new FileReader()

  // Store for cleanup
  this.fileReader = reader

  reader.onload = (e) => {
    // Guard: Check if component still mounted
    if (!this.el) return

    // Process result
    this.handleImage(e.target.result)

    // Clean up
    this.fileReader = null
  }

  reader.onerror = () => {
    console.error("Failed to read file")
    this.fileReader = null
  }

  reader.readAsDataURL(file)
}

destroyed() {
  if (this.fileReader) {
    this.fileReader.abort()
    this.fileReader = null
  }
}
```

### File Input Pattern

```javascript
selectFile() {
  const input = document.createElement("input")
  input.type = "file"
  input.accept = "image/*"

  // Store for cleanup
  this.fileInput = input

  const changeHandler = () => {
    const file = input.files[0]
    if (file) {
      this.processFile(file)
    }
    // Clean up after use
    input.removeEventListener("change", changeHandler)
    this.fileInput = null
  }

  input.addEventListener("change", changeHandler)
  input.click()
}
```

---

## DOM Element Cleanup

When creating dynamic DOM elements, remove them on cleanup:

```javascript
mounted() {
  // Create tooltip
  this.tooltip = document.createElement("div")
  this.tooltip.className = "tooltip"
  this.el.appendChild(this.tooltip)
}

destroyed() {
  // Remove from DOM
  if (this.tooltip && this.tooltip.parentNode) {
    this.tooltip.parentNode.removeChild(this.tooltip)
  }
  this.tooltip = null
}
```

---

## Common Anti-Patterns

### ❌ Missing destroyed()

```javascript
// BAD: No cleanup
const BadHook = {
  mounted() {
    window.addEventListener("resize", this.handleResize);
  },
  // Missing destroyed() - MEMORY LEAK!
};
```

### ❌ Double Initialization

```javascript
// BAD: No guard against re-init
initAnimations() {
  this.el.querySelectorAll(".item").forEach(el => {
    gsap.to(el, { ... })  // Called multiple times!
  })
}

// GOOD: Guard with data attribute
initAnimations() {
  this.el.querySelectorAll(".item").forEach(el => {
    if (el.dataset.gsapInit) return
    el.dataset.gsapInit = "true"
    gsap.to(el, { ... })
  })
}
```

### ❌ Referencing Dead Elements

```javascript
// BAD: No guard in async callback
reader.onload = () => {
  this.quill.insertEmbed(...)  // this.quill might be null!
}

// GOOD: Guard against unmounted component
reader.onload = () => {
  if (!this.quill) return
  this.quill.insertEmbed(...)
}
```

### ❌ Not Nulling References

```javascript
// BAD: References kept alive
destroyed() {
  this.observer.disconnect()
}

// GOOD: Null out for garbage collection
destroyed() {
  if (this.observer) {
    this.observer.disconnect()
    this.observer = null
  }
}
```

---

## Reference Examples

### Simple Hook Template

```javascript
const SimpleHook = {
  mounted() {
    this.clickHandler = (e) => {
      // Handle click
    };
    this.el.addEventListener("click", this.clickHandler);
  },

  destroyed() {
    if (this.clickHandler) {
      this.el.removeEventListener("click", this.clickHandler);
    }
  },
};
```

### Complete Hook Template

```javascript
const CompleteHook = {
  mounted() {
    // Store all handlers and resources
    this.handlers = [];
    this.observers = [];
    this.timeouts = [];

    // Wait for DOM to settle
    requestAnimationFrame(() => {
      this.init();
    });
  },

  updated() {
    // Re-initialize if needed
    this.init();
  },

  init() {
    // Guard against double init if needed
    if (this.el.dataset.initialized) return;
    this.el.dataset.initialized = "true";

    // Setup logic here
  },

  destroyed() {
    // 1. Remove element listeners
    this.handlers.forEach(({ el, event, handler }) => {
      el.removeEventListener(event, handler);
    });

    // 2. Disconnect observers
    this.observers.forEach((obs) => obs.disconnect());

    // 3. Clear timeouts
    this.timeouts.forEach((id) => clearTimeout(id));

    // 4. Null out references
    this.handlers = null;
    this.observers = null;
    this.timeouts = null;
  },
};
```

---

## Quick Reference Card

| Resource Type         | Store As                | Cleanup Method                               |
| --------------------- | ----------------------- | -------------------------------------------- |
| Element listener      | `this.handler`          | `el.removeEventListener(event, handler)`     |
| Window/doc listener   | `this.handler`          | `window.removeEventListener(event, handler)` |
| IntersectionObserver  | `this.observer`         | `observer.disconnect()`                      |
| ResizeObserver        | `this.resizeObserver`   | `resizeObserver.disconnect()`                |
| MutationObserver      | `this.mutationObserver` | `mutationObserver.disconnect()`              |
| setTimeout            | `this.timeout`          | `clearTimeout(timeout)`                      |
| setInterval           | `this.interval`         | `clearInterval(interval)`                    |
| requestAnimationFrame | `this.frameId`          | `cancelAnimationFrame(frameId)`              |
| GSAP Tween            | `this.tween`            | `tween.kill()`                               |
| ScrollTrigger         | `this.scrollTrigger`    | `scrollTrigger.kill()`                       |
| FileReader            | `this.reader`           | `reader.abort()`                             |
| Dynamic DOM element   | `this.element`          | `element.parentNode.removeChild(element)`    |

---

_Last updated: December 2024_
