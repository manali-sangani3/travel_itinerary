# Development Impact Analysis — Travel Itinerary App (V2)

## 1. Database Schema Changes

### Schema Updates in `backend/src/db/schema.js`:
- **`trips` Table Modification:**
  - Add `home_currency TEXT DEFAULT 'USD'` column.
- **New Table `trip_shares`:**
  ```sql
  CREATE TABLE IF NOT EXISTS trip_shares (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    share_token TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('viewer', 'editor')),
    expires_at TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
  );
  ```
- **New Table `document_checklist`:**
  ```sql
  CREATE TABLE IF NOT EXISTS document_checklist (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    checked INTEGER DEFAULT 0
  );
  ```
- **New Table `packing_templates`:**
  ```sql
  CREATE TABLE IF NOT EXISTS packing_templates (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    trip_type TEXT NOT NULL,
    items TEXT NOT NULL -- JSON array of items
  );
  ```
- **New Table `trip_notes`:**
  ```sql
  CREATE TABLE IF NOT EXISTS trip_notes (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    day_date TEXT, -- YYYY-MM-DD
    location_tag TEXT,
    created_at TEXT DEFAULT (datetime('now'))
  );
  ```
- **New Table `trip_photos`:**
  ```sql
  CREATE TABLE IF NOT EXISTS trip_photos (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    location_tag TEXT,
    date_taken TEXT NOT NULL,
    uploaded_at TEXT DEFAULT (datetime('now'))
  );
  ```

---

## 2. Backend API Endpoint Impact

### New Routes and Mappings:
1. **Weather Forecast API:**
   - `GET /weather/:destination/:date`
2. **Currency Converter API:**
   - `GET /currency/convert?base=USD&target=INR&amount=100`
3. **Time Zone Calculator API:**
   - `GET /timezone/diff?from=America/New_York&to=Asia/Kolkata`
4. **Itinerary Sharing API:**
   - `POST /trips/:id/share` (Body: `{ role, expiresInDays }`)
   - `GET /trips/:id/share`
   - `DELETE /trips/:id/share/:shareId`
   - `GET /shares/:token` (Public endpoint to fetch shared trip details)
5. **Travel Document Checklist API:**
   - `GET /trips/:id/checklist/documents`
   - `PUT /trips/:id/checklist/documents` (Body: `{ itemId, checked }`)
6. **Packing Templates & Generator API:**
   - `GET /trips/:id/packing/templates`
   - `POST /trips/:id/packing/generate` (Body: `{ templateId }`)
7. **Trip Notes API:**
   - `POST /trips/:id/notes`
   - `GET /trips/:id/notes`
   - `PUT /trips/:id/notes/:noteId`
   - `DELETE /trips/:id/notes/:noteId`
8. **Photo Gallery API:**
   - `GET /trips/:id/photos`
   - `POST /trips/:id/photos` (Multipart form-data)
   - `DELETE /trips/:id/photos/:photoId`

### Modified Routes:
- `GET /trips/:id/budget` -> Modified to return:
  ```json
  {
    "plannedTotal": 5000,
    "actualTotal": 1200,
    "categoryBreakdown": [
      { "category": "food", "planned": 1000, "actual": 200 },
      ...
    ],
    "currency": "USD"
  }
  ```

---

## 3. Frontend / Flutter Client Impact

### New Screens / Widgets:
1. **Packing Screen Extensions:**
   - Template list and "Generate Packing List" button.
2. **Document Checklist Tab:**
   - Add to `DocumentsPage`.
3. **Standalone Budget Screen:**
   - Custom progress ring, category comparison progress bars, category breakdown.
4. **Trip Notes & Memories Screen:**
   - CRUD flow for notes, chronological layout, tag support.
5. **Photo Gallery Screen:**
   - Grid layout grouping by date/location, lightbox image viewer.
6. **Weather Card:**
   - Embedded into daily timeline items in `ItineraryPage`.
7. **Utilities Section:**
   - Modals or pages for Currency Converter and Time Zone Calculator.
8. **Sharing Management Dialog:**
   - Share link generation and role setup interface.

### State Management (Bloc):
- Define Bloc events, states, and data models for:
  - `WeatherBloc`
  - `CurrencyBloc`
  - `SharingBloc`
  - `NotesBloc`
  - `PhotosBloc`
  - `DocumentChecklistBloc`
- Extend existing `PackingBloc` and `BudgetBloc` with V2 capabilities.

---

## 4. Risks & Mitigations

1. **Third-Party API Outages:**
   - **Mitigation:** Implement offline fallback/caching for weather forecasts and currency rates. Use mock responses if external requests fail or if API keys are missing.
2. **Storage Allocation:**
   - **Mitigation:** Limit upload photo sizes to 20MB and enforce image file formats (JPEG, PNG).
3. **Share Link Expiry & Security:**
   - **Mitigation:** Generate secure UUID-based random share tokens. Enforce expiration timestamps in backend database checks.
