# KPI — Travel Itinerary App

---

## 1. Authentication & Profiles

| Acceptance Criteria | Status |
|---|---|
| User can register with email and password | Fail |
| User receives JWT on successful login | Fail |
| Expired JWT refreshes transparently without re-login prompt | Fail |
| Passport details are stored encrypted; plaintext never appears in logs or API responses | Fail |
| User can update travel preferences and changes persist after logout | Fail |
| Invalid credentials return a 401 with no user enumeration leak | Fail |

---

## 2. Trip Management

| Acceptance Criteria | Status |
|---|---|
| User can create a trip with destination, dates, purpose, and companions | Fail |
| Trip status transitions correctly: planning → active → completed | Fail |
| User can edit and delete their own trips | Fail |
| Deleted trip cascades removal of all itinerary items, bookings, and documents | Fail |

---

## 3. Itinerary Planner

| Acceptance Criteria | Status |
|---|---|
| User can add activities with title, location, and time slot to a specific day | Fail |
| Drag-and-drop reorder persists correctly after app restart | Fail |
| Visual timeline renders all day items without overlap or rendering errors | Fail |
| Travel time estimate is shown between consecutive activities | Fail |
| Activity spanning midnight renders correctly across day boundary | Fail |

---

## 4. Bookings & Documents

| Acceptance Criteria | Status |
|---|---|
| User can add flight, hotel, car rental, and activity bookings to a trip | Fail |
| User can upload PDF and image documents (confirmation, passport copy, insurance) | Fail |
| Unsupported file types are rejected with a clear error message | Fail |
| Documents are accessible only to trip members (owner + collaborators) | Fail |
| Viewer-role collaborators cannot access passport document type | Fail |

---

## 5. Packing & Checklists

| Acceptance Criteria | Status |
|---|---|
| User can create and name a packing list per trip | Fail |
| User can add, check, and delete individual packing items | Fail |
| Pre-travel checklist completion state persists between sessions | Fail |

---

## 6. Budget Tracking

| Acceptance Criteria | Status |
|---|---|
| User can set a budget per category (accommodation, food, transport, activities, misc) | Fail |
| User can log expenses with amount, currency, and category | Fail |
| Planned vs. actual summary is accurate per category | Fail |
| Expenses in multiple currencies display correctly in the summary view | Fail |
| Expense logged offline syncs to server on reconnection without duplication | Fail |

---

## 7. Collaboration

| Acceptance Criteria | Status |
|---|---|
| Owner can share a trip and assign viewer / editor / admin role | Fail |
| Viewer cannot edit itinerary, delete items, or upload documents | Fail |
| Editor can modify itinerary and bookings but cannot change collaborator roles | Fail |
| Comment posted by one collaborator appears on co-editor's screen in real time | Fail |
| Owner cannot remove themselves unless another admin exists on the trip | Fail |
| Expense split balances sum to zero across all members | Fail |
| Planning tasks can be created and assigned to collaborators | Fail |
| Removing a collaborator revokes their access immediately | Fail |

---

## 8. Travel Journal

| Acceptance Criteria | Status |
|---|---|
| User can create a daily diary entry with rich text | Fail |
| User can upload and attach photos to a journal entry | Fail |
| Photos are geo-tagged to an activity or location; falls back gracefully when none exists | Fail |
| Completed-trip summary displays photo grid and trip stats | Fail |

---

## 9. Offline Support

| Acceptance Criteria | Status |
|---|---|
| Itinerary, bookings, and packing list are readable in airplane mode | Fail |
| Edits made offline are queued and synced automatically on reconnection | Fail |
| No data is lost when the app reconnects after offline edits | Fail |
| Server timestamp arbitration resolves conflicts; user sees a conflict banner with both versions | Fail |
| Large photo uploads queued offline are sent sequentially, not in parallel, to avoid timeout | Fail |

---

## 10. Security

| Acceptance Criteria | Status |
|---|---|
| All API endpoints reject requests without a valid JWT | Fail |
| All SQL queries use parameterized statements; no raw string interpolation | Fail |
| helmet.js security headers are present on all API responses | Fail |
| Sensitive fields (passport, document files) are AES-256 encrypted at rest | Fail |
| Socket.IO events are scoped to the correct trip room; cross-trip data never leaks | Fail |

---

## 11. Performance

| Acceptance Criteria | Status |
|---|---|
| App launches and reaches the home screen on a mid-range Android device without perceptible delay | Fail |
| Core trip and itinerary API endpoints respond without perceptible delay under normal load | Fail |
| Document upload completes within a reasonable time on a standard mobile connection | Fail |
| Drag-and-drop interaction is smooth with no visible frame drops | Fail |

---

## 12. Responsiveness

| Acceptance Criteria | Status |
|---|---|
| All screens render correctly on phone (small) and tablet (large) form factors | Fail |
| No UI element overflows or clips on any supported screen size | Fail |
| Timeline and drag-drop interactions are fully usable on tablet layout | Fail |
