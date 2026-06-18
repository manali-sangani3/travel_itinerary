# KPI v2 — Travel Itinerary App

**Project Name:** Travel Itinerary App — Enhancement Features
**Version:** 2.0
**Date:** 2026-06-15
**Author:** Senior Product Manager

---

## STEP – MODULE CHANGE ANALYSIS

### Existing Modules / Features (Reference Only)

> KPIs for these modules are preserved unchanged from KPI v1. No new KPIs are generated unless the module is being modified.

| Module        | Current Functionality                                                                                     |
| ------------- | --------------------------------------------------------------------------------------------------------- |
| Auth          | User registration, JWT login, token refresh, encrypted passport storage, travel preferences               |
| Trips         | Trip creation with destination, dates, purpose, companions; status transitions; edit and delete           |
| Itinerary     | Day-by-day activity planning, drag-and-drop reorder, visual timeline, travel time estimate                |
| Bookings      | Flight, hotel, car rental, activity booking storage; document upload (PDF, image)                        |
| Packing       | Custom packing list creation; add, check, delete items; pre-travel checklist persistence                  |
| Budget        | Category budgets; multi-currency expense logging; planned vs. actual summary                              |
| Collaboration | Trip sharing with roles (viewer/editor/admin); comments; task assignment; group expense splitting         |
| Journal       | Daily diary entries; photo upload and geo-tagging; completed-trip summary                                |
| Offline       | Itinerary, bookings, packing readable offline; offline edits queued and synced; conflict resolution       |
| Security      | JWT enforcement; parameterised queries; security headers; AES-256 encryption; Socket.IO room scoping      |
| Performance   | App launch speed; API response time; document upload time; drag-and-drop smoothness                      |
| Responsiveness| Screen rendering on phone and tablet; no overflow or clipping; timeline and drag-drop usability on tablet |

---

### New Modules / Features

> Complete KPI coverage is generated for all new modules below.

| Module                   | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
| Packing Checklist Generator | Auto-generates customisable packing lists based on trip type and duration  |
| Travel Document Checklist   | Structured per-trip checklist for passports, visas, tickets, insurance, etc. |
| Itinerary Sharing (Extended) | Time-limited shareable links with View/Edit role for friends and family    |
| Trip Notes and Memories     | Per-trip timestamped free-text notes and reflections                        |
| Weather Forecast Integration | Third-party weather data per destination per itinerary date                |
| Currency Converter          | In-app currency conversion with live/cached exchange rates                 |
| Time Zone Calculator        | Time difference and local time display between two IANA timezone locations  |
| Travel Checklist Templates  | Pre-defined packing templates by trip type (Beach, Business, etc.)          |
| Photo Gallery for Trips     | Per-trip grid photo gallery organised by location and date with lightbox     |
| Trip Budget Tracking (Standalone) | Dedicated budget tracking screen with category breakdown and chart    |

---

### Modified Modules / Features

> KPIs are generated only for the modified functionality and its direct impact.

| Module        | Existing Behavior                                   | Updated Behavior                                                             |
| ------------- | --------------------------------------------------- | ---------------------------------------------------------------------------- |
| Packing       | Manual custom list creation only                    | Extended with Checklist Generator and pre-defined Templates                  |
| Journal       | Photo upload/tagging; diary entries                 | Extended with structured Trip Notes & Memories and dedicated Photo Gallery   |
| Collaboration | Permission-based sharing with companions            | Extended with guest/friend share links (time-limited, View/Edit roles)       |
| Documents     | File upload only (passport, insurance, confirmations)| Extended with a structured Travel Document Checklist with check-off          |
| Budget        | Category budgets; multi-currency expense logging    | API enhanced with plannedTotal, actualTotal, categoryBreakdown, currency     |

---

## STEP – KPI GENERATION

---

## OLD KPIs — Preserved Unchanged from KPI v1

> The following KPIs are carried forward exactly as documented in `KPI.md`. No changes have been made.

---

### 1. Authentication & Profiles

| Acceptance Criteria | Status |
|---|---|
| User can register with email and password | Fail |
| User receives JWT on successful login | Fail |
| Expired JWT refreshes transparently without re-login prompt | Fail |
| Passport details are stored encrypted; plaintext never appears in logs or API responses | Fail |
| User can update travel preferences and changes persist after logout | Fail |
| Invalid credentials return a 401 with no user enumeration leak | Fail |

---

### 2. Trip Management

| Acceptance Criteria | Status |
|---|---|
| User can create a trip with destination, dates, purpose, and companions | Fail |
| Trip status transitions correctly: planning → active → completed | Fail |
| User can edit and delete their own trips | Fail |
| Deleted trip cascades removal of all itinerary items, bookings, and documents | Fail |

---

### 3. Itinerary Planner

| Acceptance Criteria | Status |
|---|---|
| User can add activities with title, location, and time slot to a specific day | Fail |
| Drag-and-drop reorder persists correctly after app restart | Fail |
| Visual timeline renders all day items without overlap or rendering errors | Fail |
| Travel time estimate is shown between consecutive activities | Fail |
| Activity spanning midnight renders correctly across day boundary | Fail |

---

### 4. Bookings & Documents

| Acceptance Criteria | Status |
|---|---|
| User can add flight, hotel, car rental, and activity bookings to a trip | Fail |
| User can upload PDF and image documents (confirmation, passport copy, insurance) | Fail |
| Unsupported file types are rejected with a clear error message | Fail |
| Documents are accessible only to trip members (owner + collaborators) | Fail |
| Viewer-role collaborators cannot access passport document type | Fail |

---

### 5. Packing & Checklists

| Acceptance Criteria | Status |
|---|---|
| User can create and name a packing list per trip | Fail |
| User can add, check, and delete individual packing items | Fail |
| Pre-travel checklist completion state persists between sessions | Fail |

---

### 6. Budget Tracking

| Acceptance Criteria | Status |
|---|---|
| User can set a budget per category (accommodation, food, transport, activities, misc) | Fail |
| User can log expenses with amount, currency, and category | Fail |
| Planned vs. actual summary is accurate per category | Fail |
| Expenses in multiple currencies display correctly in the summary view | Fail |
| Expense logged offline syncs to server on reconnection without duplication | Fail |

---

### 7. Collaboration

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

### 8. Travel Journal

| Acceptance Criteria | Status |
|---|---|
| User can create a daily diary entry with rich text | Fail |
| User can upload and attach photos to a journal entry | Fail |
| Photos are geo-tagged to an activity or location; falls back gracefully when none exists | Fail |
| Completed-trip summary displays photo grid and trip stats | Fail |

---

### 9. Offline Support

| Acceptance Criteria | Status |
|---|---|
| Itinerary, bookings, and packing list are readable in airplane mode | Fail |
| Edits made offline are queued and synced automatically on reconnection | Fail |
| No data is lost when the app reconnects after offline edits | Fail |
| Server timestamp arbitration resolves conflicts; user sees a conflict banner with both versions | Fail |
| Large photo uploads queued offline are sent sequentially, not in parallel, to avoid timeout | Fail |

---

### 10. Security

| Acceptance Criteria | Status |
|---|---|
| All API endpoints reject requests without a valid JWT | Fail |
| All SQL queries use parameterized statements; no raw string interpolation | Fail |
| helmet.js security headers are present on all API responses | Fail |
| Sensitive fields (passport, document files) are AES-256 encrypted at rest | Fail |
| Socket.IO events are scoped to the correct trip room; cross-trip data never leaks | Fail |

---

### 11. Performance

| Acceptance Criteria | Status |
|---|---|
| App launches and reaches the home screen on a mid-range Android device without perceptible delay | Fail |
| Core trip and itinerary API endpoints respond without perceptible delay under normal load | Fail |
| Document upload completes within a reasonable time on a standard mobile connection | Fail |
| Drag-and-drop interaction is smooth with no visible frame drops | Fail |

---

### 12. Responsiveness

| Acceptance Criteria | Status |
|---|---|
| All screens render correctly on phone (small) and tablet (large) form factors | Fail |
| No UI element overflows or clips on any supported screen size | Fail |
| Timeline and drag-drop interactions are fully usable on tablet layout | Fail |

---

---

## NEW KPIs — Added in v2 (Based on PRD_v2.md Enhancement Features)

> Generated for New Modules, Modified Modules, and Impacted Integrations only.

---

### KPI Table — New & Modified Modules

| KPI Number | Module | KPI Name | Description | Criteria |
|---|---|---|---|---|
| KPI-N-01 | Packing Checklist Generator | Generator Invocation | User triggers the Checklist Generator by selecting a trip type | GIVEN a trip exists, WHEN user selects a trip type and taps "Generate List," THEN a populated checklist is displayed within 2 seconds |
| KPI-N-02 | Packing Checklist Generator | Item Customisation | User can add, remove, and reorder generated items | GIVEN a generated checklist is shown, WHEN user adds or removes an item, THEN the change persists after screen navigation |
| KPI-N-03 | Packing Checklist Generator | Item Check-Off Persistence | Checked items persist across sessions | GIVEN items are checked, WHEN user closes and reopens the app, THEN checked state is preserved |
| KPI-N-04 | Packing Checklist Generator | Trip-Type Accuracy | Generated list is relevant to the selected trip type | GIVEN a "Beach Holiday" type is selected, WHEN the list is generated, THEN beach-specific items (sunscreen, swimwear, etc.) appear and business items do not |
| KPI-N-05 | Travel Checklist Templates | Template Selection | User selects a pre-defined template from the Packing section | GIVEN user opens Packing, WHEN they select a template, THEN template items load and the user can customise from the pre-populated list |
| KPI-N-06 | Travel Checklist Templates | Template Coverage | System provides templates for all documented trip types | GIVEN the template list screen, WHEN user browses, THEN at minimum Beach Holiday, Business Trip, Backpacking, Winter Vacation, and Road Trip templates are available |
| KPI-N-07 | Travel Checklist Templates | Fallback on No Match | System handles missing template gracefully | GIVEN an unsupported trip type is requested, WHEN the system has no matching template, THEN a "General Travel" fallback template is applied and the user is notified |
| KPI-N-08 | Travel Document Checklist | Checklist Visibility | Document checklist is accessible per trip | GIVEN a trip exists, WHEN user opens the Document Checklist tab, THEN a pre-populated list of document items (passport, visa, tickets, insurance, vaccination, hotel voucher) is displayed |
| KPI-N-09 | Travel Document Checklist | Check-Off Capability | Each document item can be individually checked off | GIVEN the document checklist is open, WHEN user taps a checklist item, THEN it is marked as checked and the state persists |
| KPI-N-10 | Travel Document Checklist | Read-Only Enforcement for Viewers | View-only collaborators cannot check off items | GIVEN a view-only collaborator accesses the document checklist, WHEN they attempt to check an item, THEN the action is blocked and a 403 response is returned |
| KPI-N-11 | Travel Document Checklist | Checklist Reset on Trip Duplication | Checklist resets if trip is duplicated | GIVEN a trip with completed checklist items is duplicated, WHEN the new trip is opened, THEN all checklist items show as unchecked |
| KPI-N-12 | Itinerary Sharing (Extended) | Share Link Generation | User generates a time-limited share link | GIVEN user taps "Share Trip," WHEN they select View or Edit role and confirm, THEN a valid shareable URL is produced and copied to clipboard |
| KPI-N-13 | Itinerary Sharing (Extended) | Role Enforcement on Share Link | Shared link respects the assigned role | GIVEN a view-only share link is accessed, WHEN the recipient opens the trip, THEN itinerary is read-only and all edit controls are hidden |
| KPI-N-14 | Itinerary Sharing (Extended) | Share Link Expiry | Expired links are rejected | GIVEN a share link has passed its expiry date, WHEN the link is accessed, THEN a 410 Gone response and "Link expired" message are shown |
| KPI-N-15 | Itinerary Sharing (Extended) | Unauthenticated Share Access | Unauthenticated users are prompted to log in | GIVEN an unauthenticated user accesses a share link, WHEN the link is opened, THEN the user is redirected to login/register and the share token is preserved in session |
| KPI-N-16 | Itinerary Sharing (Extended) | Share Revocation | Owner can revoke an active share link | GIVEN an active share link exists, WHEN the owner revokes it, THEN subsequent access to that link returns 410 Gone immediately |
| KPI-N-17 | Itinerary Sharing (Extended) | Trip Deletion Invalidates All Links | Deleting a trip invalidates all share links | GIVEN active share links exist for a trip, WHEN the trip is deleted, THEN all share links are invalidated and collaborators are notified |
| KPI-N-18 | Trip Notes and Memories | Note Creation | User can add a timestamped note to a trip | GIVEN user is on a trip detail screen, WHEN they create a note with text content, THEN the note is saved with a creation timestamp and displayed in chronological order |
| KPI-N-19 | Trip Notes and Memories | Note Editing | User can edit an existing note | GIVEN a saved note exists, WHEN user edits the content, THEN the updated content persists and the edit timestamp is updated |
| KPI-N-20 | Trip Notes and Memories | Note Deletion | User can delete a note | GIVEN a saved note exists, WHEN user deletes it, THEN the note is removed immediately and does not reappear on refresh |
| KPI-N-21 | Trip Notes and Memories | Location & Day Tagging | Notes can be tagged to a specific day or location | GIVEN the note editor, WHEN user attaches a dayDate or locationTag, THEN the note is displayed with the associated day and location label |
| KPI-N-22 | Trip Notes and Memories | Character Limit Enforcement | Notes beyond the character limit are rejected | GIVEN user types beyond the character limit, WHEN they attempt to save, THEN the client prevents submission and a character-count warning is displayed; server returns 422 if bypassed |
| KPI-N-23 | Weather Forecast Integration | Forecast Display per Day | Weather data is shown per itinerary day | GIVEN a trip has future itinerary dates, WHEN user views the itinerary screen, THEN temperature, weather condition, and precipitation probability are displayed for each scheduled day |
| KPI-N-24 | Weather Forecast Integration | API Unavailability Handling | App remains functional when weather API is down | GIVEN the weather API is unavailable, WHEN the itinerary screen loads, THEN a "Weather unavailable" message is shown with a retry option and the itinerary loads without blocking |
| KPI-N-25 | Weather Forecast Integration | Destination Not Found Handling | Invalid destination does not crash the screen | GIVEN an unrecognised destination, WHEN forecast is requested, THEN a graceful error message is displayed and no exception is thrown |
| KPI-N-26 | Currency Converter | Conversion Accuracy | Converted amount matches expected exchange rate | GIVEN user enters an amount, base currency, and target currency, WHEN they tap Convert, THEN the result matches the current exchange rate within an acceptable rounding tolerance |
| KPI-N-27 | Currency Converter | Stale Rate Warning | User is informed when rate data exceeds 24 hours | GIVEN exchange rate data is older than 24 hours, WHEN user views the converter, THEN a staleness warning is displayed with the last-updated timestamp |
| KPI-N-28 | Currency Converter | Unsupported Currency Rejection | Unsupported currency codes return a clear error | GIVEN a currency code not in the supported list is entered, WHEN conversion is requested, THEN a 400 response with the supported currency list is returned |
| KPI-N-29 | Currency Converter | Offline Behaviour | Cached rates are shown when offline | GIVEN the device is offline, WHEN the converter is opened, THEN the last cached rates are displayed with an "offline — cached rate" indicator |
| KPI-N-30 | Time Zone Calculator | Offset Calculation | Correct time difference is shown between two zones | GIVEN user selects two IANA timezone identifiers, WHEN the calculator runs, THEN the UTC offset difference, local time in each zone, and DST status are displayed correctly |
| KPI-N-31 | Time Zone Calculator | Invalid Timezone Handling | Invalid timezone identifiers return a validation error | GIVEN an invalid timezone string is entered, WHEN submitted, THEN a validation error is shown and a list of valid IANA identifiers is provided |
| KPI-N-32 | Time Zone Calculator | DST Awareness | DST transitions are reflected in the displayed offset | GIVEN a timezone subject to DST and a date during the DST transition period, WHEN the calculation is run, THEN the DST-adjusted offset is shown |
| KPI-N-33 | Photo Gallery for Trips | Gallery Visibility | Photo gallery is accessible per trip | GIVEN a trip has uploaded photos, WHEN user opens the Photo Gallery screen, THEN photos are displayed in a grid layout organised by location and date |
| KPI-N-34 | Photo Gallery for Trips | Lightbox Viewer | Tapping a photo opens a lightbox | GIVEN the gallery grid is displayed, WHEN user taps a photo, THEN the photo opens in a fullscreen lightbox with navigation to adjacent photos |
| KPI-N-35 | Photo Gallery for Trips | Upload Size Limit Enforcement | Oversized photos are rejected | GIVEN a photo exceeding 20 MB is selected, WHEN upload is attempted, THEN a 413 error is returned with a message specifying the size limit and supported formats |
| KPI-N-36 | Photo Gallery for Trips | Post-Upload Metadata Tagging | Photos uploaded without metadata can be tagged after upload | GIVEN a photo uploaded with no location or date, WHEN user opens the gallery, THEN they can tag location and date from the gallery view |
| KPI-N-37 | Photo Gallery for Trips | Group-by Toggle | Gallery can be toggled between grouping by location and by date | GIVEN the gallery is open, WHEN user toggles between "By Location" and "By Date" views, THEN photos re-group correctly under the selected dimension |
| KPI-N-38 | Photo Gallery for Trips | Photo Deletion | User can delete a photo from the gallery | GIVEN a photo exists in the gallery, WHEN user deletes it, THEN it is removed immediately from the gallery grid and does not reappear on refresh |
| KPI-N-39 | Trip Budget Tracking (Standalone) | Planned vs. Actual Display | Budget screen shows planned and actual amounts per category | GIVEN a trip budget is configured, WHEN the user opens the Budget screen, THEN planned total, actual total, and category-level breakdown are displayed with visual indicators |
| KPI-N-40 | Trip Budget Tracking (Standalone) | Real-Time Update on Expense Log | Budget summary updates when a new expense is logged | GIVEN the budget screen is open, WHEN user logs a new expense, THEN the actual total and category breakdown update within the current session without requiring a screen reload |
| KPI-N-41 | Trip Budget Tracking (Standalone) | Category Breakdown Accuracy | Category totals match the sum of logged expenses | GIVEN multiple expenses are logged across categories, WHEN the breakdown is displayed, THEN each category total equals the arithmetic sum of all expenses in that category |

---

### Regression KPIs — Impacted Existing Modules

> Generated because modifications to Packing, Journal, Collaboration, Documents, and Budget directly affect existing behaviour.

| KPI Number | Module | KPI Name | Description | Criteria |
|---|---|---|---|---|
| KPI-R-01 | Packing (Regression) | Existing Custom List Unaffected | Adding generator/templates does not break custom list creation | GIVEN user creates a manual packing list (no template), WHEN they add and check items, THEN behaviour is identical to pre-v2 and no data is lost |
| KPI-R-02 | Packing (Regression) | Checklist Persistence Unchanged | Session persistence of pre-travel checklists continues to function | GIVEN checklist items are checked in an existing list, WHEN the app is restarted, THEN checked state is preserved exactly as in v1 |
| KPI-R-03 | Collaboration (Regression) | Existing Role-Based Sharing Unaffected | Companion-based sharing still enforces viewer/editor/admin roles | GIVEN an existing trip with collaborators, WHEN accessed after v2 deployment, THEN role enforcement behaves identically to v1 |
| KPI-R-04 | Collaboration (Regression) | Comment System Unaffected | Real-time comments between collaborators continue to function | GIVEN two collaborators are on the same trip, WHEN one posts a comment, THEN it appears for the other without latency regression |
| KPI-R-05 | Journal (Regression) | Diary Entry Unaffected by Gallery Feature | Adding Photo Gallery does not disrupt diary entry creation or photo tagging | GIVEN an existing journal entry with photos, WHEN the user opens the journal after v2 deployment, THEN entry content and photo tags display correctly |
| KPI-R-06 | Documents (Regression) | Existing Document Upload Unaffected | File upload functionality is unchanged by the addition of the Document Checklist | GIVEN a user uploads a PDF, WHEN the upload completes, THEN the file is accessible and viewer-role access restrictions remain enforced |
| KPI-R-07 | Budget (Regression) | Existing Expense Logging Unaffected | Enhanced budget API does not break existing expense logging flows | GIVEN an expense is logged using the existing UI flow, WHEN the budget summary is viewed, THEN existing category totals are correctly reflected and no data regression occurs |
| KPI-R-08 | Security (Regression) | New Endpoints Require Valid JWT | All new v2 API endpoints enforce JWT authentication | GIVEN an unauthenticated request is made to any new v2 endpoint, WHEN the request is processed, THEN a 401 Unauthorized response is returned |
| KPI-R-09 | Security (Regression) | New DB Entities Use Parameterised Queries | All queries against new tables use parameterised statements | GIVEN a new v2 database entity is queried, WHEN the query executes, THEN no raw string interpolation is present and SQL injection is not possible |
| KPI-R-10 | Offline (Regression) | Offline Read Unaffected by New Features | New features do not degrade offline readability of core data | GIVEN the device is in airplane mode, WHEN user opens the itinerary, bookings, and existing packing list, THEN all data is readable without error, consistent with v1 behaviour |

---

## STEP – IMPACT ANALYSIS

| Area      | Impact Type | Description |
|---|---|---|
| UI        | New         | Budget Screen, Sharing Screen, Photo Gallery Screen, Utilities Screen (Currency, Time Zone) added as new screens |
| UI        | Modified    | Trip Detail Screen, Packing Screen, Itinerary Screen, Journal/Notes Screen extended with new tabs and components |
| API       | New         | 17 new endpoints added across Weather, Currency, Timezone, Sharing, Document Checklist, Packing Templates, Notes, Photos |
| API       | Modified    | `GET /api/v1/trips/{tripId}/budget` extended with plannedTotal, actualTotal, categoryBreakdown, currency fields |
| Database  | New         | `trip_shares`, `document_checklist`, `packing_templates`, `trip_notes`, `trip_photos` entities added |
| Database  | Modified    | `trips` table: `homeCurrency` field added. `budget_entries` table: `category` and `currency` fields added |
| Security  | New         | Share token cryptographic generation; time-limited token expiry and revocation; pre-signed photo URLs; third-party API key server-side secret storage |
| Security  | Modified    | Document checklist access scoped to trip owner and explicitly shared collaborators; trip notes encrypted at rest |
| Reporting | New         | Budget category breakdown chart (planned vs. actual); Photo Gallery group-by views (location, date) |

---

## STEP – IMPLEMENTATION ROADMAP

### Development Timeline

| Sprint | Focus Area | Deliverables |
|---|---|---|
| Sprint 1 | Packing Enhancement | Packing Checklist Generator, Travel Checklist Templates (pre-defined templates: Beach, Business, Backpacking, Winter, Road Trip) |
| Sprint 2 | Documents & Budget | Travel Document Checklist (per-trip, check-off, role enforcement), Trip Budget Tracking standalone screen (planned vs. actual chart, category breakdown) |
| Sprint 3 | Utility Features | Currency Converter (live/cached rates, offline support), Time Zone Calculator (IANA zones, DST awareness) |
| Sprint 4 | Travel Intelligence | Weather Forecast Integration (third-party API, per-day display, unavailability handling) |
| Sprint 5 | Sharing & Collaboration | Itinerary Sharing Extended (time-limited links, View/Edit roles, revocation, expiry handling) |
| Sprint 6 | Journal & Gallery | Trip Notes and Memories (timestamped, tagged), Photo Gallery for Trips (grid, lightbox, group-by toggle, metadata tagging) |
| Sprint 7 | Regression & Security | Regression testing of all impacted existing modules; security audit of new endpoints and DB entities; performance validation |

---

### Success Criteria

| Category | Success Metric | Target |
|---|---|---|
| Packing Adoption | % of new trips using Checklist Generator or Template | ≥ 60% within 30 days of launch |
| Document Readiness | % of trips with all document checklist items marked before departure | ≥ 70% |
| Sharing Engagement | % of multi-day trips with at least one share link generated | ≥ 30% |
| Weather Engagement | % of future-dated trips with weather forecast viewed at least once | ≥ 50% |
| Currency Utility Usage | % of international trips using Currency Converter | ≥ 40% |
| Time Zone Utility Usage | % of multi-timezone trips using Time Zone Calculator | ≥ 35% |
| Photo Gallery Engagement | Average photos uploaded per completed trip | ≥ 5 photos within 60 days |
| Notes Engagement | Average notes logged per completed trip | ≥ 2 notes within 60 days |
| User Retention | D30 retention improvement vs. pre-enhancement baseline | ≥ 10% |
| API Reliability | Error rate across all new v2 API endpoints | < 1% under normal load |
| Regression Pass Rate | % of regression KPIs passing in QA post-deployment | 100% |
| Security Compliance | New endpoints with JWT enforcement and parameterised queries | 100% |

---
