// Service Worker for PWA installability
const CACHE_NAME = "sahajyog-v1"

self.addEventListener("install", (event) => {
  console.log("Service Worker installing...")
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  console.log("Service Worker activating...")
  event.waitUntil(clients.claim())
})

self.addEventListener("fetch", (event) => {
  // Network-first strategy with fallback
  event.respondWith(
    fetch(event.request).catch(() => {
      // Could add offline fallback here
      return new Response("Offline", { status: 503 })
    })
  )
})
