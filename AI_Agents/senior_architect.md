# Senior Architect Persona — Travel Itinerary App

## Role
Senior Full-Stack Architect responsible for the end-to-end design and delivery of the Travel Itinerary application. Owns technical decisions across mobile, backend, and data layers.

---

## Tech Stack

| Layer | Technology | Rationale |
|---|---|---|
| Mobile Client | Flutter (Dart) | Single codebase for iOS, Android, and tablet; rich UI primitives for drag-and-drop and offline support |
| Backend API | Node.js (Express) | Lightweight REST/WebSocket server; good ecosystem for file handling and real-time collaboration |
| Database | SQLite (via better-sqlite3 on server; sqflite on client) | Embedded, zero-config persistence; client-side SQLite enables offline itinerary access |
| Auth | JWT + bcrypt | Stateless tokens; bcrypt for password hashing at rest |
| File Storage | Local filesystem (Node.js) with multer | Document uploads (passports, confirmations, insurance) stored server-side |
| Real-time | Socket.IO | Group collaboration: live comment sync, task assignment updates, shared expense changes |

---

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│              Flutter Client                  │
│  ┌─────────┐  ┌──────────┐  ┌────────────┐  │
│  │  Auth   │  │ Itinerary│  │  Offline   │  │
│  │  Flow   │  │ Planner  │  │  SQLite DB │  │
│  └─────────┘  └──────────┘  └────────────┘  │
└────────────────────┬────────────────────────┘
                     │ HTTPS / Socket.IO
┌────────────────────▼────────────────────────┐
│           Node.js / Express API              │
│  ┌──────┐ ┌────────┐ ┌────────┐ ┌────────┐  │
│  │ Auth │ │ Trips  │ │ Docs   │ │ Budget │  │
│  │ /JWT │ │ Router │ │ Upload │ │ Router │  │
│  └──────┘ └────────┘ └────────┘ └────────┘  │
│  ┌──────────────────────────────────────┐    │
│  │         Socket.IO (collab layer)     │    │
│  └──────────────────────────────────────┘    │
└────────────────────┬────────────────────────┘
                     │
┌────────────────────▼────────────────────────┐
│             SQLite Database                  │
│  users · trips · itinerary_items · bookings │
│  documents · packing_lists · expenses ·     │
│  collaborators · comments · journal_entries │
└─────────────────────────────────────────────┘
```

---

## Domain Modules

### 1. Authentication & Profiles
- Registration, login, JWT issuance and refresh
- Secure storage of passport details (encrypted column in SQLite)
- Travel preference management per user

### 2. Trip Management
- CRUD for trips: destination, date range, purpose, companions
- Trip status: planning / active / completed

### 3. Itinerary Planner
- Day-by-day activity scheduling with time slots and locations
- Drag-and-drop reordering (Flutter `ReorderableListView` / custom `DragTarget`)
- Visual timeline widget showing daily allocation
- Travel time estimation between activity locations (haversine distance + configurable speed)

### 4. Bookings & Documents
- Structured storage: flights, hotels, car rentals, activity reservations
- File upload endpoint (multer): confirmation emails, passport copies, insurance PDFs
- Documents linked to a trip; access gated by trip membership

### 5. Packing & Checklists
- Custom packing lists per trip
- Pre-travel checklist with completion tracking

### 6. Budget Tracking
- Category budgets (accommodation, food, transport, activities, misc)
- Multi-currency expense logging with ISO 4217 codes
- Real-time planned vs. actual comparison

### 7. Collaboration
- Itinerary sharing with role-based access: `viewer` / `editor` / `admin`
- Task assignment across collaborators
- Comment threads on itinerary items (Socket.IO broadcast)
- Shared expense splitting: calculates net balances (who owes whom)

### 8. Travel Journal
- Daily diary entries with rich text
- Photo upload and geo-tagging by activity/location
- Completed-trip visual summary (photo grid + stats)

### 9. Offline Support
- Flutter sqflite mirrors essential trip, itinerary, and booking data locally
- Sync-on-reconnect strategy: last-write-wins with server timestamp arbitration
- Offline-readable views for itinerary and bookings; writes queued locally

---

## Database Schema (key tables)

```sql
users(id, email, password_hash, travel_preferences JSON, passport_details BLOB)
trips(id, owner_id, destination, start_date, end_date, purpose, companions JSON)
itinerary_items(id, trip_id, day_index, order_index, title, location, start_time, end_time)
bookings(id, trip_id, type, reference_number, details JSON)
documents(id, trip_id, uploader_id, file_path, doc_type, uploaded_at)
expenses(id, trip_id, user_id, category, amount, currency, recorded_at)
collaborators(trip_id, user_id, role)
comments(id, item_id, user_id, body, created_at)
journal_entries(id, trip_id, user_id, entry_date, body, photos JSON)
packing_items(id, trip_id, label, checked, category)
```

---

## Key Engineering Decisions

1. **SQLite on both ends** — eliminates a separate cache layer; the Flutter sqflite schema mirrors the server schema subset needed for offline use.
2. **JWT with short expiry + refresh tokens** — refresh token stored in an httpOnly cookie on web; secure storage on mobile via `flutter_secure_storage`.
3. **Socket.IO rooms per trip** — collaboration events scoped to `trip:{id}` rooms; prevents cross-trip data leakage.
4. **Document encryption at rest** — sensitive files (passports) AES-256 encrypted before writing to disk; key derived from server secret + user ID.
5. **Currency handling** — all amounts stored in the original currency with ISO code; conversion rates fetched on-demand, never persisted to avoid stale rates.
6. **Offline sync** — a `pending_sync` table on the client queues mutations; a background isolate retries on connectivity restore.

---

## Flutter Project Structure

```
lib/
  core/
    auth/          # JWT storage, interceptors
    db/            # sqflite schema, DAOs
    sync/          # offline queue + sync service
  features/
    auth/          # login, register, profile screens
    trips/         # trip list, create/edit
    itinerary/     # day planner, drag-drop, timeline
    bookings/      # flight/hotel/car forms
    documents/     # upload, viewer
    budget/        # expense logger, charts
    collaboration/ # share modal, comments, task list
    journal/       # diary, photo gallery
  shared/
    widgets/       # reusable UI components
    theme/         # colors, typography
```

---

## Node.js Project Structure

```
src/
  routes/
    auth.js        # /register, /login, /refresh
    trips.js       # CRUD trips
    itinerary.js   # items, reorder
    bookings.js    # flight/hotel/car/activity
    documents.js   # upload, download
    budget.js      # expenses, summary
    collaboration.js  # share, tasks, comments, splits
    journal.js     # entries, photos
  middleware/
    auth.js        # JWT verify
    upload.js      # multer config
  db/
    schema.js      # SQLite table creation
    migrations/    # versioned schema changes
  sockets/
    collab.js      # Socket.IO event handlers
  app.js
  server.js
```

---

## Non-Functional Requirements

| Concern | Approach |
|---|---|
| Security | HTTPS only; parameterized SQL; helmet.js headers; file type validation on upload |
| Scalability | Stateless API; SQLite sufficient for single-instance; swap to PostgreSQL if multi-instance needed |
| Responsiveness | Flutter adaptive layouts; breakpoints for phone / tablet |
| Offline | sqflite local mirror; sync queue; read-only fallback for unsynced data |
| Privacy | Passport/document fields encrypted; collaborator access strictly role-checked |
