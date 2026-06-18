# Project Scope v2 — Travel Itinerary App

**Project Name:** Travel Itinerary App — Enhancement Features
**Version:** 2.0
**Date:** 2026-06-15
**Author:** Senior Product Manager

---

---

## OLD SCOPE — Preserved Unchanged from PROJECT_SCOPE.md

> The following scope is carried forward exactly as documented in `PROJECT_SCOPE.md`. No changes have been made.

---

### 1. Included Features

#### Authentication & Profiles
- User registration and login with email and password
- JWT issuance, expiry, and transparent refresh
- Travel preference management
- Encrypted passport details storage

#### Trip Management
- Create, read, update, and delete trips
- Trip fields: destination, dates, purpose, companions
- Trip status lifecycle: planning → active → completed

#### Itinerary Planner
- Day-by-day activity scheduling with title, location, and time slot
- Drag-and-drop reordering of activities
- Visual timeline for daily allocation
- Travel time estimation between consecutive activities

#### Bookings & Documents
- Structured booking entries: flights, hotels, car rentals, activity reservations
- File upload for confirmations, passport copies, and insurance PDFs
- Document access restricted to trip members by role

#### Packing & Checklists
- Custom packing lists per trip
- Pre-travel checklist with persistent completion state

#### Budget Tracking
- Per-category budget setup: accommodation, food, transport, activities, misc
- Multi-currency expense logging using ISO 4217 codes
- Real-time planned vs. actual comparison per category

#### Collaboration
- Trip sharing with role-based access: viewer / editor / admin
- Planning task creation and assignment to collaborators
- Real-time comment threads on itinerary items via Socket.IO
- Shared expense logging and net balance calculation (who owes whom)

#### Travel Journal
- Daily diary entries with rich text
- Photo upload attached to journal entries
- Geo-tagging of photos to activity or location
- Completed-trip visual summary (photo grid + trip stats)

#### Offline Support
- Local SQLite mirror of trips, itinerary items, bookings, and packing lists
- Read access to core data in airplane mode
- Write queue (pending_sync) with auto-sync on reconnection
- Conflict resolution via server timestamp arbitration

---

### 2. Technical Scope (Old)

#### Flutter Client
- iOS and Android support from a single codebase
- Adaptive layouts for phone and tablet
- Offline-capable via sqflite local database
- Secure token storage via flutter_secure_storage

#### Node.js / Express API
- RESTful endpoints for all domain modules
- Socket.IO for real-time collaboration events scoped per trip room
- File upload handling via multer
- JWT middleware for all protected routes
- helmet.js security headers
- Parameterized SQL throughout; no raw string queries

#### SQLite Database
- Single database file on the server (better-sqlite3)
- Local mirror on the client (sqflite)
- Tables: users, trips, itinerary_items, bookings, documents, expenses, collaborators, comments, journal_entries, packing_items, pending_sync

---

### 3. Security Scope (Old)

- HTTPS enforced on all API communication
- Passwords hashed with bcrypt
- Passport details and sensitive documents AES-256 encrypted at rest
- JWT with short expiry; refresh token in secure storage
- Role-based access enforced on every API endpoint
- File type validation on all uploads

---

### 4. Platforms in Scope (Old)

| Platform | Support |
|---|---|
| Android (phone) | Yes |
| Android (tablet) | Yes |
| iOS (phone) | Yes |
| iOS (tablet / iPad) | Yes |
| Web | No |
| Desktop | No |

---

---

## NEW SCOPE — Added in v2 (Based on PRD_v2.md Enhancement Features)

---

## 1. Goal & Problem Statement

* **The Problem:** Travelers manage trip logistics — packing, documents, budgets, weather, currency, time zones, and memories — across multiple disconnected third-party tools, causing fragmentation, missed tasks, and a poor planning experience.
* **The Solution:** Extend the existing Travel Itinerary app with 10 integrated enhancement features that consolidate all travel utility functions into a single platform, eliminating the need for external tools.

---

## 2. Tech Stack

* **Frontend:** Flutter (Dart) — existing single codebase for iOS and Android; new screens added as feature modules
* **Backend & API:** Node.js / Express — 17 new RESTful endpoints; existing JWT middleware and helmet.js security headers applied to all new routes
* **Database & Caching:** SQLite via better-sqlite3 (server); sqflite (client); 5 new tables added; 2 existing tables modified; live/cached exchange rates cached server-side; weather data cached per destination per date
* **Auth / Infra:** JWT (existing); cryptographically random time-limited share tokens (new); object storage provider (e.g., AWS S3 or Firebase Storage) for photo gallery; third-party API keys stored as server-side environment secrets (OpenWeatherMap, ExchangeRatesAPI, IANA Timezone Database)

---

## 3. Existing Features (Reference Only)

> Functionality that already exists and is not being changed in this scope.

| Feature Number | Feature Name | Description |
|---|---|---|
| EF-001 | User Registration & Login | Email/password registration, JWT login, transparent token refresh |
| EF-002 | Profile Management | Travel preferences and encrypted passport details storage |
| EF-003 | Trip Creation & Management | Create/edit/delete trips with destination, dates, purpose, companions; status lifecycle |
| EF-004 | Day-by-Day Itinerary Planning | Activity scheduling with title, location, time slot; drag-and-drop reorder; visual timeline |
| EF-005 | Travel Time Estimation | Estimated travel time between consecutive itinerary activities |
| EF-006 | Booking Storage | Structured entries for flights, hotels, car rentals, activity reservations |
| EF-007 | Document Upload | PDF and image upload (confirmations, passport copies, insurance); role-restricted access |
| EF-008 | Custom Packing Lists | Per-trip packing list with add/check/delete and persistent completion state |
| EF-009 | Budget Tracking (Existing) | Category budgets; multi-currency expense logging; planned vs. actual summary |
| EF-010 | Role-Based Collaboration | Trip sharing with viewer/editor/admin roles; task assignment; real-time comments via Socket.IO |
| EF-011 | Group Expense Splitting | Shared expense logging with net balance (who owes whom) calculation |
| EF-012 | Travel Journal | Daily diary entries with rich text; photo upload and geo-tagging |
| EF-013 | Completed-Trip Summary | Photo grid and trip stats summary for completed trips |
| EF-014 | Offline Support | SQLite local mirror; read in airplane mode; write queue with auto-sync; conflict resolution |

---

## 4. New / Modified Features & Acceptance Criteria

| Feature Number | Type | Feature Name | Description | Acceptance Criteria |
|---|---|---|---|---|
| NF-001 | New | Packing Checklist Generator | Auto-generates a customisable packing list based on trip type (beach, business, hiking, winter, etc.), destination, and duration | GIVEN a trip exists, WHEN user selects a trip type and taps "Generate List," THEN a type-appropriate packing checklist is displayed within 2 seconds and all items are individually customisable |
| NF-002 | New | Travel Checklist Templates | Pre-defined packing templates for Beach Holiday, Business Trip, Backpacking, Winter Vacation, and Road Trip trip types | GIVEN user opens the Packing section, WHEN they select a pre-defined template, THEN template items are loaded and the user can add, remove, or reorder items before saving |
| NF-003 | New | Travel Document Checklist | Structured per-trip checklist for passport, visa, tickets, travel insurance, vaccination certificates, and hotel vouchers with check-off capability | GIVEN a trip exists, WHEN user opens the Document Checklist tab, THEN a pre-populated checklist is displayed; each item can be individually checked off and state persists across sessions |
| NF-004 | New | Itinerary Sharing (Extended) | Time-limited shareable links for friends/family with role-based access (View / Edit); link revocation and expiry enforcement | GIVEN user taps "Share Trip," WHEN they select a role (View/Edit) and generate a link, THEN a time-limited URL is produced; expired links return 410 Gone; revocation invalidates access immediately |
| NF-005 | New | Trip Notes and Memories | Per-trip free-text notes with timestamp, optional day-date, and location tag; full CRUD capability | GIVEN user is on the trip detail screen, WHEN they add a note, THEN it is saved with a creation timestamp, displayed in chronological order, and is editable and deletable |
| NF-006 | New | Weather Forecast Integration | Third-party weather forecast (temperature, condition, precipitation) displayed per itinerary day for the trip destination | GIVEN a trip has future itinerary dates, WHEN user views the itinerary screen, THEN weather data is shown per day; if the API is unavailable, a "Weather unavailable" message is shown with a retry option without blocking the screen |
| NF-007 | New | Currency Converter | In-app conversion between home currency and destination currency using live or cached exchange rates | GIVEN user enters an amount and selects base/target currencies, WHEN they tap Convert, THEN the converted amount, exchange rate, and last-updated timestamp are displayed; cached rates older than 24 hours show a staleness warning |
| NF-008 | New | Time Zone Calculator | Displays local time and UTC offset for two IANA timezone locations with DST awareness | GIVEN user selects two IANA timezone identifiers, WHEN the calculator runs, THEN current local time, UTC offset, and DST status are correctly displayed for both locations |
| NF-009 | New | Photo Gallery for Trips | Dedicated per-trip gallery with grid layout, group-by (location / date) toggle, lightbox viewer, and post-upload metadata tagging | GIVEN a trip has uploaded photos, WHEN user opens the Photo Gallery, THEN photos appear in a grid organised by location and date; tapping a photo opens a lightbox; group-by toggle re-groups correctly |
| NF-010 | New | Trip Budget Tracking (Standalone) | Dedicated budget tracking screen per trip with planned budget, expense logging by category, and planned vs. actual comparison chart | GIVEN a trip budget is configured, WHEN user opens the Budget screen, THEN planned total, actual total, and category breakdown are displayed with visual indicators; logging a new expense updates the summary in the current session |
| MF-001 | Modified | Packing Module | Extended with Checklist Generator (NF-001) and Template Selector (NF-002); existing manual list creation remains unchanged | GIVEN user opens Packing on an existing trip, WHEN they use the manual list flow, THEN behaviour is identical to v1 and no data is lost |
| MF-002 | Modified | Travel Journal | Extended with structured Trip Notes & Memories (NF-005) and dedicated Photo Gallery view (NF-009); existing diary entries and photo tagging unchanged | GIVEN an existing journal entry with photos, WHEN opened post-v2 deployment, THEN content and photo tags display correctly and the new Notes and Gallery sections are additive |
| MF-003 | Modified | Collaboration Module | Extended with guest/friend Itinerary Sharing links (NF-004); existing role-based companion sharing, comments, and task assignment unchanged | GIVEN an existing trip with collaborators, WHEN accessed post-v2 deployment, THEN existing role enforcement is identical to v1 and the new sharing link option is additive |
| MF-004 | Modified | Documents Module | Extended with Travel Document Checklist (NF-003); existing file upload and role-restricted access unchanged | GIVEN an existing document upload, WHEN accessed post-v2 deployment, THEN file is accessible and access restrictions remain enforced; checklist is a new additive tab |
| MF-005 | Modified | Budget Module API | `GET /api/v1/trips/{tripId}/budget` response extended with `plannedTotal`, `actualTotal`, `categoryBreakdown[]`, and `currency` fields for the standalone Budget screen | GIVEN an expense is logged using the existing flow, WHEN the budget API is called, THEN existing category totals are correctly reflected and the new fields are populated without data regression |

---

## 5. UI/UX Standards

* **Theme & Style:** Consistent with the existing app design system — mobile-first, dark-mode-compatible; new screens (Budget, Sharing, Photo Gallery, Utilities) match the existing visual language using the established colour palette, typography, and component library.
* **Layout:** Mobile-first responsive layout; adaptive for phone and tablet form factors; new gallery screen uses a grid layout with lightbox; utility screens (Currency, Timezone) use clean card-based layouts; weather forecast displayed as compact day cards embedded in the itinerary screen; all new interactive elements include appropriate loading and error states.

---

## 6. Out of Scope

* Real-time flight tracking or airline disruption alerts.
* In-app booking or payment processing.
* Social feed or public trip discovery.
* AI-based itinerary auto-generation.
* Hotel and flight price comparison.
* Live collaboration editing (real-time co-editing with conflict resolution).
* Web platform support.
* Desktop platform support.
* Push notifications for weather changes or share link activity.
* Multi-language / localisation support beyond existing implementation.
* User-defined custom packing template creation (only pre-defined templates are in scope).
* Offline support for Weather, Currency Converter, and Time Zone Calculator beyond cached data display.

---
