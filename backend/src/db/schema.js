const db = require('./index');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    travel_preferences TEXT DEFAULT '{}',
    passport_details TEXT,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS refresh_tokens (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    expires_at TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS trips (
    id TEXT PRIMARY KEY,
    owner_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    destination TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT NOT NULL,
    purpose TEXT,
    companions TEXT DEFAULT '[]',
    status TEXT DEFAULT 'planning',
    home_currency TEXT DEFAULT 'USD',
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS itinerary_items (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    day_index INTEGER NOT NULL,
    order_index INTEGER NOT NULL,
    title TEXT NOT NULL,
    location TEXT,
    start_time TEXT,
    end_time TEXT,
    updated_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS bookings (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    reference_number TEXT,
    details TEXT DEFAULT '{}',
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS documents (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    uploader_id TEXT NOT NULL REFERENCES users(id),
    file_path TEXT NOT NULL,
    doc_type TEXT NOT NULL,
    original_name TEXT,
    uploaded_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS expenses (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id),
    category TEXT NOT NULL,
    amount REAL NOT NULL,
    currency TEXT NOT NULL,
    note TEXT,
    recorded_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS budgets (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    amount REAL NOT NULL,
    UNIQUE(trip_id, category)
  );

  CREATE TABLE IF NOT EXISTS collaborators (
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'viewer',
    PRIMARY KEY (trip_id, user_id)
  );

  CREATE TABLE IF NOT EXISTS tasks (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    assigned_to TEXT REFERENCES users(id),
    title TEXT NOT NULL,
    completed INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS comments (
    id TEXT PRIMARY KEY,
    item_id TEXT NOT NULL REFERENCES itinerary_items(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id),
    body TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS journal_entries (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(id),
    entry_date TEXT NOT NULL,
    body TEXT,
    photos TEXT DEFAULT '[]',
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS packing_items (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    category TEXT,
    checked INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS trip_shares (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    share_token TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('viewer', 'editor')),
    expires_at TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS document_checklist (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    label TEXT NOT NULL,
    checked INTEGER DEFAULT 0
  );

  CREATE TABLE IF NOT EXISTS packing_templates (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    trip_type TEXT NOT NULL,
    items TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS trip_notes (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    day_date TEXT,
    location_tag TEXT,
    created_at TEXT DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS trip_photos (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    location_tag TEXT,
    date_taken TEXT NOT NULL,
    uploaded_at TEXT DEFAULT (datetime('now'))
  );
`);

try {
  db.exec("ALTER TABLE trips ADD COLUMN home_currency TEXT DEFAULT 'USD'");
} catch (e) {
  // Column already exists
}

// Seed default packing templates if empty
const count = db.prepare("SELECT COUNT(*) as count FROM packing_templates").get();
if (count.count === 0) {
  const templates = [
    { id: 't1', name: 'Beach Holiday', tripType: 'beach', items: JSON.stringify(['Swimwear', 'Sunscreen', 'Sunglasses', 'Beach Towel', 'Flip Flops', 'Hat']) },
    { id: 't2', name: 'Business Trip', tripType: 'business', items: JSON.stringify(['Suit/Blazer', 'Formal Shoes', 'Tie', 'Laptop Charger', 'Notebook', 'Business Cards']) },
    { id: 't3', name: 'Backpacking', tripType: 'hiking', items: JSON.stringify(['Backpack Rain Cover', 'Hiking Boots', 'Water Bottle', 'Map/Compass', 'First Aid Kit', 'Multi-tool']) },
    { id: 't4', name: 'Winter Vacation', tripType: 'winter', items: JSON.stringify(['Heavy Coat', 'Thermal Wear', 'Gloves', 'Beanie', 'Scarf', 'Snow Boots']) },
    { id: 't5', name: 'Road Trip', tripType: 'road', items: JSON.stringify(['Car Charger', 'Offline Maps', 'First Aid Kit', 'Snacks', 'Travel Pillow', 'Playlist']) }
  ];
  const stmt = db.prepare("INSERT INTO packing_templates (id, name, trip_type, items) VALUES (?, ?, ?, ?)");
  for (const t of templates) {
    stmt.run(t.id, t.name, t.tripType, t.items);
  }
}

module.exports = db;
