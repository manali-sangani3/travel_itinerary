-- =============================================================================
-- Travel Itinerary — V2 Enhancement Database Migration
-- =============================================================================
-- File    : v2_migration.sql
-- Target  : SQLite (better-sqlite3)
-- Version : 2.0.0
-- Date    : 2026-06-18
-- Author  : Auto-generated for V2 enhancements
--
-- Features covered in this migration:
--   1.  Packing Checklist Generator  (packing_items, packing_templates)
--   2.  Travel Document Checklist    (document_checklist)
--   3.  Itinerary Sharing            (trip_shares)
--   4.  Trip Notes & Memories        (trip_notes)
--   5.  Photo Gallery                (trip_photos)
--   6.  Bookings                     (bookings — enhanced details JSON)
--   7.  Collaboration Tasks          (tasks — already present, queries added)
--   8.  Expense Splits               (expense_splits — view only)
--   9.  Currency column on trips     (home_currency)
--  10.  Journal Entry Photos         (journal_entry_photos — new join table)
-- =============================================================================


-- =============================================================================
-- SECTION 1 — SCHEMA MIGRATIONS
-- Run these CREATE / ALTER statements once per database.
-- All statements use IF NOT EXISTS / try-catch guards so they are safe
-- to re-run on a database that has already applied a partial migration.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1.1  PACKING ITEMS
-- Already created in v1 schema; reproduced here for completeness.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS packing_items (
  id          TEXT    PRIMARY KEY,
  trip_id     TEXT    NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  label       TEXT    NOT NULL,
  category    TEXT,                        -- preset category label (e.g. 'Toiletries')
  checked     INTEGER DEFAULT 0            -- 0 = unchecked, 1 = checked
);

-- Performance index: fetch all items for a trip quickly
CREATE INDEX IF NOT EXISTS idx_packing_items_trip_id
  ON packing_items(trip_id);


-- -----------------------------------------------------------------------------
-- 1.2  PACKING TEMPLATES  (Packing Checklist Generator)
-- Predefined templates that users can auto-generate lists from.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS packing_templates (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,               -- e.g. 'Beach Holiday'
  trip_type  TEXT NOT NULL,               -- e.g. 'beach', 'business', 'hiking'
  items      TEXT NOT NULL               -- JSON array: '["Sunscreen","Swimsuit",...]'
);

-- Seed default templates (idempotent — only inserts when table is empty)
-- Executed conditionally in app code; raw SQL equivalent provided here:
INSERT OR IGNORE INTO packing_templates (id, name, trip_type, items) VALUES
  ('t1', 'Beach Holiday',  'beach',    '["Swimwear","Sunscreen","Sunglasses","Beach Towel","Flip Flops","Hat"]'),
  ('t2', 'Business Trip',  'business', '["Suit/Blazer","Formal Shoes","Tie","Laptop Charger","Notebook","Business Cards"]'),
  ('t3', 'Backpacking',    'hiking',   '["Backpack Rain Cover","Hiking Boots","Water Bottle","Map/Compass","First Aid Kit","Multi-tool"]'),
  ('t4', 'Winter Vacation','winter',   '["Heavy Coat","Thermal Wear","Gloves","Beanie","Scarf","Snow Boots"]'),
  ('t5', 'Road Trip',      'road',     '["Car Charger","Offline Maps","First Aid Kit","Snacks","Travel Pillow","Playlist"]');


-- -----------------------------------------------------------------------------
-- 1.3  TRAVEL DOCUMENT CHECKLIST
-- Per-trip checklist items seeded from a default list.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS document_checklist (
  id       TEXT    PRIMARY KEY,
  trip_id  TEXT    NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  label    TEXT    NOT NULL,              -- e.g. 'Passport', 'Visa'
  checked  INTEGER DEFAULT 0             -- 0 = pending, 1 = checked
);

CREATE INDEX IF NOT EXISTS idx_document_checklist_trip_id
  ON document_checklist(trip_id);


-- -----------------------------------------------------------------------------
-- 1.4  TRIP SHARES  (Itinerary Sharing)
-- Cryptographic token-based share links with role and expiry.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS trip_shares (
  id           TEXT    PRIMARY KEY,
  trip_id      TEXT    NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  share_token  TEXT    UNIQUE NOT NULL,  -- 48-char hex token (crypto.randomBytes(24))
  role         TEXT    NOT NULL CHECK(role IN ('viewer', 'editor')),
  expires_at   TEXT    NOT NULL,         -- ISO-8601 datetime
  created_at   TEXT    DEFAULT (datetime('now'))
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_trip_shares_token
  ON trip_shares(share_token);

CREATE INDEX IF NOT EXISTS idx_trip_shares_trip_id
  ON trip_shares(trip_id);


-- -----------------------------------------------------------------------------
-- 1.5  TRIP NOTES  (Trip Notes & Memories)
-- Free-text reflections / memories attached to a trip day or location.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS trip_notes (
  id           TEXT    PRIMARY KEY,
  trip_id      TEXT    NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  content      TEXT    NOT NULL,
  day_date     TEXT,                     -- optional: ISO date 'YYYY-MM-DD'
  location_tag TEXT,                     -- optional: e.g. 'Eiffel Tower'
  created_at   TEXT    DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_trip_notes_trip_id
  ON trip_notes(trip_id);


-- -----------------------------------------------------------------------------
-- 1.6  TRIP PHOTOS  (Photo Gallery for Trips)
-- Per-trip photo records with optional location tag and date taken.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS trip_photos (
  id           TEXT    PRIMARY KEY,
  trip_id      TEXT    NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  file_path    TEXT    NOT NULL,         -- relative path: 'uploads/<filename>'
  location_tag TEXT,                     -- optional grouping tag
  date_taken   TEXT    NOT NULL,         -- 'YYYY-MM-DD' (defaults to upload date)
  uploaded_at  TEXT    DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_trip_photos_trip_id
  ON trip_photos(trip_id);

CREATE INDEX IF NOT EXISTS idx_trip_photos_date_taken
  ON trip_photos(trip_id, date_taken);

CREATE INDEX IF NOT EXISTS idx_trip_photos_location
  ON trip_photos(trip_id, location_tag);


-- -----------------------------------------------------------------------------
-- 1.7  JOURNAL ENTRY PHOTOS  (Photo-per-entry join — V2 enhancement)
-- Journal entries already exist (journal_entries).
-- This table tracks photos uploaded to specific journal entries.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS journal_entry_photos (
  id         TEXT PRIMARY KEY,
  entry_id   TEXT NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
  trip_id    TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  file_path  TEXT NOT NULL,
  location   TEXT,
  uploaded_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_journal_entry_photos_entry_id
  ON journal_entry_photos(entry_id);


-- -----------------------------------------------------------------------------
-- 1.8  HOME CURRENCY column on trips (safe ALTER — already guarded in app code)
-- -----------------------------------------------------------------------------

-- NOTE: SQLite does not support IF NOT EXISTS on ALTER TABLE.
-- The application wraps this in a try/catch (already done in schema.js).
-- Kept here for documentation purposes.
--
--   ALTER TABLE trips ADD COLUMN home_currency TEXT DEFAULT 'USD';


-- -----------------------------------------------------------------------------
-- 1.9  COLLABORATORS / TASKS  (already present in v1 — no new columns needed)
-- Tasks table reproduced for reference:
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS tasks (
  id          TEXT    PRIMARY KEY,
  trip_id     TEXT    NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
  assigned_to TEXT    REFERENCES users(id),
  title       TEXT    NOT NULL,
  completed   INTEGER DEFAULT 0,
  created_at  TEXT    DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_tasks_trip_id ON tasks(trip_id);


-- -----------------------------------------------------------------------------
-- 1.10  EXPENSE SPLITS VIEW
-- Derived from existing expenses table — no new table, just a named view.
-- -----------------------------------------------------------------------------

CREATE VIEW IF NOT EXISTS v_expense_splits AS
SELECT
  e.trip_id,
  e.user_id,
  SUM(e.amount) AS paid,
  (SUM(e.amount) - (
      SELECT AVG(sub.amount_sum)
      FROM (
        SELECT user_id, SUM(amount) AS amount_sum
        FROM expenses
        WHERE trip_id = e.trip_id
        GROUP BY user_id
      ) sub
  )) AS owes
FROM expenses e
GROUP BY e.trip_id, e.user_id;


-- =============================================================================
-- SECTION 2 — RUNTIME SQL QUERIES
-- All queries used in the V2 feature controllers, grouped by feature.
-- Placeholders use ? (positional) as required by better-sqlite3.
-- =============================================================================


-- =============================================================================
-- 2.1  PACKING CHECKLIST  (packing_items)
-- =============================================================================

-- ► GET all items for a trip (ordered: unchecked first, then alphabetically)
SELECT *
FROM   packing_items
WHERE  trip_id = ?
ORDER  BY checked ASC, label ASC;

-- ► GET items filtered by category
SELECT *
FROM   packing_items
WHERE  trip_id  = ?
  AND  category = ?
ORDER  BY label ASC;

-- ► INSERT a new packing item
INSERT INTO packing_items (id, trip_id, label, category, checked)
VALUES (?, ?, ?, ?, 0);

-- ► TOGGLE checked status (0 → 1 or 1 → 0)
UPDATE packing_items
SET    checked = ?           -- 0 or 1
WHERE  id = ?;

-- ► DELETE a single packing item
DELETE FROM packing_items
WHERE id = ?;

-- ► DELETE all packing items for a trip (used before template generation)
DELETE FROM packing_items
WHERE trip_id = ?;

-- ► COUNT packed vs total (progress calculation)
SELECT
  COUNT(*)                            AS total,
  SUM(CASE WHEN checked = 1 THEN 1 ELSE 0 END) AS packed
FROM packing_items
WHERE trip_id = ?;


-- =============================================================================
-- 2.2  PACKING TEMPLATES
-- =============================================================================

-- ► GET all templates
SELECT id, name, trip_type, items
FROM   packing_templates
ORDER  BY name ASC;

-- ► GET a single template by id
SELECT id, name, trip_type, items
FROM   packing_templates
WHERE  id = ?;

-- ► GET template by trip_type
SELECT id, name, trip_type, items
FROM   packing_templates
WHERE  trip_type = ?;

-- ► INSERT packing items generated from a template (loop per item label)
INSERT INTO packing_items (id, trip_id, label, category, checked)
VALUES (?, ?, ?, ?, 0);
-- Parameters: (uuid, tripId, itemLabel, templateName)


-- =============================================================================
-- 2.3  TRAVEL DOCUMENT CHECKLIST  (document_checklist)
-- =============================================================================

-- ► GET checklist for a trip
SELECT *
FROM   document_checklist
WHERE  trip_id = ?
ORDER  BY label ASC;

-- ► COUNT of checklist (used to decide whether to seed defaults)
SELECT COUNT(*) AS count
FROM   document_checklist
WHERE  trip_id = ?;

-- ► INSERT default checklist item (called in loop for first-access seeding)
INSERT INTO document_checklist (id, trip_id, label, checked)
VALUES (?, ?, ?, 0);
-- Default labels seeded: 'Passport', 'Visa', 'Tickets',
--   'Travel Insurance', 'Vaccination Certificates', 'Hotel Vouchers'

-- ► UPDATE checked status of a checklist item
UPDATE document_checklist
SET    checked = ?           -- 1 or 0
WHERE  id = ?;

-- ► DELETE all checklist items for a trip (cascade handled by FK)
DELETE FROM document_checklist
WHERE trip_id = ?;

-- ► INSERT a custom checklist item
INSERT INTO document_checklist (id, trip_id, label, checked)
VALUES (?, ?, ?, 0);

-- ► DELETE a single checklist item
DELETE FROM document_checklist
WHERE id = ?;


-- =============================================================================
-- 2.4  ITINERARY SHARING  (trip_shares)
-- =============================================================================

-- ► CREATE a new share link
INSERT INTO trip_shares (id, trip_id, share_token, role, expires_at)
VALUES (?, ?, ?, ?, ?);
-- Parameters: (uuid, tripId, 48-char-hex-token, role, expiryISOString)

-- ► GET all active share links for a trip
SELECT *
FROM   trip_shares
WHERE  trip_id = ?
ORDER  BY created_at DESC;

-- ► GET share by token (used when a visitor follows a share URL)
SELECT *
FROM   trip_shares
WHERE  share_token = ?;

-- ► GET share by id
SELECT *
FROM   trip_shares
WHERE  id = ?;

-- ► CHECK if share link is expired
SELECT id, expires_at
FROM   trip_shares
WHERE  share_token = ?
  AND  expires_at > datetime('now');   -- returns nothing if expired

-- ► REVOKE (delete) a share link
DELETE FROM trip_shares
WHERE id = ?;

-- ► REVOKE all expired share links (maintenance / cleanup job)
DELETE FROM trip_shares
WHERE expires_at < datetime('now');

-- ► GET full trip data through a share token (used by publicShare route)
SELECT
  t.*,
  s.role        AS share_role,
  s.expires_at  AS share_expires_at
FROM   trips t
JOIN   trip_shares s ON s.trip_id = t.id
WHERE  s.share_token = ?
  AND  s.expires_at  > datetime('now');

-- ► GET itinerary through a share token
SELECT ii.*
FROM   itinerary_items ii
JOIN   trip_shares s ON s.trip_id = ii.trip_id
WHERE  s.share_token = ?
ORDER  BY ii.day_index ASC, ii.order_index ASC;

-- ► GET packing items through a share token
SELECT pi.*
FROM   packing_items pi
JOIN   trip_shares s ON s.trip_id = pi.trip_id
WHERE  s.share_token = ?;


-- =============================================================================
-- 2.5  TRIP NOTES & MEMORIES  (trip_notes)
-- =============================================================================

-- ► GET all notes for a trip (newest first)
SELECT *
FROM   trip_notes
WHERE  trip_id = ?
ORDER  BY created_at DESC;

-- ► GET notes for a specific date
SELECT *
FROM   trip_notes
WHERE  trip_id  = ?
  AND  day_date = ?
ORDER  BY created_at DESC;

-- ► GET notes by location tag
SELECT *
FROM   trip_notes
WHERE  trip_id      = ?
  AND  location_tag = ?
ORDER  BY created_at DESC;

-- ► INSERT a new note
INSERT INTO trip_notes (id, trip_id, content, day_date, location_tag)
VALUES (?, ?, ?, ?, ?);
-- Parameters: (uuid, tripId, content, dayDate|null, locationTag|null)

-- ► GET a single note by id
SELECT *
FROM   trip_notes
WHERE  id = ?;

-- ► UPDATE note content
UPDATE trip_notes
SET    content = ?
WHERE  id = ?;

-- ► UPDATE note with location tag
UPDATE trip_notes
SET    content      = ?,
       location_tag = ?
WHERE  id = ?;

-- ► DELETE a note
DELETE FROM trip_notes
WHERE id = ?;

-- ► DELETE all notes for a trip (cascade on trip delete)
DELETE FROM trip_notes
WHERE trip_id = ?;

-- ► COUNT notes per trip
SELECT COUNT(*) AS note_count
FROM   trip_notes
WHERE  trip_id = ?;


-- =============================================================================
-- 2.6  PHOTO GALLERY  (trip_photos)
-- =============================================================================

-- ► GET all photos for a trip (newest first)
SELECT *
FROM   trip_photos
WHERE  trip_id = ?
ORDER  BY date_taken DESC, uploaded_at DESC;

-- ► GET photos grouped by date (client-side grouping, raw ordered query)
SELECT *
FROM   trip_photos
WHERE  trip_id = ?
ORDER  BY date_taken DESC;

-- ► GET photos grouped by location
SELECT *
FROM   trip_photos
WHERE  trip_id = ?
ORDER  BY location_tag ASC, date_taken DESC;

-- ► GET distinct location tags for a trip
SELECT DISTINCT location_tag
FROM   trip_photos
WHERE  trip_id      = ?
  AND  location_tag IS NOT NULL
ORDER  BY location_tag ASC;

-- ► GET distinct dates with photos
SELECT DISTINCT date_taken
FROM   trip_photos
WHERE  trip_id = ?
ORDER  BY date_taken DESC;

-- ► INSERT a new photo record
INSERT INTO trip_photos (id, trip_id, file_path, location_tag, date_taken)
VALUES (?, ?, ?, ?, ?);
-- Parameters: (uuid, tripId, filePath, locationTag|null, dateTaken)

-- ► GET a single photo by id (used before delete to get file_path)
SELECT *
FROM   trip_photos
WHERE  id = ?;

-- ► DELETE a photo record
DELETE FROM trip_photos
WHERE id = ?;

-- ► DELETE all photos for a trip
DELETE FROM trip_photos
WHERE trip_id = ?;

-- ► COUNT photos per trip
SELECT COUNT(*) AS photo_count
FROM   trip_photos
WHERE  trip_id = ?;

-- ► SEARCH photos by location tag (partial match)
SELECT *
FROM   trip_photos
WHERE  trip_id      = ?
  AND  location_tag LIKE '%' || ? || '%';


-- =============================================================================
-- 2.7  JOURNAL ENTRIES & ENTRY PHOTOS  (journal_entries, journal_entry_photos)
-- =============================================================================

-- ► GET all journal entries for a trip (newest first, with photo count)
SELECT
  je.*,
  COUNT(jep.id) AS photo_count
FROM   journal_entries je
LEFT   JOIN journal_entry_photos jep ON jep.entry_id = je.id
WHERE  je.trip_id = ?
GROUP  BY je.id
ORDER  BY je.entry_date DESC, je.created_at DESC;

-- ► GET a single journal entry with photos array
SELECT je.*
FROM   journal_entries je
WHERE  je.id = ?;

-- ► GET photos for a specific journal entry
SELECT *
FROM   journal_entry_photos
WHERE  entry_id = ?
ORDER  BY uploaded_at ASC;

-- ► INSERT a journal entry
INSERT INTO journal_entries (id, trip_id, user_id, entry_date, body, photos)
VALUES (?, ?, ?, ?, ?, '[]');
-- Parameters: (uuid, tripId, userId, entryDate, body)

-- ► UPDATE journal entry body
UPDATE journal_entries
SET    body = ?
WHERE  id = ?;

-- ► INSERT a photo linked to a journal entry
INSERT INTO journal_entry_photos (id, entry_id, trip_id, file_path, location)
VALUES (?, ?, ?, ?, ?);
-- Parameters: (uuid, entryId, tripId, filePath, location|null)

-- ► DELETE a journal entry (cascades to journal_entry_photos via FK)
DELETE FROM journal_entries
WHERE id = ?;

-- ► DELETE a single entry photo
DELETE FROM journal_entry_photos
WHERE id = ?;


-- =============================================================================
-- 2.8  BOOKINGS  (bookings)
-- =============================================================================

-- ► GET all bookings for a trip
SELECT *
FROM   bookings
WHERE  trip_id = ?
ORDER  BY created_at DESC;

-- ► GET bookings filtered by type
SELECT *
FROM   bookings
WHERE  trip_id = ?
  AND  type    = ?           -- 'flight' | 'hotel' | 'car_rental' | 'activity'
ORDER  BY created_at DESC;

-- ► GET a single booking
SELECT *
FROM   bookings
WHERE  id = ?;

-- ► INSERT a new booking
INSERT INTO bookings (id, trip_id, type, reference_number, details)
VALUES (?, ?, ?, ?, ?);
-- Parameters: (uuid, tripId, type, referenceNumber, JSON.stringify(details))

-- ► UPDATE a booking's details
UPDATE bookings
SET    reference_number = ?,
       details          = ?
WHERE  id = ?;

-- ► DELETE a booking
DELETE FROM bookings
WHERE id = ?;

-- ► COUNT bookings by type for a trip (summary card)
SELECT
  type,
  COUNT(*) AS booking_count
FROM   bookings
WHERE  trip_id = ?
GROUP  BY type;


-- =============================================================================
-- 2.9  COLLABORATION — TASKS  (tasks)
-- =============================================================================

-- ► GET all tasks for a trip
SELECT
  t.*,
  u.email AS assigned_to_email
FROM   tasks t
LEFT   JOIN users u ON u.id = t.assigned_to
WHERE  t.trip_id = ?
ORDER  BY t.created_at ASC;

-- ► GET incomplete tasks
SELECT *
FROM   tasks
WHERE  trip_id   = ?
  AND  completed = 0
ORDER  BY created_at ASC;

-- ► INSERT a new task
INSERT INTO tasks (id, trip_id, title, assigned_to, completed)
VALUES (?, ?, ?, ?, 0);

-- ► TOGGLE task completion
UPDATE tasks
SET    completed = ?         -- 1 or 0
WHERE  id = ?;

-- ► ASSIGN task to a user
UPDATE tasks
SET    assigned_to = ?
WHERE  id = ?;

-- ► DELETE a task
DELETE FROM tasks
WHERE id = ?;

-- ► TASK COMPLETION SUMMARY per trip
SELECT
  COUNT(*)                                         AS total,
  SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END)  AS done,
  SUM(CASE WHEN completed = 0 THEN 1 ELSE 0 END)  AS pending
FROM tasks
WHERE trip_id = ?;


-- =============================================================================
-- 2.10  COLLABORATION — MEMBERS / ROLES  (collaborators)
-- =============================================================================

-- ► GET all collaborators for a trip (with user email)
SELECT
  c.trip_id,
  c.role,
  c.user_id,
  u.email
FROM   collaborators c
JOIN   users         u ON u.id = c.user_id
WHERE  c.trip_id = ?;

-- ► CHECK if a user is a collaborator (permission guard)
SELECT role
FROM   collaborators
WHERE  trip_id = ?
  AND  user_id = ?;

-- ► INSERT a collaborator
INSERT INTO collaborators (trip_id, user_id, role)
VALUES (?, ?, ?);

-- ► UPDATE collaborator role
UPDATE collaborators
SET    role = ?
WHERE  trip_id = ?
  AND  user_id = ?;

-- ► REMOVE a collaborator
DELETE FROM collaborators
WHERE trip_id = ?
  AND user_id = ?;


-- =============================================================================
-- 2.11  EXPENSE SPLITS  (expenses — existing table, new aggregate queries)
-- =============================================================================

-- ► GET expense split summary per user for a trip
SELECT
  e.user_id,
  u.email,
  SUM(e.amount)                                   AS paid,
  SUM(e.amount) - AVG(total.trip_total) / COUNT(DISTINCT e.user_id)
                                                  AS owes
FROM expenses e
JOIN users u ON u.id = e.user_id
JOIN (
  SELECT trip_id, SUM(amount) AS trip_total
  FROM   expenses
  WHERE  trip_id = ?
  GROUP  BY trip_id
) total ON total.trip_id = e.trip_id
WHERE e.trip_id = ?
GROUP BY e.user_id;

-- ► SIMPLIFIED split view (used by collaboration controller)
SELECT
  user_id,
  SUM(amount) AS paid,
  (
    SUM(amount) - (
      SELECT SUM(amount) / COUNT(DISTINCT user_id)
      FROM   expenses
      WHERE  trip_id = ?
    )
  ) AS owes
FROM expenses
WHERE trip_id = ?
GROUP BY user_id;

-- ► GET total expenses per category for a trip
SELECT
  category,
  SUM(amount) AS actual_total
FROM   expenses
WHERE  trip_id = ?
GROUP  BY category;


-- =============================================================================
-- SECTION 3 — MAINTENANCE & UTILITY QUERIES
-- =============================================================================

-- ► CLEANUP: remove expired share links (run as a scheduled job)
DELETE FROM trip_shares
WHERE expires_at < datetime('now');

-- ► CLEANUP: orphan packing items with no matching trip
DELETE FROM packing_items
WHERE trip_id NOT IN (SELECT id FROM trips);

-- ► CLEANUP: orphan trip_photos with no matching trip
DELETE FROM trip_photos
WHERE trip_id NOT IN (SELECT id FROM trips);

-- ► CLEANUP: orphan trip_notes with no matching trip
DELETE FROM trip_notes
WHERE trip_id NOT IN (SELECT id FROM trips);

-- ► HEALTH CHECK: count rows in all v2 tables
SELECT 'packing_items'      AS tbl, COUNT(*) AS rows FROM packing_items
UNION ALL
SELECT 'packing_templates'  AS tbl, COUNT(*) AS rows FROM packing_templates
UNION ALL
SELECT 'document_checklist' AS tbl, COUNT(*) AS rows FROM document_checklist
UNION ALL
SELECT 'trip_shares'        AS tbl, COUNT(*) AS rows FROM trip_shares
UNION ALL
SELECT 'trip_notes'         AS tbl, COUNT(*) AS rows FROM trip_notes
UNION ALL
SELECT 'trip_photos'        AS tbl, COUNT(*) AS rows FROM trip_photos
UNION ALL
SELECT 'journal_entry_photos' AS tbl, COUNT(*) AS rows FROM journal_entry_photos
UNION ALL
SELECT 'bookings'           AS tbl, COUNT(*) AS rows FROM bookings
UNION ALL
SELECT 'tasks'              AS tbl, COUNT(*) AS rows FROM tasks
UNION ALL
SELECT 'collaborators'      AS tbl, COUNT(*) AS rows FROM collaborators;


-- =============================================================================
-- SECTION 4 — QUICK REFERENCE: TABLE ↔ FEATURE ↔ ROUTE MAPPING
-- =============================================================================
--
--  Table                   Feature                       Primary Route
--  ─────────────────────────────────────────────────────────────────────────
--  packing_items           Packing Checklist Generator   /trips/:id/packing
--  packing_templates       Packing Templates             /trips/:id/packing/templates
--                                                        /trips/:id/packing/generate
--  document_checklist      Document Checklist            /trips/:id/checklist/documents
--  documents               Document File Upload          /trips/:id/documents
--  trip_shares             Itinerary Sharing             /trips/:id/share
--                          Public Read                   /shares/:token
--  trip_notes              Trip Notes & Memories         /trips/:id/notes/:noteId
--  trip_photos             Photo Gallery                 /trips/:id/photos/:photoId
--  journal_entries         Travel Journal                /trips/:id/journal
--  journal_entry_photos    Journal Entry Photos          /trips/:id/journal/:entryId/photos
--  bookings                Bookings                      /trips/:id/bookings/:bookingId
--  tasks                   Collaboration Tasks           /trips/:id/tasks/:taskId
--  collaborators           Collaboration Members         /trips/:id/collaborators/:userId
--  expenses                Budget / Expense Splits       /trips/:id/expenses
--  budgets                 Category Budgets              /trips/:id/budget
--
-- =============================================================================
-- END OF FILE
-- =============================================================================
