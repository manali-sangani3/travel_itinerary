const db = require('../db');

exports.getCollaborators = (tripId) => db.prepare('SELECT c.*, u.email FROM collaborators c JOIN users u ON u.id = c.user_id WHERE c.trip_id = ?').all(tripId);
exports.add = (tripId, userId, role) => db.prepare('INSERT INTO collaborators (trip_id, user_id, role) VALUES (?, ?, ?)').run(tripId, userId, role);
exports.updateRole = (tripId, userId, role) => db.prepare('UPDATE collaborators SET role = ? WHERE trip_id = ? AND user_id = ?').run(role, tripId, userId);
exports.remove = (tripId, userId) => db.prepare('DELETE FROM collaborators WHERE trip_id = ? AND user_id = ?').run(tripId, userId);
exports.find = (tripId, userId) => db.prepare('SELECT * FROM collaborators WHERE trip_id = ? AND user_id = ?').get(tripId, userId);
exports.countAdmins = (tripId) => db.prepare("SELECT COUNT(*) as n FROM collaborators WHERE trip_id = ? AND role = 'admin'").get(tripId).n;

exports.getTasks = (tripId) => db.prepare('SELECT * FROM tasks WHERE trip_id = ?').all(tripId);
exports.createTask = (t) => db.prepare('INSERT INTO tasks (id, trip_id, assigned_to, title) VALUES (@id, @trip_id, @assigned_to, @title)').run(t);
exports.updateTask = (id, fields) => {
  const sets = Object.keys(fields).map((k) => `${k} = @${k}`).join(', ');
  return db.prepare(`UPDATE tasks SET ${sets} WHERE id = @id`).run({ ...fields, id });
};

exports.getComments = (itemId) => db.prepare('SELECT c.*, u.email FROM comments c JOIN users u ON u.id = c.user_id WHERE c.item_id = ?').all(itemId);
exports.createComment = (c) => db.prepare('INSERT INTO comments (id, item_id, user_id, body) VALUES (@id, @item_id, @user_id, @body)').run(c);

exports.getSplits = (tripId) => {
  const expenses = db.prepare('SELECT user_id, SUM(amount) as total FROM expenses WHERE trip_id = ? GROUP BY user_id').all(tripId);
  if (!expenses.length) return [];
  const grand = expenses.reduce((s, e) => s + e.total, 0);
  const share = grand / expenses.length;
  return expenses.map((e) => ({ user_id: e.user_id, paid: e.total, owes: +(share - e.total).toFixed(2) }));
};
