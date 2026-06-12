const db = require('../db');

exports.findByTrip = (tripId) => db.prepare('SELECT * FROM packing_items WHERE trip_id = ?').all(tripId);
exports.create = (item) => db.prepare('INSERT INTO packing_items (id, trip_id, label, category, checked) VALUES (@id, @trip_id, @label, @category, @checked)').run(item);
exports.update = (id, fields) => {
  const sets = Object.keys(fields).map((k) => `${k} = @${k}`).join(', ');
  return db.prepare(`UPDATE packing_items SET ${sets} WHERE id = @id`).run({ ...fields, id });
};
exports.delete = (id) => db.prepare('DELETE FROM packing_items WHERE id = ?').run(id);
