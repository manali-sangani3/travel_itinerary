const db = require('../db');

exports.findAllByUser = (userId) => db.prepare(`
  SELECT t.* FROM trips t
  LEFT JOIN collaborators c ON c.trip_id = t.id AND c.user_id = ?
  WHERE t.owner_id = ? OR c.user_id = ?
`).all(userId, userId, userId);

exports.findById = (id) => db.prepare('SELECT * FROM trips WHERE id = ?').get(id);

exports.create = (trip) => db.prepare(`
  INSERT INTO trips (id, owner_id, destination, start_date, end_date, purpose, companions, status)
  VALUES (@id, @owner_id, @destination, @start_date, @end_date, @purpose, @companions, @status)
`).run(trip);

exports.update = (id, fields) => {
  const sets = Object.keys(fields).map((k) => `${k} = @${k}`).join(', ');
  return db.prepare(`UPDATE trips SET ${sets}, updated_at = datetime('now') WHERE id = @id`).run({ ...fields, id });
};

exports.delete = (id) => db.prepare('DELETE FROM trips WHERE id = ?').run(id);
