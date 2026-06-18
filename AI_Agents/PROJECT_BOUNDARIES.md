# Project Boundaries — Travel Itinerary App

---

## What This App Does

- Authenticated trip planning and management
- Day-by-day itinerary scheduling with drag-and-drop
- Centralized bookings, documents, and packing lists
- Multi-currency budget tracking
- Real-time group collaboration with role-based access
- Travel journaling with photos
- Offline access to core trip data

---

## Tech Boundaries

| Layer | Choice |
|---|---|
| Mobile | Flutter (iOS + Android only) |
| Backend | Node.js / Express |
| Database | SQLite (server + client) |
| Real-time | Socket.IO |
| Auth | JWT + bcrypt |

---

## Platform Boundaries

- Mobile only (phone + tablet)
- No web, no desktop

---

## Hard Limits

- No push notifications
- No real-time map or traffic routing
- No offline currency conversion
- No two-factor authentication
- No horizontal scaling (single SQLite instance)
