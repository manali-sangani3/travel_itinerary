const db = require('../db');

exports.findByTrip = (tripId) => db.prepare('SELECT * FROM bookings WHERE trip_id = ?').all(tripId);
exports.findById = (id) => db.prepare('SELECT * FROM bookings WHERE id = ?').get(id);
exports.create = (b) => db.prepare('INSERT INTO bookings (id, trip_id, type, reference_number, details) VALUES (@id, @trip_id, @type, @reference_number, @details)').run(b);
exports.update = (id, fields) => {
  const sets = Object.keys(fields).map((k) => `${k} = @${k}`).join(', ');
  return db.prepare(`UPDATE bookings SET ${sets} WHERE id = @id`).run({ ...fields, id });
};
exports.delete = (id) => db.prepare('DELETE FROM bookings WHERE id = ?').run(id);
