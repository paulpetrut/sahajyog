// Service Worker for PWA installability with YouTube caching
const CACHE_NAME = "sahajyog-v1"
const YOUTUBE_CACHE = "youtube-resources-v1"

self.addEventListener("install", (event) => {
  console.log("Service Worker installing...")
  self.skipWaiting()
})

self.addEventListener("activate", (event) => {
  console.log("Service Worker activating...")
  event.waitUntil(
    clients.claim().then(() => {
      // Clean up old caches
      return caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => name !== CACHE_NAME && name !== YOUTUBE_CACHE)
            .map((name) => caches.delete(name))
        )
      })
    })
  )
})

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url)

  // Cache YouTube resources (iframe, player scripts, thumbnails, etc.)
  if (
    url.hostname.includes("youtube.com") ||
    url.hostname.includes("ytimg.com") ||
    url.hostname.includes("googlevideo.com")
  ) {
    event.respondWith(
      caches.open(YOUTUBE_CACHE).then((cache) => {
        return cache.match(event.request).then((cachedResponse) => {
          // Return cached response if available
          if (cachedResponse) {
            console.log("Serving from cache:", url.pathname)
            return cachedResponse
          }

          // Otherwise fetch from network and cache
          return fetch(event.request)
            .then((networkResponse) => {
              // Only cache successful responses
              if (networkResponse && networkResponse.status === 200) {
                cache.put(event.request, networkResponse.clone())
              }
              return networkResponse
            })
            .catch((error) => {
              console.error("Fetch failed for:", url.pathname, error)
              // Return cached response if network fails, even if expired
              return cachedResponse || new Response("Offline", { status: 503 })
            })
        })
      })
    )
  } else {
    // Network-first strategy for everything else
    event.respondWith(
      fetch(event.request).catch(() => {
        return new Response("Offline", { status: 503 })
      })
    )
  }
})
