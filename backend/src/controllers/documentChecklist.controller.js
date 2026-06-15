const db = require('../db');
const crypto = require('crypto');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

const DEFAULT_DOCUMENTS = [
  'Passport',
  'Visa',
  'Tickets',
  'Travel Insurance',
  'Vaccination Certificates',
  'Hotel Vouchers'
];

exports.getChecklist = wrap(async (req, res) => {
  const tripId = req.params.id;
  
  let items = db.prepare('SELECT * FROM document_checklist WHERE trip_id = ?').all(tripId);
  
  if (items.length === 0) {
    const stmt = db.prepare('INSERT INTO document_checklist (id, trip_id, label, checked) VALUES (?, ?, ?, 0)');
    for (const label of DEFAULT_DOCUMENTS) {
      stmt.run(crypto.randomUUID(), tripId, label);
    }
    items = db.prepare('SELECT * FROM document_checklist WHERE trip_id = ?').all(tripId);
  }

  res.json(items);
});

exports.updateChecklist = wrap(async (req, res) => {
  const { itemId, checked } = req.body;
  
  db.prepare('UPDATE document_checklist SET checked = ? WHERE id = ?')
    .run(checked ? 1 : 0, itemId);

  res.json({ message: 'Updated successfully' });
});
