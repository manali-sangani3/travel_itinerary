# Developer Handover & Workflow Document

**Project Name:** Travel Itinerary App — V2 Enhancements
**Document Version:** 1.0
**Date:** 2026-06-15
**Author:** Senior Flutter Architect / Development Team
**Status:** Final

---

## 1. Project Overview

### Project Name
Travel Itinerary App — V2 Enhancements

### Business Purpose
The Travel Itinerary App is a cross-platform mobile application that enables travelers to plan, manage, and remember their trips from a single consolidated platform. The V2 release extends the existing V1 feature set with 10 new enhancement modules, eliminating the need for travelers to switch between multiple third-party tools (spreadsheets, weather apps, currency converters, note-taking apps, photo albums).

### Problem Statement
Travelers manage trip logistics — packing lists, document tracking, budget planning, weather monitoring, currency conversion, time zone calculations, and trip memories — across multiple disconnected external tools. This fragmentation increases the risk of missed tasks, budget overruns, forgotten documents, and a poor user experience. Lack of consolidation also reduces daily active usage and user retention of the core travel app.

### Solution Summary
V2 integrates 10 utility and memory features directly into the existing Travel Itinerary app:
1. **Packing Checklist Generator** — smart, type-aware packing list creation
2. **Travel Checklist Templates** — pre-defined packing templates by trip type
3. **Travel Document Checklist** — per-trip document readiness tracking
4. **Itinerary Sharing** — time-limited shareable links with View/Edit roles
5. **Trip Notes and Memories** — timestamped free-text reflections per trip
6. **Weather Forecast Integration** — third-party forecast per itinerary day
7. **Currency Converter** — live/cached exchange rate conversion utility
8. **Time Zone Calculator** — IANA timezone offset and DST utility
9. **Photo Gallery for Trips** — grid gallery organized by location and date
10. **Standalone Budget Tracking** — planned vs. actual category-level budget screen

### Key Features (V1 + V2)
- Secure authentication with JWT and transparent token refresh
- Full trip lifecycle management (planning → active → completed)
- Day-by-day itinerary planner with drag-and-drop reordering
- Booking storage (flights, hotels, car rentals, activities)
- Document upload with role-restricted access
- Role-based collaboration with real-time comments via Socket.IO
- Group expense splitting with net balance calculation
- Travel journal with daily diary entries and geo-tagged photos
- Offline access via local SQLite mirror with auto-sync queue
- All 10 V2 enhancement features listed above

---

## 2. Technology Stack

| Layer          | Technologies                                                                          |
| -------------- | ------------------------------------------------------------------------------------- |
| Frontend       | Flutter 3.x (Dart), BLoC pattern, GetIt (dependency injection), go_router, sqflite, flutter_secure_storage |
| Backend        | Node.js 20+, Express 4, Socket.IO 4, multer (file uploads), Joi (validation), Winston (logging) |
| Database       | SQLite via better-sqlite3 (server-side), sqflite (Flutter client-side mirror)        |
| Auth / Security| JWT (jsonwebtoken), bcryptjs (password hashing), AES-256 encryption (passport data), helmet.js |
| Infrastructure | Local file storage for uploads (`/uploads`), object storage (AWS S3 / Firebase Storage) for photo gallery (configurable), third-party APIs: OpenWeatherMap, ExchangeRatesAPI.io, IANA Timezone Database |
| Testing        | Jest + Supertest (backend, 52 tests), Flutter Test / dart:test (frontend, 46 tests)   |

---

## 3. Architecture Overview

### High-Level Architecture

```
┌──────────────────────────────────────────────┐
│              Flutter Mobile App               │
│  (iOS & Android — single codebase)           │
│                                              │
│  BLoC Pattern (State Management)            │
│  go_router (Navigation)                     │
│  GetIt (Service Locator / DI)               │
│  sqflite (Local SQLite Mirror)              │
│  flutter_secure_storage (JWT Tokens)        │
└──────────────────┬───────────────────────────┘
                   │ REST API (HTTP/HTTPS)
                   │ Socket.IO (Real-time Collaboration)
┌──────────────────▼───────────────────────────┐
│              Node.js / Express API            │
│                                              │
│  JWT Middleware (Auth Guard)                │
│  Helmet.js (Security Headers)               │
│  Multer (File Uploads)                      │
│  Socket.IO Server (Collaboration Events)    │
│  Joi (Request Validation)                   │
│  Winston (Structured Logging)               │
└──────┬─────────────────────┬────────────────┘
       │                     │
┌──────▼──────┐    ┌─────────▼──────────────────┐
│   SQLite DB  │    │  Third-Party APIs / Storage  │
│ (better-sql3)│    │  OpenWeatherMap              │
│ travel.db    │    │  ExchangeRatesAPI.io         │
└─────────────┘    │  IANA Timezone Database      │
                   │  AWS S3 / Firebase Storage   │
                   └──────────────────────────────┘
```

### Request / Data Flow

1. **Flutter App** sends HTTP request with `Authorization: Bearer <JWT>` header.
2. **Express JWT Middleware** validates the token; rejects with 401 if invalid/expired.
3. **Route Handler** dispatches to the appropriate **Controller**.
4. **Controller** invokes the **Service / Repository** layer for business logic and DB access.
5. **SQLite (better-sqlite3)** executes parameterized SQL; results return through the layers.
6. **Response** is serialized as JSON and returned to the Flutter client.
7. **BLoC** on the Flutter side receives the response, emits a new state, and the UI rebuilds.
8. **Real-time events** (collaboration comments) travel via Socket.IO on a per-trip room.

### Major Components

| Component               | Location                     | Responsibility                                    |
| ----------------------- | ---------------------------- | ------------------------------------------------- |
| `TravelItineraryApp`    | `lib/main.dart`              | App entry point, MultiBlocProvider, MaterialApp.router |
| `AppRouter`             | `lib/core/router/app_router.dart` | go_router route definitions                  |
| `AppTheme`              | `lib/core/theme/app_theme.dart`   | Light theme, color palette, typography        |
| `injection.dart`        | `lib/core/di/injection.dart`      | GetIt service locator setup                   |
| Feature BLoCs           | `lib/features/<feature>/presentation/bloc/` | State management per feature     |
| Feature Pages           | `lib/features/<feature>/presentation/pages/` | UI screens                        |
| Express `app.js`        | `backend/src/app.js`         | Express middleware setup and route mounting        |
| Route files             | `backend/src/routes/`        | REST endpoint definitions                         |
| Controllers             | `backend/src/controllers/`   | Request handling and response shaping             |
| Repositories            | `backend/src/repositories/`  | Database queries via better-sqlite3               |
| Services                | `backend/src/services/`      | Business logic, third-party API calls             |
| `schema.js`             | `backend/src/db/schema.js`   | SQLite table definitions and migrations           |

### External Integrations

| Integration           | Purpose                             | Config Key                    |
| --------------------- | ----------------------------------- | ----------------------------- |
| OpenWeatherMap API    | Weather forecast per destination/date | `WEATHER_API_KEY` (`.env`)  |
| ExchangeRatesAPI.io   | Live currency exchange rates        | `EXCHANGE_RATES_API_KEY` (`.env`) |
| IANA Timezone Database| DST-aware timezone offset calculation | Server-side (no API key needed) |
| AWS S3 / Firebase Storage | Photo gallery object storage   | `STORAGE_BUCKET` (`.env`)     |

---

## 4. Project Structure

### Frontend Folder Structure

```
travel_itinerary/
├── lib/
│   ├── main.dart                         # App entry point
│   ├── core/
│   │   ├── constants/                    # App-wide constants (API base URL, keys)
│   │   ├── db/                           # sqflite local database helper
│   │   ├── di/                           # GetIt dependency injection setup
│   │   ├── errors/                       # Failure / Exception classes
│   │   ├── network/                      # HTTP client (Dio/http), interceptors
│   │   ├── router/                       # go_router configuration
│   │   ├── theme/                        # AppTheme, colors, typography
│   │   └── utils/                        # Shared utility functions
│   ├── features/
│   │   ├── auth/                         # Login, Register, Profile (BLoC + Pages)
│   │   ├── bookings/                     # Booking storage (BLoC + Pages)
│   │   ├── budget/                       # Budget tracking (BLoC + Pages)
│   │   ├── collaboration/                # Sharing, tasks, comments (BLoC + Pages)
│   │   ├── documents/                    # Document upload + Document Checklist (V2)
│   │   ├── itinerary/                    # Day planner + Weather cards (BLoC + Pages)
│   │   ├── journal/                      # Diary, Notes, Photo Gallery (BLoC + Pages)
│   │   ├── packing/                      # Packing lists, templates, generator (BLoC + Pages)
│   │   └── trips/                        # Trip CRUD + utilities (BLoC + Pages)
│   └── shared/                           # Shared widgets, extensions, mixins
├── test/
│   └── widget_test.dart                  # Flutter widget tests (46 cases)
├── pubspec.yaml                          # Flutter dependencies
└── pubspec.lock
```

### Backend Folder Structure

```
backend/
├── src/
│   ├── app.js                            # Express app setup, middleware mounting
│   ├── server.js                         # HTTP + Socket.IO server bootstrap
│   ├── config/                           # Config loader (env vars, constants)
│   ├── controllers/                      # Request handlers per domain
│   ├── db/
│   │   └── schema.js                     # SQLite table definitions and INIT
│   ├── middleware/                        # JWT auth, role enforcement, file validation
│   ├── repositories/                     # Database query functions (better-sqlite3)
│   ├── routes/                           # Express Router definitions (19 route files)
│   ├── services/                         # Business logic, external API calls
│   ├── sockets/                          # Socket.IO event handlers (per-trip rooms)
│   └── utils/                            # Shared utility functions (token gen, etc.)
├── tests/                                # Jest test suites (52 test cases)
│   ├── setup.js                          # Test DB setup and teardown
│   ├── auth.test.js
│   ├── trips.test.js
│   ├── itinerary.test.js
│   ├── collaboration.test.js
│   ├── journal.test.js
│   ├── security.test.js
│   └── budget.test.js
├── data/
│   └── travel.db                         # SQLite database file
├── uploads/                              # Local file upload storage
├── .env                                  # Environment variables (DO NOT COMMIT)
├── .env.example                          # Environment variable template
└── package.json
```

### Feature / Module Structure (Flutter)

Each feature follows Clean Architecture conventions:
```
features/<feature>/
├── data/
│   ├── datasources/          # Remote (API) and local (sqflite) data sources
│   ├── models/               # Data transfer objects (JSON serializable)
│   └── repositories/         # Repository implementation
├── domain/
│   ├── entities/             # Business entities (pure Dart classes)
│   ├── repositories/         # Repository interface (abstract)
│   └── usecases/             # Use case classes (single responsibility)
└── presentation/
    ├── bloc/                 # BLoC events, states, and bloc class
    ├── pages/                # Full-screen pages
    └── widgets/              # Reusable UI components for this feature
```

---

## 5. Module Summary

| Module           | Purpose                                                                 | Key Components                                                              | Dependencies                                |
| ---------------- | ----------------------------------------------------------------------- | --------------------------------------------------------------------------- | ------------------------------------------- |
| Auth             | User registration, login, JWT token management, profile management      | `AuthBloc`, `LoginPage`, `RegisterPage`, `ProfilePage`                      | `flutter_secure_storage`, JWT, bcryptjs      |
| Trips            | Trip CRUD, lifecycle management, utility screens (Currency, Timezone)   | `TripsBloc`, `TripListPage`, `CreateTripPage`, `TripDetailPage`             | Auth, `go_router`                            |
| Itinerary        | Day-by-day scheduling, drag-and-drop, weather forecast cards            | `ItineraryBloc`, `WeatherBloc`, `ItineraryPage`, `WeatherCard`              | Trips, OpenWeatherMap API                    |
| Bookings         | Structured booking entry storage (flights, hotels, car rentals)         | `BookingsBloc`, `BookingsPage`, `AddBookingPage`                            | Trips                                        |
| Documents        | File upload, role-restricted access, V2: Document Checklist tab         | `DocumentsBloc`, `DocumentsPage`, `DocumentChecklistBloc`                   | Trips, multer, JWT middleware                |
| Packing          | Custom packing lists, V2: Template Selector, Checklist Generator        | `PackingBloc`, `PackingPage`, `TemplatePickerSheet`, `GenerateListButton`   | Trips, `packing_templates` table             |
| Budget           | Category budgets, multi-currency expense logging, planned vs. actual    | `BudgetBloc`, `BudgetPage`, `AddExpensePage`, `SetBudgetsSheet`             | Trips, `expenses` table, `budget_entries`    |
| Collaboration    | Role-based trip sharing, task assignment, comments, V2: share links     | `SharingBloc`, `SharePage`, Socket.IO rooms                                 | Trips, Auth, `trip_shares` table             |
| Journal          | Diary entries, V2: Trip Notes & Memories, V2: Photo Gallery             | `NotesBloc`, `PhotosBloc`, `NotesPage`, `PhotoGalleryPage`                  | Trips, `trip_notes`, `trip_photos` tables    |
| Core / DI        | GetIt service locator, go_router config, theme, network client           | `injection.dart`, `AppRouter`, `AppTheme`, `ApiClient`                      | All features                                 |

---

## 6. Database Overview

### Server-Side SQLite Tables (`data/travel.db`)

| Entity / Collection   | Purpose                                                                              | Relationships                                         |
| --------------------- | ------------------------------------------------------------------------------------ | ----------------------------------------------------- |
| `users`               | Stores user credentials (hashed password), travel preferences, encrypted passport    | Parent of `trips`, `collaborators`                    |
| `trips`               | Core trip record (destination, dates, purpose, status, `home_currency`)              | Parent of all trip-scoped tables; belongs to `users`  |
| `itinerary_items`     | Day-by-day activities (title, location, time slot, day_date, order)                 | Belongs to `trips`                                    |
| `bookings`            | Flight, hotel, car rental, activity booking records                                  | Belongs to `trips`                                    |
| `documents`           | Uploaded file metadata (path, type, name)                                            | Belongs to `trips`                                    |
| `expenses`            | Multi-currency expense log entries with category                                     | Belongs to `trips`; referenced by budget summary      |
| `budget_entries`      | Per-category planned budget amounts (`category`, `planned`, `currency`)             | Belongs to `trips`                                    |
| `collaborators`       | Trip sharing records with `viewer`/`editor`/`admin` roles                            | Belongs to `trips` and `users`                        |
| `comments`            | Real-time comment threads on itinerary items                                         | Belongs to `itinerary_items`                          |
| `journal_entries`     | Daily diary entries with rich text and photos                                        | Belongs to `trips`                                    |
| `packing_items`       | Custom packing list items with checked state                                         | Belongs to `trips`                                    |
| `pending_sync`        | Write queue for offline mutations awaiting server sync                               | Belongs to `trips`                                    |
| `trip_shares` *(V2)*  | Time-limited share tokens with `viewer`/`editor` roles and expiry timestamps         | Belongs to `trips`; CASCADE delete on trip deletion   |
| `document_checklist` *(V2)* | Per-trip document readiness checklist items (label, `checked` flag)           | Belongs to `trips`; CASCADE delete                    |
| `packing_templates` *(V2)*  | Pre-defined packing templates keyed by trip type with JSON item arrays         | Independent lookup table (seed data)                  |
| `trip_notes` *(V2)*   | Free-text notes/memories per trip with optional `day_date` and `location_tag`        | Belongs to `trips`; CASCADE delete                    |
| `trip_photos` *(V2)*  | Photo metadata (file path, `location_tag`, `date_taken`); binary in object storage  | Belongs to `trips`; CASCADE delete                    |

---

## 7. CRUD Overview

### Authentication

| Endpoint                         | Method | Purpose                                | Auth Required |
| -------------------------------- | ------ | -------------------------------------- | ------------- |
| `/api/v1/auth/register`          | POST   | Create user account                    | No            |
| `/api/v1/auth/login`             | POST   | Issue JWT access + refresh tokens      | No            |
| `/api/v1/auth/refresh`           | POST   | Exchange refresh token for new JWT     | No            |
| `/api/v1/auth/profile`           | GET    | Get current user profile               | Yes           |
| `/api/v1/auth/profile`           | PUT    | Update travel preferences              | Yes           |

### Trips

| Endpoint                         | Method | Purpose                                | Auth Required |
| -------------------------------- | ------ | -------------------------------------- | ------------- |
| `/api/v1/trips`                  | GET    | List all trips for the current user    | Yes           |
| `/api/v1/trips`                  | POST   | Create a new trip                      | Yes           |
| `/api/v1/trips/:id`              | GET    | Get trip details                       | Yes           |
| `/api/v1/trips/:id`              | PUT    | Update trip fields                     | Yes           |
| `/api/v1/trips/:id`              | DELETE | Delete trip and all cascade data       | Yes           |

### Itinerary

| Endpoint                         | Method | Purpose                                | Auth Required |
| -------------------------------- | ------ | -------------------------------------- | ------------- |
| `/api/v1/trips/:id/itinerary`    | GET    | List all itinerary items for a trip    | Yes           |
| `/api/v1/trips/:id/itinerary`    | POST   | Add an itinerary activity              | Yes           |
| `/api/v1/trips/:id/itinerary/:itemId` | PUT | Update an itinerary item          | Yes           |
| `/api/v1/trips/:id/itinerary/:itemId` | DELETE | Remove an itinerary item        | Yes           |

### Budget (V1 + V2 Enhanced)

| Endpoint                         | Method | Purpose                                             | Auth Required |
| -------------------------------- | ------ | --------------------------------------------------- | ------------- |
| `/api/v1/trips/:id/budget`       | GET    | Get planned vs. actual summary with category breakdown | Yes        |
| `/api/v1/trips/:id/budget`       | PUT    | Set per-category planned budget amounts             | Yes           |
| `/api/v1/trips/:id/expenses`     | POST   | Log a new expense entry                             | Yes           |
| `/api/v1/trips/:id/expenses`     | GET    | List all expenses for a trip                        | Yes           |
| `/api/v1/trips/:id/expenses/:expId` | DELETE | Remove an expense entry                          | Yes           |

### V2 — Weather, Currency, Timezone (Utility APIs)

| Endpoint                                   | Method | Purpose                                      | Auth Required |
| ------------------------------------------ | ------ | -------------------------------------------- | ------------- |
| `/api/v1/weather/:destination/:date`       | GET    | Fetch weather forecast (temp, condition, precip) | Yes       |
| `/api/v1/currency/convert`                 | GET    | Convert amount between currencies (`?base=&target=&amount=`) | Yes |
| `/api/v1/timezone/diff`                    | GET    | Return time offset between two IANA zones (`?from=&to=`) | Yes |

### V2 — Itinerary Sharing

| Endpoint                                   | Method | Purpose                                      | Auth Required |
| ------------------------------------------ | ------ | -------------------------------------------- | ------------- |
| `/api/v1/trips/:id/share`                  | POST   | Generate a time-limited share link           | Yes           |
| `/api/v1/trips/:id/share`                  | GET    | List active share links for a trip           | Yes           |
| `/api/v1/trips/:id/share/:shareId`         | DELETE | Revoke a share link                          | Yes           |
| `/api/v1/shares/:token`                    | GET    | Fetch shared trip by token (public endpoint) | No            |

### V2 — Document Checklist

| Endpoint                                         | Method | Purpose                              | Auth Required |
| ------------------------------------------------ | ------ | ------------------------------------ | ------------- |
| `/api/v1/trips/:id/checklist/documents`          | GET    | Get document checklist for a trip   | Yes           |
| `/api/v1/trips/:id/checklist/documents`          | PUT    | Update an item's checked status     | Yes           |

### V2 — Packing Templates & Generator

| Endpoint                                         | Method | Purpose                                      | Auth Required |
| ------------------------------------------------ | ------ | -------------------------------------------- | ------------- |
| `/api/v1/trips/:id/packing/templates`            | GET    | List available packing templates             | Yes           |
| `/api/v1/trips/:id/packing/generate`             | POST   | Generate packing list from a template        | Yes           |

### V2 — Trip Notes

| Endpoint                                         | Method | Purpose                                      | Auth Required |
| ------------------------------------------------ | ------ | -------------------------------------------- | ------------- |
| `/api/v1/trips/:id/notes`                        | POST   | Add a trip note/memory entry                 | Yes           |
| `/api/v1/trips/:id/notes`                        | GET    | List all notes for a trip (desc by date)     | Yes           |
| `/api/v1/trips/:id/notes/:noteId`                | PUT    | Update a specific note                       | Yes           |
| `/api/v1/trips/:id/notes/:noteId`                | DELETE | Delete a specific note                       | Yes           |

### V2 — Photo Gallery

| Endpoint                                         | Method | Purpose                                      | Auth Required |
| ------------------------------------------------ | ------ | -------------------------------------------- | ------------- |
| `/api/v1/trips/:id/photos`                       | GET    | List photos grouped by location or date      | Yes           |
| `/api/v1/trips/:id/photos`                       | POST   | Upload photo with metadata (multipart)       | Yes           |
| `/api/v1/trips/:id/photos/:photoId`              | DELETE | Delete a specific photo                      | Yes           |

### Authentication & Authorization Flow

1. Client sends credentials to `/auth/login`.
2. Server validates, hashes comparison via bcryptjs, returns `accessToken` (15 min) + `refreshToken` (7 days).
3. Client stores tokens in `flutter_secure_storage`.
4. All protected requests include `Authorization: Bearer <accessToken>`.
5. JWT middleware (`middleware/auth.js`) verifies the token signature and expiry.
6. On 401 (token expired), client calls `/auth/refresh` with the refresh token to obtain a new access token — transparent to the user.
7. Role checks on trip-scoped endpoints verify the requesting user's role (`viewer`/`editor`/`admin`) from the `collaborators` table before processing.

---

## 8. Environment & Setup

### Required Environment Variables

| Variable               | Description                                     | Example Value                    |
| ---------------------- | ----------------------------------------------- | -------------------------------- |
| `PORT`                 | Express server port                             | `3000`                           |
| `JWT_SECRET`           | Secret key for access token signing             | `your_jwt_secret_here`           |
| `JWT_EXPIRES_IN`       | Access token expiry duration                    | `15m`                            |
| `JWT_REFRESH_SECRET`   | Secret key for refresh token signing            | `your_refresh_secret_here`       |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token expiry duration                 | `7d`                             |
| `ENCRYPTION_KEY`       | 32-char hex key for AES-256 data encryption     | `32_char_hex_key_here`           |
| `DB_PATH`              | Path to the SQLite database file                | `./data/travel.db`               |
| `UPLOAD_PATH`          | Local path for uploaded file storage            | `./uploads`                      |
| `WEATHER_API_KEY`      | OpenWeatherMap API key (V2)                     | `<your_key>`                     |
| `EXCHANGE_RATES_API_KEY` | ExchangeRatesAPI.io key (V2)                  | `<your_key>`                     |
| `STORAGE_BUCKET`       | Object storage bucket name for photos (V2)      | `travel-photos-bucket`           |

### Installation Steps

#### Prerequisites
- **Flutter SDK** 3.x (stable channel): [flutter.dev](https://flutter.dev)
- **Node.js** 20+ and **npm** 10+
- **Android Studio** or **Xcode** for mobile simulator/emulator

#### Backend Setup

```bash
# 1. Navigate to the backend directory
cd travel_itinerary/backend

# 2. Install Node.js dependencies
npm install

# 3. Copy and configure environment variables
cp .env.example .env
# Edit .env and fill in all required values

# 4. The SQLite database is auto-created on first server start
#    via the schema initialization in src/db/schema.js

# 5. Seed packing templates (if applicable)
#    Templates are auto-seeded on first start if packing_templates table is empty
```

#### Frontend Setup

```bash
# 1. Navigate to the Flutter project directory
cd travel_itinerary/travel_itinerary

# 2. Install Flutter dependencies
flutter pub get

# 3. Update API base URL in core/constants/ to match your backend URL
#    Default: http://localhost:3000/api/v1

# 4. Ensure a connected device/emulator is available
flutter devices
```

### Local Setup — Running the Application

#### Start Backend

```bash
# Development mode (nodemon — auto-restarts on file changes)
cd travel_itinerary/backend
npm run dev

# Production mode
npm start
```

Backend starts on `http://localhost:3000` by default.

#### Start Flutter App

```bash
# Run on connected device or emulator
cd travel_itinerary/travel_itinerary
flutter run

# Run on a specific device
flutter run -d <device_id>
```

### Build Commands

```bash
# Flutter — Android APK (debug)
flutter build apk --debug

# Flutter — Android APK (release)
flutter build apk --release

# Flutter — iOS (release, requires macOS + Xcode)
flutter build ios --release

# Backend — No build step required (Node.js runs directly)
```

---

## 9. Business Workflows

### Workflow 1: User Registration and First Trip

**Purpose:** Onboard a new user and guide them to create their first trip.

**Steps:**
1. User opens the app → navigates to the Register screen.
2. User enters email and password → submits form.
3. Backend validates credentials, hashes password with bcryptjs, creates user record.
4. JWT access and refresh tokens are returned.
5. App stores tokens in `flutter_secure_storage` → navigates to Trip Dashboard.
6. User taps "New Trip" → enters destination, dates, purpose, and companions.
7. Backend creates a trip record and returns the trip ID.
8. App navigates to the Trip Detail screen.

**Validation Rules:**
- Email must be a valid format (Joi validation on backend).
- Password must meet minimum length requirement.
- Trip destination cannot be empty; start date must be before end date.

**Expected Outcome:** User is authenticated and can see their new trip in the dashboard.

---

### Workflow 2: Planning an Itinerary with Weather Forecast

**Purpose:** Allow users to build a day-by-day itinerary and view weather forecasts for each day.

**Steps:**
1. User opens a trip → navigates to the Itinerary tab.
2. User taps "Add Activity" → enters title, location, time slot, and day date.
3. Backend saves the itinerary item.
4. `WeatherBloc` fires `FetchWeather` event with the trip destination and itinerary dates.
5. Backend calls OpenWeatherMap API → returns temperature, condition, and precipitation.
6. `WeatherCard` widget renders inline on each day row in the itinerary timeline.
7. User can drag-and-drop activities to reorder within a day.

**Validation Rules:**
- Activity title is required.
- If the Weather API is unavailable, display "Weather unavailable" with a retry button without blocking the itinerary screen load.

**Expected Outcome:** Itinerary is saved with day-level weather cards visible alongside each activity.

---

### Workflow 3: Budget Planning and Expense Logging

**Purpose:** Help users set a planned budget per category and track actual spending in real time.

**Steps:**
1. User navigates to the Budget tab for a trip.
2. User taps the FAB → "Set Budgets" bottom sheet opens.
3. User enters planned amounts for Lodging, Food, Flights, Activities, and Misc.
4. Backend saves category planned budgets via `PUT /trips/:id/budget`.
5. Budget screen reloads showing planned totals and an empty actual total (donut ring, linear progress bars).
6. User taps "Add Expense" → enters amount, category, currency, and description.
7. `AddExpensePage` calls `POST /trips/:id/expenses` → pops back to `BudgetPage`.
8. `BudgetPage._load()` is triggered → budget summary refreshes with updated actual totals.

**Validation Rules:**
- Planned budget values must be non-negative numbers.
- Expense amount must be a positive number and currency code must be a valid ISO 4217 code.

**Expected Outcome:** Budget screen instantly reflects new expenses; category progress bars update without manual refresh.

---

### Workflow 4: Generating a Packing List from a Template

**Purpose:** Help users quickly build a trip-appropriate packing list.

**Steps:**
1. User navigates to Packing → taps "Use Template."
2. App calls `GET /trips/:id/packing/templates` → displays available templates (Beach Holiday, Business Trip, etc.).
3. User selects a template → taps "Generate List."
4. App calls `POST /trips/:id/packing/generate` with the `templateId`.
5. Backend fetches template items from `packing_templates` table → inserts items into `packing_items` for the trip.
6. Packing screen reloads showing the generated list.
7. User can add, remove, and check off individual items.

**Validation Rules:**
- If no template matches the selected trip type, fallback to "General Travel" template and notify the user.

**Expected Outcome:** A pre-populated, customizable packing list is available within 2 seconds of selection.

---

### Workflow 5: Sharing a Trip Itinerary

**Purpose:** Allow users to share their itinerary with friends or family via a link.

**Steps:**
1. User opens a trip → taps "Share Trip."
2. Sharing screen opens; user selects role (View / Edit) and expiry duration.
3. App calls `POST /trips/:id/share` → backend generates a cryptographically random UUID token, stores it in `trip_shares` with expiry timestamp and role.
4. A shareable URL is returned: `https://<app_domain>/shares/<token>`.
5. User copies the link and shares it externally.
6. Recipient opens the link → app calls `GET /api/v1/shares/:token`.
7. Backend validates token expiry and role → returns trip data scoped to the granted role.
8. Expired tokens return HTTP 410 Gone. Revoked tokens return HTTP 403 Forbidden.

**Validation Rules:**
- Share tokens must be time-limited; expiry is enforced server-side on every request.
- View-only collaborators receive 403 Forbidden if they attempt edit operations (e.g., checking off document checklist items).

**Expected Outcome:** Recipient gains appropriate access (read-only or co-edit) to the trip itinerary.

---

### Workflow 6: Adding Trip Notes and Memories

**Purpose:** Allow users to log free-text reflections and memories per trip day or location.

**Steps:**
1. User opens Trip Detail → navigates to the Notes tab.
2. User taps "Add Note" → enters free-text content, optional day date, and optional location tag.
3. App calls `POST /trips/:id/notes` → backend saves the note with a `created_at` timestamp.
4. Notes list reloads in reverse chronological order.
5. User can tap any note to edit (PUT) or swipe to delete (DELETE).

**Validation Rules:**
- Note content cannot be empty.
- Note content is limited to 2,000 characters; server returns 422 if the limit is exceeded at API level.

**Expected Outcome:** Notes are saved, timestamped, and displayed in chronological order. Each note is individually editable and deletable.

---

### Workflow 7: Uploading and Viewing the Photo Gallery

**Purpose:** Let users organize trip photos in a grid gallery by location and date.

**Steps:**
1. User opens Trip Detail → navigates to the Photo Gallery tab.
2. User taps the upload button → selects an image (JPEG/PNG, max 20 MB) from device.
3. App sends a multipart POST request to `/api/v1/trips/:id/photos` with the file, `locationTag`, and `dateTaken`.
4. Backend validates file type and size via multer, saves file to storage, stores metadata in `trip_photos`.
5. Gallery grid reloads with the new photo.
6. User can toggle grouping between "by Location" and "by Date" using the group-by toggle.
7. Tapping a photo opens a lightbox viewer.
8. Swipe or long-press on a photo → Delete option → calls `DELETE /api/v1/trips/:id/photos/:photoId`.

**Validation Rules:**
- File size must not exceed 20 MB; server returns 413 with a descriptive message.
- Only JPEG and PNG formats are accepted.
- Location tag and date are optional at upload time; users can add them post-upload.

**Expected Outcome:** Photos appear in the grid organized by the selected dimension; lightbox opens on tap; deletion removes the photo immediately.

---

## 10. Security & Error Handling

### Authentication & Authorization
- All API endpoints (except `/auth/register`, `/auth/login`, `/auth/refresh`, `/shares/:token`) require a valid JWT Bearer token.
- JWT tokens expire in 15 minutes; refresh tokens expire in 7 days and are stored securely in `flutter_secure_storage`.
- Role enforcement (viewer / editor / admin) is verified on every trip-scoped API request.
- Share tokens are cryptographically random (UUID v4), time-limited, and scoped to a single role. Revocation immediately invalidates access.

### Sensitive Data Handling
- Passwords are hashed with bcryptjs before storage (never stored in plaintext).
- Passport details and sensitive documents are AES-256 encrypted at rest using the `ENCRYPTION_KEY`.
- Third-party API keys (weather, currency) are stored server-side as environment secrets and never exposed to the client.
- Photo binaries are stored in access-controlled object storage; only pre-signed URLs are returned to clients.

### Validation Strategy
- All incoming request bodies are validated with **Joi** on the backend before processing.
- File uploads are validated by **multer** middleware (type allowlist, size limit 20 MB).
- Client-side validation (character limits, required fields) is performed in Flutter before API calls.

### Error Handling Strategy
- Express errors are caught by a global error handler middleware that returns structured JSON errors with HTTP status codes.
- Backend uses **Winston** for structured logging (all errors and warnings are logged with context).
- Flutter BLoC error states (`Failure` classes) surface user-friendly messages without exposing stack traces.

### Error Scenario Table

| Scenario                                    | Expected Behavior                                                                 |
| ------------------------------------------- | --------------------------------------------------------------------------------- |
| JWT expired                                 | Client auto-calls `/auth/refresh`; if refresh also expired, redirects to Login    |
| Weather API unavailable                     | Display "Weather unavailable" card with a Retry button; itinerary loads normally  |
| Currency rate stale (>24h)                  | Display cached rate with a staleness warning banner                               |
| Share link accessed after expiry            | HTTP 410 Gone with user-friendly "Link expired" page                              |
| Photo upload exceeds 20 MB                  | HTTP 413 with message specifying max size and allowed formats                     |
| Trip note exceeds 2,000 characters          | HTTP 422 with field-level error; client enforces the limit before submission      |
| View-only collaborator attempts edit action | HTTP 403 Forbidden with "Insufficient permissions" message                        |
| Invalid IANA timezone identifier            | HTTP 400 with validation error prompting valid identifier selection               |
| Unsupported currency code                   | HTTP 400 with list of supported ISO 4217 codes                                    |
| Trip deleted with active share links        | All share tokens cascade-deleted; subsequent access returns HTTP 404              |

---

## 11. Testing Overview

| Test Type         | Coverage                                                                               | Tools                     |
| ----------------- | -------------------------------------------------------------------------------------- | ------------------------- |
| Backend Unit/Integration | Authentication, Trips CRUD, Itinerary, Collaboration (sharing/roles), Journal (notes, photos), Budget (category planning, real-time update), Security | Jest + Supertest |
| Frontend Widget   | Auth pages, Trips list/create, Itinerary page (with mock WeatherBloc), Document checklist, Budget page (donut ring, set budgets, add expense), BLoC injection | Flutter Test (dart:test) |

### Test Results (Latest Run)

| Suite                      | Tests  | Status   |
| -------------------------- | ------ | -------- |
| `auth.test.js`             | 8      | Passed   |
| `trips.test.js`            | 9      | Passed   |
| `itinerary.test.js`        | 8      | Passed   |
| `collaboration.test.js`    | 9      | Passed   |
| `journal.test.js`          | 10     | Passed   |
| `security.test.js`         | 4      | Passed   |
| `budget.test.js`           | 4      | Passed   |
| **Backend Total**          | **52** | **PASS** |
| Flutter Widget Tests       | 46     | **PASS** |

### Test Execution Commands

```bash
# Backend tests
cd travel_itinerary/backend
npm test

# Flutter widget tests
cd travel_itinerary/travel_itinerary
flutter test test/widget_test.dart

# Flutter all tests
flutter test
```

### Important Testing Notes
- **BLoC Mocking:** `ItineraryPage` and `BudgetPage` widget tests require `BlocProvider` wrappers for `TripsBloc` and `WeatherBloc` (due to `context.watch<TripsBloc>()` dependencies). Without these, tests will throw a `ProviderNotFoundException`.
- **MockWeatherBloc:** The `close()` method must be stubbed with `Future.value()` to prevent a `TypeError` during widget disposal in tests.
- **Backend Test DB:** The `tests/setup.js` file creates an in-memory SQLite database for each test run; no manual DB setup is required for testing.

---

## 12. Deployment & Operations

### Deployment Process

#### Backend Deployment (Node.js)
1. Provision a Node.js 20+ server (e.g., AWS EC2, Railway, Render, or VPS).
2. Clone the repository and navigate to `backend/`.
3. Run `npm install --production`.
4. Copy `.env.example` to `.env` and fill all production values.
5. Start the server with a process manager: `pm2 start src/server.js --name travel-backend`.
6. Configure a reverse proxy (Nginx/Caddy) with HTTPS termination.
7. The SQLite database file (`data/travel.db`) is auto-initialized on first start.

#### Flutter App Deployment
1. **Android:** Build release APK or AAB (`flutter build apk --release` / `flutter build appbundle`). Upload to the Google Play Console.
2. **iOS:** Build with `flutter build ios --release`. Archive via Xcode and upload to App Store Connect.
3. Update `core/constants/` with the production API base URL before building.

### CI/CD Flow (Recommended)

```
Git Push → CI Pipeline Trigger
├── Backend:   npm install → npm test → Deploy to staging → Run smoke tests → Promote to prod
└── Flutter:   flutter pub get → flutter analyze → flutter test → flutter build → Upload to store
```

### Monitoring & Logging
- **Backend:** Winston logger outputs structured JSON logs. Integrate with a log aggregation service (e.g., Datadog, Logtail, or AWS CloudWatch).
- **Error Tracking:** Integrate Sentry (Flutter SDK + Node.js SDK) for real-time error capture and stack traces.
- **Health Check:** Expose a `GET /health` endpoint returning `{ status: "ok", uptime: <seconds> }` for load balancer health checks.

### Rollback Strategy
- **Backend:** Use `pm2` with the `--update-env` flag; rollback by reverting to the previous release tag with `git checkout <prev_tag>` and `npm install`.
- **Database:** SQLite schema changes must be additive (new columns/tables only). No destructive schema changes without a backup of `data/travel.db`.
- **Flutter:** Google Play and App Store both support staged rollouts and rollbacks to previous builds.

---

## 13. Known Limitations & Future Enhancements

| Type              | Description                                                                                          | Priority |
| ----------------- | ---------------------------------------------------------------------------------------------------- | -------- |
| Limitation        | Photo gallery uses local file storage by default; migration to object storage (S3/Firebase) required for production scale | High     |
| Limitation        | Weather and currency features show cached/offline data when the API is unavailable; freshness is limited to the last successful API call | Medium   |
| Limitation        | Share link access for unauthenticated users requires registration before granting trip access         | Medium   |
| Limitation        | SQLite is not horizontally scalable; migration to PostgreSQL is recommended for multi-instance deployment | High  |
| Future            | Push notifications for weather changes, share link activity, and budget threshold alerts             | Medium   |
| Future            | AI-based itinerary auto-generation from a destination and date range prompt                          | Low      |
| Future            | Real-time collaborative editing with conflict resolution (currently limited to comment threads)      | Low      |
| Future            | Multi-language / localisation support                                                                | Medium   |
| Future            | Web platform support via Flutter Web                                                                  | Low      |
| Future            | User-defined custom packing template creation (V2 supports only pre-defined templates)              | Medium   |
| Future            | Hotel and flight price comparison integration                                                         | Low      |

---

## 14. Troubleshooting Guide

| Issue                                                                 | Resolution                                                                                                 |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Flutter app cannot connect to backend                                 | Verify `API_BASE_URL` in `core/constants/` matches the running backend. For Android emulator, use `10.0.2.2` instead of `localhost`. |
| `ProviderNotFoundException` in widget tests                           | Wrap the widget under test in `BlocProvider<TripsBloc>` and `BlocProvider<WeatherBloc>` with mock instances. |
| `TypeError` on `MockWeatherBloc.close()` in tests                    | Stub `close()` in the mock class: `when(() => mockWeatherBloc.close()).thenAnswer((_) => Future.value());` |
| Backend returns 500 on first start                                    | Verify `.env` file exists and all required variables are set; check that `data/` directory is writable.    |
| Budget screen not reflecting new expense after adding                 | Ensure `AddExpensePage` uses `context.pop()` (not `context.go()`), and `BudgetPage` uses `await context.push()` followed by `_load()`. |
| SQLite `UNIQUE constraint failed: trip_shares.share_token`            | Share token collision (extremely rare); retry token generation on conflict in the repository layer.         |
| Weather cards not appearing on itinerary                              | Verify `WEATHER_API_KEY` is set in `.env`; check backend logs for API call failures.                       |
| Photo upload returns 413                                              | Client is sending a file > 20 MB. Add client-side file size validation before the upload call.             |
| Packing template `Generate List` shows empty list                    | Verify `packing_templates` table has been seeded; check backend logs for template lookup errors.           |
| JWT refresh loop (infinite redirect to login)                         | Verify `JWT_REFRESH_SECRET` in `.env` matches the value used when tokens were originally issued.           |
| Socket.IO collaboration events not received                           | Ensure the Flutter client connects to the Socket.IO server URL (not just the REST base URL). Check CORS config in `app.js`. |

---

## 15. Developer Quick Start

A new developer should be able to start contributing using only the steps below.

### Step 1: Install Dependencies

```bash
# Install Flutter SDK (stable channel)
# https://docs.flutter.dev/get-started/install

# Verify Flutter installation
flutter doctor

# Install Node.js 20+ (via nvm recommended)
nvm install 20
nvm use 20

# Clone the project
git clone <repository_url>
cd travel_itinerary
```

### Step 2: Configure Environment

```bash
# Backend environment setup
cd backend
cp .env.example .env
# Open .env and set:
#   JWT_SECRET, JWT_REFRESH_SECRET, ENCRYPTION_KEY, WEATHER_API_KEY, EXCHANGE_RATES_API_KEY

# Install backend dependencies
npm install
```

### Step 3: Run the Application

```bash
# Terminal 1 — Start the backend API server
cd travel_itinerary/backend
npm run dev
# Server starts at http://localhost:3000

# Terminal 2 — Run the Flutter app
cd travel_itinerary/travel_itinerary
flutter pub get
flutter run
# App launches on the connected device/emulator
```

### Step 4: Execute Tests

```bash
# Backend tests (must pass all 52 before submitting any PR)
cd travel_itinerary/backend
npm test

# Flutter widget tests (must pass all 46 before submitting any PR)
cd travel_itinerary/travel_itinerary
flutter test test/widget_test.dart

# Flutter static analysis (must produce 0 issues)
flutter analyze
```

### Step 5: Build the Project

```bash
# Flutter Android debug build
cd travel_itinerary/travel_itinerary
flutter build apk --debug

# Flutter Android release build
flutter build apk --release

# Flutter iOS release build (macOS only)
flutter build ios --release
```

### Step 6: Deploy the Application

```bash
# Backend — Start with pm2 (production)
cd travel_itinerary/backend
pm2 start src/server.js --name travel-backend

# Flutter — Build and upload Android release to Play Store
flutter build appbundle --release
# Upload .aab file via Google Play Console

# Flutter — Build and upload iOS release to App Store
flutter build ios --release
# Archive and upload via Xcode → Product → Archive → Distribute App
```

---

## Document Revision History

| Version | Date       | Author                        | Changes                                   |
| ------- | ---------- | ----------------------------- | ----------------------------------------- |
| 1.0     | 2026-06-15 | Senior Flutter Architect      | Initial handover document — V2 enhancements |

---

*This document is the single source of truth for onboarding, maintaining, troubleshooting, and extending the Travel Itinerary App. Update this document whenever new features are shipped or architectural decisions are changed.*
