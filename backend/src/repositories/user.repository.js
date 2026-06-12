const db = require('../db');

exports.findByEmail = (email) => db.prepare('SELECT * FROM users WHERE email = ?').get(email);
exports.findById = (id) => db.prepare('SELECT id, email, travel_preferences, passport_details FROM users WHERE id = ?').get(id);
exports.create = (user) => db.prepare('INSERT INTO users (id, email, password_hash) VALUES (@id, @email, @password_hash)').run(user);
exports.updatePreferences = (id, prefs) => db.prepare('UPDATE users SET travel_preferences = ? WHERE id = ?').run(JSON.stringify(prefs), id);
exports.updatePassport = (id, encrypted) => db.prepare('UPDATE users SET passport_details = ? WHERE id = ?').run(encrypted, id);

exports.saveRefreshToken = (id, userId, token, expiresAt) =>
  db.prepare('INSERT INTO refresh_tokens (id, user_id, token, expires_at) VALUES (?, ?, ?, ?)').run(id, userId, token, expiresAt);
exports.findRefreshToken = (token) => db.prepare('SELECT * FROM refresh_tokens WHERE token = ?').get(token);
exports.deleteRefreshToken = (token) => db.prepare('DELETE FROM refresh_tokens WHERE token = ?').run(token);
exports.deleteAllUserTokens = (userId) => db.prepare('DELETE FROM refresh_tokens WHERE user_id = ?').run(userId);
