const db = require('../db');

exports.findByTrip = (tripId) => db.prepare('SELECT * FROM itinerary_items WHERE trip_id = ? ORDER BY day_index, order_index').all(tripId);
exports.findById = (id) => db.prepare('SELECT * FROM itinerary_items WHERE id = ?').get(id);
exports.create = (item) => db.prepare(`
  INSERT INTO itinerary_items (id, trip_id, day_index, order_index, title, location, start_time, end_time)
  VALUES (@id, @trip_id, @day_index, @order_index, @title, @location, @start_time, @end_time)
`).run(item);
exports.update = (id, fields) => {
  const sets = Object.keys(fields).map((k) => `${k} = @${k}`).join(', ');
  return db.prepare(`UPDATE itinerary_items SET ${sets}, updated_at = datetime('now') WHERE id = @id`).run({ ...fields, id });
};
exports.delete = (id) => db.prepare('DELETE FROM itinerary_items WHERE id = ?').run(id);

exports.reorder = db.transaction((items) => {
  const stmt = db.prepare("UPDATE itinerary_items SET order_index = @order_index, updated_at = datetime('now') WHERE id = @id");
  for (const item of items) stmt.run(item);
});
