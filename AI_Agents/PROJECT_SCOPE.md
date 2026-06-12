# Project Scope — Travel Itinerary App

---

## 1. Included Features

### Authentication & Profiles
- User registration and login with email and password
- JWT issuance, expiry, and transparent refresh
- Travel preference management
- Encrypted passport details storage

### Trip Management
- Create, read, update, and delete trips
- Trip fields: destination, dates, purpose, companions
- Trip status lifecycle: planning → active → completed

### Itinerary Planner
- Day-by-day activity scheduling with title, location, and time slot
- Drag-and-drop reordering of activities
- Visual timeline for daily allocation
- Travel time estimation between consecutive activities

### Bookings & Documents
- Structured booking entries: flights, hotels, car rentals, activity reservations
- File upload for confirmations, passport copies, and insurance PDFs
- Document access restricted to trip members by role

### Packing & Checklists
- Custom packing lists per trip
- Pre-travel checklist with persistent completion state

### Budget Tracking
- Per-category budget setup: accommodation, food, transport, activities, misc
- Multi-currency expense logging using ISO 4217 codes
- Real-time planned vs. actual comparison per category

### Collaboration
- Trip sharing with role-based access: viewer / editor / admin
- Planning task creation and assignment to collaborators
- Real-time comment threads on itinerary items via Socket.IO
- Shared expense logging and net balance calculation (who owes whom)

### Travel Journal
- Daily diary entries with rich text
- Photo upload attached to journal entries
- Geo-tagging of photos to activity or location
- Completed-trip visual summary (photo grid + trip stats)

### Offline Support
- Local SQLite mirror of trips, itinerary items, bookings, and packing lists
- Read access to core data in airplane mode
- Write queue (pending_sync) with auto-sync on reconnection
- Conflict resolution via server timestamp arbitration

---

## 2. Technical Scope

### Flutter Client
- iOS and Android support from a single codebase
- Adaptive layouts for phone and tablet
- Offline-capable via sqflite local database
- Secure token storage via flutter_secure_storage

### Node.js / Express API
- RESTful endpoints for all domain modules
- Socket.IO for real-time collaboration events scoped per trip room
- File upload handling via multer
- JWT middleware for all protected routes
- helmet.js security headers
- Parameterized SQL throughout; no raw string queries

### SQLite Database
- Single database file on the server (better-sqlite3)
- Local mirror on the client (sqflite)
- Tables: users, trips, itinerary_items, bookings, documents, expenses, collaborators, comments, journal_entries, packing_items, pending_sync

---

## 3. Security Scope

- HTTPS enforced on all API communication
- Passwords hashed with bcrypt
- Passport details and sensitive documents AES-256 encrypted at rest
- JWT with short expiry; refresh token in secure storage
- Role-based access enforced on every API endpoint
- File type validation on all uploads

---

## 4. Platforms in Scope

| Platform | Support |
|---|---|
| Android (phone) | Yes |
| Android (tablet) | Yes |
| iOS (phone) | Yes |
| iOS (tablet / iPad) | Yes |
| Web | No |
| Desktop | No |
