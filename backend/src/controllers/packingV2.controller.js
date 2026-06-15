const db = require('../db');
const crypto = require('crypto');

const wrap = (fn) => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

exports.getTemplates = wrap(async (req, res) => {
  const templates = db.prepare('SELECT * FROM packing_templates').all();
  // parse items JSON string
  const results = templates.map((t) => ({
    id: t.id,
    name: t.name,
    tripType: t.trip_type,
    items: JSON.parse(t.items)
  }));
  res.json(results);
});

exports.generateList = wrap(async (req, res, next) => {
  const tripId = req.params.id;
  const { templateId } = req.body;

  const t = db.prepare('SELECT * FROM packing_templates WHERE id = ?').get(templateId);
  if (!t) {
    // Fallback to Beach Holiday if template not found
    const defaultTemplate = db.prepare('SELECT * FROM packing_templates LIMIT 1').get();
    if (!defaultTemplate) return res.status(404).json({ error: 'No templates available' });
    return redirectGeneration(tripId, defaultTemplate, res);
  }

  return redirectGeneration(tripId, t, res);
});

function redirectGeneration(tripId, template, res) {
  const items = JSON.parse(template.items);
  
  // Optional: clear existing packing items
  db.prepare('DELETE FROM packing_items WHERE trip_id = ?').run(tripId);

  const stmt = db.prepare('INSERT INTO packing_items (id, trip_id, label, category, checked) VALUES (?, ?, ?, ?, 0)');
  for (const item of items) {
    stmt.run(crypto.randomUUID(), tripId, item, template.name);
  }

  const generatedItems = db.prepare('SELECT * FROM packing_items WHERE trip_id = ?').all(tripId);
  res.status(201).json(generatedItems);
}
