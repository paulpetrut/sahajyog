# Animation Strategy for Phoenix LiveView

This document summarizes when and how to use different animation tools (CSS, Motion, GSAP) within a Phoenix LiveView application (`Sahajyog`).

## 1. At a Glance: The "When to Use What" Table

| Feature              | **CSS (Tailwind)**                               | **Motion (motion.dev)**                            | **GSAP**                                                     |
| :------------------- | :----------------------------------------------- | :------------------------------------------------- | :----------------------------------------------------------- |
| **Primary Use Case** | **Standard UI** (Hovers, Fades, Dropdowns)       | **Interactive UI** (Springs, Dragging, Reordering) | **Cinematic UI** (Scroll Stories, Intros, Complex Timelines) |
| **Best For**         | entering/leaving the DOM (LiveView `phx-remove`) | Buttons, Lists, Layout Shifts                      | Hero Sections, Landing Pages, Demos                          |
| **Performance**      | 🟢 Best (Compositor Thread)                      | 🟢 Great (WAAPI / Hybrid)                          | 🟡 Good (JS Engine, heavier bundle)                          |
| **Physics support**  | ❌ None (Bezier curves only)                     | ✅ **Excellent** (Springs, Inertia)                | ✅ Good (via Plugins)                                        |
| **Bundle Size**      | 0 KB                                             | ~10 KB                                             | ~25 KB+                                                      |

---

## 2. Deep Dive: The Three Pillars

### A. CSS / Tailwind (The Foundation)

**Use for 80% of your application.**
CSS is the most performant and reliable way to handle elements appearing and disappearing because it integrates natively with LiveView's lifecycle.

- **Key specific use-case**: `phx-remove`. LiveView waits for CSS animations to finish before removing an element from the DOM.
- **Example**:
  ```html
  <!-- Flash Messages / Modals -->
  <div
    phx-mounted-class="opacity-100 scale-100"
    phx-remove-class="opacity-0 scale-95"
    class="transition-all duration-300 opacity-0 scale-95"
  >
    Success!
  </div>
  ```

### B. Motion (The Polish)

**Use for "App-Like" Feel.**
Motion bridges the gap between static web pages and native mobile apps. Use it for anything that needs "weight" or momentum.

- **Key specific use-case**: **Spring Physics** & **Layout Animation**. CSS transitions are linear or curved; Motion springs simulate real-world physics (bouncing, settling).
- **Example**:
  - **Springy Buttons**: Buttons that "squish" naturally when clicked.
  - **Staggered Lists**: Making a list of items appear one-by-one (cascading) without hardcoding CSS delays.
  - **Optimistic UI**: Instantly animating a "Like" button before the server responds to mask latency.
- **Implementation**: Use `phx-hook="MotionHook"`.

### C. GSAP (The Showstopper)

**Use for "Wow" Moments.**
GSAP is overkill for simple UI but is the undisputed king of complex, orchestrated sequences.

- **Key specific use-case**: **Timelines** & **ScrollTrigger**.
  - "Move this box, _then_ spin that circle, _then_ fade in the text, _while_ the user scrolls."
- **Implementation**: Use `phx-hook="GSAPHook"` inside `mounted()`.
- **Warning**: Requires manual cleanup in `destroyed()` to prevent memory leaks.

---

## 3. Special Considerations for LiveView

### The "DOM Patching" Conflict

LiveView updates the DOM from the server. JavaScript animation libraries update the DOM from the client. **They will fight.**

- **Scenario**:
  1. JS animates an element to `opacity: 0.5`.
  2. Server sends a LiveView update.
  3. LiveView re-renders the element, resetting it to `opacity: 1` (default CSS).
- **Solution**: `phx-update="ignore"`
  For complex GSAP/Motion canvases (like the Christmas Tree demo), tell LiveView to **ignore** that container so it doesn't overwrite your JS work.
  ```html
  <div id="christmas-scene" phx-update="ignore">
    <!-- GSAP owns this -->
  </div>
  ```

### Latency Masking (Optimistic UI)

LiveView has a round-trip delay (Server <-> Client). Motion is the best tool to hide this.

- **Strategy**: Trigger the animation _immediately_ on click (via `phx-click`), independent of the server response. The user sees an instant reaction, making the app feel "local."
