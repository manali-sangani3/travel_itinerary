const db = require('../db');

exports.findByTrip = (tripId) => db.prepare('SELECT * FROM journal_entries WHERE trip_id = ? ORDER BY entry_date DESC, created_at DESC').all(tripId);
exports.findById = (id) => db.prepare('SELECT * FROM journal_entries WHERE id = ?').get(id);
exports.create = (e) => db.prepare('INSERT INTO journal_entries (id, trip_id, user_id, entry_date, body, photos) VALUES (@id, @trip_id, @user_id, @entry_date, @body, @photos)').run(e);
exports.update = (id, fields) => {
  const sets = Object.keys(fields).map((k) => `${k} = @${k}`).join(', ');
  return db.prepare(`UPDATE journal_entries SET ${sets} WHERE id = @id`).run({ ...fields, id });
};
exports.delete = (id) => db.prepare('DELETE FROM journal_entries WHERE id = ?').run(id);

exports.addPhoto = (id, photos) => db.prepare('UPDATE journal_entries SET photos = ? WHERE id = ?').run(JSON.stringify(photos), id);
