// Service worker Budget — réseau d'abord, cache en secours.
// En ligne : toujours la dernière version. Hors ligne : l'app s'ouvre
// quand même (les données vivent déjà dans localStorage, sur l'appareil).
const CACHE = "budget-app-v1";

self.addEventListener("install", () => self.skipWaiting());
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;
  event.respondWith(
    fetch(request)
      .then((response) => {
        if (response.ok) {
          const copy = response.clone();
          caches.open(CACHE).then((cache) => cache.put(request, copy)).catch(() => {});
        }
        return response;
      })
      .catch(() =>
        caches.match(request).then((hit) => hit || caches.match("./"))
      )
  );
});
