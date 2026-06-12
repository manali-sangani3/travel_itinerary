# Product Requirements Document — Travel Itinerary App

---

## 1. Problem Statement

Travelers manage trip logistics across disconnected tools — notes apps, spreadsheets, email threads, and messaging groups. This causes:

- Lost booking confirmations and documents
- No single view of a day's schedule or budget
- Poor group coordination (split expenses, shared plans)
- No access to plans when offline (flights, remote areas)
- Memories scattered across device photo libraries with no trip context

---

## 2. Solution Overview

A Flutter mobile app backed by a Node.js/Express API and SQLite that centralizes the full travel lifecycle — from planning to journaling — under one authenticated account.

| Pillar | What it delivers |
|---|---|
| Secure accounts | Auth-gated access; encrypted sensitive documents |
| Itinerary planner | Drag-and-drop day builder with visual timeline |
| Logistics hub | Bookings, documents, packing lists in one place |
| Budget tracker | Multi-currency spend vs. plan, per category |
| Collaboration | Shared itineraries, tasks, comments, expense splits |
| Travel journal | Photo + diary entries tagged to locations |
| Offline access | Core itinerary readable with no internet |

---

## 3. User Flow

### 3.1 Auth
```
Register → verify email → login → JWT issued
→ Profile setup (preferences, passport details)
→ Token refresh on expiry
```

### 3.2 Trip Lifecycle
```
Create trip (destination, dates, purpose, companions)
→ Add itinerary items per day (drag to reorder)
→ Attach bookings (flight / hotel / car / activity)
→ Upload documents (confirmation, passport copy, insurance)
→ Build packing list + pre-travel checklist
→ Set category budgets → log expenses during trip
→ Write journal entries + upload photos
→ View completed-trip summary
```

### 3.3 Collaboration
```
Owner shares trip → assign role (viewer / editor / admin)
→ Collaborators view / edit per role
→ Comment on itinerary items (real-time via Socket.IO)
→ Log shared expenses → app calculates net balances
→ Assign planning tasks to members
```

### 3.4 Offline
```
App syncs trip data to local SQLite on connectivity
→ User boards flight / loses signal
→ Reads itinerary, bookings, documents offline
→ Any writes queued in pending_sync table
→ Auto-sync on reconnect (last-write-wins, server timestamp wins conflict)
```

---

## 4. API Design

### Auth
| Method | Endpoint | Description |
|---|---|---|
| POST | `/auth/register` | Create account |
| POST | `/auth/login` | Return JWT + refresh token |
| POST | `/auth/refresh` | Rotate JWT |
| GET/PUT | `/auth/profile` | Read / update preferences, passport |

### Trips
| Method | Endpoint | Description |
|---|---|---|
| GET | `/trips` | List user's trips |
| POST | `/trips` | Create trip |
| GET/PUT/DELETE | `/trips/:id` | Read / update / delete |

### Itinerary
| Method | Endpoint | Description |
|---|---|---|
| GET | `/trips/:id/itinerary` | All items for trip |
| POST | `/trips/:id/itinerary` | Add item |
| PUT | `/trips/:id/itinerary/:itemId` | Update item |
| PUT | `/trips/:id/itinerary/reorder` | Batch reorder (drag-drop) |
| DELETE | `/trips/:id/itinerary/:itemId` | Remove item |

### Bookings
| Method | Endpoint | Description |
|---|---|---|
| GET/POST | `/trips/:id/bookings` | List / add booking |
| PUT/DELETE | `/trips/:id/bookings/:bookingId` | Update / delete |

### Documents
| Method | Endpoint | Description |
|---|---|---|
| POST | `/trips/:id/documents` | Upload file (multipart) |
| GET | `/trips/:id/documents` | List documents |
| GET | `/trips/:id/documents/:docId` | Download file |
| DELETE | `/trips/:id/documents/:docId` | Delete |

### Budget
| Method | Endpoint | Description |
|---|---|---|
| GET/PUT | `/trips/:id/budget` | Category budgets |
| GET/POST | `/trips/:id/expenses` | List / log expense |
| DELETE | `/trips/:id/expenses/:expId` | Remove expense |
| GET | `/trips/:id/budget/summary` | Planned vs. actual per category |

### Collaboration
| Method | Endpoint | Description |
|---|---|---|
| POST | `/trips/:id/collaborators` | Share trip with user |
| PUT/DELETE | `/trips/:id/collaborators/:userId` | Change role / remove |
| GET/POST | `/trips/:id/tasks` | List / create task |
| PUT | `/trips/:id/tasks/:taskId` | Update / assign task |
| GET/POST | `/itinerary/:itemId/comments` | List / post comment |
| GET | `/trips/:id/expenses/splits` | Net balance per member |

### Journal
| Method | Endpoint | Description |
|---|---|---|
| GET/POST | `/trips/:id/journal` | List / create entry |
| PUT/DELETE | `/trips/:id/journal/:entryId` | Edit / delete |
| POST | `/trips/:id/journal/:entryId/photos` | Upload photo |

### Socket.IO Events
| Event | Direction | Payload |
|---|---|---|
| `join_trip` | client → server | `{ tripId }` |
| `comment:new` | server → room | `{ itemId, comment }` |
| `task:updated` | server → room | `{ taskId, changes }` |
| `expense:added` | server → room | `{ expense }` |
| `itinerary:reordered` | server → room | `{ dayIndex, order }` |

---

## 5. Edge Cases

| Area | Case | Handling |
|---|---|---|
| Auth | Expired JWT on offline launch | Read-only local SQLite; prompt re-auth on reconnect |
| Auth | Passport details update | Re-encrypt with new key derivation; invalidate old sessions |
| Itinerary | Drag-drop conflict (two editors simultaneously) | Socket.IO broadcasts reorder; last `updated_at` wins |
| Itinerary | Activity end time > midnight | Store as ISO 8601 datetime, not time-only; span renders across day boundary |
| Booking | Duplicate flight number entry | Warn user; allow override (same flight, different leg) |
| Documents | Unsupported file type upload | Reject at multer middleware; return 415 with allowed types |
| Documents | Passport copy access by viewer role | Documents endpoint checks `collaborators.role`; viewer blocked from passport doc_type |
| Budget | Expense in unknown currency | Accept any ISO 4217 code; flag unknown codes in summary |
| Budget | Expense logged offline | Queued in `pending_sync`; server deduplicates by client-generated UUID |
| Collaboration | Owner removes self | Blocked unless another admin exists on the trip |
| Collaboration | Shared trip deleted by owner | Cascade removes collaborators; notify via Socket.IO `trip:deleted` event |
| Offline | Conflicting edits during offline period | Server timestamp arbitration; client shows conflict banner with both versions |
| Offline | Large photo upload queued offline | Queue stores file path; uploads sequentially on reconnect, not in parallel |
| Journal | Photo geo-tag missing | Falls back to activity location linked to the entry; null if none |

---

## 6. KPIs (Success Metrics / Acceptance Criteria)

### Auth & Onboarding
- [ ] Registration → first trip created in < 3 minutes for new user
- [ ] Login succeeds with valid credentials; JWT expires and refreshes transparently
- [ ] Passport details stored encrypted; plaintext never logged

### Itinerary
- [ ] Drag-and-drop reorder persists correctly after app restart
- [ ] Timeline renders all items for a day without overlap errors
- [ ] Travel time estimate shown between consecutive activities

### Offline
- [ ] Itinerary, bookings, and packing list readable with airplane mode enabled
- [ ] Edits made offline sync within 10 seconds of reconnection
- [ ] Zero data loss on sync (pending_sync table fully flushed)

### Budget
- [ ] Planned vs. actual summary accurate to 2 decimal places per category
- [ ] Multi-currency expenses converted correctly in summary view

### Collaboration
- [ ] Comment from one collaborator appears on co-editor's screen in < 2 seconds (Socket.IO)
- [ ] Expense split balances sum to zero across all members
- [ ] Viewer role cannot edit, delete, or upload documents

### Performance
- [ ] API p95 response time < 300 ms on core trip/itinerary endpoints
- [ ] Flutter app cold start < 2 seconds on mid-range Android device
- [ ] Document upload (< 10 MB) completes in < 5 seconds on LTE

### Quality
- [ ] No JWT or passport data appears in server logs
- [ ] All SQL queries use parameterized statements (no raw string interpolation)

---

## 7. Limitations

| Limitation | Detail |
|---|---|
| Single-server SQLite | SQLite does not support concurrent writes at scale; horizontal scaling requires migration to PostgreSQL |
| No real-time map routing | Travel time uses haversine (straight-line); does not account for traffic or transit modes |
| Currency conversion | Rates fetched on-demand from a third-party API; no offline conversion for new expenses |
| File storage | Documents stored on local filesystem; no CDN or redundancy — single point of failure for uploads |
| Offline writes scope | Complex operations (new collaboration invite, expense split recalculation) blocked offline; only simple CRUD queued |
| Push notifications | No push notification system defined; group collaboration alerts require app to be open (Socket.IO only) |
| No 2FA | Auth relies on email + password only; no TOTP or hardware key support |
| Photo storage | Photos stored server-side with no compression pipeline; large libraries will grow disk usage rapidly |
