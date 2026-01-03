// Basic Service Worker for PWA installability
const CACHE_NAME = 'sahajyog-v1';

// We don't necessarily need to cache everything for it to be installable,
// but a fetch handler is required.
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(clients.claim());
});

self.addEventListener('fetch', (event) => {
  // Pass-through for now. 
  // You can add caching logic here later for offline support.
  event.respondWith(fetch(event.request));
});
